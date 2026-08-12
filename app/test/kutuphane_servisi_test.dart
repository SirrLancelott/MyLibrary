import 'package:benim_kutuphanem/modeller/modeller.dart';
import 'package:benim_kutuphanem/servisler/kutuphane_servisi.dart';
import 'package:flutter_test/flutter_test.dart';

/// Veri katmaninin tamami bellek ici SQLite uzerinde denenir.
void main() {
  late KutuphaneServisi servis;

  setUp(() async {
    servis = KutuphaneServisi.bellekte();
    await servis.girisYap('admin', '1234');
  });

  tearDown(() => servis.kapat());

  Future<Kitap> ornekKitap({
    String ad = 'Tutunamayanlar',
    String? yazar = 'Oğuz Atay',
    String? yayinevi = 'İletişim',
    String? tur = 'Roman',
    int? sayfa = 724,
    bool okundu = false,
  }) =>
      servis.kitapEkle(Kitap(
        kitapId: 0,
        siraNo: 0,
        ad: ad,
        yazar: yazar,
        yayinevi: yayinevi,
        tur: tur,
        sayfaSayisi: sayfa,
        okunduMu: okundu,
      ));

  Future<void> ornekIstek({
    String ad = 'Dune',
    String? tur = 'Bilim Kurgu',
    String? site = 'Kitap Yurdu',
    double? fiyat = 249.90,
    bool alindi = false,
  }) =>
      servis.istekEkle(Istek(
        istekId: 0,
        siraNo: 0,
        ad: ad,
        yazar: 'Frank Herbert',
        tur: tur,
        site: site,
        fiyat: fiyat,
        satinAlindi: alindi,
      ));

  group('Giris', () {
    test('bos veritabaninda admin hesabi olusur ve giris yapilir', () async {
      final vt2 = KutuphaneServisi.bellekte();
      final oturum = await vt2.girisYap('admin', '1234');
      expect(oturum.kullaniciAdi, 'admin');
      expect(oturum.oncekiGiris, isNull, reason: 'ilk giriste onceki giris yok');
      vt2.kapat();
    });

    test('yanlis sifre ve olmayan kullanici ayni mesaji verir', () async {
      final vt2 = KutuphaneServisi.bellekte();
      String? m1, m2;
      try {
        await vt2.girisYap('admin', 'yanlis');
      } on KutuphaneHatasi catch (e) {
        m1 = e.mesaj;
      }
      try {
        await vt2.girisYap('olmayan', '1234');
      } on KutuphaneHatasi catch (e) {
        m2 = e.mesaj;
      }
      expect(m1, isNotNull);
      expect(m1, equals(m2));
      vt2.kapat();
    });

    test('ikinci giriste onceki giris zamani gelir', () async {
      final vt2 = KutuphaneServisi.bellekte();
      await vt2.girisYap('admin', '1234');
      final ikinci = await vt2.girisYap('admin', '1234');
      expect(ikinci.oncekiGiris, isNotNull);
      vt2.kapat();
    });

    test('giris yapilmadan veri istenirse hata verir', () async {
      final vt2 = KutuphaneServisi.bellekte();
      expect(() => vt2.ozetGetir(), throwsA(isA<KutuphaneHatasi>()));
      vt2.kapat();
    });
  });

  group('Kitaplar', () {
    test('eklenen kitap geri okunur, SiraNo otomatik artar', () async {
      final k1 = await ornekKitap();
      final k2 = await ornekKitap(ad: 'Tehlikeli Oyunlar');
      expect(k1.siraNo, 1);
      expect(k2.siraNo, 2);
      expect(k1.ad, 'Tutunamayanlar');
      expect(k1.yazar, 'Oğuz Atay');
    });

    test('arama Turkce buyuk/kucuk harf ayirmaz', () async {
      await ornekKitap(ad: 'İSTANBUL Hatırası');
      for (final terim in ['istanbul', 'İSTANBUL', 'İstanbul', 'hatırası']) {
        final sonuc = await servis.kitaplariGetir(arama: terim);
        expect(sonuc, hasLength(1), reason: 'arama terimi: $terim');
      }
    });

    test('arama yazar icinde de gecer', () async {
      await ornekKitap();
      expect(await servis.kitaplariGetir(arama: 'Oğuz'), hasLength(1));
      expect(await servis.kitaplariGetir(arama: 'bulunmaz'), isEmpty);
    });

    test('tur ve okundu filtreleri birlikte calisir', () async {
      await ornekKitap(ad: 'A', tur: 'Roman', okundu: true);
      await ornekKitap(ad: 'B', tur: 'Roman', okundu: false);
      await ornekKitap(ad: 'C', tur: 'Manga', okundu: true);

      expect(await servis.kitaplariGetir(tur: 'Roman'), hasLength(2));
      expect(await servis.kitaplariGetir(okundu: true), hasLength(2));
      expect(
        await servis.kitaplariGetir(tur: 'Roman', okundu: true),
        hasLength(1),
      );
      expect(await servis.kitaplariGetir(), hasLength(3));
    });

    test('guncelleme ve okundu anahtari', () async {
      final k = await ornekKitap();
      final guncel = await servis.kitapGuncelle(k.kitapId, k.kopyala(okunduMu: true));
      expect(guncel.okunduMu, isTrue);
      expect(guncel.ad, k.ad, reason: 'kopyala digerlerini korumali');
    });

    test('silme calisir, olmayan kayit hata verir', () async {
      final k = await ornekKitap();
      await servis.kitapSil(k.kitapId);
      expect(await servis.kitaplariGetir(), isEmpty);
      expect(() => servis.kitapSil(9999), throwsA(isA<KutuphaneHatasi>()));
    });

    test('bos ad reddedilir', () async {
      expect(
        () => ornekKitap(ad: '   '),
        throwsA(isA<KutuphaneHatasi>()),
      );
    });

    test('bos birakilan alanlar null kalir', () async {
      final k = await ornekKitap(yazar: null, yayinevi: null, tur: null, sayfa: null);
      expect(k.yazar, isNull);
      expect(k.tur, isNull);
      expect(k.sayfaSayisi, isNull);
    });
  });

  group('Referanslar', () {
    test('listede olmayan deger otomatik olusur, tekrarlanmaz', () async {
      await ornekKitap(ad: 'A', yazar: 'Yeni Yazar');
      await ornekKitap(ad: 'B', yazar: 'Yeni Yazar');
      final ref = await servis.referanslariGetir();
      expect(ref.yazarlar.where((y) => y == 'Yeni Yazar'), hasLength(1));
    });

    test('kitap ve istek ayni referans tablosunu paylasir', () async {
      await ornekKitap(tur: 'Manga');
      await ornekIstek(tur: 'Manga');
      final ref = await servis.referanslariGetir();
      expect(ref.turler.where((t) => t == 'Manga'), hasLength(1));
    });

    test('bastaki sondaki bosluk kirpilir', () async {
      await ornekKitap(yayinevi: '  Kitap Yurdu  ');
      final ref = await servis.referanslariGetir();
      expect(ref.yayinevleri, contains('Kitap Yurdu'));
    });
  });

  group('Istek listesi ve fiyat', () {
    test('fiyat kurus hassasiyetiyle korunur', () async {
      await ornekIstek(fiyat: 249.90);
      final liste = await servis.istekleriGetir();
      expect(liste.first.fiyat, 249.90);
    });

    test('bircok fiyat toplaminda yuvarlama hatasi birikmez', () async {
      for (final f in [0.10, 0.20, 0.30, 19.99, 249.90]) {
        await ornekIstek(ad: 'Kitap $f', fiyat: f);
      }
      final ozet = await servis.ozetGetir();
      expect(ozet.istekToplamTutar, 270.49);
    });

    test('satin alinanlar toplam tutara girmez', () async {
      await ornekIstek(ad: 'A', fiyat: 100.00, alindi: false);
      await ornekIstek(ad: 'B', fiyat: 50.00, alindi: true);
      final ozet = await servis.ozetGetir();
      expect(ozet.istekAdedi, 2);
      expect(ozet.istekToplamTutar, 100.00);
    });

    test('site filtresi calisir', () async {
      await ornekIstek(ad: 'A', site: 'Amazon');
      await ornekIstek(ad: 'B', site: 'D&R');
      expect(await servis.istekleriGetir(site: 'Amazon'), hasLength(1));
    });

    test('fiyati olmayan kayit kabul edilir', () async {
      await ornekIstek(fiyat: null);
      expect((await servis.istekleriGetir()).first.fiyat, isNull);
    });
  });

  group('Kitapliga tasima', () {
    test('istek silinir, kitap okunmadi olarak eklenir', () async {
      await ornekIstek(ad: 'Dune', tur: 'Bilim Kurgu');
      final istek = (await servis.istekleriGetir()).first;

      await servis.istegiKitapligaTasi(istek.istekId);

      expect(await servis.istekleriGetir(), isEmpty);
      final kitaplar = await servis.kitaplariGetir();
      expect(kitaplar, hasLength(1));
      expect(kitaplar.first.ad, 'Dune');
      expect(kitaplar.first.tur, 'Bilim Kurgu');
      expect(kitaplar.first.okunduMu, isFalse);
    });

    test('olmayan kayit tasinmaya calisilirsa hicbir sey degismez', () async {
      await ornekIstek();
      expect(
        () => servis.istegiKitapligaTasi(9999),
        throwsA(isA<KutuphaneHatasi>()),
      );
      expect(await servis.istekleriGetir(), hasLength(1));
      expect(await servis.kitaplariGetir(), isEmpty);
    });
  });

  group('Ozet', () {
    test('sayilar dogru', () async {
      await ornekKitap(ad: 'A', sayfa: 100, okundu: true);
      await ornekKitap(ad: 'B', sayfa: 250, okundu: false);
      await ornekKitap(ad: 'C', sayfa: null, okundu: false);

      final ozet = await servis.ozetGetir();
      expect(ozet.toplamKitap, 3);
      expect(ozet.okunanKitap, 1);
      expect(ozet.okunmayanKitap, 2);
      expect(ozet.toplamSayfa, 350);
    });

    test('bos kutuphanede sifirlar doner', () async {
      final ozet = await servis.ozetGetir();
      expect(ozet.toplamKitap, 0);
      expect(ozet.istekToplamTutar, 0);
    });
  });

  group('Sifre degistirme', () {
    test('basarili degisiklikten sonra yeni sifre gecerli olur', () async {
      await servis.sifreDegistir('1234', 'yeniSifre');
      expect(servis.girisYapildi, isFalse, reason: 'oturum kapanmali');

      expect(
        () => servis.girisYap('admin', '1234'),
        throwsA(isA<KutuphaneHatasi>()),
      );
      final oturum = await servis.girisYap('admin', 'yeniSifre');
      expect(oturum.kullaniciAdi, 'admin');
    });

    test('kurallar uygulanir', () async {
      expect(() => servis.sifreDegistir('1234', '123'), throwsA(isA<KutuphaneHatasi>()));
      expect(() => servis.sifreDegistir('1234', '1234'), throwsA(isA<KutuphaneHatasi>()));
      expect(() => servis.sifreDegistir('yanlis', 'yeniSifre'), throwsA(isA<KutuphaneHatasi>()));
    });
  });
}
