using System.Collections.Concurrent;
using System.Security.Cryptography;

namespace KutuphaneApi.Guvenlik;

/// <summary>Giris yapan kullanicinin oturum bilgisi.</summary>
public sealed record Oturum(int KullaniciId, string KullaniciAdi, DateTime SonErisim);

/// <summary>
/// Bellek ici oturum deposu. Giriste bir token uretilir, istemci bunu
/// "Authorization: Bearer &lt;token&gt;" basligiyla gonderir.
/// Tek kullanicili masaustu senaryosu icin yeterlidir; API yeniden
/// baslatildiginda oturumlar dusser ve tekrar giris gerekir.
/// </summary>
public sealed class OturumDeposu
{
    private static readonly TimeSpan Zamanasimi = TimeSpan.FromHours(8);
    private readonly ConcurrentDictionary<string, Oturum> _oturumlar = new();

    public string Olustur(int kullaniciId, string kullaniciAdi)
    {
        var token = Convert.ToHexString(RandomNumberGenerator.GetBytes(32));
        _oturumlar[token] = new Oturum(kullaniciId, kullaniciAdi, DateTime.UtcNow);
        return token;
    }

    public Oturum? Cozumle(string? token)
    {
        if (string.IsNullOrWhiteSpace(token) || !_oturumlar.TryGetValue(token, out var oturum))
            return null;

        if (DateTime.UtcNow - oturum.SonErisim > Zamanasimi)
        {
            _oturumlar.TryRemove(token, out _);
            return null;
        }

        var tazelenmis = oturum with { SonErisim = DateTime.UtcNow };
        _oturumlar[token] = tazelenmis;
        return tazelenmis;
    }

    public void Sil(string? token)
    {
        if (!string.IsNullOrWhiteSpace(token))
            _oturumlar.TryRemove(token, out _);
    }

    /// <summary>Sifre degistiginde o kullanicinin tum oturumlarini dusurur.</summary>
    public void KullaniciOturumlariniSil(int kullaniciId)
    {
        foreach (var (token, oturum) in _oturumlar)
        {
            if (oturum.KullaniciId == kullaniciId)
                _oturumlar.TryRemove(token, out _);
        }
    }
}
