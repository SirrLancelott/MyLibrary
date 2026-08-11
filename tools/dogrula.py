# -*- coding: utf-8 -*-
"""
Excel  <->  SQL Server karsilastirmasi.

BenimKutuphanem veritabanina aktarilan verinin Excel ile birebir ayni olup
olmadigini satir satir, alan alan dogrular. Hicbir fark yoksa "FARK YOK" yazar.

Kullanim:
    python tools/dogrula.py
"""

from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from excel_to_sql import excel_oku  # noqa: E402

SUNUCU = r".\SQLEXPRESS"
VERITABANI = "BenimKutuphanem"
AYIRAC = "¦"  # broken bar - kitap adlarinda gecmez


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


def esittir(excel_deger, db_deger) -> bool:
    if excel_deger is None:
        return db_deger is None
    return str(excel_deger).strip() == str(db_deger).strip()


def main() -> int:
    sahip, istek, atlanan = excel_oku()
    farklar: list[str] = []

    # ---------------- Kitaplar ----------------
    db_kitap = {
        int(r[0]): r
        for r in sorgula(
            "SELECT SiraNo, Ad, ISNULL(Yazar,'NULL'), ISNULL(Yayinevi,'NULL'), "
            "ISNULL(Tur,'NULL'), ISNULL(CAST(SayfaSayisi AS NVARCHAR(10)),'NULL'), "
            "CAST(OkunduMu AS INT) FROM dbo.vw_Kitaplar ORDER BY SiraNo"
        )
    }
    if len(db_kitap) != len(sahip):
        farklar.append(f"Kitaplar satir sayisi: Excel={len(sahip)}  DB={len(db_kitap)}")

    for k in sahip:
        r = db_kitap.get(k["sira"])
        if r is None:
            farklar.append(f"Kitaplar #{k['sira']} ({k['ad']}) veritabaninda yok")
            continue
        for ad_alan, excel_deger, db_deger in [
            ("Ad", k["ad"], r[1]),
            ("Yazar", k["yazar"], r[2]),
            ("Yayinevi", k["yayinevi"], r[3]),
            ("Tur", k["tur"], r[4]),
            ("SayfaSayisi", k["sayfa"], r[5]),
            ("OkunduMu", k["okundu"], r[6]),
        ]:
            if not esittir(excel_deger, db_deger):
                farklar.append(
                    f"Kitaplar #{k['sira']} {ad_alan}: Excel={excel_deger!r} DB={db_deger!r}"
                )

    # ---------------- Istek listesi ----------------
    db_istek = {
        int(r[0]): r
        for r in sorgula(
            "SELECT SiraNo, Ad, ISNULL(Yazar,'NULL'), ISNULL(Yayinevi,'NULL'), "
            "ISNULL(Tur,'NULL'), ISNULL(CAST(SayfaSayisi AS NVARCHAR(10)),'NULL'), "
            "ISNULL(Site,'NULL'), ISNULL(CAST(CAST(Fiyat AS INT) AS NVARCHAR(10)),'NULL') "
            "FROM dbo.vw_IstekListesi ORDER BY SiraNo"
        )
    }
    if len(db_istek) != len(istek):
        farklar.append(f"IstekListesi satir sayisi: Excel={len(istek)}  DB={len(db_istek)}")

    for i in istek:
        r = db_istek.get(i["sira"])
        if r is None:
            farklar.append(f"IstekListesi #{i['sira']} ({i['ad']}) veritabaninda yok")
            continue
        for ad_alan, excel_deger, db_deger in [
            ("Ad", i["ad"], r[1]),
            ("Yazar", i["yazar"], r[2]),
            ("Yayinevi", i["yayinevi"], r[3]),
            ("Tur", i["tur"], r[4]),
            ("SayfaSayisi", i["sayfa"], r[5]),
            ("Site", i["site"], r[6]),
            ("Fiyat", i["fiyat"], r[7]),
        ]:
            if not esittir(excel_deger, db_deger):
                farklar.append(
                    f"IstekListesi #{i['sira']} {ad_alan}: Excel={excel_deger!r} DB={db_deger!r}"
                )

    print(f"Excel  : Kitaplar={len(sahip)}  IstekListesi={len(istek)}  atlanan={atlanan}")
    print(f"SQL    : Kitaplar={len(db_kitap)}  IstekListesi={len(db_istek)}")
    if farklar:
        print(f"\n{len(farklar)} FARK BULUNDU:")
        for f in farklar:
            print("  -", f)
        return 1

    print("\nFARK YOK - Excel ile veritabani birebir ayni.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
