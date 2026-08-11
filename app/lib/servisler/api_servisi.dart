import 'dart:convert';

import 'package:http/http.dart' as http;

import '../modeller/modeller.dart';

/// API'den gelen is hatalari (401, 400, 404 ...) bu tiple firlatilir.
class ApiHatasi implements Exception {
  ApiHatasi(this.mesaj, {this.durumKodu});

  final String mesaj;
  final int? durumKodu;

  bool get oturumDustu => durumKodu == 401;

  @override
  String toString() => mesaj;
}

/// KutuphaneApi ile konusan tek katman.
/// Tum istekler 127.0.0.1'e gider; disariya baglanti kurulmaz.
class ApiServisi {
  ApiServisi({String? adres, http.Client? istemci})
      : _kok = Uri.parse(adres ?? varsayilanAdres),
        _istemci = istemci ?? http.Client();

  static const varsayilanAdres = 'http://127.0.0.1:5199';
  static const _zamanAsimi = Duration(seconds: 15);

  final Uri _kok;
  final http.Client _istemci;

  String? _token;

  bool get girisYapildi => _token != null;

  void oturumuTemizle() => _token = null;

  Map<String, String> get _basliklar => {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Uri _adres(String yol, [Map<String, dynamic>? sorgu]) {
    final temiz = <String, String>{};
    sorgu?.forEach((anahtar, deger) {
      if (deger != null && '$deger'.isNotEmpty) temiz[anahtar] = '$deger';
    });
    return _kok.replace(path: yol, queryParameters: temiz.isEmpty ? null : temiz);
  }

  Future<dynamic> _cagir(
    String yontem,
    String yol, {
    Map<String, dynamic>? sorgu,
    Object? govde,
  }) async {
    final adres = _adres(yol, sorgu);
    final govdeMetni = govde == null ? null : jsonEncode(govde);

    http.Response yanit;
    try {
      yanit = switch (yontem) {
        'GET' => await _istemci.get(adres, headers: _basliklar).timeout(_zamanAsimi),
        'POST' => await _istemci
            .post(adres, headers: _basliklar, body: govdeMetni)
            .timeout(_zamanAsimi),
        'PUT' => await _istemci
            .put(adres, headers: _basliklar, body: govdeMetni)
            .timeout(_zamanAsimi),
        'DELETE' =>
          await _istemci.delete(adres, headers: _basliklar).timeout(_zamanAsimi),
        _ => throw ArgumentError('Bilinmeyen yontem: $yontem'),
      };
    } catch (_) {
      throw ApiHatasi(
        'Sunucuya ulasilamadi.\n'
        'KutuphaneApi calisiyor mu? (baslat.bat dosyasini calistirin)',
      );
    }

    // Yanit her zaman UTF-8; Turkce karakterlerin bozulmamasi icin
    // http paketinin varsayilan latin-1 cozumlemesine birakilmaz.
    final metin = utf8.decode(yanit.bodyBytes);
    final coz = metin.isEmpty ? null : jsonDecode(metin);

    if (yanit.statusCode >= 200 && yanit.statusCode < 300) return coz;

    final mesaj = (coz is Map && coz['mesaj'] is String)
        ? coz['mesaj'] as String
        : 'Beklenmeyen hata (HTTP ${yanit.statusCode})';
    throw ApiHatasi(mesaj, durumKodu: yanit.statusCode);
  }

  // ------------------------------------------------------------- Kimlik ---

  Future<Oturum> girisYap(String kullaniciAdi, String sifre) async {
    final yanit = await _cagir('POST', '/api/giris', govde: {
      'kullaniciAdi': kullaniciAdi,
      'sifre': sifre,
    });
    final oturum = Oturum.jsondan(yanit as Map<String, dynamic>);
    _token = oturum.token;
    return oturum;
  }

  Future<void> cikisYap() async {
    try {
      await _cagir('POST', '/api/cikis');
    } on ApiHatasi {
      // cikista hata onemsiz
    } finally {
      _token = null;
    }
  }

  /// Basarili olursa oturum sunucuda dusurulur; yeniden giris gerekir.
  Future<String> sifreDegistir(String mevcutSifre, String yeniSifre) async {
    final yanit = await _cagir('POST', '/api/sifre-degistir', govde: {
      'mevcutSifre': mevcutSifre,
      'yeniSifre': yeniSifre,
    });
    _token = null;
    return (yanit as Map<String, dynamic>)['mesaj'] as String;
  }

  // --------------------------------------------------------------- Veri ---

  Future<Ozet> ozetGetir() async =>
      Ozet.jsondan(await _cagir('GET', '/api/ozet') as Map<String, dynamic>);

  Future<Referanslar> referanslariGetir() async => Referanslar.jsondan(
      await _cagir('GET', '/api/referanslar') as Map<String, dynamic>);

  Future<List<Kitap>> kitaplariGetir({
    String? arama,
    String? tur,
    bool? okundu,
  }) async {
    final yanit = await _cagir('GET', '/api/kitaplar', sorgu: {
      'arama': arama,
      'tur': tur,
      'okundu': okundu,
    });
    return (yanit as List)
        .map((e) => Kitap.jsondan(e as Map<String, dynamic>))
        .toList();
  }

  Future<Kitap> kitapEkle(Kitap kitap) async => Kitap.jsondan(
      await _cagir('POST', '/api/kitaplar', govde: kitap.gonderilecekJson())
          as Map<String, dynamic>);

  Future<Kitap> kitapGuncelle(int kitapId, Kitap kitap) async => Kitap.jsondan(
      await _cagir('PUT', '/api/kitaplar/$kitapId',
          govde: kitap.gonderilecekJson()) as Map<String, dynamic>);

  Future<void> kitapSil(int kitapId) async =>
      _cagir('DELETE', '/api/kitaplar/$kitapId');

  Future<List<Istek>> istekleriGetir({
    String? arama,
    String? tur,
    String? site,
    bool? satinAlindi,
  }) async {
    final yanit = await _cagir('GET', '/api/istekler', sorgu: {
      'arama': arama,
      'tur': tur,
      'site': site,
      'satinAlindi': satinAlindi,
    });
    return (yanit as List)
        .map((e) => Istek.jsondan(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> istekEkle(Istek istek) async =>
      _cagir('POST', '/api/istekler', govde: istek.gonderilecekJson());

  Future<void> istekGuncelle(int istekId, Istek istek) async =>
      _cagir('PUT', '/api/istekler/$istekId', govde: istek.gonderilecekJson());

  Future<void> istekSil(int istekId) async =>
      _cagir('DELETE', '/api/istekler/$istekId');

  Future<void> istegiKitapligaTasi(int istekId) async =>
      _cagir('POST', '/api/istekler/$istekId/kitapliga-tasi');
}
