using System.Data;
using KutuphaneApi.Modeller;
using Microsoft.Data.SqlClient;

namespace KutuphaneApi.Veri;

/// <summary>
/// BenimKutuphanem veritabanina erisen tek katman.
/// Tum sorgular parametrelidir (SQL injection'a kapali).
/// </summary>
public sealed class KutuphaneDeposu(string baglantiMetni)
{
    private readonly string _baglantiMetni = baglantiMetni;

    private async Task<SqlConnection> AcAsync(CancellationToken iptal)
    {
        var baglanti = new SqlConnection(_baglantiMetni);
        await baglanti.OpenAsync(iptal);
        return baglanti;
    }

    private static object Db(object? deger) => deger ?? DBNull.Value;

    private static string? Metin(SqlDataReader okuyucu, int sutun) =>
        okuyucu.IsDBNull(sutun) ? null : okuyucu.GetString(sutun);

    private static int? TamSayi(SqlDataReader okuyucu, int sutun) =>
        okuyucu.IsDBNull(sutun) ? null : okuyucu.GetInt32(sutun);

    private static decimal? Ondalik(SqlDataReader okuyucu, int sutun) =>
        okuyucu.IsDBNull(sutun) ? null : okuyucu.GetDecimal(sutun);

    // ------------------------------------------------------------ Kimlik ---

    public async Task<Kullanici?> KullaniciBulAsync(string kullaniciAdi, CancellationToken iptal)
    {
        const string sql = """
            SELECT KullaniciId, KullaniciAdi, SifreHash, AdSoyad, Aktif, SonGirisTarihi
            FROM   dbo.Kullanicilar
            WHERE  KullaniciAdi = @kullaniciAdi;
            """;

        await using var baglanti = await AcAsync(iptal);
        await using var komut = new SqlCommand(sql, baglanti);
        komut.Parameters.Add("@kullaniciAdi", SqlDbType.NVarChar, 50).Value = kullaniciAdi;

        await using var okuyucu = await komut.ExecuteReaderAsync(iptal);
        if (!await okuyucu.ReadAsync(iptal))
            return null;

        return new Kullanici(
            okuyucu.GetInt32(0),
            okuyucu.GetString(1),
            okuyucu.GetString(2),
            Metin(okuyucu, 3),
            okuyucu.GetBoolean(4),
            okuyucu.IsDBNull(5) ? null : okuyucu.GetDateTime(5));
    }

    public async Task GirisZamaniniIsleAsync(int kullaniciId, CancellationToken iptal)
    {
        const string sql = "UPDATE dbo.Kullanicilar SET SonGirisTarihi = SYSDATETIME() WHERE KullaniciId = @id;";
        await using var baglanti = await AcAsync(iptal);
        await using var komut = new SqlCommand(sql, baglanti);
        komut.Parameters.Add("@id", SqlDbType.Int).Value = kullaniciId;
        await komut.ExecuteNonQueryAsync(iptal);
    }

    public async Task SifreGuncelleAsync(int kullaniciId, string yeniHash, CancellationToken iptal)
    {
        const string sql = """
            UPDATE dbo.Kullanicilar
            SET    SifreHash = @hash,
                   SifreDegistirmeTarihi = SYSDATETIME()
            WHERE  KullaniciId = @id;
            """;

        await using var baglanti = await AcAsync(iptal);
        await using var komut = new SqlCommand(sql, baglanti);
        komut.Parameters.Add("@hash", SqlDbType.NVarChar, 255).Value = yeniHash;
        komut.Parameters.Add("@id", SqlDbType.Int).Value = kullaniciId;
        await komut.ExecuteNonQueryAsync(iptal);
    }

    // ----------------------------------------------------------- Kitaplar ---

    public async Task<List<Kitap>> KitaplariGetirAsync(
        string? arama, string? tur, bool? okundu, CancellationToken iptal)
    {
        const string sql = """
            SELECT KitapId, SiraNo, Ad, Yazar, Yayinevi, Tur, SayfaSayisi, OkunduMu
            FROM   dbo.vw_Kitaplar
            WHERE  (@arama  IS NULL OR Ad LIKE '%' + @arama + '%' OR ISNULL(Yazar, N'') LIKE '%' + @arama + '%')
              AND  (@tur    IS NULL OR Tur = @tur)
              AND  (@okundu IS NULL OR OkunduMu = @okundu)
            ORDER BY SiraNo;
            """;

        await using var baglanti = await AcAsync(iptal);
        await using var komut = new SqlCommand(sql, baglanti);
        komut.Parameters.Add("@arama", SqlDbType.NVarChar, 250).Value = Db(arama);
        komut.Parameters.Add("@tur", SqlDbType.NVarChar, 100).Value = Db(tur);
        komut.Parameters.Add("@okundu", SqlDbType.Bit).Value = Db(okundu);

        var liste = new List<Kitap>();
        await using var okuyucu = await komut.ExecuteReaderAsync(iptal);
        while (await okuyucu.ReadAsync(iptal))
        {
            liste.Add(new Kitap(
                okuyucu.GetInt32(0),
                okuyucu.GetInt32(1),
                okuyucu.GetString(2),
                Metin(okuyucu, 3),
                Metin(okuyucu, 4),
                Metin(okuyucu, 5),
                TamSayi(okuyucu, 6),
                okuyucu.GetBoolean(7)));
        }
        return liste;
    }

    public async Task<Kitap?> KitapGetirAsync(int kitapId, CancellationToken iptal)
    {
        const string sql = """
            SELECT KitapId, SiraNo, Ad, Yazar, Yayinevi, Tur, SayfaSayisi, OkunduMu
            FROM   dbo.vw_Kitaplar
            WHERE  KitapId = @id;
            """;

        await using var baglanti = await AcAsync(iptal);
        await using var komut = new SqlCommand(sql, baglanti);
        komut.Parameters.Add("@id", SqlDbType.Int).Value = kitapId;

        await using var okuyucu = await komut.ExecuteReaderAsync(iptal);
        if (!await okuyucu.ReadAsync(iptal))
            return null;

        return new Kitap(
            okuyucu.GetInt32(0), okuyucu.GetInt32(1), okuyucu.GetString(2),
            Metin(okuyucu, 3), Metin(okuyucu, 4), Metin(okuyucu, 5),
            TamSayi(okuyucu, 6), okuyucu.GetBoolean(7));
    }

    public async Task<int> KitapEkleAsync(KitapIstegi istek, CancellationToken iptal)
    {
        await using var baglanti = await AcAsync(iptal);
        await using var islem = (SqlTransaction)await baglanti.BeginTransactionAsync(iptal);

        var yazarId = await ReferansIdAsync(baglanti, islem, "Yazarlar", "AdSoyad", "YazarId", istek.Yazar, iptal);
        var yayinId = await ReferansIdAsync(baglanti, islem, "Yayinevleri", "Ad", "YayineviId", istek.Yayinevi, iptal);
        var turId = await ReferansIdAsync(baglanti, islem, "Turler", "Ad", "TurId", istek.Tur, iptal);

        const string sql = """
            INSERT INTO dbo.Kitaplar (SiraNo, Ad, YazarId, YayineviId, TurId, SayfaSayisi, OkunduMu)
            OUTPUT INSERTED.KitapId
            SELECT ISNULL((SELECT MAX(SiraNo) FROM dbo.Kitaplar), 0) + 1,
                   @ad, @yazarId, @yayinId, @turId, @sayfa, @okundu;
            """;

        await using var komut = new SqlCommand(sql, baglanti, islem);
        komut.Parameters.Add("@ad", SqlDbType.NVarChar, 250).Value = istek.Ad.Trim();
        komut.Parameters.Add("@yazarId", SqlDbType.Int).Value = Db(yazarId);
        komut.Parameters.Add("@yayinId", SqlDbType.Int).Value = Db(yayinId);
        komut.Parameters.Add("@turId", SqlDbType.Int).Value = Db(turId);
        komut.Parameters.Add("@sayfa", SqlDbType.Int).Value = Db(istek.SayfaSayisi);
        komut.Parameters.Add("@okundu", SqlDbType.Bit).Value = istek.OkunduMu;

        var yeniId = (int)(await komut.ExecuteScalarAsync(iptal))!;
        await islem.CommitAsync(iptal);
        return yeniId;
    }

    public async Task<bool> KitapGuncelleAsync(int kitapId, KitapIstegi istek, CancellationToken iptal)
    {
        await using var baglanti = await AcAsync(iptal);
        await using var islem = (SqlTransaction)await baglanti.BeginTransactionAsync(iptal);

        var yazarId = await ReferansIdAsync(baglanti, islem, "Yazarlar", "AdSoyad", "YazarId", istek.Yazar, iptal);
        var yayinId = await ReferansIdAsync(baglanti, islem, "Yayinevleri", "Ad", "YayineviId", istek.Yayinevi, iptal);
        var turId = await ReferansIdAsync(baglanti, islem, "Turler", "Ad", "TurId", istek.Tur, iptal);

        const string sql = """
            UPDATE dbo.Kitaplar
            SET    Ad = @ad, YazarId = @yazarId, YayineviId = @yayinId,
                   TurId = @turId, SayfaSayisi = @sayfa, OkunduMu = @okundu
            WHERE  KitapId = @id;
            """;

        await using var komut = new SqlCommand(sql, baglanti, islem);
        komut.Parameters.Add("@ad", SqlDbType.NVarChar, 250).Value = istek.Ad.Trim();
        komut.Parameters.Add("@yazarId", SqlDbType.Int).Value = Db(yazarId);
        komut.Parameters.Add("@yayinId", SqlDbType.Int).Value = Db(yayinId);
        komut.Parameters.Add("@turId", SqlDbType.Int).Value = Db(turId);
        komut.Parameters.Add("@sayfa", SqlDbType.Int).Value = Db(istek.SayfaSayisi);
        komut.Parameters.Add("@okundu", SqlDbType.Bit).Value = istek.OkunduMu;
        komut.Parameters.Add("@id", SqlDbType.Int).Value = kitapId;

        var etkilenen = await komut.ExecuteNonQueryAsync(iptal);
        await islem.CommitAsync(iptal);
        return etkilenen > 0;
    }

    public async Task<bool> KitapSilAsync(int kitapId, CancellationToken iptal)
    {
        await using var baglanti = await AcAsync(iptal);
        await using var komut = new SqlCommand("DELETE FROM dbo.Kitaplar WHERE KitapId = @id;", baglanti);
        komut.Parameters.Add("@id", SqlDbType.Int).Value = kitapId;
        return await komut.ExecuteNonQueryAsync(iptal) > 0;
    }

    // ------------------------------------------------------ Istek listesi ---

    public async Task<List<Istek>> IstekleriGetirAsync(
        string? arama, string? tur, string? site, bool? satinAlindi, CancellationToken iptal)
    {
        const string sql = """
            SELECT IstekId, SiraNo, Ad, Yazar, Yayinevi, Tur, SayfaSayisi, Site, Fiyat, SatinAlindi
            FROM   dbo.vw_IstekListesi
            WHERE  (@arama IS NULL OR Ad LIKE '%' + @arama + '%' OR ISNULL(Yazar, N'') LIKE '%' + @arama + '%')
              AND  (@tur   IS NULL OR Tur = @tur)
              AND  (@site  IS NULL OR Site = @site)
              AND  (@alindi IS NULL OR SatinAlindi = @alindi)
            ORDER BY SiraNo;
            """;

        await using var baglanti = await AcAsync(iptal);
        await using var komut = new SqlCommand(sql, baglanti);
        komut.Parameters.Add("@arama", SqlDbType.NVarChar, 250).Value = Db(arama);
        komut.Parameters.Add("@tur", SqlDbType.NVarChar, 100).Value = Db(tur);
        komut.Parameters.Add("@site", SqlDbType.NVarChar, 100).Value = Db(site);
        komut.Parameters.Add("@alindi", SqlDbType.Bit).Value = Db(satinAlindi);

        var liste = new List<Istek>();
        await using var okuyucu = await komut.ExecuteReaderAsync(iptal);
        while (await okuyucu.ReadAsync(iptal))
        {
            liste.Add(new Istek(
                okuyucu.GetInt32(0),
                okuyucu.GetInt32(1),
                okuyucu.GetString(2),
                Metin(okuyucu, 3),
                Metin(okuyucu, 4),
                Metin(okuyucu, 5),
                TamSayi(okuyucu, 6),
                Metin(okuyucu, 7),
                Ondalik(okuyucu, 8),
                okuyucu.GetBoolean(9)));
        }
        return liste;
    }

    public async Task<int> IstekEkleAsync(IstekIstegi istek, CancellationToken iptal)
    {
        await using var baglanti = await AcAsync(iptal);
        await using var islem = (SqlTransaction)await baglanti.BeginTransactionAsync(iptal);

        var yazarId = await ReferansIdAsync(baglanti, islem, "Yazarlar", "AdSoyad", "YazarId", istek.Yazar, iptal);
        var yayinId = await ReferansIdAsync(baglanti, islem, "Yayinevleri", "Ad", "YayineviId", istek.Yayinevi, iptal);
        var turId = await ReferansIdAsync(baglanti, islem, "Turler", "Ad", "TurId", istek.Tur, iptal);
        var siteId = await ReferansIdAsync(baglanti, islem, "SatisSiteleri", "Ad", "SiteId", istek.Site, iptal);

        const string sql = """
            INSERT INTO dbo.IstekListesi (SiraNo, Ad, YazarId, YayineviId, TurId, SayfaSayisi, SiteId, Fiyat, SatinAlindi)
            OUTPUT INSERTED.IstekId
            SELECT ISNULL((SELECT MAX(SiraNo) FROM dbo.IstekListesi), 0) + 1,
                   @ad, @yazarId, @yayinId, @turId, @sayfa, @siteId, @fiyat, @alindi;
            """;

        await using var komut = new SqlCommand(sql, baglanti, islem);
        komut.Parameters.Add("@ad", SqlDbType.NVarChar, 250).Value = istek.Ad.Trim();
        komut.Parameters.Add("@yazarId", SqlDbType.Int).Value = Db(yazarId);
        komut.Parameters.Add("@yayinId", SqlDbType.Int).Value = Db(yayinId);
        komut.Parameters.Add("@turId", SqlDbType.Int).Value = Db(turId);
        komut.Parameters.Add("@sayfa", SqlDbType.Int).Value = Db(istek.SayfaSayisi);
        komut.Parameters.Add("@siteId", SqlDbType.Int).Value = Db(siteId);
        komut.Parameters.Add("@fiyat", SqlDbType.Decimal).Value = Db(istek.Fiyat);
        komut.Parameters["@fiyat"].Precision = 10;
        komut.Parameters["@fiyat"].Scale = 2;
        komut.Parameters.Add("@alindi", SqlDbType.Bit).Value = istek.SatinAlindi;

        var yeniId = (int)(await komut.ExecuteScalarAsync(iptal))!;
        await islem.CommitAsync(iptal);
        return yeniId;
    }

    public async Task<bool> IstekGuncelleAsync(int istekId, IstekIstegi istek, CancellationToken iptal)
    {
        await using var baglanti = await AcAsync(iptal);
        await using var islem = (SqlTransaction)await baglanti.BeginTransactionAsync(iptal);

        var yazarId = await ReferansIdAsync(baglanti, islem, "Yazarlar", "AdSoyad", "YazarId", istek.Yazar, iptal);
        var yayinId = await ReferansIdAsync(baglanti, islem, "Yayinevleri", "Ad", "YayineviId", istek.Yayinevi, iptal);
        var turId = await ReferansIdAsync(baglanti, islem, "Turler", "Ad", "TurId", istek.Tur, iptal);
        var siteId = await ReferansIdAsync(baglanti, islem, "SatisSiteleri", "Ad", "SiteId", istek.Site, iptal);

        const string sql = """
            UPDATE dbo.IstekListesi
            SET    Ad = @ad, YazarId = @yazarId, YayineviId = @yayinId, TurId = @turId,
                   SayfaSayisi = @sayfa, SiteId = @siteId, Fiyat = @fiyat, SatinAlindi = @alindi
            WHERE  IstekId = @id;
            """;

        await using var komut = new SqlCommand(sql, baglanti, islem);
        komut.Parameters.Add("@ad", SqlDbType.NVarChar, 250).Value = istek.Ad.Trim();
        komut.Parameters.Add("@yazarId", SqlDbType.Int).Value = Db(yazarId);
        komut.Parameters.Add("@yayinId", SqlDbType.Int).Value = Db(yayinId);
        komut.Parameters.Add("@turId", SqlDbType.Int).Value = Db(turId);
        komut.Parameters.Add("@sayfa", SqlDbType.Int).Value = Db(istek.SayfaSayisi);
        komut.Parameters.Add("@siteId", SqlDbType.Int).Value = Db(siteId);
        komut.Parameters.Add("@fiyat", SqlDbType.Decimal).Value = Db(istek.Fiyat);
        komut.Parameters["@fiyat"].Precision = 10;
        komut.Parameters["@fiyat"].Scale = 2;
        komut.Parameters.Add("@alindi", SqlDbType.Bit).Value = istek.SatinAlindi;
        komut.Parameters.Add("@id", SqlDbType.Int).Value = istekId;

        var etkilenen = await komut.ExecuteNonQueryAsync(iptal);
        await islem.CommitAsync(iptal);
        return etkilenen > 0;
    }

    public async Task<bool> IstekSilAsync(int istekId, CancellationToken iptal)
    {
        await using var baglanti = await AcAsync(iptal);
        await using var komut = new SqlCommand("DELETE FROM dbo.IstekListesi WHERE IstekId = @id;", baglanti);
        komut.Parameters.Add("@id", SqlDbType.Int).Value = istekId;
        return await komut.ExecuteNonQueryAsync(iptal) > 0;
    }

    /// <summary>Istek listesindeki bir kaydi kitapliga tasir.</summary>
    public async Task<int?> IstegiKitapligaTasiAsync(int istekId, CancellationToken iptal)
    {
        await using var baglanti = await AcAsync(iptal);
        await using var islem = (SqlTransaction)await baglanti.BeginTransactionAsync(iptal);

        const string tasi = """
            INSERT INTO dbo.Kitaplar (SiraNo, Ad, YazarId, YayineviId, TurId, SayfaSayisi, OkunduMu)
            OUTPUT INSERTED.KitapId
            SELECT ISNULL((SELECT MAX(SiraNo) FROM dbo.Kitaplar), 0) + 1,
                   i.Ad, i.YazarId, i.YayineviId, i.TurId, i.SayfaSayisi, 0
            FROM   dbo.IstekListesi AS i
            WHERE  i.IstekId = @id;
            """;

        await using (var komut = new SqlCommand(tasi, baglanti, islem))
        {
            komut.Parameters.Add("@id", SqlDbType.Int).Value = istekId;
            var sonuc = await komut.ExecuteScalarAsync(iptal);
            if (sonuc is not int yeniKitapId)
            {
                await islem.RollbackAsync(iptal);
                return null;
            }

            await using (var sil = new SqlCommand(
                "DELETE FROM dbo.IstekListesi WHERE IstekId = @id;", baglanti, islem))
            {
                sil.Parameters.Add("@id", SqlDbType.Int).Value = istekId;
                await sil.ExecuteNonQueryAsync(iptal);
            }

            await islem.CommitAsync(iptal);
            return yeniKitapId;
        }
    }

    // ------------------------------------------------------------- Diger ----

    public async Task<Ozet> OzetGetirAsync(CancellationToken iptal)
    {
        const string sql = """
            SELECT ToplamKitap, OkunanKitap, OkunmayanKitap, ToplamSayfa, IstekAdedi, IstekToplamTutar
            FROM   dbo.vw_Ozet;
            """;

        await using var baglanti = await AcAsync(iptal);
        await using var komut = new SqlCommand(sql, baglanti);
        await using var okuyucu = await komut.ExecuteReaderAsync(iptal);
        await okuyucu.ReadAsync(iptal);

        return new Ozet(
            okuyucu.GetInt32(0),
            okuyucu.GetInt32(1),
            okuyucu.GetInt32(2),
            okuyucu.GetInt32(3),
            okuyucu.GetInt32(4),
            okuyucu.GetDecimal(5));
    }

    public async Task<Referanslar> ReferanslariGetirAsync(CancellationToken iptal)
    {
        await using var baglanti = await AcAsync(iptal);

        async Task<List<string>> ListeAsync(string sql)
        {
            var liste = new List<string>();
            await using var komut = new SqlCommand(sql, baglanti);
            await using var okuyucu = await komut.ExecuteReaderAsync(iptal);
            while (await okuyucu.ReadAsync(iptal))
                liste.Add(okuyucu.GetString(0));
            return liste;
        }

        return new Referanslar(
            await ListeAsync("SELECT AdSoyad FROM dbo.Yazarlar ORDER BY AdSoyad;"),
            await ListeAsync("SELECT Ad FROM dbo.Yayinevleri ORDER BY Ad;"),
            await ListeAsync("SELECT Ad FROM dbo.Turler ORDER BY Ad;"),
            await ListeAsync("SELECT Ad FROM dbo.SatisSiteleri ORDER BY Ad;"));
    }

    /// <summary>
    /// Referans tablosunda verilen adi arar; yoksa ekler ve Id'sini dondurur.
    /// Bos/null ad icin null doner (kolon NULL kalir).
    /// Tablo ve sutun adlari sabit metinlerden gelir, kullanici girdisi degildir.
    /// </summary>
    private static async Task<int?> ReferansIdAsync(
        SqlConnection baglanti,
        SqlTransaction islem,
        string tablo,
        string adSutunu,
        string idSutunu,
        string? ad,
        CancellationToken iptal)
    {
        if (string.IsNullOrWhiteSpace(ad))
            return null;

        var temiz = ad.Trim();

        var sql = $"""
            SELECT {idSutunu} FROM dbo.{tablo} WHERE {adSutunu} = @ad;
            IF @@ROWCOUNT = 0
            BEGIN
                INSERT INTO dbo.{tablo} ({adSutunu}) OUTPUT INSERTED.{idSutunu} VALUES (@ad);
            END
            """;

        await using var komut = new SqlCommand(sql, baglanti, islem);
        komut.Parameters.Add("@ad", SqlDbType.NVarChar, 150).Value = temiz;

        await using var okuyucu = await komut.ExecuteReaderAsync(iptal);
        do
        {
            if (await okuyucu.ReadAsync(iptal))
                return okuyucu.GetInt32(0);
        } while (await okuyucu.NextResultAsync(iptal));

        return null;
    }
}
