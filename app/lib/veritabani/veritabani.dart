import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import 'sema.dart';

/// Veritabani dosyasini acar ve semanin kurulu olmasini garanti eder.
///
/// Dosya, exe'nin yaninda degil kullanicinin veri klasorunde tutulur:
///     %LOCALAPPDATA%\BenimKutuphanem\kutuphane.db
/// Program Files altina yazma izni olmadigi icin bu sart; ayrica
/// uygulama guncellenince veri yerinde kalir.
class Veritabani {
  Veritabani._();

  static const dosyaAdi = 'kutuphane.db';
  static const klasorAdi = 'BenimKutuphanem';

  /// Uygulamanin kullandigi gercek veritabani yolu.
  static String get varsayilanYol => p.join(_veriKlasoru(), dosyaAdi);

  /// Diskteki veritabanini acar; yoksa olusturur.
  static Database ac({String? yol}) {
    final hedef = yol ?? varsayilanYol;
    Directory(p.dirname(hedef)).createSync(recursive: true);
    final vt = sqlite3.open(hedef);
    _hazirla(vt);
    return vt;
  }

  /// Testler icin bellek ici veritabani.
  static Database bellekte() {
    final vt = sqlite3.openInMemory();
    _hazirla(vt);
    return vt;
  }

  static void _hazirla(Database vt) {
    vt.execute('PRAGMA foreign_keys = ON;');
    vt.execute('PRAGMA journal_mode = WAL;');
    vt.execute(semaBetigi);
    _kucukHarfIsleviniEkle(vt);
    _yoneticiHesabiniGarantile(vt);
  }

  /// SQLite'in yerlesik lower() islevi yalnizca ASCII harfleri kucultur;
  /// "İSTANBUL" gibi bir baslik aramada eslesmez. Dart'in Unicode
  /// farkindaligini SQL'e tasiyan bir islev tanimlanir.
  static void _kucukHarfIsleviniEkle(Database vt) {
    vt.createFunction(
      functionName: 'kucuk',
      argumentCount: const AllowedArgumentCount(1),
      deterministic: true,
      directOnly: false,
      function: (args) {
        final deger = args.first;
        return deger is String ? deger.toLowerCase() : deger;
      },
    );
  }

  /// Hic kullanici yoksa varsayilan yonetici hesabini olusturur.
  /// Var olan hesaplara dokunmaz; sifre degistirilmisse sifirlanmaz.
  static void _yoneticiHesabiniGarantile(Database vt) {
    final adet = vt.select('SELECT COUNT(*) AS adet FROM Kullanicilar;').first['adet'] as int;
    if (adet > 0) return;

    vt.execute(
      'INSERT INTO Kullanicilar (KullaniciAdi, SifreHash, AdSoyad) VALUES (?, ?, ?);',
      ['admin', varsayilanYoneticiHash, 'Yonetici'],
    );
  }

  static String _veriKlasoru() {
    final yerel = Platform.environment['LOCALAPPDATA'];
    if (yerel != null && yerel.isNotEmpty) return p.join(yerel, klasorAdi);

    // Windows disi ortam ya da degisken yoksa ev dizinine dus
    final ev = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        Directory.current.path;
    return p.join(ev, '.$klasorAdi');
  }
}
