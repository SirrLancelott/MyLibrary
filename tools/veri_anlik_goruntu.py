# -*- coding: utf-8 -*-
"""
Calisan kurulumdaki veritabaninin temiz bir anlik goruntusunu alir.

Uygulama WAL kipinde calisir; kutuphane.db dosyasini elle kopyalamak
yeterli degildir, son yazilanlar kutuphane.db-wal icinde durur. Bu betik
VACUUM INTO ile tek parca, WAL'siz, tutarli bir kopya uretir.

Kullanim:
    python tools/veri_anlik_goruntu.py <hedef.db> [kaynak.db]

Kaynak verilmezse varsayilan yol kullanilir:
    %LOCALAPPDATA%\\BenimKutuphanem\\kutuphane.db
"""

from __future__ import annotations

import os
import sqlite3
import sys
from pathlib import Path

KLASOR_ADI = "BenimKutuphanem"
DOSYA_ADI = "kutuphane.db"

# Anlik goruntude bulunmasi beklenen tablolar
BEKLENEN_TABLOLAR = ["Kitaplar", "IstekListesi", "Kullanicilar"]


def varsayilan_kaynak() -> Path:
    yerel = os.environ.get("LOCALAPPDATA")
    if yerel:
        return Path(yerel) / KLASOR_ADI / DOSYA_ADI
    ev = os.environ.get("USERPROFILE") or os.environ.get("HOME") or "."
    return Path(ev) / f".{KLASOR_ADI}" / DOSYA_ADI


def anlik_goruntu_al(kaynak: Path, hedef: Path) -> dict[str, int]:
    if not kaynak.is_file():
        sys.exit(f"HATA: Veritabani bulunamadi: {kaynak}")

    hedef.parent.mkdir(parents=True, exist_ok=True)
    # VACUUM INTO var olan dosyanin uzerine yazmaz
    for artik in (hedef, Path(f"{hedef}-wal"), Path(f"{hedef}-shm")):
        if artik.exists():
            artik.unlink()

    # Salt okunur ac: paketleme sirasinda kaynak veritabanina dokunulmaz
    vt = sqlite3.connect(f"file:{kaynak.as_posix()}?mode=ro", uri=True)
    try:
        vt.execute("VACUUM INTO ?;", (str(hedef),))
    finally:
        vt.close()

    return dogrula(hedef)


def dogrula(hedef: Path) -> dict[str, int]:
    """Kopyanin acilabildigini ve dolu oldugunu kontrol eder."""
    vt = sqlite3.connect(hedef)
    try:
        bozuk = vt.execute("PRAGMA integrity_check;").fetchone()[0]
        if bozuk != "ok":
            sys.exit(f"HATA: Kopya butunluk kontrolunden gecmedi: {bozuk}")

        mevcut = {ad for (ad,) in vt.execute(
            "SELECT name FROM sqlite_master WHERE type='table';"
        )}
        eksik = [t for t in BEKLENEN_TABLOLAR if t not in mevcut]
        if eksik:
            sys.exit(f"HATA: Kopyada su tablolar yok: {', '.join(eksik)}")

        return {t: vt.execute(f'SELECT COUNT(*) FROM "{t}";').fetchone()[0]
                for t in BEKLENEN_TABLOLAR}
    finally:
        vt.close()


def main(argv: list[str]) -> int:
    if not argv:
        sys.exit(__doc__)

    hedef = Path(argv[0]).resolve()
    kaynak = Path(argv[1]).resolve() if len(argv) > 1 else varsayilan_kaynak()

    sayilar = anlik_goruntu_al(kaynak, hedef)

    print(f"Kaynak : {kaynak}")
    print(f"Kopya  : {hedef}  ({hedef.stat().st_size // 1024} KB)")
    for ad, adet in sayilar.items():
        print(f"         {ad:<14} {adet}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
