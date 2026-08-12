/// SQLite semasi. sql/01_sema.sql dosyasinin (T-SQL) karsiligidir.
///
/// Tur karsiliklari:
///   INT IDENTITY(1,1)  -> INTEGER PRIMARY KEY AUTOINCREMENT
///   NVARCHAR(n)        -> TEXT
///   BIT                -> INTEGER (0/1)
///   DATETIME2          -> TEXT (ISO-8601, datetime('now'))
///   DECIMAL(10,2)      -> INTEGER  (bkz. asagidaki not)
///
/// Fiyat neden kurus: SQLite'ta ondalik sayi tipi yoktur; REAL kullanmak
/// ikili gosterim nedeniyle yuvarlama hatasi biriktirir. Tutarlar kurus
/// cinsinden tam sayi olarak saklanir, arayuze cikarken 100'e bolunur.
/// Boylece T-SQL surumundeki DECIMAL(10,2) hassasiyeti korunur.
library;

const String semaBetigi = '''
PRAGMA foreign_keys = ON;

-- ---------------------------------------------------------------- Kullanicilar
CREATE TABLE IF NOT EXISTS Kullanicilar (
    KullaniciId           INTEGER PRIMARY KEY AUTOINCREMENT,
    KullaniciAdi          TEXT    NOT NULL UNIQUE
                                  CHECK (length(trim(KullaniciAdi)) >= 3),
    SifreHash             TEXT    NOT NULL,
    AdSoyad               TEXT,
    Aktif                 INTEGER NOT NULL DEFAULT 1,
    OlusturmaTarihi       TEXT    NOT NULL DEFAULT (datetime('now')),
    SonGirisTarihi        TEXT,
    SifreDegistirmeTarihi TEXT
);

-- ------------------------------------------------------------ Referans tablolari
CREATE TABLE IF NOT EXISTS Yazarlar (
    YazarId INTEGER PRIMARY KEY AUTOINCREMENT,
    AdSoyad TEXT    NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS Yayinevleri (
    YayineviId INTEGER PRIMARY KEY AUTOINCREMENT,
    Ad         TEXT    NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS Turler (
    TurId INTEGER PRIMARY KEY AUTOINCREMENT,
    Ad    TEXT    NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS SatisSiteleri (
    SiteId INTEGER PRIMARY KEY AUTOINCREMENT,
    Ad     TEXT    NOT NULL UNIQUE
);

-- -------------------------------------------------------------------- Kitaplar
CREATE TABLE IF NOT EXISTS Kitaplar (
    KitapId       INTEGER PRIMARY KEY AUTOINCREMENT,
    SiraNo        INTEGER NOT NULL UNIQUE,
    Ad            TEXT    NOT NULL,
    YazarId       INTEGER REFERENCES Yazarlar(YazarId),
    YayineviId    INTEGER REFERENCES Yayinevleri(YayineviId),
    TurId         INTEGER REFERENCES Turler(TurId),
    SayfaSayisi   INTEGER CHECK (SayfaSayisi IS NULL OR SayfaSayisi > 0),
    OkunduMu      INTEGER NOT NULL DEFAULT 0,
    EklenmeTarihi TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS IX_Kitaplar_Ad       ON Kitaplar(Ad);
CREATE INDEX IF NOT EXISTS IX_Kitaplar_TurId    ON Kitaplar(TurId);
CREATE INDEX IF NOT EXISTS IX_Kitaplar_OkunduMu ON Kitaplar(OkunduMu);

-- ---------------------------------------------------------------- IstekListesi
CREATE TABLE IF NOT EXISTS IstekListesi (
    IstekId       INTEGER PRIMARY KEY AUTOINCREMENT,
    SiraNo        INTEGER NOT NULL UNIQUE,
    Ad            TEXT    NOT NULL,
    YazarId       INTEGER REFERENCES Yazarlar(YazarId),
    YayineviId    INTEGER REFERENCES Yayinevleri(YayineviId),
    TurId         INTEGER REFERENCES Turler(TurId),
    SayfaSayisi   INTEGER CHECK (SayfaSayisi IS NULL OR SayfaSayisi > 0),
    SiteId        INTEGER REFERENCES SatisSiteleri(SiteId),
    FiyatKurus    INTEGER CHECK (FiyatKurus IS NULL OR FiyatKurus >= 0),
    SatinAlindi   INTEGER NOT NULL DEFAULT 0,
    EklenmeTarihi TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS IX_IstekListesi_Ad     ON IstekListesi(Ad);
CREATE INDEX IF NOT EXISTS IX_IstekListesi_SiteId ON IstekListesi(SiteId);

-- ----------------------------------------------------------------- Gorunumler
CREATE VIEW IF NOT EXISTS vw_Kitaplar AS
SELECT  k.KitapId,
        k.SiraNo,
        k.Ad,
        ya.AdSoyad AS Yazar,
        yv.Ad      AS Yayinevi,
        t.Ad       AS Tur,
        k.SayfaSayisi,
        k.OkunduMu,
        k.EklenmeTarihi
FROM      Kitaplar    AS k
LEFT JOIN Yazarlar    AS ya ON ya.YazarId    = k.YazarId
LEFT JOIN Yayinevleri AS yv ON yv.YayineviId = k.YayineviId
LEFT JOIN Turler      AS t  ON t.TurId       = k.TurId;

CREATE VIEW IF NOT EXISTS vw_IstekListesi AS
SELECT  i.IstekId,
        i.SiraNo,
        i.Ad,
        ya.AdSoyad AS Yazar,
        yv.Ad      AS Yayinevi,
        t.Ad       AS Tur,
        i.SayfaSayisi,
        s.Ad       AS Site,
        i.FiyatKurus,
        i.SatinAlindi,
        i.EklenmeTarihi
FROM      IstekListesi  AS i
LEFT JOIN Yazarlar      AS ya ON ya.YazarId    = i.YazarId
LEFT JOIN Yayinevleri   AS yv ON yv.YayineviId = i.YayineviId
LEFT JOIN Turler        AS t  ON t.TurId       = i.TurId
LEFT JOIN SatisSiteleri AS s  ON s.SiteId      = i.SiteId;

CREATE VIEW IF NOT EXISTS vw_Ozet AS
SELECT
    (SELECT COUNT(*)                  FROM Kitaplar)                    AS ToplamKitap,
    (SELECT COUNT(*)                  FROM Kitaplar WHERE OkunduMu = 1) AS OkunanKitap,
    (SELECT COUNT(*)                  FROM Kitaplar WHERE OkunduMu = 0) AS OkunmayanKitap,
    (SELECT COALESCE(SUM(SayfaSayisi), 0) FROM Kitaplar)                AS ToplamSayfa,
    (SELECT COUNT(*)                  FROM IstekListesi)                AS IstekAdedi,
    (SELECT COALESCE(SUM(FiyatKurus), 0) FROM IstekListesi
                                      WHERE SatinAlindi = 0)            AS IstekToplamKurus;
''';

/// Bos bir veritabaninda olusturulacak yonetici hesabi.
/// Sifre: 1234  (ilk giristen sonra degistirilmesi beklenir)
const String varsayilanYoneticiHash =
    r'PBKDF2-SHA256$100000$ag7l3wLCVUH2vIEBkBKOaw==$LcOhbxSQQQorEC/CJ2y5+O6z/8/s9mttel3OfPW/2W4=';
