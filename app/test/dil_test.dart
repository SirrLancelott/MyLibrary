import 'package:benim_kutuphanem/main.dart';
import 'package:benim_kutuphanem/servisler/kutuphane_servisi.dart';
import 'package:benim_kutuphanem/widgetlar/ortak.dart';
import 'package:benim_kutuphanem/yerellestirme/ceviri.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sag ustteki dil dugmesi. Uzerinde gecilecek dilin adi yazar:
/// Turkce arayuzde "EN", Ingilizce arayuzde "TR".
Finder dilDugmesi(String yazi) => find.widgetWithText(DilDugmesi, yazi);

Future<void> girisYap(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Kullanıcı adı'),
    'admin',
  );
  await tester.enterText(find.widgetWithText(TextFormField, 'Şifre'), '1234');
  await tester.tap(find.widgetWithText(FilledButton, 'Giriş yap'));
  await tester.pumpAndSettle();
}

void main() {
  late KutuphaneServisi servis;

  setUp(() => servis = KutuphaneServisi.bellekte());
  tearDown(() => servis.kapat());

  testWidgets('Giris ekrani EN dugmesiyle Ingilizceye gecer', (tester) async {
    await tester.pumpWidget(BenimKutuphanemUygulamasi(servis: servis));

    expect(find.text('Giriş yap'), findsOneWidget);

    await tester.tap(dilDugmesi('EN'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Giriş yap'), findsNothing);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Library Management System'), findsOneWidget);

    // Dugme artik geri donusu gosterir
    expect(dilDugmesi('TR'), findsOneWidget);
  });

  testWidgets('Ingilizceden Turkceye geri donulur', (tester) async {
    await tester.pumpWidget(BenimKutuphanemUygulamasi(servis: servis));

    await tester.tap(dilDugmesi('EN'));
    await tester.pumpAndSettle();
    await tester.tap(dilDugmesi('TR'));
    await tester.pumpAndSettle();

    expect(find.text('Giriş yap'), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);
  });

  testWidgets('Ana ekran ve sekme adlari da cevrilir', (tester) async {
    await tester.pumpWidget(BenimKutuphanemUygulamasi(servis: servis));
    await girisYap(tester);

    expect(find.text('Kitaplarım'), findsOneWidget);

    await tester.tap(dilDugmesi('EN'));
    await tester.pumpAndSettle();

    expect(find.text('My Books'), findsOneWidget);
    expect(find.text('Wish List'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Kitaplarım'), findsNothing);
  });

  testWidgets('Servisten gelen hata secili dilde gosterilir', (tester) async {
    await tester.pumpWidget(BenimKutuphanemUygulamasi(servis: servis));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Kullanıcı adı'),
      'admin',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Şifre'),
      'yanlis',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Giriş yap'));
    await tester.pumpAndSettle();

    expect(find.text('Kullanıcı adı veya şifre hatalı.'), findsOneWidget);

    // Hata ekranda dururken dil degisirse mesaj da cevrilmeli: bu yuzden
    // ekranlarda metin degil KutuphaneHatasi'nin kendisi saklaniyor.
    await tester.tap(dilDugmesi('EN'));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect username or password.'), findsOneWidget);
    expect(find.text('Kullanıcı adı veya şifre hatalı.'), findsNothing);
  });

  group('Bicimlendirme', () {
    test('sayi ayiraci dile gore degisir', () {
      expect(Ceviri.icin(Dil.turkce).sayiBicimi.format(12345), '12.345');
      expect(Ceviri.icin(Dil.ingilizce).sayiBicimi.format(12345), '12,345');
    });

    test('tutar her iki dilde de TL kalir', () {
      expect(Ceviri.icin(Dil.turkce).paraBicimi.format(1234.5), '₺1.234,50');
      expect(Ceviri.icin(Dil.ingilizce).paraBicimi.format(1234.5), '₺1,234.50');
    });

    test('tarih bicimi dile gore degisir', () {
      final tarih = DateTime(2026, 3, 9, 14, 5);
      expect(
        Ceviri.icin(Dil.turkce).tarihBicimi.format(tarih),
        '09.03.2026 14:05',
      );
      expect(
        Ceviri.icin(Dil.ingilizce).tarihBicimi.format(tarih),
        '03/09/2026 14:05',
      );
    });
  });
}
