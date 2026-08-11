/* ============================================================================
   BenimKutuphanem  -  Veritabani Semasi
   ----------------------------------------------------------------------------
   Kaynak    : BenimKutuphanem_Renkli.xlsx  ("Kitap Listesi" sayfasi)
   Sunucu    : .\SQLEXPRESS   (Microsoft SQL Server 2025 Express)
   Calistirma: sqlcmd -S .\SQLEXPRESS -E -d BenimKutuphanem -i 01_sema.sql
   ----------------------------------------------------------------------------
   Betik idempotenttir: tekrar tekrar calistirilabilir, veri kaybi olmaz
   (sadece asagidaki eski deneme tablolari kasitli olarak silinir).
   ============================================================================ */

USE BenimKutuphanem;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* ---------------------------------------------------------------------------
   0) Eski deneme tablolarini kaldir
   --------------------------------------------------------------------------- */
DROP TABLE IF EXISTS dbo.Kutuphanem;
DROP TABLE IF EXISTS dbo.AlinacakKitaplar;
GO

/* ---------------------------------------------------------------------------
   1) Kullanicilar  -  uygulama girisi
       SifreHash formati:  PBKDF2-SHA256$<iterasyon>$<base64 salt>$<base64 hash>
       Sifre asla duz metin olarak tutulmaz; dogrulama ve degistirme islemini
       API yapar (bkz. backend/Guvenlik/SifreServisi.cs).
   --------------------------------------------------------------------------- */
IF OBJECT_ID('dbo.Kullanicilar', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Kullanicilar
    (
        KullaniciId            INT            IDENTITY(1,1) NOT NULL,
        KullaniciAdi           NVARCHAR(50)   NOT NULL,
        SifreHash              NVARCHAR(255)  NOT NULL,
        AdSoyad                NVARCHAR(100)  NULL,
        Aktif                  BIT            NOT NULL CONSTRAINT DF_Kullanicilar_Aktif DEFAULT (1),
        OlusturmaTarihi        DATETIME2(0)   NOT NULL CONSTRAINT DF_Kullanicilar_Olusturma DEFAULT (SYSDATETIME()),
        SonGirisTarihi         DATETIME2(0)   NULL,
        SifreDegistirmeTarihi  DATETIME2(0)   NULL,
        CONSTRAINT PK_Kullanicilar        PRIMARY KEY (KullaniciId),
        CONSTRAINT UQ_Kullanicilar_Adi    UNIQUE (KullaniciAdi),
        CONSTRAINT CK_Kullanicilar_Adi    CHECK (LEN(LTRIM(RTRIM(KullaniciAdi))) >= 3)
    );
END
GO

/* ---------------------------------------------------------------------------
   2) Referans (lookup) tablolari
       Excel'deki "Kitap Yazari", "Yayini", "Turu" ve "Alinacak Site"
       sutunlarinin normallestirilmis halleri. Her iki liste de ayni
       tablolari paylasir (ornegin "Manga" turu ikisinde de ayni satirdir).
   --------------------------------------------------------------------------- */
IF OBJECT_ID('dbo.Yazarlar', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Yazarlar
    (
        YazarId  INT           IDENTITY(1,1) NOT NULL,
        AdSoyad  NVARCHAR(150) NOT NULL,
        CONSTRAINT PK_Yazarlar     PRIMARY KEY (YazarId),
        CONSTRAINT UQ_Yazarlar_Ad  UNIQUE (AdSoyad)
    );
END
GO

IF OBJECT_ID('dbo.Yayinevleri', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Yayinevleri
    (
        YayineviId INT           IDENTITY(1,1) NOT NULL,
        Ad         NVARCHAR(150) NOT NULL,
        CONSTRAINT PK_Yayinevleri     PRIMARY KEY (YayineviId),
        CONSTRAINT UQ_Yayinevleri_Ad  UNIQUE (Ad)
    );
END
GO

IF OBJECT_ID('dbo.Turler', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Turler
    (
        TurId INT           IDENTITY(1,1) NOT NULL,
        Ad    NVARCHAR(100) NOT NULL,
        CONSTRAINT PK_Turler     PRIMARY KEY (TurId),
        CONSTRAINT UQ_Turler_Ad  UNIQUE (Ad)
    );
END
GO

IF OBJECT_ID('dbo.SatisSiteleri', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.SatisSiteleri
    (
        SiteId INT           IDENTITY(1,1) NOT NULL,
        Ad     NVARCHAR(100) NOT NULL,
        CONSTRAINT PK_SatisSiteleri     PRIMARY KEY (SiteId),
        CONSTRAINT UQ_SatisSiteleri_Ad  UNIQUE (Ad)
    );
END
GO

/* ---------------------------------------------------------------------------
   3) Kitaplar  -  Excel'in "SAHIP OLDUKLARIM" bloku (A:G sutunlari)
   --------------------------------------------------------------------------- */
IF OBJECT_ID('dbo.Kitaplar', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Kitaplar
    (
        KitapId       INT           IDENTITY(1,1) NOT NULL,
        SiraNo        INT           NOT NULL,              -- Excel'deki "Numara"
        Ad            NVARCHAR(250) NOT NULL,
        YazarId       INT           NULL,
        YayineviId    INT           NULL,
        TurId         INT           NULL,
        SayfaSayisi   INT           NULL,
        OkunduMu      BIT           NOT NULL CONSTRAINT DF_Kitaplar_Okundu DEFAULT (0),
        EklenmeTarihi DATETIME2(0)  NOT NULL CONSTRAINT DF_Kitaplar_Eklenme DEFAULT (SYSDATETIME()),
        CONSTRAINT PK_Kitaplar            PRIMARY KEY (KitapId),
        CONSTRAINT UQ_Kitaplar_SiraNo     UNIQUE (SiraNo),
        CONSTRAINT CK_Kitaplar_Sayfa      CHECK (SayfaSayisi IS NULL OR SayfaSayisi > 0),
        CONSTRAINT FK_Kitaplar_Yazar      FOREIGN KEY (YazarId)    REFERENCES dbo.Yazarlar(YazarId),
        CONSTRAINT FK_Kitaplar_Yayinevi   FOREIGN KEY (YayineviId) REFERENCES dbo.Yayinevleri(YayineviId),
        CONSTRAINT FK_Kitaplar_Tur        FOREIGN KEY (TurId)      REFERENCES dbo.Turler(TurId)
    );

    CREATE INDEX IX_Kitaplar_Ad        ON dbo.Kitaplar(Ad);
    CREATE INDEX IX_Kitaplar_TurId     ON dbo.Kitaplar(TurId);
    CREATE INDEX IX_Kitaplar_OkunduMu  ON dbo.Kitaplar(OkunduMu);
END
GO

/* ---------------------------------------------------------------------------
   4) IstekListesi  -  Excel'in "ALMAK ISTEDIKLERIM" bloku (I:P sutunlari)
   --------------------------------------------------------------------------- */
IF OBJECT_ID('dbo.IstekListesi', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.IstekListesi
    (
        IstekId       INT            IDENTITY(1,1) NOT NULL,
        SiraNo        INT            NOT NULL,             -- Excel'deki "Numara"
        Ad            NVARCHAR(250)  NOT NULL,
        YazarId       INT            NULL,
        YayineviId    INT            NULL,
        TurId         INT            NULL,
        SayfaSayisi   INT            NULL,
        SiteId        INT            NULL,                 -- "Alinacak Site"
        Fiyat         DECIMAL(10,2)  NULL,                 -- "Fiyati" (TL)
        SatinAlindi   BIT            NOT NULL CONSTRAINT DF_Istek_SatinAlindi DEFAULT (0),
        EklenmeTarihi DATETIME2(0)   NOT NULL CONSTRAINT DF_Istek_Eklenme DEFAULT (SYSDATETIME()),
        CONSTRAINT PK_IstekListesi          PRIMARY KEY (IstekId),
        CONSTRAINT UQ_IstekListesi_SiraNo   UNIQUE (SiraNo),
        CONSTRAINT CK_IstekListesi_Sayfa    CHECK (SayfaSayisi IS NULL OR SayfaSayisi > 0),
        CONSTRAINT CK_IstekListesi_Fiyat    CHECK (Fiyat IS NULL OR Fiyat >= 0),
        CONSTRAINT FK_Istek_Yazar           FOREIGN KEY (YazarId)    REFERENCES dbo.Yazarlar(YazarId),
        CONSTRAINT FK_Istek_Yayinevi        FOREIGN KEY (YayineviId) REFERENCES dbo.Yayinevleri(YayineviId),
        CONSTRAINT FK_Istek_Tur             FOREIGN KEY (TurId)      REFERENCES dbo.Turler(TurId),
        CONSTRAINT FK_Istek_Site            FOREIGN KEY (SiteId)     REFERENCES dbo.SatisSiteleri(SiteId)
    );

    CREATE INDEX IX_IstekListesi_Ad     ON dbo.IstekListesi(Ad);
    CREATE INDEX IX_IstekListesi_SiteId ON dbo.IstekListesi(SiteId);
END
GO

/* ---------------------------------------------------------------------------
   5) Okuma view'lari  -  uygulama listeleri bunlardan beslenir
   --------------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.vw_Kitaplar
AS
SELECT  k.KitapId,
        k.SiraNo,
        k.Ad,
        ya.AdSoyad AS Yazar,
        yv.Ad      AS Yayinevi,
        t.Ad       AS Tur,
        k.SayfaSayisi,
        k.OkunduMu,
        k.YazarId,
        k.YayineviId,
        k.TurId,
        k.EklenmeTarihi
FROM        dbo.Kitaplar    AS k
LEFT JOIN   dbo.Yazarlar    AS ya ON ya.YazarId    = k.YazarId
LEFT JOIN   dbo.Yayinevleri AS yv ON yv.YayineviId = k.YayineviId
LEFT JOIN   dbo.Turler      AS t  ON t.TurId       = k.TurId;
GO

CREATE OR ALTER VIEW dbo.vw_IstekListesi
AS
SELECT  i.IstekId,
        i.SiraNo,
        i.Ad,
        ya.AdSoyad AS Yazar,
        yv.Ad      AS Yayinevi,
        t.Ad       AS Tur,
        i.SayfaSayisi,
        s.Ad       AS Site,
        i.Fiyat,
        i.SatinAlindi,
        i.YazarId,
        i.YayineviId,
        i.TurId,
        i.SiteId,
        i.EklenmeTarihi
FROM        dbo.IstekListesi  AS i
LEFT JOIN   dbo.Yazarlar      AS ya ON ya.YazarId    = i.YazarId
LEFT JOIN   dbo.Yayinevleri   AS yv ON yv.YayineviId = i.YayineviId
LEFT JOIN   dbo.Turler        AS t  ON t.TurId       = i.TurId
LEFT JOIN   dbo.SatisSiteleri AS s  ON s.SiteId      = i.SiteId;
GO

/* Ana ekrandaki ozet kutulari icin */
CREATE OR ALTER VIEW dbo.vw_Ozet
AS
SELECT
    (SELECT COUNT(*)               FROM dbo.Kitaplar)                     AS ToplamKitap,
    (SELECT COUNT(*)               FROM dbo.Kitaplar WHERE OkunduMu = 1)  AS OkunanKitap,
    (SELECT COUNT(*)               FROM dbo.Kitaplar WHERE OkunduMu = 0)  AS OkunmayanKitap,
    (SELECT ISNULL(SUM(SayfaSayisi), 0) FROM dbo.Kitaplar)                AS ToplamSayfa,
    (SELECT COUNT(*)               FROM dbo.IstekListesi)                 AS IstekAdedi,
    (SELECT ISNULL(SUM(Fiyat), 0)  FROM dbo.IstekListesi
                                   WHERE SatinAlindi = 0)                 AS IstekToplamTutar;
GO

/* ---------------------------------------------------------------------------
   6) Baslangic kullanicilari
       admin / 1234        ve        emir / 1234
       (Ilk giristen sonra uygulama icindeki "Sifre Degistir" ekranindan
        degistirilmelidir.)
   --------------------------------------------------------------------------- */
MERGE dbo.Kullanicilar AS h
USING (VALUES
        (N'admin', N'PBKDF2-SHA256$100000$ag7l3wLCVUH2vIEBkBKOaw==$LcOhbxSQQQorEC/CJ2y5+O6z/8/s9mttel3OfPW/2W4=', N'Sistem Yoneticisi'),
        (N'emir',  N'PBKDF2-SHA256$100000$Yz8ReHW0sE9ZsiafgRFjFQ==$WJmPJ/cTxYMS5V8loROpfRDucdW4aTA7bCA4ktnIvcM=', N'Emir Can Bicen')
      ) AS k (KullaniciAdi, SifreHash, AdSoyad)
    ON h.KullaniciAdi = k.KullaniciAdi
WHEN NOT MATCHED BY TARGET THEN
    INSERT (KullaniciAdi, SifreHash, AdSoyad)
    VALUES (k.KullaniciAdi, k.SifreHash, k.AdSoyad);
GO

PRINT 'Sema hazir: Kullanicilar, Yazarlar, Yayinevleri, Turler, SatisSiteleri, Kitaplar, IstekListesi';
GO
