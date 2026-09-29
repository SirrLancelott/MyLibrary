import 'package:benim_kutuphanem/widgetlar/ortak.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Yazar alani + arkasindan gelen bir alan. Tab'in hem tamamladigini hem
/// de odagi bir sonraki alana gecirdigini gormek icin ikinci alan var.
Widget alanlariSar(TextEditingController yazar, FocusNode sonraki) =>
    MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            OneriliAlan(
              denetleyici: yazar,
              etiket: 'Yazar',
              oneriler: const [
                'Oğuz Atay',
                'Orhan Pamuk',
                'Sabahattin Ali',
                'İlber Ortaylı',
              ],
            ),
            TextField(focusNode: sonraki),
          ],
        ),
      ),
    );

void main() {
  late TextEditingController yazar;
  late FocusNode sonraki;

  setUp(() {
    yazar = TextEditingController();
    sonraki = FocusNode();
  });

  tearDown(() {
    yazar.dispose();
    sonraki.dispose();
  });

  Future<void> yazVeTabaBas(WidgetTester tester, String metin) async {
    await tester.pumpWidget(alanlariSar(yazar, sonraki));
    await tester.enterText(find.byType(TextField).first, metin);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
  }

  testWidgets('Tab kayitli yazari tamamlar ve sonraki alana gecer',
      (tester) async {
    await yazVeTabaBas(tester, 'orh');
    expect(yazar.text, 'Orhan Pamuk');
    expect(sonraki.hasFocus, isTrue);
  });

  testWidgets('Buyuk/kucuk harf ve Turkce I farki tamamlamayi engellemez',
      (tester) async {
    await yazVeTabaBas(tester, 'ilber');
    expect(yazar.text, 'İlber Ortaylı');
  });

  testWidgets('Yalnizca icinde gecen ad tamamlanmaz', (tester) async {
    // "Ali" yeni bir yazar olabilir; "Sabahattin Ali"ye cevrilmemeli.
    await yazVeTabaBas(tester, 'Ali');
    expect(yazar.text, 'Ali');
    expect(sonraki.hasFocus, isTrue);
  });

  testWidgets('Eslesme yoksa yazilan aynen kalir', (tester) async {
    await yazVeTabaBas(tester, 'Yeni Yazar');
    expect(yazar.text, 'Yeni Yazar');
  });

  testWidgets('Bos alanda Tab bir sey doldurmaz', (tester) async {
    await tester.pumpWidget(alanlariSar(yazar, sonraki));
    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    expect(yazar.text, isEmpty);
    expect(sonraki.hasFocus, isTrue);
  });

  testWidgets('Ok tusuyla isaretlenen oneri Tab ile secilir', (tester) async {
    await tester.pumpWidget(alanlariSar(yazar, sonraki));
    await tester.enterText(find.byType(TextField).first, 'o');
    await tester.pumpAndSettle();

    // "o" ile baslayanlar once gelir: Oğuz Atay, Orhan Pamuk, ...
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    expect(yazar.text, 'Orhan Pamuk');
  });
}
