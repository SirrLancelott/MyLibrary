using System.Text.Json;
using KutuphaneApi.Guvenlik;
using KutuphaneApi.Modeller;
using KutuphaneApi.Veri;
using Microsoft.Data.SqlClient;

// ContentRootPath acikca exe'nin bulundugu klasore ayarlanir; boylece API
// hangi calisma dizininden baslatilirsa baslatilsin appsettings.json bulunur.
var builder = WebApplication.CreateBuilder(new WebApplicationOptions
{
    Args = args,
    ContentRootPath = AppContext.BaseDirectory,
});

// Sadece yerel makineden erisilebilir - disariya acik degil.
builder.WebHost.UseUrls("http://127.0.0.1:5199");

var baglantiMetni = builder.Configuration.GetConnectionString("BenimKutuphanem")
    ?? throw new InvalidOperationException("appsettings.json icinde 'BenimKutuphanem' baglanti metni yok.");

builder.Services.AddSingleton(new KutuphaneDeposu(baglantiMetni));
builder.Services.AddSingleton<OturumDeposu>();
builder.Services.ConfigureHttpJsonOptions(o =>
{
    o.SerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
});

var app = builder.Build();

// SQL Server hatalarini duzgun bir JSON mesaja cevir
app.Use(async (baglam, sonraki) =>
{
    try
    {
        await sonraki(baglam);
    }
    catch (SqlException hata)
    {
        app.Logger.LogError(hata, "Veritabani hatasi");
        baglam.Response.StatusCode = StatusCodes.Status503ServiceUnavailable;
        await baglam.Response.WriteAsJsonAsync(
            new HataYaniti($"Veritabanina erisilemedi: {hata.Message}"));
    }
});

// ---------------------------------------------------------------------------
// Yardimcilar
// ---------------------------------------------------------------------------

static string? TokenAl(HttpContext baglam)
{
    var baslik = baglam.Request.Headers.Authorization.ToString();
    return baslik.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase)
        ? baslik["Bearer ".Length..].Trim()
        : null;
}

IResult YetkisizYanit() => Results.Json(new HataYaniti("Oturum gecersiz veya suresi dolmus."),
    statusCode: StatusCodes.Status401Unauthorized);

// ---------------------------------------------------------------------------
// Kimlik uclari
// ---------------------------------------------------------------------------

app.MapGet("/api/durum", () => Results.Ok(new { durum = "calisiyor", surum = "1.0" }));

app.MapPost("/api/giris", async (
    GirisIstegi istek,
    KutuphaneDeposu depo,
    OturumDeposu oturumlar,
    CancellationToken iptal) =>
{
    if (string.IsNullOrWhiteSpace(istek.KullaniciAdi) || string.IsNullOrEmpty(istek.Sifre))
        return Results.BadRequest(new HataYaniti("Kullanici adi ve sifre zorunludur."));

    var kullanici = await depo.KullaniciBulAsync(istek.KullaniciAdi.Trim(), iptal);

    // Kullanici yoksa da sahte bir dogrulama yaparak cevap suresini esitle
    var gecerli = kullanici is not null && SifreServisi.Dogrula(istek.Sifre, kullanici.SifreHash);

    if (kullanici is null || !gecerli)
        return Results.Json(new HataYaniti("Kullanici adi veya sifre hatali."),
            statusCode: StatusCodes.Status401Unauthorized);

    if (!kullanici.Aktif)
        return Results.Json(new HataYaniti("Bu kullanici pasif durumda."),
            statusCode: StatusCodes.Status403Forbidden);

    var oncekiGiris = kullanici.SonGirisTarihi;
    await depo.GirisZamaniniIsleAsync(kullanici.KullaniciId, iptal);

    var token = oturumlar.Olustur(kullanici.KullaniciId, kullanici.KullaniciAdi);
    return Results.Ok(new GirisYaniti(
        token, kullanici.KullaniciId, kullanici.KullaniciAdi, kullanici.AdSoyad, oncekiGiris));
});

app.MapPost("/api/cikis", (HttpContext baglam, OturumDeposu oturumlar) =>
{
    oturumlar.Sil(TokenAl(baglam));
    return Results.Ok(new { mesaj = "Cikis yapildi." });
});

app.MapPost("/api/sifre-degistir", async (
    SifreDegistirmeIstegi istek,
    HttpContext baglam,
    KutuphaneDeposu depo,
    OturumDeposu oturumlar,
    CancellationToken iptal) =>
{
    var oturum = oturumlar.Cozumle(TokenAl(baglam));
    if (oturum is null)
        return YetkisizYanit();

    if (string.IsNullOrEmpty(istek.YeniSifre) || istek.YeniSifre.Length < 4)
        return Results.BadRequest(new HataYaniti("Yeni sifre en az 4 karakter olmalidir."));

    if (istek.YeniSifre == istek.MevcutSifre)
        return Results.BadRequest(new HataYaniti("Yeni sifre eskisiyle ayni olamaz."));

    var kullanici = await depo.KullaniciBulAsync(oturum.KullaniciAdi, iptal);
    if (kullanici is null)
        return YetkisizYanit();

    if (!SifreServisi.Dogrula(istek.MevcutSifre, kullanici.SifreHash))
        return Results.BadRequest(new HataYaniti("Mevcut sifre hatali."));

    await depo.SifreGuncelleAsync(kullanici.KullaniciId, SifreServisi.Hashle(istek.YeniSifre), iptal);

    // Sifre degisti: acik oturumlar dusurulur, yeniden giris istenir.
    oturumlar.KullaniciOturumlariniSil(kullanici.KullaniciId);

    return Results.Ok(new { mesaj = "Sifre guncellendi. Lutfen yeni sifrenizle tekrar giris yapin." });
});

// ---------------------------------------------------------------------------
// Veri uclari  (hepsi oturum ister)
// ---------------------------------------------------------------------------

app.MapGet("/api/ozet", async (HttpContext baglam, KutuphaneDeposu depo, OturumDeposu oturumlar, CancellationToken iptal) =>
    oturumlar.Cozumle(TokenAl(baglam)) is null
        ? YetkisizYanit()
        : Results.Ok(await depo.OzetGetirAsync(iptal)));

app.MapGet("/api/referanslar", async (HttpContext baglam, KutuphaneDeposu depo, OturumDeposu oturumlar, CancellationToken iptal) =>
    oturumlar.Cozumle(TokenAl(baglam)) is null
        ? YetkisizYanit()
        : Results.Ok(await depo.ReferanslariGetirAsync(iptal)));

// ------ Kitaplar ------

app.MapGet("/api/kitaplar", async (
    HttpContext baglam, KutuphaneDeposu depo, OturumDeposu oturumlar,
    string? arama, string? tur, bool? okundu, CancellationToken iptal) =>
{
    if (oturumlar.Cozumle(TokenAl(baglam)) is null) return YetkisizYanit();
    return Results.Ok(await depo.KitaplariGetirAsync(
        string.IsNullOrWhiteSpace(arama) ? null : arama.Trim(),
        string.IsNullOrWhiteSpace(tur) ? null : tur.Trim(),
        okundu, iptal));
});

app.MapPost("/api/kitaplar", async (
    KitapIstegi istek, HttpContext baglam, KutuphaneDeposu depo, OturumDeposu oturumlar, CancellationToken iptal) =>
{
    if (oturumlar.Cozumle(TokenAl(baglam)) is null) return YetkisizYanit();
    if (string.IsNullOrWhiteSpace(istek.Ad))
        return Results.BadRequest(new HataYaniti("Kitap adi zorunludur."));

    var yeniId = await depo.KitapEkleAsync(istek, iptal);
    var kitap = await depo.KitapGetirAsync(yeniId, iptal);
    return Results.Created($"/api/kitaplar/{yeniId}", kitap);
});

app.MapPut("/api/kitaplar/{id:int}", async (
    int id, KitapIstegi istek, HttpContext baglam, KutuphaneDeposu depo, OturumDeposu oturumlar, CancellationToken iptal) =>
{
    if (oturumlar.Cozumle(TokenAl(baglam)) is null) return YetkisizYanit();
    if (string.IsNullOrWhiteSpace(istek.Ad))
        return Results.BadRequest(new HataYaniti("Kitap adi zorunludur."));

    if (!await depo.KitapGuncelleAsync(id, istek, iptal))
        return Results.NotFound(new HataYaniti("Kitap bulunamadi."));

    return Results.Ok(await depo.KitapGetirAsync(id, iptal));
});

app.MapDelete("/api/kitaplar/{id:int}", async (
    int id, HttpContext baglam, KutuphaneDeposu depo, OturumDeposu oturumlar, CancellationToken iptal) =>
{
    if (oturumlar.Cozumle(TokenAl(baglam)) is null) return YetkisizYanit();
    return await depo.KitapSilAsync(id, iptal)
        ? Results.Ok(new { mesaj = "Kitap silindi." })
        : Results.NotFound(new HataYaniti("Kitap bulunamadi."));
});

// ------ Istek listesi ------

app.MapGet("/api/istekler", async (
    HttpContext baglam, KutuphaneDeposu depo, OturumDeposu oturumlar,
    string? arama, string? tur, string? site, bool? satinAlindi, CancellationToken iptal) =>
{
    if (oturumlar.Cozumle(TokenAl(baglam)) is null) return YetkisizYanit();
    return Results.Ok(await depo.IstekleriGetirAsync(
        string.IsNullOrWhiteSpace(arama) ? null : arama.Trim(),
        string.IsNullOrWhiteSpace(tur) ? null : tur.Trim(),
        string.IsNullOrWhiteSpace(site) ? null : site.Trim(),
        satinAlindi, iptal));
});

app.MapPost("/api/istekler", async (
    IstekIstegi istek, HttpContext baglam, KutuphaneDeposu depo, OturumDeposu oturumlar, CancellationToken iptal) =>
{
    if (oturumlar.Cozumle(TokenAl(baglam)) is null) return YetkisizYanit();
    if (string.IsNullOrWhiteSpace(istek.Ad))
        return Results.BadRequest(new HataYaniti("Kitap adi zorunludur."));

    var yeniId = await depo.IstekEkleAsync(istek, iptal);
    return Results.Created($"/api/istekler/{yeniId}", new { istekId = yeniId });
});

app.MapPut("/api/istekler/{id:int}", async (
    int id, IstekIstegi istek, HttpContext baglam, KutuphaneDeposu depo, OturumDeposu oturumlar, CancellationToken iptal) =>
{
    if (oturumlar.Cozumle(TokenAl(baglam)) is null) return YetkisizYanit();
    if (string.IsNullOrWhiteSpace(istek.Ad))
        return Results.BadRequest(new HataYaniti("Kitap adi zorunludur."));

    return await depo.IstekGuncelleAsync(id, istek, iptal)
        ? Results.Ok(new { mesaj = "Guncellendi." })
        : Results.NotFound(new HataYaniti("Kayit bulunamadi."));
});

app.MapDelete("/api/istekler/{id:int}", async (
    int id, HttpContext baglam, KutuphaneDeposu depo, OturumDeposu oturumlar, CancellationToken iptal) =>
{
    if (oturumlar.Cozumle(TokenAl(baglam)) is null) return YetkisizYanit();
    return await depo.IstekSilAsync(id, iptal)
        ? Results.Ok(new { mesaj = "Kayit silindi." })
        : Results.NotFound(new HataYaniti("Kayit bulunamadi."));
});

app.MapPost("/api/istekler/{id:int}/kitapliga-tasi", async (
    int id, HttpContext baglam, KutuphaneDeposu depo, OturumDeposu oturumlar, CancellationToken iptal) =>
{
    if (oturumlar.Cozumle(TokenAl(baglam)) is null) return YetkisizYanit();
    var yeniKitapId = await depo.IstegiKitapligaTasiAsync(id, iptal);
    return yeniKitapId is null
        ? Results.NotFound(new HataYaniti("Kayit bulunamadi."))
        : Results.Ok(new { kitapId = yeniKitapId.Value, mesaj = "Kitapliga tasindi." });
});

app.Logger.LogInformation("KutuphaneApi hazir: http://127.0.0.1:5199");
app.Run();
