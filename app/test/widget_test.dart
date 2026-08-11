import 'package:benim_kutuphanem/ekranlar/giris_ekrani.dart';
import 'package:benim_kutuphanem/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Uygulama giris ekraniyla acilir', (tester) async {
    await tester.pumpWidget(const BenimKutuphanemUygulamasi());

    expect(find.byType(GirisEkrani), findsOneWidget);
    expect(find.text('Benim Kütüphanem'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Giriş yap'), findsOneWidget);
  });

  testWidgets('Bos alanlarla giris denenince uyari gosterilir', (tester) async {
    await tester.pumpWidget(const BenimKutuphanemUygulamasi());

    await tester.tap(find.widgetWithText(FilledButton, 'Giriş yap'));
    await tester.pump();

    expect(find.text('Kullanıcı adı giriniz'), findsOneWidget);
    expect(find.text('Şifre giriniz'), findsOneWidget);
  });
}
