# -*- coding: utf-8 -*-
"""
Uygulama ikonunu uretir:  app/windows/runner/resources/app_icon.ico

Ikon, uygulamanin icinde kullanilan Material "menu_book_rounded" simgesinin
(0xF8B4) aynisidir; boylece pencere basligi, gorev cubugu ve giris ekranindaki
logo birbiriyle tutarli olur.

Once 1024x1024 bir ana goruntu ciziliyor, sonra her ikon boyutuna
LANCZOS ile kucultuluyor. Kucuk boyutlarda dogrudan cizim yerine kucultme
kullanilmasi kenarlarin daha temiz cikmasini sagliyor.

Kullanim:
    python tools/ikon_olustur.py
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

PROJE = Path(__file__).resolve().parent.parent
ICO_YOLU = PROJE / "app" / "windows" / "runner" / "resources" / "app_icon.ico"
ONIZLEME_YOLU = PROJE / "tools" / "ikon_onizleme.png"

# Material Icons yazi tipi icin aranacak yerler (ilk bulunan kullanilir)
YAZI_TIPI_ADAYLARI = [
    PROJE / "app" / "build" / "windows" / "x64" / "runner" / "Release" / "data"
          / "flutter_assets" / "fonts" / "MaterialIcons-Regular.otf",
    Path(r"C:/flutter/bin/cache/dart-sdk/bin/resources/devtools/assets/fonts/MaterialIcons-Regular.otf"),
]

SIMGE = chr(0xF8B4)          # Icons.menu_book_rounded
ANA_BOYUT = 1024
BOYUTLAR = [256, 128, 64, 48, 32, 24, 16]

UST_RENK = (58, 111, 165)    # #3A6FA5
ALT_RENK = (32, 66, 100)     # #204264
SIMGE_RENGI = (255, 255, 255)


def yazi_tipi_bul() -> Path:
    for yol in YAZI_TIPI_ADAYLARI:
        if yol.exists():
            return yol
    sys.exit(
        "MaterialIcons-Regular.otf bulunamadi.\n"
        "Once 'flutter build windows --release' calistirin ya da\n"
        "YAZI_TIPI_ADAYLARI listesine Flutter SDK yolunuzu ekleyin."
    )


def ana_goruntu(yazi_tipi_yolu: Path, simge_orani: float = 0.60) -> Image.Image:
    n = ANA_BOYUT

    # 1) Dikey degrade zemin
    zemin = Image.new("RGB", (n, n))
    cizim = ImageDraw.Draw(zemin)
    for y in range(n):
        oran = y / (n - 1)
        cizim.line(
            [(0, y), (n, y)],
            fill=tuple(
                round(UST_RENK[k] + (ALT_RENK[k] - UST_RENK[k]) * oran) for k in range(3)
            ),
        )

    # 2) Yuvarlatilmis kose maskesi (Windows 11 uslubu, yaricap ~%22)
    maske = Image.new("L", (n, n), 0)
    ImageDraw.Draw(maske).rounded_rectangle(
        [0, 0, n - 1, n - 1], radius=round(n * 0.22), fill=255
    )

    ikon = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    ikon.paste(zemin, (0, 0), maske)

    # 3) Ust kenara hafif parlaklik: zeminin duz gorunmesini engelliyor
    parlaklik = Image.new("L", (n, n), 0)
    ImageDraw.Draw(parlaklik).ellipse(
        [-n * 0.35, -n * 0.85, n * 1.35, n * 0.42], fill=38
    )
    parlak_katman = Image.new("RGBA", (n, n), (255, 255, 255, 255))
    parlak_katman.putalpha(Image.composite(parlaklik, Image.new("L", (n, n), 0), maske))
    ikon = Image.alpha_composite(ikon, parlak_katman)

    # 4) Kitap simgesi, optik olarak ortalanmis
    yazi_tipi = ImageFont.truetype(str(yazi_tipi_yolu), round(n * simge_orani))
    kutu = yazi_tipi.getbbox(SIMGE)
    genislik = kutu[2] - kutu[0]
    yukseklik = kutu[3] - kutu[1]
    x = (n - genislik) / 2 - kutu[0]
    y = (n - yukseklik) / 2 - kutu[1]

    ImageDraw.Draw(ikon).text((x, y), SIMGE, font=yazi_tipi, fill=SIMGE_RENGI)
    return ikon


def onizleme(katmanlar: dict[int, Image.Image]) -> Image.Image:
    """Boyutlari yan yana gosteren kontrol goruntusu."""
    dolgu = 16
    gosterilecek = [256, 128, 64, 48, 32, 24, 16]
    genislik = sum(gosterilecek) + dolgu * (len(gosterilecek) + 1)
    tuval = Image.new("RGB", (genislik, 256 + dolgu * 2), (245, 245, 245))
    x = dolgu
    for boyut in gosterilecek:
        kucuk = katmanlar[boyut]
        tuval.paste(kucuk, (x, dolgu + (256 - boyut) // 2), kucuk)
        x += boyut + dolgu
    return tuval


def main() -> None:
    yazi_tipi_yolu = yazi_tipi_bul()

    # Buyuk boyutlarda ferah, kucuk boyutlarda daha dolgun bir simge:
    # 32 piksel ve altinda kitap kucuk kalip okunmaz hale geliyordu.
    buyuk = ana_goruntu(yazi_tipi_yolu, simge_orani=0.60)
    kucuk = ana_goruntu(yazi_tipi_yolu, simge_orani=0.76)

    katmanlar = {
        boyut: (buyuk if boyut >= 48 else kucuk).resize((boyut, boyut), Image.LANCZOS)
        for boyut in BOYUTLAR
    }

    ICO_YOLU.parent.mkdir(parents=True, exist_ok=True)
    # append_images ile her boyut kendi kaynagindan gomuluyor
    ilk = katmanlar[BOYUTLAR[0]]
    ilk.save(
        ICO_YOLU,
        format="ICO",
        sizes=[(b, b) for b in BOYUTLAR],
        append_images=[katmanlar[b] for b in BOYUTLAR[1:]],
    )
    onizleme(katmanlar).save(ONIZLEME_YOLU)

    print(f"Yazi tipi : {yazi_tipi_yolu}")
    print(f"Ikon      : {ICO_YOLU}  ({ICO_YOLU.stat().st_size} bayt)")
    print(f"Boyutlar  : {', '.join(f'{b}x{b}' for b in BOYUTLAR)}")
    print(f"Onizleme  : {ONIZLEME_YOLU}")


if __name__ == "__main__":
    main()
