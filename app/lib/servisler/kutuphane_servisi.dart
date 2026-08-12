import 'package:sqlite3/sqlite3.dart';

import '../guvenlik/sifre_servisi.dart';
import '../modeller/modeller.dart';
import '../veritabani/veritabani.dart';

/// Kullaniciya gosterilebilecek is hatalari bu tiple firlatilir.
class KutuphaneHatasi implements Exception {
  KutuphaneHatasi(this.mesaj);

  final String mesaj;

  @override
  String toString() => mesaj;
}

/// Uygulamanin tek veri katmani.
///
/// Onceki surumde bu isi yerel bir REST API (KutuphaneApi) yapiyordu;
/// SQL Server'a Dart'tan parametreli sorgu gonderilemedigi icin araya
/// konulmustu. SQLite gomulu calistigi ve parametre baglama sorunu
/// olmadigi icin sunucu katmani kaldirildi: sorgular dogrudan buradan
/// gidiyor. Tum sorgular parametrelidir.
class KutuphaneServisi {
  KutuphaneServisi(this._vt);

  /// Diskteki veritabanini kullanan normal calisma bicimi.
  factory KutuphaneServisi.ac({String? yol}) =>
      KutuphaneServisi(Veritabani.ac(yol: yol));

  /// Testler icin bellek ici veritabani.
  factory KutuphaneServisi.bellekte() =>
      KutuphaneServisi(Veritabani.bellekte());

  final Database _vt;
  int? _kullaniciId;

  bool get girisYapildi => _kullaniciId != null;

  void oturumuTemizle() => _kullaniciId = null;

  void kapat() => _vt.close();

  // ------------------------------------------------------------- Yardimci ---

  static String? _metin(Row satir, String sutun) => satir[sutun] as String?;

  static int? _tamSayi(Row satir, String sutun) {
    final deger = satir[sutun];
    return deger == null ? null : (deger as int);
  }

  static bool _mantik(Row satir, String sutun) => (satir[sutun] as int) != 0;

  /// Kurus -> TL. Fiyatlar veritabaninda tam sayi kurus olarak durur.
  static double? _kurustanTl(Object? kurus) =>
      kurus == null ? null : (kurus as int) / 100.0;

  /// TL -> kurus. Yuvarlama, kayan noktali degerin kurusa oturmasini saglar.
  static int? _tldenKurus(double? tl) => tl == null ? null : (tl * 100).round();

  static Kitap _kitapOku(Row s) => Kitap(
        kitapId: s['KitapId'] as int,
        siraNo: s['SiraNo'] as int,
        ad: s['Ad'] as String,
        yazar: _metin(s, 'Yazar'),
        yayinevi: _metin(s, 'Yayinevi'),
        tur: _metin(s, 'Tur'),
        sayfaSayisi: _tamSayi(s, 'SayfaSayisi'),
        okunduMu: _mantik(s, 'OkunduMu'),
      );

  static Istek _istekOku(Row s) => Istek(
        istekId: s['IstekId'] as int,
        siraNo: s['SiraNo'] as int,
        ad: s['Ad'] as String,
        yazar: _metin(s, 'Yazar'),
        yayinevi: _metin(s, 'Yayinevi'),
        tur: _metin(s, 'Tur'),
        sayfaSayisi: _tamSayi(s, 'SayfaSayisi'),
        site: _metin(s, 'Site'),
        fiyat: _kurustanTl(s['FiyatKurus']),
        satinAlindi: _mantik(s, 'SatinAlindi'),
      );

  /// Islemi tek transaction icinde yurutur; hata olursa geri alir.
  T _islemde<T>(T Function() govde) {
    _vt.execute('BEGIN;');
    try {
      final sonuc = govde();
      _vt.execute('COMMIT;');
      return sonuc;
    } catch (_) {
      _vt.execute('ROLLBACK;');
      rethrow;
    }
  }

  void _oturumGerekli() {
    if (_kullaniciId == null) {
      throw KutuphaneHatasi('Bu islem icin giris yapilmis olmalidir.');
    }
  }

  // --------------------------------------------------------------- Kimlik ---

  Future<Oturum> girisYap(String kullaniciAdi, String sifre) async {
    final ad = kullaniciAdi.trim();
    final satirlar = _vt.select(
      'SELECT KullaniciId, KullaniciAdi, SifreHash, AdSoyad, Aktif, SonGirisTarihi '
      'FROM Kullanicilar WHERE KullaniciAdi = ?;',
      [ad],
    );

    // Kullanici bulunamasa da ayni mesaj doner; hangi kullanici adlarinin
    // var oldugu disariya sizmaz.
    if (satirlar.isEmpty) {
      throw KutuphaneHatasi('Kullanıcı adı veya şifre hatalı.');
    }

    final satir = satirlar.first;
    if (!SifreServisi.dogrula(sifre, satir['SifreHash'] as String)) {
      throw KutuphaneHatasi('Kullanıcı adı veya şifre hatalı.');
    }
    if ((satir['Aktif'] as int) == 0) {
      throw KutuphaneHatasi('Bu kullanıcı pasif durumda.');
    }

    final kullaniciId = satir['KullaniciId'] as int;
    final oncekiGirisMetni = _metin(satir, 'SonGirisTarihi');

    _vt.execute(
      "UPDATE Kullanicilar SET SonGirisTarihi = datetime('now') WHERE KullaniciId = ?;",
      [kullaniciId],
    );

    _kullaniciId = kullaniciId;
    return Oturum(
      kullaniciId: kullaniciId,
      kullaniciAdi: satir['KullaniciAdi'] as String,
      adSoyad: _metin(satir, 'AdSoyad'),
      // SQLite datetime('now') UTC uretir; arayuzde yerel saat gosterilir.
      oncekiGiris: oncekiGirisMetni == null
          ? null
          : DateTime.parse('${oncekiGirisMetni}Z').toLocal(),
    );
  }

  Future<void> cikisYap() async => oturumuTemizle();

  /// Basarili olursa oturum kapatilir; yeniden giris gerekir.
  Future<String> sifreDegistir(String mevcutSifre, String yeniSifre) async {
    _oturumGerekli();

    if (yeniSifre.length < 4) {
      throw KutuphaneHatasi('Yeni şifre en az 4 karakter olmalıdır.');
    }
    if (yeniSifre == mevcutSifre) {
      throw KutuphaneHatasi('Yeni şifre eskisiyle aynı olamaz.');
    }

    final satirlar = _vt.select(
      'SELECT SifreHash FROM Kullanicilar WHERE KullaniciId = ?;',
      [_kullaniciId],
    );
    if (satirlar.isEmpty) {
      throw KutuphaneHatasi('Kullanıcı bulunamadı.');
    }
    if (!SifreServisi.dogrula(mevcutSifre, satirlar.first['SifreHash'] as String)) {
      throw KutuphaneHatasi('Mevcut şifre hatalı.');
    }

    _vt.execute(
      "UPDATE Kullanicilar SET SifreHash = ?, SifreDegistirmeTarihi = datetime('now') "
      'WHERE KullaniciId = ?;',
      [SifreServisi.hashle(yeniSifre), _kullaniciId],
    );

    oturumuTemizle();
    return 'Şifre güncellendi. Lütfen yeni şifrenizle tekrar giriş yapın.';
  }

  // ----------------------------------------------------------------- Veri ---

  Future<Ozet> ozetGetir() async {
    _oturumGerekli();
    final s = _vt.select('SELECT * FROM vw_Ozet;').first;
    return Ozet(
      toplamKitap: s['ToplamKitap'] as int,
      okunanKitap: s['OkunanKitap'] as int,
      okunmayanKitap: s['OkunmayanKitap'] as int,
      toplamSayfa: s['ToplamSayfa'] as int,
      istekAdedi: s['IstekAdedi'] as int,
      istekToplamTutar: _kurustanTl(s['IstekToplamKurus']) ?? 0,
    );
  }

  Future<Referanslar> referanslariGetir() async {
    _oturumGerekli();
    List<String> liste(String sql) =>
        _vt.select(sql).map((s) => s.values.first as String).toList();

    return Referanslar(
      yazarlar: liste('SELECT AdSoyad FROM Yazarlar ORDER BY AdSoyad;'),
      yayinevleri: liste('SELECT Ad FROM Yayinevleri ORDER BY Ad;'),
      turler: liste('SELECT Ad FROM Turler ORDER BY Ad;'),
      siteler: liste('SELECT Ad FROM SatisSiteleri ORDER BY Ad;'),
    );
  }

  // ------------------------------------------------------------- Kitaplar ---

  Future<List<Kitap>> kitaplariGetir({
    String? arama,
    String? tur,
    bool? okundu,
  }) async {
    _oturumGerekli();
    final desen = _aramaDeseni(arama);

    return _vt.select(
      '''
      SELECT KitapId, SiraNo, Ad, Yazar, Yayinevi, Tur, SayfaSayisi, OkunduMu
      FROM   vw_Kitaplar
      WHERE  (?1 IS NULL OR kucuk(Ad) LIKE ?1 OR kucuk(COALESCE(Yazar, '')) LIKE ?1)
        AND  (?2 IS NULL OR Tur = ?2)
        AND  (?3 IS NULL OR OkunduMu = ?3)
      ORDER BY SiraNo;
      ''',
      [desen, _bosaNull(tur), okundu == null ? null : (okundu ? 1 : 0)],
    ).map(_kitapOku).toList();
  }

  Future<Kitap?> _kitapGetir(int kitapId) async {
    final satirlar = _vt.select(
      'SELECT KitapId, SiraNo, Ad, Yazar, Yayinevi, Tur, SayfaSayisi, OkunduMu '
      'FROM vw_Kitaplar WHERE KitapId = ?;',
      [kitapId],
    );
    return satirlar.isEmpty ? null : _kitapOku(satirlar.first);
  }

  Future<Kitap> kitapEkle(Kitap kitap) async {
    _oturumGerekli();
    final ad = kitap.ad.trim();
    if (ad.isEmpty) throw KutuphaneHatasi('Kitap adı zorunludur.');

    final yeniId = _islemde(() {
      final yazarId = _referansId('Yazarlar', 'AdSoyad', 'YazarId', kitap.yazar);
      final yayinId = _referansId('Yayinevleri', 'Ad', 'YayineviId', kitap.yayinevi);
      final turId = _referansId('Turler', 'Ad', 'TurId', kitap.tur);

      return _vt.select(
        '''
        INSERT INTO Kitaplar (SiraNo, Ad, YazarId, YayineviId, TurId, SayfaSayisi, OkunduMu)
        VALUES (COALESCE((SELECT MAX(SiraNo) FROM Kitaplar), 0) + 1, ?, ?, ?, ?, ?, ?)
        RETURNING KitapId;
        ''',
        [ad, yazarId, yayinId, turId, kitap.sayfaSayisi, kitap.okunduMu ? 1 : 0],
      ).first['KitapId'] as int;
    });

    return (await _kitapGetir(yeniId))!;
  }

  Future<Kitap> kitapGuncelle(int kitapId, Kitap kitap) async {
    _oturumGerekli();
    final ad = kitap.ad.trim();
    if (ad.isEmpty) throw KutuphaneHatasi('Kitap adı zorunludur.');

    final etkilenen = _islemde(() {
      final yazarId = _referansId('Yazarlar', 'AdSoyad', 'YazarId', kitap.yazar);
      final yayinId = _referansId('Yayinevleri', 'Ad', 'YayineviId', kitap.yayinevi);
      final turId = _referansId('Turler', 'Ad', 'TurId', kitap.tur);

      _vt.execute(
        '''
        UPDATE Kitaplar
        SET    Ad = ?, YazarId = ?, YayineviId = ?, TurId = ?,
               SayfaSayisi = ?, OkunduMu = ?
        WHERE  KitapId = ?;
        ''',
        [ad, yazarId, yayinId, turId, kitap.sayfaSayisi, kitap.okunduMu ? 1 : 0, kitapId],
      );
      return _vt.updatedRows;
    });

    if (etkilenen == 0) throw KutuphaneHatasi('Kitap bulunamadı.');
    return (await _kitapGetir(kitapId))!;
  }

  Future<void> kitapSil(int kitapId) async {
    _oturumGerekli();
    _vt.execute('DELETE FROM Kitaplar WHERE KitapId = ?;', [kitapId]);
    if (_vt.updatedRows == 0) throw KutuphaneHatasi('Kitap bulunamadı.');
  }

  // --------------------------------------------------------- Istek listesi ---

  Future<List<Istek>> istekleriGetir({
    String? arama,
    String? tur,
    String? site,
    bool? satinAlindi,
  }) async {
    _oturumGerekli();
    final desen = _aramaDeseni(arama);

    return _vt.select(
      '''
      SELECT IstekId, SiraNo, Ad, Yazar, Yayinevi, Tur, SayfaSayisi,
             Site, FiyatKurus, SatinAlindi
      FROM   vw_IstekListesi
      WHERE  (?1 IS NULL OR kucuk(Ad) LIKE ?1 OR kucuk(COALESCE(Yazar, '')) LIKE ?1)
        AND  (?2 IS NULL OR Tur = ?2)
        AND  (?3 IS NULL OR Site = ?3)
        AND  (?4 IS NULL OR SatinAlindi = ?4)
      ORDER BY SiraNo;
      ''',
      [
        desen,
        _bosaNull(tur),
        _bosaNull(site),
        satinAlindi == null ? null : (satinAlindi ? 1 : 0),
      ],
    ).map(_istekOku).toList();
  }

  Future<void> istekEkle(Istek istek) async {
    _oturumGerekli();
    final ad = istek.ad.trim();
    if (ad.isEmpty) throw KutuphaneHatasi('Kitap adı zorunludur.');

    _islemde(() {
      final yazarId = _referansId('Yazarlar', 'AdSoyad', 'YazarId', istek.yazar);
      final yayinId = _referansId('Yayinevleri', 'Ad', 'YayineviId', istek.yayinevi);
      final turId = _referansId('Turler', 'Ad', 'TurId', istek.tur);
      final siteId = _referansId('SatisSiteleri', 'Ad', 'SiteId', istek.site);

      _vt.execute(
        '''
        INSERT INTO IstekListesi
              (SiraNo, Ad, YazarId, YayineviId, TurId, SayfaSayisi, SiteId, FiyatKurus, SatinAlindi)
        VALUES (COALESCE((SELECT MAX(SiraNo) FROM IstekListesi), 0) + 1, ?, ?, ?, ?, ?, ?, ?, ?);
        ''',
        [
          ad, yazarId, yayinId, turId, istek.sayfaSayisi, siteId,
          _tldenKurus(istek.fiyat), istek.satinAlindi ? 1 : 0,
        ],
      );
    });
  }

  Future<void> istekGuncelle(int istekId, Istek istek) async {
    _oturumGerekli();
    final ad = istek.ad.trim();
    if (ad.isEmpty) throw KutuphaneHatasi('Kitap adı zorunludur.');

    final etkilenen = _islemde(() {
      final yazarId = _referansId('Yazarlar', 'AdSoyad', 'YazarId', istek.yazar);
      final yayinId = _referansId('Yayinevleri', 'Ad', 'YayineviId', istek.yayinevi);
      final turId = _referansId('Turler', 'Ad', 'TurId', istek.tur);
      final siteId = _referansId('SatisSiteleri', 'Ad', 'SiteId', istek.site);

      _vt.execute(
        '''
        UPDATE IstekListesi
        SET    Ad = ?, YazarId = ?, YayineviId = ?, TurId = ?,
               SayfaSayisi = ?, SiteId = ?, FiyatKurus = ?, SatinAlindi = ?
        WHERE  IstekId = ?;
        ''',
        [
          ad, yazarId, yayinId, turId, istek.sayfaSayisi, siteId,
          _tldenKurus(istek.fiyat), istek.satinAlindi ? 1 : 0, istekId,
        ],
      );
      return _vt.updatedRows;
    });

    if (etkilenen == 0) throw KutuphaneHatasi('Kayıt bulunamadı.');
  }

  Future<void> istekSil(int istekId) async {
    _oturumGerekli();
    _vt.execute('DELETE FROM IstekListesi WHERE IstekId = ?;', [istekId]);
    if (_vt.updatedRows == 0) throw KutuphaneHatasi('Kayıt bulunamadı.');
  }

  /// Istek listesindeki kaydi kitapliga tasir: ekleme ve silme
  /// tek transaction icinde, ya birlikte olur ya hic olmaz.
  Future<void> istegiKitapligaTasi(int istekId) async {
    _oturumGerekli();

    final tasindi = _islemde(() {
      final sonuc = _vt.select(
        '''
        INSERT INTO Kitaplar (SiraNo, Ad, YazarId, YayineviId, TurId, SayfaSayisi, OkunduMu)
        SELECT COALESCE((SELECT MAX(SiraNo) FROM Kitaplar), 0) + 1,
               i.Ad, i.YazarId, i.YayineviId, i.TurId, i.SayfaSayisi, 0
        FROM   IstekListesi AS i
        WHERE  i.IstekId = ?
        RETURNING KitapId;
        ''',
        [istekId],
      );
      if (sonuc.isEmpty) return false;

      _vt.execute('DELETE FROM IstekListesi WHERE IstekId = ?;', [istekId]);
      return true;
    });

    if (!tasindi) throw KutuphaneHatasi('Kayıt bulunamadı.');
  }

  // -------------------------------------------------------------- Referans ---

  /// Referans tablosunda verilen adi arar; yoksa ekleyip Id'sini dondurur.
  /// Bos/null ad icin null doner (kolon NULL kalir).
  /// Tablo ve sutun adlari sabit metinlerden gelir, kullanici girdisi degildir.
  int? _referansId(String tablo, String adSutunu, String idSutunu, String? ad) {
    final temiz = ad?.trim();
    if (temiz == null || temiz.isEmpty) return null;

    final mevcut = _vt.select(
      'SELECT $idSutunu FROM $tablo WHERE $adSutunu = ?;',
      [temiz],
    );
    if (mevcut.isNotEmpty) return mevcut.first[idSutunu] as int;

    return _vt.select(
      'INSERT INTO $tablo ($adSutunu) VALUES (?) RETURNING $idSutunu;',
      [temiz],
    ).first[idSutunu] as int;
  }

  static String? _bosaNull(String? deger) {
    final temiz = deger?.trim();
    return (temiz == null || temiz.isEmpty) ? null : temiz;
  }

  /// LIKE deseni: kucuk harfe cevrilip % ile sarilir.
  /// kucuk() islevi SQL tarafinda sutuna da uygulanir (bkz. Veritabani).
  static String? _aramaDeseni(String? arama) {
    final temiz = _bosaNull(arama);
    return temiz == null ? null : '%${temiz.toLowerCase()}%';
  }
}
