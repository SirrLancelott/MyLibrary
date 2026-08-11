# -*- coding: utf-8 -*-
"""
BenimKutuphanem_Renkli.xlsx  ->  sql/02_veri.sql

Excel'deki "Kitap Listesi" sayfasi iki bagimsiz blok icerir:
    A:G  -> SAHIP OLDUKLARIM   (Numara, Kitap Adi, Yazar, Yayin, Tur, Sayfa, Okunma Durumu)
    I:P  -> ALMAK ISTEDIKLERIM (Numara, Kitap Adi, Yazar, Yayin, Tur, Sayfa, Site, Fiyat)

Bu betik iki blogu da okur, metinleri kirpar (bastaki/sondaki bosluklar),
referans degerlerini (yazar / yayinevi / tur / site) tekillestirir ve
tekrar tekrar calistirilabilir bir T-SQL veri betigi uretir.

Kullanim:
    python tools/excel_to_sql.py
"""

from __future__ import annotations

import sys
from pathlib import Path

import openpyxl

EXCEL_YOLU = Path(
    r"C:\Users\sekreterlik\Desktop\Notlar\Kütüphane Otomasyon\BenimKutuphanem_Renkli.xlsx"
)
SAYFA_ADI = "Kitap Listesi"
CIKTI = Path(__file__).resolve().parent.parent / "sql" / "02_veri.sql"

# Excel sutun indeksleri (0 tabanli)
SAHIP_SUTUNLARI = slice(0, 7)    # A..G
ISTEK_SUTUNLARI = slice(8, 16)   # I..P


def metin(deger) -> str | None:
    """Hucreyi kirpilmis metne cevirir; bos ise None dondurur."""
    if deger is None:
        return None
    s = str(deger).strip()
    return s or None


def sayi(deger) -> int | None:
    if deger is None or str(deger).strip() == "":
        return None
    return int(float(str(deger).strip().replace(",", ".")))


def sql_metin(deger: str | None) -> str:
    """T-SQL Unicode string literali; NULL guvenli, tirnak kacisli."""
    if deger is None:
        return "NULL"
    return "N'" + deger.replace("'", "''") + "'"


def sql_sayi(deger) -> str:
    return "NULL" if deger is None else str(deger)


def excel_oku():
    if not EXCEL_YOLU.exists():
        sys.exit(f"Excel dosyasi bulunamadi: {EXCEL_YOLU}")

    wb = openpyxl.load_workbook(EXCEL_YOLU, data_only=True)
    ws = wb[SAYFA_ADI]

    # 1. satir blok basligi, 2. satir sutun basliklari -> veri 3. satirdan baslar
    satirlar = list(ws.iter_rows(min_row=3, values_only=True))

    sahip, istek, atlanan = [], [], []

    for ham in satirlar:
        a = ham[SAHIP_SUTUNLARI]
        if any(h is not None and str(h).strip() for h in a):
            durum = (metin(a[6]) or "").lower()
            sahip.append(
                {
                    "sira": sayi(a[0]),
                    "ad": metin(a[1]),
                    "yazar": metin(a[2]),
                    "yayinevi": metin(a[3]),
                    "tur": metin(a[4]),
                    "sayfa": sayi(a[5]),
                    "okundu": 1 if durum.startswith("okundu") else 0,
                }
            )

        b = ham[ISTEK_SUTUNLARI]
        if any(h is not None and str(h).strip() for h in b):
            kayit = {
                "sira": sayi(b[0]),
                "ad": metin(b[1]),
                "yazar": metin(b[2]),
                "yayinevi": metin(b[3]),
                "tur": metin(b[4]),
                "sayfa": sayi(b[5]),
                "site": metin(b[6]),
                "fiyat": sayi(b[7]),
            }
            # Sadece numarasi olan, adi bos satirlar Excel'de bos yer tutuculardir
            if kayit["ad"] is None:
                atlanan.append(kayit["sira"])
            else:
                istek.append(kayit)

    return sahip, istek, atlanan


def tekil(kayitlar, anahtar) -> list[str]:
    """Verilen alanin bos olmayan tekil degerleri, alfabetik sirali."""
    return sorted({k[anahtar] for k in kayitlar if k.get(anahtar)}, key=str.casefold)


def merge_blogu(tablo: str, sutun: str, degerler: list[str]) -> str:
    if not degerler:
        return ""
    satirlar = ",\n".join(f"        ({sql_metin(d)})" for d in degerler)
    return (
        f"MERGE dbo.{tablo} AS h\n"
        f"USING (VALUES\n{satirlar}\n"
        f"      ) AS k ({sutun})\n"
        f"    ON h.{sutun} = k.{sutun}\n"
        f"WHEN NOT MATCHED BY TARGET THEN\n"
        f"    INSERT ({sutun}) VALUES (k.{sutun});\n"
        f"GO\n"
    )


def uret():
    sahip, istek, atlanan = excel_oku()

    yazarlar = tekil(sahip, "yazar") + tekil(istek, "yazar")
    yayinevleri = tekil(sahip, "yayinevi") + tekil(istek, "yayinevi")
    turler = tekil(sahip, "tur") + tekil(istek, "tur")
    siteler = tekil(istek, "site")

    # iki listeden gelenleri birlestirip tekrar tekillestir
    yazarlar = sorted(set(yazarlar), key=str.casefold)
    yayinevleri = sorted(set(yayinevleri), key=str.casefold)
    turler = sorted(set(turler), key=str.casefold)

    p = []
    p.append(
        "/* ============================================================================\n"
        "   BenimKutuphanem  -  Excel Veri Aktarimi\n"
        "   ----------------------------------------------------------------------------\n"
        "   BU DOSYA OTOMATIK URETILMISTIR - elle duzenlemeyin.\n"
        "   Ureten     : tools/excel_to_sql.py\n"
        f"   Kaynak     : {EXCEL_YOLU.name}  (sayfa: {SAYFA_ADI})\n"
        f"   Kitaplar   : {len(sahip)} satir\n"
        f"   IstekListesi: {len(istek)} satir\n"
        + (
            f"   Atlanan    : Excel'de sadece numarasi olan bos istek satirlari -> {atlanan}\n"
            if atlanan
            else ""
        )
        + "   ----------------------------------------------------------------------------\n"
        "   Onkosul    : 01_sema.sql calistirilmis olmali.\n"
        "   Calistirma : sqlcmd -S .\\SQLEXPRESS -E -d BenimKutuphanem -i 02_veri.sql\n"
        "   Betik tekrar calistirilabilir: Kitaplar ve IstekListesi bastan yuklenir.\n"
        "   ============================================================================ */\n\n"
        "USE BenimKutuphanem;\n"
        "GO\n\n"
        "SET NOCOUNT ON;\n"
        "SET XACT_ABORT ON;\n"
        "GO\n\n"
        "BEGIN TRANSACTION;\n"
        "GO\n\n"
        "/* --- Onceki aktarimi temizle (referans tablolari korunur) ---\n"
        "     TRUNCATE, DELETE'ten farkli olarak IDENTITY sayacini da\n"
        "     basa alir; boylece KitapId her zaman 1'den baslar.          --- */\n"
        "TRUNCATE TABLE dbo.Kitaplar;\n"
        "TRUNCATE TABLE dbo.IstekListesi;\n"
        "GO\n"
    )

    p.append(f"\n/* --- 1) Yazarlar ({len(yazarlar)} adet) --- */\n")
    p.append(merge_blogu("Yazarlar", "AdSoyad", yazarlar))

    p.append(f"\n/* --- 2) Yayinevleri ({len(yayinevleri)} adet) --- */\n")
    p.append(merge_blogu("Yayinevleri", "Ad", yayinevleri))

    p.append(f"\n/* --- 3) Turler ({len(turler)} adet) --- */\n")
    p.append(merge_blogu("Turler", "Ad", turler))

    p.append(f"\n/* --- 4) Satis siteleri ({len(siteler)} adet) --- */\n")
    p.append(merge_blogu("SatisSiteleri", "Ad", siteler))

    # ---- Kitaplar -------------------------------------------------------
    p.append(f"\n/* --- 5) Kitaplar / SAHIP OLDUKLARIM ({len(sahip)} satir) --- */\n")
    p.append(
        "INSERT INTO dbo.Kitaplar (SiraNo, Ad, YazarId, YayineviId, TurId, SayfaSayisi, OkunduMu)\n"
        "SELECT  v.SiraNo,\n"
        "        v.Ad,\n"
        "        (SELECT ya.YazarId    FROM dbo.Yazarlar    AS ya WHERE ya.AdSoyad = v.Yazar),\n"
        "        (SELECT yv.YayineviId FROM dbo.Yayinevleri AS yv WHERE yv.Ad      = v.Yayinevi),\n"
        "        (SELECT t.TurId       FROM dbo.Turler      AS t  WHERE t.Ad       = v.Tur),\n"
        "        v.SayfaSayisi,\n"
        "        v.OkunduMu\n"
        "FROM (VALUES\n"
    )
    kitap_satirlari = [
        "        ({sira:>4}, {ad}, {yazar}, {yayinevi}, {tur}, {sayfa}, {okundu})".format(
            sira=k["sira"],
            ad=sql_metin(k["ad"]),
            yazar=sql_metin(k["yazar"]),
            yayinevi=sql_metin(k["yayinevi"]),
            tur=sql_metin(k["tur"]),
            sayfa=sql_sayi(k["sayfa"]),
            okundu=k["okundu"],
        )
        for k in sahip
    ]
    p.append(",\n".join(kitap_satirlari))
    p.append(
        "\n     ) AS v (SiraNo, Ad, Yazar, Yayinevi, Tur, SayfaSayisi, OkunduMu);\n"
        "GO\n"
    )

    # ---- Istek listesi --------------------------------------------------
    p.append(f"\n/* --- 6) IstekListesi / ALMAK ISTEDIKLERIM ({len(istek)} satir) --- */\n")
    p.append(
        "INSERT INTO dbo.IstekListesi (SiraNo, Ad, YazarId, YayineviId, TurId, SayfaSayisi, SiteId, Fiyat)\n"
        "SELECT  v.SiraNo,\n"
        "        v.Ad,\n"
        "        (SELECT ya.YazarId    FROM dbo.Yazarlar      AS ya WHERE ya.AdSoyad = v.Yazar),\n"
        "        (SELECT yv.YayineviId FROM dbo.Yayinevleri   AS yv WHERE yv.Ad      = v.Yayinevi),\n"
        "        (SELECT t.TurId       FROM dbo.Turler        AS t  WHERE t.Ad       = v.Tur),\n"
        "        v.SayfaSayisi,\n"
        "        (SELECT s.SiteId      FROM dbo.SatisSiteleri AS s  WHERE s.Ad       = v.Site),\n"
        "        v.Fiyat\n"
        "FROM (VALUES\n"
    )
    istek_satirlari = [
        "        ({sira:>4}, {ad}, {yazar}, {yayinevi}, {tur}, {sayfa}, {site}, {fiyat})".format(
            sira=i["sira"],
            ad=sql_metin(i["ad"]),
            yazar=sql_metin(i["yazar"]),
            yayinevi=sql_metin(i["yayinevi"]),
            tur=sql_metin(i["tur"]),
            sayfa=sql_sayi(i["sayfa"]),
            site=sql_metin(i["site"]),
            fiyat=sql_sayi(i["fiyat"]),
        )
        for i in istek
    ]
    p.append(",\n".join(istek_satirlari))
    p.append(
        "\n     ) AS v (SiraNo, Ad, Yazar, Yayinevi, Tur, SayfaSayisi, Site, Fiyat);\n"
        "GO\n"
    )

    p.append(
        "\nCOMMIT TRANSACTION;\n"
        "GO\n\n"
        "/* --- Aktarim ozeti --- */\n"
        "SELECT 'Kitaplar' AS Tablo, COUNT(*) AS Satir FROM dbo.Kitaplar\n"
        "UNION ALL SELECT 'IstekListesi', COUNT(*) FROM dbo.IstekListesi\n"
        "UNION ALL SELECT 'Yazarlar',     COUNT(*) FROM dbo.Yazarlar\n"
        "UNION ALL SELECT 'Yayinevleri',  COUNT(*) FROM dbo.Yayinevleri\n"
        "UNION ALL SELECT 'Turler',       COUNT(*) FROM dbo.Turler\n"
        "UNION ALL SELECT 'SatisSiteleri',COUNT(*) FROM dbo.SatisSiteleri;\n"
        "GO\n"
    )

    CIKTI.parent.mkdir(parents=True, exist_ok=True)
    # sqlcmd BOM'lu UTF-8 dosyalari Unicode olarak dogru okur
    CIKTI.write_text("".join(p), encoding="utf-8-sig")

    print(f"Yazildi : {CIKTI}")
    print(f"Kitaplar: {len(sahip)}  IstekListesi: {len(istek)}  (atlanan bos satir: {atlanan})")
    print(
        f"Yazar: {len(yazarlar)}  Yayinevi: {len(yayinevleri)}  "
        f"Tur: {len(turler)}  Site: {len(siteler)}"
    )


if __name__ == "__main__":
    uret()
