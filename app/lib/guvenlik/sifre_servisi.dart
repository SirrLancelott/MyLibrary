import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Sifreleri PBKDF2-HMAC-SHA256 ile hash'ler ve dogrular.
///
/// Saklama bicimi (.NET surumundeki ile birebir ayni):
///     `PBKDF2-SHA256$<iterasyon>$<base64 salt>$<base64 hash>`
///
/// Bicim korundugu icin SQL Server doneminde uretilmis hash'ler
/// bu surumde de dogrulanabilir. Duz sifre hicbir yerde saklanmaz.
class SifreServisi {
  SifreServisi._();

  static const _algoritma = 'PBKDF2-SHA256';
  static const _iterasyon = 100000;
  static const _saltUzunlugu = 16; // 128 bit
  static const _hashUzunlugu = 32; // 256 bit

  static final _rastgele = Random.secure();

  /// Yeni bir salt uretip sifreyi hash'ler.
  static String hashle(String sifre) {
    final salt = Uint8List.fromList(
      List<int>.generate(_saltUzunlugu, (_) => _rastgele.nextInt(256)),
    );
    final hash = _turet(sifre, salt, _iterasyon, _hashUzunlugu);
    return '$_algoritma\$$_iterasyon\$${base64.encode(salt)}\$${base64.encode(hash)}';
  }

  /// Girilen sifreyi kayitli hash ile karsilastirir.
  /// Karsilastirma sabit zamanlidir; yanit suresinden bilgi sizmaz.
  static bool dogrula(String sifre, String kayitliHash) {
    final parcalar = kayitliHash.split(r'$');
    if (parcalar.length != 4 || parcalar[0] != _algoritma) return false;

    final iterasyon = int.tryParse(parcalar[1]);
    if (iterasyon == null || iterasyon <= 0) return false;

    Uint8List salt;
    Uint8List beklenen;
    try {
      salt = base64.decode(parcalar[2]);
      beklenen = base64.decode(parcalar[3]);
    } on FormatException {
      return false;
    }
    if (beklenen.isEmpty) return false;

    final hesaplanan = _turet(sifre, salt, iterasyon, beklenen.length);
    return _sabitZamanliEsit(hesaplanan, beklenen);
  }

  /// PBKDF2 (RFC 8018) - HMAC-SHA256 ile anahtar turetme.
  static Uint8List _turet(
    String sifre,
    Uint8List salt,
    int iterasyon,
    int uzunluk,
  ) {
    final hmac = Hmac(sha256, utf8.encode(sifre));
    const blokUzunlugu = 32; // SHA-256 cikti uzunlugu
    final blokSayisi = (uzunluk + blokUzunlugu - 1) ~/ blokUzunlugu;
    final sonuc = Uint8List(blokSayisi * blokUzunlugu);

    for (var blok = 1; blok <= blokSayisi; blok++) {
      // U1 = HMAC(sifre, salt || INT_BE32(blok))
      final girdi = Uint8List(salt.length + 4)
        ..setAll(0, salt)
        ..[salt.length] = (blok >> 24) & 0xff
        ..[salt.length + 1] = (blok >> 16) & 0xff
        ..[salt.length + 2] = (blok >> 8) & 0xff
        ..[salt.length + 3] = blok & 0xff;

      var u = Uint8List.fromList(hmac.convert(girdi).bytes);
      final birikim = Uint8List.fromList(u);

      // U2..Uc: her tur bir onceki ciktinin HMAC'i, hepsi XOR'lanir
      for (var tur = 1; tur < iterasyon; tur++) {
        u = Uint8List.fromList(hmac.convert(u).bytes);
        for (var i = 0; i < blokUzunlugu; i++) {
          birikim[i] ^= u[i];
        }
      }
      sonuc.setAll((blok - 1) * blokUzunlugu, birikim);
    }
    return Uint8List.sublistView(sonuc, 0, uzunluk);
  }

  static bool _sabitZamanliEsit(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var fark = 0;
    for (var i = 0; i < a.length; i++) {
      fark |= a[i] ^ b[i];
    }
    return fark == 0;
  }
}
