using System.Security.Cryptography;

namespace KutuphaneApi.Guvenlik;

/// <summary>
/// Sifreleri PBKDF2-HMAC-SHA256 ile hash'ler ve dogrular.
/// Veritabaninda tutulan bicim:
///     PBKDF2-SHA256$&lt;iterasyon&gt;$&lt;base64 salt&gt;$&lt;base64 hash&gt;
/// Duz sifre hicbir yerde saklanmaz.
/// </summary>
public static class SifreServisi
{
    private const string Algoritma = "PBKDF2-SHA256";
    private const int Iterasyon = 100_000;
    private const int SaltUzunlugu = 16;   // 128 bit
    private const int HashUzunlugu = 32;   // 256 bit

    /// <summary>Yeni bir salt uretip sifreyi hash'ler.</summary>
    public static string Hashle(string sifre)
    {
        var salt = RandomNumberGenerator.GetBytes(SaltUzunlugu);
        var hash = Rfc2898DeriveBytes.Pbkdf2(sifre, salt, Iterasyon, HashAlgorithmName.SHA256, HashUzunlugu);
        return $"{Algoritma}${Iterasyon}${Convert.ToBase64String(salt)}${Convert.ToBase64String(hash)}";
    }

    /// <summary>Girilen sifreyi kayitli hash ile karsilastirir (zaman saldirisina kapali).</summary>
    public static bool Dogrula(string sifre, string kayitliHash)
    {
        var parcalar = kayitliHash.Split('$');
        if (parcalar.Length != 4 || parcalar[0] != Algoritma)
            return false;

        if (!int.TryParse(parcalar[1], out var iterasyon) || iterasyon <= 0)
            return false;

        byte[] salt, beklenen;
        try
        {
            salt = Convert.FromBase64String(parcalar[2]);
            beklenen = Convert.FromBase64String(parcalar[3]);
        }
        catch (FormatException)
        {
            return false;
        }

        var hesaplanan = Rfc2898DeriveBytes.Pbkdf2(
            sifre, salt, iterasyon, HashAlgorithmName.SHA256, beklenen.Length);

        return CryptographicOperations.FixedTimeEquals(hesaplanan, beklenen);
    }
}
