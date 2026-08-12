import 'package:benim_kutuphanem/ekranlar/istekler_sekmesi.dart';
import 'package:benim_kutuphanem/modeller/modeller.dart';
import 'package:benim_kutuphanem/servisler/kutuphane_servisi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sekme artik dogrudan SQLite'a konusuyor; testler bellek ici bir
/// veritabanini ornek kayitlarla doldurup gercek sorgu yolunu calistirir.
Future<KutuphaneServisi> hazirServis() async {
  final servis = KutuphaneServisi.bellekte();
  await servis.girisYap('admin', '1234');

  const kayitlar = [
    Istek(
      istekId: 0, siraNo: 0, ad: 'Chainsaw Man Cilt 1',
      yazar: 'Tatsuki Fujimoto', yayinevi: 'Gerekli Şeyler', tur: 'Manga',
      sayfaSayisi: 192, site: 'Kitap Yurdu', fiyat: 180.0, satinAlindi: false,
    ),
    Istek(
      istekId: 0, siraNo: 0, ad: 'Tokyo Ghoul Cilt 1',
      yazar: 'Sui İshida', yayinevi: 'Gerekli Şeyler', tur: 'Manga',
      sayfaSayisi: 200, site: 'Amazon', fiyat: 220.0, satinAlindi: false,
    ),
    Istek(
      istekId: 0, siraNo: 0, ad: 'Körlük',
      yazar: 'Jose Saramago', yayinevi: 'Kırmızı Kedi', tur: 'Roman',
      sayfaSayisi: 336, site: 'D&R', fiyat: 150.0, satinAlindi: false,
    ),
    Istek(
      istekId: 0, siraNo: 0, ad: 'Türü Girilmemiş Kitap',
      satinAlindi: false,
    ),
  ];

  for (final k in kayitlar) {
    await servis.istekEkle(k);
  }
  return servis;
}

Widget sekmeyiSar(KutuphaneServisi servis) => MaterialApp(
      home: Scaffold(
        body: IsteklerSekmesi(
          servis: servis,
          referanslar: const Referanslar(
            yazarlar: [],
            yayinevleri: [],
            turler: ['Bilim', 'Fantastik', 'Korku', 'Manga', 'Roman'],
            siteler: ['Amazon', 'D&R', 'Kitap Yurdu'],
          ),
          veriDegisti: () {},
        ),
      ),
    );

void main() {
  late KutuphaneServisi servis;

  setUp(() async => servis = await hazirServis());
  tearDown(() => servis.kapat());

  testWidgets('İstek listesi düz halde tüm kayıtları gösterir', (tester) async {
    await tester.pumpWidget(sekmeyiSar(servis));
    await tester.pumpAndSettle();

    expect(find.text('Chainsaw Man Cilt 1'), findsOneWidget);
    expect(find.text('Körlük'), findsOneWidget);
    expect(find.text('4 kayıt'), findsOneWidget);

    // Gruplamadan once tur basligi olmamali
    expect(find.text('Tür belirtilmemiş'), findsNothing);
  });

  testWidgets('Türe göre grupla açılınca kategori başlıkları gelir',
      (tester) async {
    // Liste tembel yuklendigi icin tum gruplarin ayni anda gorunecegi
    // buyuklukte bir pencere kullanilir.
    tester.view.physicalSize = const Size(1400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(sekmeyiSar(servis));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'Türe göre grupla'));
    await tester.pumpAndSettle();

    // Basliklar alfabetik, turu bos olan en sonda
    expect(find.text('Manga'), findsOneWidget);
    expect(find.text('Roman'), findsOneWidget);
    expect(find.text('Tür belirtilmemiş'), findsOneWidget);

    // Grup rozetleri: adet ve o gruba ait toplam tutar
    expect(find.textContaining('2 kitap'), findsOneWidget); // Manga
    expect(find.textContaining('1 kitap'), findsNWidgets(2)); // Roman + türsüz

    // Kartlar kaybolmamali
    expect(find.text('Tokyo Ghoul Cilt 1'), findsOneWidget);
  });

  testWidgets('Tür filtresi seçilince liste süzülür', (tester) async {
    await tester.pumpWidget(sekmeyiSar(servis));
    await tester.pumpAndSettle();

    expect(find.text('4 kayıt'), findsOneWidget);

    await tester.tap(find.widgetWithText(DropdownButtonFormField<String?>, 'Tür'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manga').last);
    await tester.pumpAndSettle();

    expect(find.text('2 kayıt'), findsOneWidget);
    expect(find.text('Chainsaw Man Cilt 1'), findsOneWidget);
    expect(find.text('Körlük'), findsNothing);
  });

  testWidgets('Toplam tutar yalnızca alınmamışları sayar', (tester) async {
    await tester.pumpWidget(sekmeyiSar(servis));
    await tester.pumpAndSettle();

    // 180 + 220 + 150 = 550, fiyatsiz kayit toplama girmez
    expect(find.textContaining('550'), findsOneWidget);
  });
}
