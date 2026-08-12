import 'package:benim_kutuphanem/guvenlik/sifre_servisi.dart';
import 'package:flutter_test/flutter_test.dart';

/// Bu hash'ler .NET tarafindaki SifreServisi.cs ile uretilip
/// sql/01_sema.sql icine yazilmisti. Dart surumu ayni bicimi
/// cozebiliyorsa port dogru demektir.
const _adminHash =
    r'PBKDF2-SHA256$100000$ag7l3wLCVUH2vIEBkBKOaw==$LcOhbxSQQQorEC/CJ2y5+O6z/8/s9mttel3OfPW/2W4=';
const _emirHash =
    r'PBKDF2-SHA256$100000$Yz8ReHW0sE9ZsiafgRFjFQ==$WJmPJ/cTxYMS5V8loROpfRDucdW4aTA7bCA4ktnIvcM=';

void main() {
  group('C# ile uretilmis hash uyumlulugu', () {
    test('admin hesabinin 1234 sifresi dogrulanir', () {
      expect(SifreServisi.dogrula('1234', _adminHash), isTrue);
    });

    test('emir hesabinin 1234 sifresi dogrulanir', () {
      expect(SifreServisi.dogrula('1234', _emirHash), isTrue);
    });

    test('yanlis sifre reddedilir', () {
      expect(SifreServisi.dogrula('12345', _adminHash), isFalse);
      expect(SifreServisi.dogrula('', _adminHash), isFalse);
      expect(SifreServisi.dogrula('1234 ', _adminHash), isFalse);
    });

    test('salt farkli oldugu icin ayni sifre farkli hash uretir', () {
      expect(_adminHash, isNot(equals(_emirHash)));
    });
  });

  group('Yeni hash uretimi', () {
    test('uretilen hash kendi sifresini dogrular', () {
      final hash = SifreServisi.hashle('gizliSifre42');
      expect(SifreServisi.dogrula('gizliSifre42', hash), isTrue);
      expect(SifreServisi.dogrula('gizliSifre43', hash), isFalse);
    });

    test('ayni sifre her seferinde farkli hash verir', () {
      expect(SifreServisi.hashle('ayni'), isNot(equals(SifreServisi.hashle('ayni'))));
    });

    test('bicim .NET surumuyle ayni', () {
      final parcalar = SifreServisi.hashle('x').split(r'$');
      expect(parcalar.length, 4);
      expect(parcalar[0], 'PBKDF2-SHA256');
      expect(parcalar[1], '100000');
    });

    test('Turkce ve unicode sifreler calisir', () {
      final hash = SifreServisi.hashle('şifrem-çğüöıİ');
      expect(SifreServisi.dogrula('şifrem-çğüöıİ', hash), isTrue);
      expect(SifreServisi.dogrula('sifrem-cguoiI', hash), isFalse);
    });
  });

  group('Bozuk girdiler', () {
    test('gecersiz bicimler cokmeden false doner', () {
      for (final bozuk in [
        '',
        'duz-metin',
        r'PBKDF2-SHA256$100000$eksik',
        r'BILINMEYEN$100000$YWJj$YWJj',
        r'PBKDF2-SHA256$sifir$YWJj$YWJj',
        r'PBKDF2-SHA256$100000$!gecersiz-base64!$YWJj',
      ]) {
        expect(SifreServisi.dogrula('1234', bozuk), isFalse, reason: bozuk);
      }
    });
  });
}
