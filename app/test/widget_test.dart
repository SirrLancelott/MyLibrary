import 'package:benim_kutuphanem/ekranlar/giris_ekrani.dart';
import 'package:benim_kutuphanem/main.dart';
import 'package:benim_kutuphanem/servisler/kutuphane_servisi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late KutuphaneServisi servis;

  // Diskteki gercek veritabanina dokunmamak icin bellek ici surum verilir.
  setUp(() => servis = KutuphaneServisi.bellekte());
  tearDown(() => servis.kapat());

  testWidgets('Uygulama giris ekraniyla acilir', (tester) async {
    await tester.pumpWidget(BenimKutuphanemUygulamasi(servis: servis));

    expect(find.byType(GirisEkrani), findsOneWidget);
    expect(find.text('Benim Kütüphanem'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Giriş yap'), findsOneWidget);
  });

  testWidgets('Bos alanlarla giris denenince uyari gosterilir', (tester) async {
    await tester.pumpWidget(BenimKutuphanemUygulamasi(servis: servis));

    await tester.tap(find.widgetWithText(FilledButton, 'Giriş yap'));
    await tester.pump();

    expect(find.text('Kullanıcı adı giriniz'), findsOneWidget);
    expect(find.text('Şifre giriniz'), findsOneWidget);
  });

  testWidgets('Hatali sifre girilince mesaj gosterilir', (tester) async {
    await tester.pumpWidget(BenimKutuphanemUygulamasi(servis: servis));

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Kullanıcı adı'), 'admin');
    await tester.enterText(find.widgetWithText(TextFormField, 'Şifre'), 'yanlis');
    await tester.tap(find.widgetWithText(FilledButton, 'Giriş yap'));
    await tester.pumpAndSettle();

    expect(find.text('Kullanıcı adı veya şifre hatalı.'), findsOneWidget);
    expect(find.byType(GirisEkrani), findsOneWidget);
  });

  testWidgets('Dogru sifreyle ana ekrana gecilir', (tester) async {
    await tester.pumpWidget(BenimKutuphanemUygulamasi(servis: servis));

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Kullanıcı adı'), 'admin');
    await tester.enterText(find.widgetWithText(TextFormField, 'Şifre'), '1234');
    await tester.tap(find.widgetWithText(FilledButton, 'Giriş yap'));
    await tester.pumpAndSettle();

    expect(find.byType(GirisEkrani), findsNothing);
    expect(find.text('Kitaplarım'), findsOneWidget);
    expect(find.text('İstek Listem'), findsOneWidget);
  });
}
