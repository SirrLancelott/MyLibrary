/// API'den gelen JSON yapilarinin Dart karsiliklari.
library;

class Oturum {
  const Oturum({
    required this.token,
    required this.kullaniciId,
    required this.kullaniciAdi,
    this.adSoyad,
    this.oncekiGiris,
  });

  final String token;
  final int kullaniciId;
  final String kullaniciAdi;
  final String? adSoyad;
  final DateTime? oncekiGiris;

  factory Oturum.jsondan(Map<String, dynamic> j) => Oturum(
        token: j['token'] as String,
        kullaniciId: j['kullaniciId'] as int,
        kullaniciAdi: j['kullaniciAdi'] as String,
        adSoyad: j['adSoyad'] as String?,
        oncekiGiris: j['oncekiGiris'] == null
            ? null
            : DateTime.parse(j['oncekiGiris'] as String),
      );

  String get gorunenAd =>
      (adSoyad != null && adSoyad!.trim().isNotEmpty) ? adSoyad! : kullaniciAdi;
}

class Kitap {
  const Kitap({
    required this.kitapId,
    required this.siraNo,
    required this.ad,
    this.yazar,
    this.yayinevi,
    this.tur,
    this.sayfaSayisi,
    required this.okunduMu,
  });

  final int kitapId;
  final int siraNo;
  final String ad;
  final String? yazar;
  final String? yayinevi;
  final String? tur;
  final int? sayfaSayisi;
  final bool okunduMu;

  factory Kitap.jsondan(Map<String, dynamic> j) => Kitap(
        kitapId: j['kitapId'] as int,
        siraNo: j['siraNo'] as int,
        ad: j['ad'] as String,
        yazar: j['yazar'] as String?,
        yayinevi: j['yayinevi'] as String?,
        tur: j['tur'] as String?,
        sayfaSayisi: j['sayfaSayisi'] as int?,
        okunduMu: j['okunduMu'] as bool,
      );

  Map<String, dynamic> gonderilecekJson() => {
        'ad': ad,
        'yazar': yazar,
        'yayinevi': yayinevi,
        'tur': tur,
        'sayfaSayisi': sayfaSayisi,
        'okunduMu': okunduMu,
      };

  Kitap kopyala({
    String? ad,
    String? yazar,
    String? yayinevi,
    String? tur,
    int? sayfaSayisi,
    bool? okunduMu,
  }) =>
      Kitap(
        kitapId: kitapId,
        siraNo: siraNo,
        ad: ad ?? this.ad,
        yazar: yazar ?? this.yazar,
        yayinevi: yayinevi ?? this.yayinevi,
        tur: tur ?? this.tur,
        sayfaSayisi: sayfaSayisi ?? this.sayfaSayisi,
        okunduMu: okunduMu ?? this.okunduMu,
      );
}

class Istek {
  const Istek({
    required this.istekId,
    required this.siraNo,
    required this.ad,
    this.yazar,
    this.yayinevi,
    this.tur,
    this.sayfaSayisi,
    this.site,
    this.fiyat,
    required this.satinAlindi,
  });

  final int istekId;
  final int siraNo;
  final String ad;
  final String? yazar;
  final String? yayinevi;
  final String? tur;
  final int? sayfaSayisi;
  final String? site;
  final double? fiyat;
  final bool satinAlindi;

  factory Istek.jsondan(Map<String, dynamic> j) => Istek(
        istekId: j['istekId'] as int,
        siraNo: j['siraNo'] as int,
        ad: j['ad'] as String,
        yazar: j['yazar'] as String?,
        yayinevi: j['yayinevi'] as String?,
        tur: j['tur'] as String?,
        sayfaSayisi: j['sayfaSayisi'] as int?,
        site: j['site'] as String?,
        fiyat: (j['fiyat'] as num?)?.toDouble(),
        satinAlindi: j['satinAlindi'] as bool,
      );

  Map<String, dynamic> gonderilecekJson() => {
        'ad': ad,
        'yazar': yazar,
        'yayinevi': yayinevi,
        'tur': tur,
        'sayfaSayisi': sayfaSayisi,
        'site': site,
        'fiyat': fiyat,
        'satinAlindi': satinAlindi,
      };
}

class Ozet {
  const Ozet({
    required this.toplamKitap,
    required this.okunanKitap,
    required this.okunmayanKitap,
    required this.toplamSayfa,
    required this.istekAdedi,
    required this.istekToplamTutar,
  });

  final int toplamKitap;
  final int okunanKitap;
  final int okunmayanKitap;
  final int toplamSayfa;
  final int istekAdedi;
  final double istekToplamTutar;

  factory Ozet.jsondan(Map<String, dynamic> j) => Ozet(
        toplamKitap: j['toplamKitap'] as int,
        okunanKitap: j['okunanKitap'] as int,
        okunmayanKitap: j['okunmayanKitap'] as int,
        toplamSayfa: j['toplamSayfa'] as int,
        istekAdedi: j['istekAdedi'] as int,
        istekToplamTutar: (j['istekToplamTutar'] as num).toDouble(),
      );
}

class Referanslar {
  const Referanslar({
    required this.yazarlar,
    required this.yayinevleri,
    required this.turler,
    required this.siteler,
  });

  final List<String> yazarlar;
  final List<String> yayinevleri;
  final List<String> turler;
  final List<String> siteler;

  static const bos = Referanslar(
    yazarlar: [],
    yayinevleri: [],
    turler: [],
    siteler: [],
  );

  factory Referanslar.jsondan(Map<String, dynamic> j) => Referanslar(
        yazarlar: (j['yazarlar'] as List).cast<String>(),
        yayinevleri: (j['yayinevleri'] as List).cast<String>(),
        turler: (j['turler'] as List).cast<String>(),
        siteler: (j['siteler'] as List).cast<String>(),
      );
}
