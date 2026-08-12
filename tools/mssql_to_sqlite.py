# -*- coding: utf-8 -*-
"""
SQL Server -> SQLite tasima betigi.

Uygulama SQL Server yerine gomulu SQLite kullanmaya gecti. Bu betik, eski
BenimKutuphanem veritabanindaki kayitlari yeni SQLite dosyasina tasir.
Bir kereye mahsus calistirilir; dagitilan pakete girmez.

Tasinanlar:
    Kullanicilar (sifre hash'leri dahil - mevcut sifreler calismaya devam eder)
    Yazarlar, Yayinevleri, Turler, SatisSiteleri
    Kitaplar, IstekListesi

Fiyat donusumu: SQL Server'da DECIMAL(10,2), SQLite'ta kurus cinsinden
INTEGER. 249.90 -> 24990. Boylece ondalik hassasiyet kaybolmaz.

Kullanim:
    python tools/mssql_to_sqlite.py              # varsayilan hedefe yaz
    python tools/mssql_to_sqlite.py --hedef X.db # baska bir dosyaya yaz
    python tools/mssql_to_sqlite.py --kuru       # sadece raporla, yazma
"""

from __future__ import annotations

import argparse
import os
import sqlite3
import subprocess
import sys
import tempfile
from decimal import Decimal
from pathlib import Path

SUNUCU = r".\SQLEXPRESS"
VERITABANI = "BenimKutuphanem"
AYIRAC = "¦"  # broken bar - kitap adlarinda gecmez


def varsayilan_hedef() -> Path:
    yerel = os.environ.get("LOCALAPPDATA")
    if not yerel:
        sys.exit("LOCALAPPDATA bulunamadi; --hedef ile yol verin.")
    return Path(yerel) / "BenimKutuphanem" / "kutuphane.db"


def sorgula(sql: str) -> list[list[str | None]]:
    """sqlcmd ile sorguyu calistirir, satirlari alan listesi olarak dondurur."""
    with tempfile.TemporaryDirectory() as gecici:
        cikti = Path(gecici) / "out.txt"
        komut = [
            "sqlcmd", "-S", SUNUCU, "-E", "-d", VERITABANI,
            "-Q", "SET NOCOUNT ON; " + sql,
            "-o", str(cikti),
            "-u",            # UTF-16 cikti -> Turkce karakterler bozulmaz
            "-h", "-1",      # basliksiz
            "-W",            # sondaki bosluklari kirp
            "-w", "8000",
            "-s", AYIRAC,
        ]
        sonuc = subprocess.run(komut, capture_output=True, text=True)
        if sonuc.returncode != 0:
            sys.exit(f"sqlcmd hatasi:\n{sonuc.stdout}\n{sonuc.stderr}")
        ham = cikti.read_text(encoding="utf-16")

    satirlar = []
    for satir in ham.splitlines():
        if not satir.strip() or satir.startswith("(") or set(satir.strip()) <= {"-", AYIRAC}:
            continue
        satirlar.append([None if a == "NULL" else a.strip() for a in satir.split(AYIRAC)])
    return satirlar


def tam_sayi(deger: str | None) -> int | None:
    return None if deger is None else int(deger)


def kurus(deger: str | None) -> int | None:
    """DECIMAL metnini kurusa cevirir. Decimal kullanilir; float ara adimi
    250.00 gibi degerlerde 24999 sonucuna yol acabilirdi."""
    if deger is None:
        return None
    return int((Decimal(deger) * 100).quantize(Decimal("1")))


def oku():
    return {
        "kullanicilar": sorgula(
            "SELECT KullaniciId, KullaniciAdi, SifreHash, AdSoyad, "
            "CAST(Aktif AS INT), CONVERT(VARCHAR(19), OlusturmaTarihi, 120), "
            "CONVERT(VARCHAR(19), SonGirisTarihi, 120), "
            "CONVERT(VARCHAR(19), SifreDegistirmeTarihi, 120) "
            "FROM dbo.Kullanicilar ORDER BY KullaniciId;"
        ),
        "yazarlar": sorgula("SELECT YazarId, AdSoyad FROM dbo.Yazarlar ORDER BY YazarId;"),
        "yayinevleri": sorgula("SELECT YayineviId, Ad FROM dbo.Yayinevleri ORDER BY YayineviId;"),
        "turler": sorgula("SELECT TurId, Ad FROM dbo.Turler ORDER BY TurId;"),
        "siteler": sorgula("SELECT SiteId, Ad FROM dbo.SatisSiteleri ORDER BY SiteId;"),
        "kitaplar": sorgula(
            "SELECT KitapId, SiraNo, Ad, YazarId, YayineviId, TurId, SayfaSayisi, "
            "CAST(OkunduMu AS INT), CONVERT(VARCHAR(19), EklenmeTarihi, 120) "
            "FROM dbo.Kitaplar ORDER BY KitapId;"
        ),
        "istekler": sorgula(
            "SELECT IstekId, SiraNo, Ad, YazarId, YayineviId, TurId, SayfaSayisi, "
            "SiteId, Fiyat, CAST(SatinAlindi AS INT), "
            "CONVERT(VARCHAR(19), EklenmeTarihi, 120) "
            "FROM dbo.IstekListesi ORDER BY IstekId;"
        ),
    }


SEMA_KAYNAGI = Path(__file__).resolve().parent.parent / "app" / "lib" / "veritabani" / "sema.dart"


def sema_betigi() -> str:
    """Semayi Dart kaynagindan okur.

    Kopyalamak yerine okumanin sebebi: sema tek yerde tanimli kalsin.
    Dart tarafi degistiginde bu betik kendiliginden guncel olur.
    """
    if not SEMA_KAYNAGI.exists():
        sys.exit(f"Sema kaynagi bulunamadi: {SEMA_KAYNAGI}")

    metin = SEMA_KAYNAGI.read_text(encoding="utf-8")
    basla = metin.find("semaBetigi = '''")
    if basla == -1:
        sys.exit("sema.dart icinde semaBetigi bulunamadi.")
    basla += len("semaBetigi = '''")
    bitis = metin.find("'''", basla)
    if bitis == -1:
        sys.exit("sema.dart icindeki semaBetigi kapanmamis.")
    return metin[basla:bitis]


def yaz(hedef: Path, veri: dict) -> None:
    if not hedef.exists():
        print(f"  hedef yok, sema kuruluyor: {hedef}")
        hedef.parent.mkdir(parents=True, exist_ok=True)
        kur = sqlite3.connect(hedef)
        try:
            kur.executescript(sema_betigi())
        finally:
            kur.close()

    vt = sqlite3.connect(hedef)
    try:
        vt.execute("PRAGMA foreign_keys = OFF;")
        with vt:
            # Mevcut icerik temizlenir; tasima yerine ekleme yapilirsa
            # SiraNo ve Id catismalari olusurdu.
            for tablo in ("Kitaplar", "IstekListesi", "Yazarlar", "Yayinevleri",
                          "Turler", "SatisSiteleri", "Kullanicilar"):
                vt.execute(f"DELETE FROM {tablo};")
            vt.execute(
                "DELETE FROM sqlite_sequence WHERE name IN "
                "('Kitaplar','IstekListesi','Yazarlar','Yayinevleri',"
                "'Turler','SatisSiteleri','Kullanicilar');"
            )

            vt.executemany(
                "INSERT INTO Kullanicilar (KullaniciId, KullaniciAdi, SifreHash, AdSoyad,"
                " Aktif, OlusturmaTarihi, SonGirisTarihi, SifreDegistirmeTarihi)"
                " VALUES (?,?,?,?,?,?,?,?);",
                [(tam_sayi(s[0]), s[1], s[2], s[3], tam_sayi(s[4]), s[5], s[6], s[7])
                 for s in veri["kullanicilar"]],
            )
            vt.executemany(
                "INSERT INTO Yazarlar (YazarId, AdSoyad) VALUES (?,?);",
                [(tam_sayi(s[0]), s[1]) for s in veri["yazarlar"]],
            )
            vt.executemany(
                "INSERT INTO Yayinevleri (YayineviId, Ad) VALUES (?,?);",
                [(tam_sayi(s[0]), s[1]) for s in veri["yayinevleri"]],
            )
            vt.executemany(
                "INSERT INTO Turler (TurId, Ad) VALUES (?,?);",
                [(tam_sayi(s[0]), s[1]) for s in veri["turler"]],
            )
            vt.executemany(
                "INSERT INTO SatisSiteleri (SiteId, Ad) VALUES (?,?);",
                [(tam_sayi(s[0]), s[1]) for s in veri["siteler"]],
            )
            vt.executemany(
                "INSERT INTO Kitaplar (KitapId, SiraNo, Ad, YazarId, YayineviId, TurId,"
                " SayfaSayisi, OkunduMu, EklenmeTarihi) VALUES (?,?,?,?,?,?,?,?,?);",
                [(tam_sayi(s[0]), tam_sayi(s[1]), s[2], tam_sayi(s[3]), tam_sayi(s[4]),
                  tam_sayi(s[5]), tam_sayi(s[6]), tam_sayi(s[7]), s[8])
                 for s in veri["kitaplar"]],
            )
            vt.executemany(
                "INSERT INTO IstekListesi (IstekId, SiraNo, Ad, YazarId, YayineviId, TurId,"
                " SayfaSayisi, SiteId, FiyatKurus, SatinAlindi, EklenmeTarihi)"
                " VALUES (?,?,?,?,?,?,?,?,?,?,?);",
                [(tam_sayi(s[0]), tam_sayi(s[1]), s[2], tam_sayi(s[3]), tam_sayi(s[4]),
                  tam_sayi(s[5]), tam_sayi(s[6]), tam_sayi(s[7]), kurus(s[8]),
                  tam_sayi(s[9]), s[10])
                 for s in veri["istekler"]],
            )

        vt.execute("PRAGMA foreign_keys = ON;")
        bozuk = vt.execute("PRAGMA foreign_key_check;").fetchall()
        if bozuk:
            sys.exit(f"HATA: yabanci anahtar tutarsizligi: {bozuk[:5]}")
    finally:
        vt.close()


def main() -> int:
    ayristirici = argparse.ArgumentParser(description="SQL Server -> SQLite tasima")
    ayristirici.add_argument("--hedef", type=Path, default=None)
    ayristirici.add_argument("--kuru", action="store_true",
                             help="yazmadan yalnizca sayilari raporla")
    secenek = ayristirici.parse_args()

    hedef = secenek.hedef or varsayilan_hedef()

    print("SQL Server'dan okunuyor...")
    veri = oku()
    for ad, satirlar in veri.items():
        print(f"  {ad:14} {len(satirlar):>4} satir")

    if secenek.kuru:
        print("\n--kuru verildi, hicbir sey yazilmadi.")
        return 0

    print(f"\nSQLite'a yaziliyor: {hedef}")
    yaz(hedef, veri)

    vt = sqlite3.connect(hedef)
    try:
        ozet = vt.execute("SELECT * FROM vw_Ozet;").fetchone()
        sutunlar = [t[0] for t in vt.execute("SELECT * FROM vw_Ozet;").description]
    finally:
        vt.close()

    print("\nTasima tamamlandi. Ozet:")
    for ad, deger in zip(sutunlar, ozet):
        if ad == "IstekToplamKurus":
            print(f"  {ad:18} {deger} kurus  ({deger / 100:.2f} TL)")
        else:
            print(f"  {ad:18} {deger}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
