import 'dart:io';

import 'package:benim_kutuphanem/servisler/kutuphane_servisi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// Onceki surumun olusturdugu, Oncelik sutunu olmayan bir veritabani
/// yeni surumle acildiginda veri kaybolmadan yeni semaya gecmeli.
void main() {
  late Directory klasor;

  setUp(() => klasor = Directory.systemTemp.createTempSync('kutuphane_gecis'));
  tearDown(() => klasor.deleteSync(recursive: true));

  test('eski istek listesi tablosuna Oncelik sutunu eklenir', () async {
    final yol = p.join(klasor.path, 'eski.db');

    final eski = sqlite3.open(yol);
    eski.execute('''
      CREATE TABLE IstekListesi (
          IstekId       INTEGER PRIMARY KEY AUTOINCREMENT,
          SiraNo        INTEGER NOT NULL UNIQUE,
          Ad            TEXT    NOT NULL,
          YazarId       INTEGER,
          YayineviId    INTEGER,
          TurId         INTEGER,
          SayfaSayisi   INTEGER,
          SiteId        INTEGER,
          FiyatKurus    INTEGER,
          SatinAlindi   INTEGER NOT NULL DEFAULT 0,
          EklenmeTarihi TEXT    NOT NULL DEFAULT (datetime('now'))
      );
      CREATE VIEW vw_IstekListesi AS
      SELECT i.IstekId, i.SiraNo, i.Ad, NULL AS Yazar, NULL AS Yayinevi,
             NULL AS Tur, i.SayfaSayisi, NULL AS Site, i.FiyatKurus,
             i.SatinAlindi, i.EklenmeTarihi
      FROM IstekListesi AS i;
      INSERT INTO IstekListesi (SiraNo, Ad) VALUES (1, 'Eski Kayit');
    ''');
    eski.close();

    // Klasor silinmeden once dosya kapanmali (Windows acik dosyayi silmez).
    final servis = KutuphaneServisi.ac(yol: yol);
    try {
      await servis.girisYap('admin', '1234');

      final liste = await servis.istekleriGetir();
      expect(liste.single.ad, 'Eski Kayit');
      expect(liste.single.oncelik, isNull);

      await servis.ilkOnaEkle(liste.single.istekId);
      expect((await servis.ilkOnuGetir()).single.oncelik, 1);
    } finally {
      servis.kapat();
    }
  });
}
