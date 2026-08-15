import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../servisler/kutuphane_servisi.dart';

/// Arayuz dili. Varsayilan Turkce; kullanici sag ustteki dugmeyle degistirir.
enum Dil {
  turkce(Locale('tr'), 'TR', 'Türkçe'),
  ingilizce(Locale('en'), 'EN', 'English');

  const Dil(this.locale, this.kisaAd, this.ad);

  final Locale locale;

  /// Dugmede gorunen iki harf.
  final String kisaAd;
  final String ad;

  Dil get digeri => this == turkce ? ingilizce : turkce;
}

/// Dili agacta asagi tasir. [Ceviri.of] bunu okur.
class DilKapsami extends InheritedWidget {
  const DilKapsami({super.key, required this.dil, required super.child});

  final Dil dil;

  /// Kapsam yoksa Turkce'ye duser. Boylece tek bir widget'i sarmalayan
  /// testler DilKapsami eklemek zorunda kalmaz.
  static Dil of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DilKapsami>()?.dil ??
      Dil.turkce;

  @override
  bool updateShouldNotify(DilKapsami eski) => eski.dil != dil;
}

/// Tum arayuz metinleri. Iki dil yan yana durur; yeni bir metin eklenirken
/// ikisini birden yazmak zorunlu oldugu icin ceviri atlanmaz.
///
/// Veritabanindaki icerik (kitap adi, yazar, tur, yayinevi, site) burada
/// yer almaz: onlar kullanicinin kendi verisidir, dil degisince degismez.
class Ceviri {
  Ceviri._(this.dil);

  static final _tr = Ceviri._(Dil.turkce);
  static final _en = Ceviri._(Dil.ingilizce);

  static Ceviri icin(Dil dil) => dil == Dil.turkce ? _tr : _en;

  static Ceviri of(BuildContext context) => icin(DilKapsami.of(context));

  final Dil dil;

  /// Kisa tutuldu; asagida yuzlerce kez geciyor.
  bool get _i => dil == Dil.ingilizce;

  // ----------------------------------------------------------- Bicimlendirme
  // Tutarlar her zaman TL'dir (veri Turkiye'den); dil yalnizca basamak
  // ayiracini degistirir: 1.234,50 ₺  <->  ₺1,234.50
  late final NumberFormat paraBicimi = NumberFormat.currency(
    locale: _i ? 'en_US' : 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  late final NumberFormat sayiBicimi = NumberFormat.decimalPattern(
    _i ? 'en_US' : 'tr_TR',
  );

  late final DateFormat tarihBicimi = DateFormat(
    _i ? 'MM/dd/yyyy HH:mm' : 'dd.MM.yyyy HH:mm',
  );

  // ------------------------------------------------------------------- Genel
  String get uygulamaAdi => _i ? 'My Library' : 'Benim Kütüphanem';
  String get altBaslik =>
      _i ? 'Library Management System' : 'Kütüphane Otomasyon Sistemi';

  String get temaDegistir => _i ? 'Light / dark theme' : 'Açık / koyu tema';
  String dileGec(Dil hedef) =>
      _i ? 'Switch to ${hedef.ad}' : '${hedef.ad} diline geç';

  String get yenile => _i ? 'Refresh' : 'Yenile';
  String get yenidenDene => _i ? 'Try again' : 'Yeniden dene';
  String get vazgec => _i ? 'Cancel' : 'Vazgeç';
  String get sil => _i ? 'Delete' : 'Sil';
  String get duzenle => _i ? 'Edit' : 'Düzenle';
  String get ekle => _i ? 'Add' : 'Ekle';
  String get guncelle => _i ? 'Update' : 'Güncelle';
  String get goster => _i ? 'Show' : 'Göster';
  String get gizle => _i ? 'Hide' : 'Gizle';
  String get tumu => _i ? 'All' : 'Tümü';

  String kayitAdedi(int adet) =>
      _i ? '$adet ${adet == 1 ? 'record' : 'records'}' : '$adet kayıt';

  // ------------------------------------------------------------- Acilis hatasi
  String get veritabaniAcilamadi =>
      _i ? 'Could not open the database' : 'Veritabanı açılamadı';
  String get veriKlasoruAciklamasi => _i
      ? 'The application keeps its data in this folder:'
      : 'Uygulama verilerini şu klasörde tutuyor:';
  String get bilinmeyenHata => _i ? 'Unknown error' : 'Bilinmeyen hata';

  // -------------------------------------------------------------- Giris ekrani
  String get kullaniciAdi => _i ? 'Username' : 'Kullanıcı adı';
  String get kullaniciAdiGiriniz =>
      _i ? 'Enter a username' : 'Kullanıcı adı giriniz';
  String get sifre => _i ? 'Password' : 'Şifre';
  String get sifreGiriniz => _i ? 'Enter a password' : 'Şifre giriniz';
  String get girisYap => _i ? 'Sign in' : 'Giriş yap';
  String get kontrolEdiliyor => _i ? 'Checking…' : 'Kontrol ediliyor…';
  String get varsayilanKullanici => _i
      ? 'Default account:  admin / 1234'
      : 'Varsayılan kullanıcı:  admin / 1234';

  // ----------------------------------------------------------------- Ana ekran
  String get cikisYap => _i ? 'Sign out' : 'Çıkış yap';
  String get ozet => _i ? 'Overview' : 'Özet';
  String get kitaplarim => _i ? 'My Books' : 'Kitaplarım';
  String get istekListem => _i ? 'Wish List' : 'İstek Listem';
  String get sifreSekmesi => _i ? 'Password' : 'Şifre';

  // -------------------------------------------------------------- Ozet sekmesi
  String hosGeldin(String ad) => _i ? 'Welcome, $ad' : 'Hoş geldin, $ad';
  String get ilkGiris => _i
      ? 'This is your first sign-in. Happy reading!'
      : 'Bu, ilk girişin. İyi okumalar!';
  String sonGiris(DateTime tarih) => _i
      ? 'Last sign-in: ${tarihBicimi.format(tarih)}'
      : 'Son giriş: ${tarihBicimi.format(tarih)}';

  String get sahipOlunanKitap => _i ? 'Books I own' : 'Sahip olduğum kitap';
  String get okudugum => _i ? 'Read' : 'Okuduğum';
  String get okumadigim => _i ? 'Unread' : 'Okumadığım';
  String get toplamSayfa => _i ? 'Total pages' : 'Toplam sayfa';
  String get sayfaSayisiGirilmis =>
      _i ? 'Books with a page count' : 'Sayfa sayısı girilmiş kitaplar';
  String get istekListesi => _i ? 'Wish list' : 'İstek listesi';
  String get tahminiMaliyet => _i ? 'Estimated cost' : 'Tahmini maliyet';
  String get henuzAlinmamis =>
      _i ? 'Books not purchased yet' : 'Henüz alınmamış kitaplar';
  String get okumaIlerlemesi => _i ? 'Reading progress' : 'Okuma ilerlemesi';

  /// Isaretin yeri dile gore degisir: %42  <->  42%
  String yuzde(double oran) {
    final deger = (oran * 100).toStringAsFixed(0);
    return _i ? '$deger%' : '%$deger';
  }

  String okumaOzeti(int toplam, int okunan, int okunmayan) => _i
      ? 'You have read $okunan of $toplam ${toplam == 1 ? 'book' : 'books'}; '
            '$okunmayan ${okunmayan == 1 ? 'is' : 'are'} still waiting.'
      : '$toplam kitabın $okunan tanesini okudun, '
            '$okunmayan tanesi seni bekliyor.';

  // ---------------------------------------------------------- Kitaplar sekmesi
  String get kitapAraIpucu =>
      _i ? 'Search by title or author…' : 'Kitap adı veya yazar ara…';
  String get tur => _i ? 'Genre' : 'Tür';
  String get hepsi => _i ? 'All' : 'Hepsi';
  String get okudum => _i ? 'Read' : 'Okudum';
  String get okumadim => _i ? 'Unread' : 'Okumadım';
  String get kitapEkleDugmesi => _i ? 'Add book' : 'Kitap ekle';

  String get sutunKitapAdi => _i ? 'Title' : 'Kitap adı';
  String get sutunYazar => _i ? 'Author' : 'Yazar';
  String get sutunYayinevi => _i ? 'Publisher' : 'Yayınevi';
  String get sutunSayfa => _i ? 'Pages' : 'Sayfa';
  String get sutunOkundu => _i ? 'Read' : 'Okundu';
  String get sutunIslem => _i ? 'Actions' : 'İşlem';

  String get kitapBulunamadi => _i
      ? 'No books match these filters.\nClear the search and try again.'
      : 'Bu filtrelerle eşleşen kitap yok.\nAramayı temizleyip tekrar deneyin.';

  String kitapEklendi(String ad) =>
      _i ? '“$ad” was added to your library.' : '“$ad” kitaplığa eklendi.';
  String get kitapGuncellendi => _i ? 'Book updated.' : 'Kitap güncellendi.';
  String get kitapSilindi => _i ? 'Book deleted.' : 'Kitap silindi.';
  String get kitapSilinsinMi => _i ? 'Delete this book?' : 'Kitap silinsin mi?';
  String kitapSilmeUyarisi(String ad) => _i
      ? '“$ad” will be permanently removed from your library.'
      : '“$ad” kitaplığından kalıcı olarak silinecek.';

  // ---------------------------------------------------------- Istekler sekmesi
  String get alinacakSite => _i ? 'Store' : 'Alınacak site';
  String get tureGoreGrupla => _i ? 'Group by genre' : 'Türe göre grupla';
  String get istekEkleDugmesi => _i ? 'Add to wish list' : 'İstek ekle';
  String get turBelirtilmemis => _i ? 'No genre' : 'Tür belirtilmemiş';
  String get yazarBelirtilmemis =>
      _i ? 'Unknown author' : 'Yazar belirtilmemiş';
  String get kitapligaTasi => _i ? 'Move to my books' : 'Kitaplığa taşı';
  String get tasi => _i ? 'Move' : 'Taşı';

  String toplamTutar(double tutar) => _i
      ? 'Total ${paraBicimi.format(tutar)}'
      : 'Toplam ${paraBicimi.format(tutar)}';

  String sayfaAdedi(int sayfa) =>
      _i ? '$sayfa ${sayfa == 1 ? 'page' : 'pages'}' : '$sayfa sayfa';

  String grupOzeti(int adet, double tutar) => _i
      ? '$adet ${adet == 1 ? 'book' : 'books'} • ${paraBicimi.format(tutar)}'
      : '$adet kitap • ${paraBicimi.format(tutar)}';

  String get istekBulunamadi => _i
      ? 'No records match these filters.'
      : 'Bu filtrelerle eşleşen kayıt yok.';

  String istekEklendi(String ad) => _i
      ? '“$ad” was added to your wish list.'
      : '“$ad” istek listesine eklendi.';
  String get kayitGuncellendi => _i ? 'Record updated.' : 'Kayıt güncellendi.';
  String get kayitSilindi => _i ? 'Record deleted.' : 'Kayıt silindi.';
  String get kayitSilinsinMi =>
      _i ? 'Delete this record?' : 'Kayıt silinsin mi?';
  String istekSilmeUyarisi(String ad) => _i
      ? '“$ad” will be permanently removed from your wish list.'
      : '“$ad” istek listesinden kalıcı olarak silinecek.';

  String get kitapligaTasinsinMi =>
      _i ? 'Move to your books?' : 'Kitaplığa taşınsın mı?';
  String tasimaUyarisi(String ad) => _i
      ? '“$ad” will be removed from the wish list and added to “My Books” '
            'as unread.'
      : '“$ad” istek listesinden çıkarılıp "Kitaplarım" '
            'listesine okunmadı olarak eklenecek.';
  String kitapligaTasindi(String ad) =>
      _i ? '“$ad” was moved to your library.' : '“$ad” kitaplığa taşındı.';

  // -------------------------------------------------------------- Kitap penceresi
  String get kitabiDuzenle => _i ? 'Edit book' : 'Kitabı düzenle';
  String get yeniKitapEkle => _i ? 'Add a new book' : 'Yeni kitap ekle';
  String get kitapAdiZorunlu => _i ? 'Title *' : 'Kitap adı *';
  String get kitapAdiGerekli =>
      _i ? 'A title is required' : 'Kitap adı zorunludur';
  String get sayfaSayisi => _i ? 'Page count' : 'Sayfa sayısı';
  String get sayfaSayisiPozitif => _i
      ? 'Page count must be greater than 0'
      : 'Sayfa sayısı 0’dan büyük olmalı';
  String get sifirdanBuyuk =>
      _i ? 'Must be greater than 0' : '0’dan büyük olmalı';
  String get buKitabiOkudum =>
      _i ? 'I have read this book' : 'Bu kitabı okudum';
  String get otomatikEklenirNotu => _i
      ? 'If an author, publisher or genre is not in the list, whatever you '
            'type is added automatically.'
      : 'Yazar, yayınevi ve tür listede yoksa yazdığınız değer '
            'otomatik olarak eklenir.';

  // ------------------------------------------------------------ Istek penceresi
  String get istegiDuzenle => _i ? 'Edit wish' : 'İsteği düzenle';
  String get istekListesineEkle =>
      _i ? 'Add to wish list' : 'İstek listesine ekle';
  String get fiyat => _i ? 'Price (₺)' : 'Fiyat (₺)';
  String get gecerliFiyat =>
      _i ? 'Enter a valid price' : 'Geçerli bir fiyat girin';
  String get satinAlindiIsaretle =>
      _i ? 'Mark as purchased' : 'Satın alındı olarak işaretle';
  String get satinAlindiAciklama => _i
      ? 'Marked records are excluded from the estimated cost.'
      : 'İşaretli kayıtlar tahmini maliyete dahil edilmez.';

  // ---------------------------------------------------------- Sifre degistirme
  String get sifreDegistir => _i ? 'Change password' : 'Şifre değiştir';
  String get sifreHashAciklamasi => _i
      ? 'The new password is stored hashed with PBKDF2; it is never kept '
            'anywhere in plain text.'
      : 'Yeni şifre veritabanında PBKDF2 ile hash’lenerek '
            'saklanır; düz metin olarak hiçbir yerde tutulmaz.';
  String get mevcutSifre => _i ? 'Current password' : 'Mevcut şifre';
  String get mevcutSifreGirin =>
      _i ? 'Enter your current password' : 'Mevcut şifrenizi girin';
  String get yeniSifre => _i ? 'New password' : 'Yeni şifre';
  String get yeniSifreTekrar =>
      _i ? 'New password (repeat)' : 'Yeni şifre (tekrar)';
  String get yeniSifreKisa => _i
      ? 'The new password must be at least 4 characters'
      : 'Yeni şifre en az 4 karakter olmalı';
  String get yeniSifreAyni => _i
      ? 'The new password cannot be the same as the old one'
      : 'Yeni şifre eskisiyle aynı olamaz';
  String get sifrelerEslesmiyor =>
      _i ? 'Passwords do not match' : 'Şifreler eşleşmiyor';
  String get sifreyiGuncelle => _i ? 'Update password' : 'Şifreyi güncelle';
  String get kaydediliyor => _i ? 'Saving…' : 'Kaydediliyor…';
  String get oturumKapanacakNotu => _i
      ? 'For security, you will be signed out after the change and sign in '
            'again with your new password.'
      : 'Şifre değiştikten sonra güvenlik gereği oturumunuz '
            'kapatılır ve yeni şifrenizle tekrar giriş yaparsınız.';

  // -------------------------------------------------------------- Servis metni
  /// Servis katmaninin BuildContext'i yoktur; oradan gelen metinler
  /// [HataKodu] ile tasinir ve burada dile cevrilir. Kodu olmayan bir
  /// hata gelirse servisin yazdigi Turkce metin oldugu gibi gosterilir.
  String hataMetni(KutuphaneHatasi hata) {
    switch (hata.kod) {
      case HataKodu.girisGerekli:
        return _i
            ? 'You must be signed in for this action.'
            : 'Bu işlem için giriş yapılmış olmalıdır.';
      case HataKodu.kimlikHatali:
        return _i
            ? 'Incorrect username or password.'
            : 'Kullanıcı adı veya şifre hatalı.';
      case HataKodu.kullaniciPasif:
        return _i ? 'This account is disabled.' : 'Bu kullanıcı pasif durumda.';
      case HataKodu.kullaniciYok:
        return _i ? 'User not found.' : 'Kullanıcı bulunamadı.';
      case HataKodu.mevcutSifreHatali:
        return _i ? 'Current password is incorrect.' : 'Mevcut şifre hatalı.';
      case HataKodu.yeniSifreKisa:
        return _i
            ? 'The new password must be at least 4 characters.'
            : 'Yeni şifre en az 4 karakter olmalıdır.';
      case HataKodu.yeniSifreAyni:
        return _i
            ? 'The new password cannot be the same as the old one.'
            : 'Yeni şifre eskisiyle aynı olamaz.';
      case HataKodu.kitapAdiZorunlu:
        return _i ? 'A title is required.' : 'Kitap adı zorunludur.';
      case HataKodu.kitapYok:
        return _i ? 'Book not found.' : 'Kitap bulunamadı.';
      case HataKodu.kayitYok:
        return _i ? 'Record not found.' : 'Kayıt bulunamadı.';
      case null:
        return hata.mesaj;
    }
  }

  String get sifreGuncellendiMesaji => _i
      ? 'Password updated. Please sign in again with your new password.'
      : 'Şifre güncellendi. Lütfen yeni şifrenizle tekrar giriş yapın.';
}
