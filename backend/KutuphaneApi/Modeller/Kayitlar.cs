namespace KutuphaneApi.Modeller;

// ---------------------------------------------------------------- Kimlik ----

public sealed record GirisIstegi(string KullaniciAdi, string Sifre);

public sealed record GirisYaniti(
    string Token,
    int KullaniciId,
    string KullaniciAdi,
    string? AdSoyad,
    DateTime? OncekiGiris);

public sealed record SifreDegistirmeIstegi(string MevcutSifre, string YeniSifre);

public sealed record Kullanici(
    int KullaniciId,
    string KullaniciAdi,
    string SifreHash,
    string? AdSoyad,
    bool Aktif,
    DateTime? SonGirisTarihi);

// ---------------------------------------------------------------- Kitaplar --

/// <summary>dbo.vw_Kitaplar goruntusunun karsiligi.</summary>
public sealed record Kitap(
    int KitapId,
    int SiraNo,
    string Ad,
    string? Yazar,
    string? Yayinevi,
    string? Tur,
    int? SayfaSayisi,
    bool OkunduMu);

/// <summary>Kitap ekleme/guncelleme istegi. Referanslar ad olarak gonderilir,
/// API bunlari lookup tablolarinda bulur, yoksa olusturur.</summary>
public sealed record KitapIstegi(
    string Ad,
    string? Yazar,
    string? Yayinevi,
    string? Tur,
    int? SayfaSayisi,
    bool OkunduMu);

// ----------------------------------------------------------- Istek listesi --

/// <summary>dbo.vw_IstekListesi goruntusunun karsiligi.</summary>
public sealed record Istek(
    int IstekId,
    int SiraNo,
    string Ad,
    string? Yazar,
    string? Yayinevi,
    string? Tur,
    int? SayfaSayisi,
    string? Site,
    decimal? Fiyat,
    bool SatinAlindi);

public sealed record IstekIstegi(
    string Ad,
    string? Yazar,
    string? Yayinevi,
    string? Tur,
    int? SayfaSayisi,
    string? Site,
    decimal? Fiyat,
    bool SatinAlindi);

// ------------------------------------------------------------------ Diger ---

public sealed record Ozet(
    int ToplamKitap,
    int OkunanKitap,
    int OkunmayanKitap,
    int ToplamSayfa,
    int IstekAdedi,
    decimal IstekToplamTutar);

public sealed record Referanslar(
    IReadOnlyList<string> Yazarlar,
    IReadOnlyList<string> Yayinevleri,
    IReadOnlyList<string> Turler,
    IReadOnlyList<string> Siteler);

public sealed record HataYaniti(string Mesaj);
