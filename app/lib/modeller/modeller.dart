/// Uygulamanin veri modelleri.
///
/// Onceki surumde bu siniflar API'den gelen JSON'dan uretiliyordu.
/// Veri artik dogrudan SQLite'tan okundugu icin JSON donusum metotlari
/// kaldirildi; satir -> nesne esleme KutuphaneServisi icinde yapiliyor.
library;

class Oturum {
  const Oturum({
    required this.kullaniciId,
    required this.kullaniciAdi,
    this.adSoyad,
    this.oncekiGiris,
  });

  final int kullaniciId;
  final String kullaniciAdi;
  final String? adSoyad;

  /// Bu giristen bir onceki giris zamani (ilk giriste null).
  final DateTime? oncekiGiris;

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

  /// Tek bir alani degistirip kaydi geri gondermek icin.
  /// Listedeki "okundu" anahtari bunu kullanir.
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

  /// TL cinsinden. Veritabaninda kurus (tam sayi) olarak saklanir.
  final double? fiyat;
  final bool satinAlindi;
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

  /// Henuz alinmamis kitaplarin toplami, TL.
  final double istekToplamTutar;
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
}
