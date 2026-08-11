import 'dart:convert';

import 'package:benim_kutuphanem/ekranlar/istekler_sekmesi.dart';
import 'package:benim_kutuphanem/modeller/modeller.dart';
import 'package:benim_kutuphanem/servisler/api_servisi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// API'yi taklit eden istemci: /api/istekler cagrisina sabit bir liste doner
/// ve gelen "tur" sorgu parametresine gore suzer (sunucudaki davranisin ayni).
http.Client sahteIstemci({List<String>? gorulenTurler}) {
  final kayitlar = [
    {
      'istekId': 1, 'siraNo': 1, 'ad': 'Chainsaw Man Cilt 1',
      'yazar': 'Tatsuki Fujimoto', 'yayinevi': 'Gerekli Şeyler', 'tur': 'Manga',
      'sayfaSayisi': 192, 'site': 'Kitap Yurdu', 'fiyat': 180.0,
      'satinAlindi': false,
    },
    {
      'istekId': 2, 'siraNo': 2, 'ad': 'Tokyo Ghoul Cilt 1',
      'yazar': 'Sui İshida', 'yayinevi': 'Gerekli Şeyler', 'tur': 'Manga',
      'sayfaSayisi': 200, 'site': 'Amazon', 'fiyat': 220.0,
      'satinAlindi': false,
    },
    {
      'istekId': 3, 'siraNo': 3, 'ad': 'Körlük',
      'yazar': 'Jose Saramago', 'yayinevi': 'Kırmızı Kedi', 'tur': 'Roman',
      'sayfaSayisi': 336, 'site': 'D&R', 'fiyat': 150.0,
      'satinAlindi': false,
    },
    {
      'istekId': 4, 'siraNo': 4, 'ad': 'Türü Girilmemiş Kitap',
      'yazar': null, 'yayinevi': null, 'tur': null,
      'sayfaSayisi': null, 'site': null, 'fiyat': null,
      'satinAlindi': false,
    },
  ];

  return MockClient((istek) async {
    final tur = istek.url.queryParameters['tur'];
    gorulenTurler?.add(tur ?? '(yok)');

    final suzulmus =
        tur == null ? kayitlar : kayitlar.where((k) => k['tur'] == tur).toList();

    return http.Response(
      jsonEncode(suzulmus),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });
}

Widget sekmeyiSar(ApiServisi api) => MaterialApp(
      home: Scaffold(
        body: IsteklerSekmesi(
          api: api,
          referanslar: const Referanslar(
            yazarlar: [],
            yayinevleri: [],
            turler: ['Bilim', 'Fantastik', 'Korku', 'Manga', 'Roman'],
            siteler: ['Amazon', 'D&R', 'Kitap Yurdu'],
          ),
          veriDegisti: () {},
          oturumDustu: () {},
        ),
      ),
    );

void main() {
  testWidgets('İstek listesi düz halde tüm kayıtları gösterir', (tester) async {
    await tester.pumpWidget(sekmeyiSar(ApiServisi(istemci: sahteIstemci())));
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

    await tester.pumpWidget(sekmeyiSar(ApiServisi(istemci: sahteIstemci())));
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

  testWidgets('Tür filtresi seçilince API"ye tur parametresi gider',
      (tester) async {
    final gorulen = <String>[];
    await tester.pumpWidget(
        sekmeyiSar(ApiServisi(istemci: sahteIstemci(gorulenTurler: gorulen))));
    await tester.pumpAndSettle();

    expect(gorulen, ['(yok)']);

    await tester.tap(find.widgetWithText(DropdownButtonFormField<String?>, 'Tür'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manga').last);
    await tester.pumpAndSettle();

    expect(gorulen.last, 'Manga');
    expect(find.text('Körlük'), findsNothing);
    expect(find.text('2 kayıt'), findsOneWidget);
  });
}
