/* ============================================================================
   BenimKutuphanem  -  Excel Veri Aktarimi
   ----------------------------------------------------------------------------
   BU DOSYA OTOMATIK URETILMISTIR - elle duzenlemeyin.
   Ureten     : tools/excel_to_sql.py
   Kaynak     : BenimKutuphanem_Renkli.xlsx  (sayfa: Kitap Listesi)
   Kitaplar   : 64 satir
   IstekListesi: 100 satir
   Atlanan    : Excel'de sadece numarasi olan bos istek satirlari -> [55, 56]
   ----------------------------------------------------------------------------
   Onkosul    : 01_sema.sql calistirilmis olmali.
   Calistirma : sqlcmd -S .\SQLEXPRESS -E -d BenimKutuphanem -i 02_veri.sql
   Betik tekrar calistirilabilir: Kitaplar ve IstekListesi bastan yuklenir.
   ============================================================================ */

USE BenimKutuphanem;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRANSACTION;
GO

/* --- Onceki aktarimi temizle (referans tablolari korunur) ---
     TRUNCATE, DELETE'ten farkli olarak IDENTITY sayacini da
     basa alir; boylece KitapId her zaman 1'den baslar.          --- */
TRUNCATE TABLE dbo.Kitaplar;
TRUNCATE TABLE dbo.IstekListesi;
GO

/* --- 1) Yazarlar (51 adet) --- */
MERGE dbo.Yazarlar AS h
USING (VALUES
        (N'Aka Akasaka'),
        (N'Andrzej Sapkowski'),
        (N'Antoine de Saint Exupery'),
        (N'Brandon Sanderson'),
        (N'Carl Sagan'),
        (N'Coşkun Taşdenmir'),
        (N'Dmitry Glukhovsky'),
        (N'Edgar Allen Poe'),
        (N'Ferda İzbudak Akıncı'),
        (N'Franz Kafka'),
        (N'Geoff Johns'),
        (N'George Orwell'),
        (N'George William Cortis'),
        (N'H.G. Wells'),
        (N'Haro Aso'),
        (N'Heather McELHATTON'),
        (N'Hitoshi İwaaki'),
        (N'J.K. Rowling'),
        (N'J.R.R Tolkien'),
        (N'James Dashner'),
        (N'Jhon Stainback'),
        (N'Jhon Steinbeck'),
        (N'Jose Mauro De Vasconselos'),
        (N'Jose Saramago'),
        (N'Juliana Horitia Ewing'),
        (N'Kemal Tahir'),
        (N'Kolektif'),
        (N'Liz Ruckdeschel & Sara James'),
        (N'Makota Şinai'),
        (N'Marcus Aurelius'),
        (N'Mario Mazzanti'),
        (N'Matt Haig'),
        (N'Maxime Chattam'),
        (N'Michio Kaku'),
        (N'Naoya Matsumoto'),
        (N'Peyami Safa'),
        (N'Pierre Varrod'),
        (N'Resul Kara'),
        (N'Sir Arthur Canon Doyle'),
        (N'Stefan Zweig'),
        (N'Stephan Hawking'),
        (N'Stephan King'),
        (N'Stephanie Garber'),
        (N'Sui İshida'),
        (N'Sui İşida'),
        (N'Suzune Collins'),
        (N'Takahiro'),
        (N'Tatsuki Fujimoto'),
        (N'Tatsuya Endo'),
        (N'Tsugimi Ohba'),
        (N'Yakup Kadri karaosmanoğlu')
      ) AS k (AdSoyad)
    ON h.AdSoyad = k.AdSoyad
WHEN NOT MATCHED BY TARGET THEN
    INSERT (AdSoyad) VALUES (k.AdSoyad);
GO

/* --- 2) Yayinevleri (35 adet) --- */
MERGE dbo.Yayinevleri AS h
USING (VALUES
        (N'Akıl Çelen Kitaplar'),
        (N'Akılçelen Yayınları'),
        (N'Alfa Yayınları'),
        (N'Altın Kitaplar'),
        (N'April Yayıncılık'),
        (N'April Yayınları'),
        (N'Athica Yayınları'),
        (N'Can Yayınları'),
        (N'Carpe Diem'),
        (N'DEX Yayınları'),
        (N'Dikeyeksen Yayıncılık'),
        (N'Domingo Yayınları'),
        (N'Gerekli Şeyler'),
        (N'İletişim Yayınları'),
        (N'İthaki Yayınları'),
        (N'İş Bankası Yayınları'),
        (N'Kayıp Kıta'),
        (N'Kuru Kafa'),
        (N'Kırmızı Kedi Yayınları'),
        (N'Marmara Çizgi Yayınları'),
        (N'Martı'),
        (N'Metis Yayınları'),
        (N'Nar Çocuk Yayınları'),
        (N'Nobel Akademik Yayıncılık'),
        (N'ODTÜ GELİŞTİRME VAKFI YAYINCILIK'),
        (N'Olympia Yayınları'),
        (N'Panama Yayıncılık'),
        (N'Pegasus Yayınları'),
        (N'Ren Kitap'),
        (N'Sel Yayınları'),
        (N'Sonsuz Kitap'),
        (N'Tudem'),
        (N'Türkiye İş Bankası'),
        (N'YKY'),
        (N'Ötüken Nişriyat')
      ) AS k (Ad)
    ON h.Ad = k.Ad
WHEN NOT MATCHED BY TARGET THEN
    INSERT (Ad) VALUES (k.Ad);
GO

/* --- 3) Turler (16 adet) --- */
MERGE dbo.Turler AS h
USING (VALUES
        (N'Bilim'),
        (N'Bilim Kurgu'),
        (N'Fantastik'),
        (N'Felsefe'),
        (N'İngilize Practice'),
        (N'Kod/Ders'),
        (N'Korku'),
        (N'Kısa Roman'),
        (N'Manga'),
        (N'Masal'),
        (N'Otobiyografik Roman'),
        (N'Polisiye'),
        (N'Psikolojik Kurgu'),
        (N'Roman'),
        (N'Çizgi Roman'),
        (N'Çocuk Romanı')
      ) AS k (Ad)
    ON h.Ad = k.Ad
WHEN NOT MATCHED BY TARGET THEN
    INSERT (Ad) VALUES (k.Ad);
GO

/* --- 4) Satis siteleri (3 adet) --- */
MERGE dbo.SatisSiteleri AS h
USING (VALUES
        (N'Amazon'),
        (N'D&R'),
        (N'Kitap Yurdu')
      ) AS k (Ad)
    ON h.Ad = k.Ad
WHEN NOT MATCHED BY TARGET THEN
    INSERT (Ad) VALUES (k.Ad);
GO

/* --- 5) Kitaplar / SAHIP OLDUKLARIM (64 satir) --- */
INSERT INTO dbo.Kitaplar (SiraNo, Ad, YazarId, YayineviId, TurId, SayfaSayisi, OkunduMu)
SELECT  v.SiraNo,
        v.Ad,
        (SELECT ya.YazarId    FROM dbo.Yazarlar    AS ya WHERE ya.AdSoyad = v.Yazar),
        (SELECT yv.YayineviId FROM dbo.Yayinevleri AS yv WHERE yv.Ad      = v.Yayinevi),
        (SELECT t.TurId       FROM dbo.Turler      AS t  WHERE t.Ad       = v.Tur),
        v.SayfaSayisi,
        v.OkunduMu
FROM (VALUES
        (   1, N'Harry Potter ve Felsefe Taşı', N'J.K. Rowling', N'YKY', N'Fantastik', NULL, 1),
        (   2, N'Harry Potter ve Sırlar Odası', N'J.K. Rowling', N'YKY', N'Fantastik', NULL, 1),
        (   3, N'Harry Potter ve Azkaban Tutsağı', N'J.K. Rowling', N'YKY', N'Fantastik', NULL, 1),
        (   4, N'Harry Potter ve Ateş Kadehi', N'J.K. Rowling', N'YKY', N'Fantastik', NULL, 1),
        (   5, N'Harry Potter ve Zümrüdüanka Yoldaşlığı', N'J.K. Rowling', N'YKY', N'Fantastik', NULL, 1),
        (   6, N'Harry Potter ve Melez Prens', N'J.K. Rowling', N'YKY', N'Fantastik', NULL, 1),
        (   7, N'Harry Potter ve Ölüm Yadigarları', N'J.K. Rowling', N'YKY', N'Fantastik', NULL, 1),
        (   8, N'Çağlar Boyu Quidditch', N'J.K. Rowling', N'YKY', N'Fantastik', NULL, 1),
        (   9, N'Fantastik Canavarlar ve Onları Nerede Bulursun', N'J.K. Rowling', N'YKY', N'Fantastik', NULL, 1),
        (  10, N'Ozan Beedle''ın Hikayeleri', N'J.K. Rowling', N'YKY', N'Fantastik', NULL, 1),
        (  11, N'Harry Potter ve Lanetli Çocuk', N'J.K. Rowling', N'YKY', N'Fantastik', NULL, 1),
        (  12, N'Harry Potter Fantasstik Canavarlar Rehberi (un)', NULL, N'Martı', N'Fantastik', NULL, 1),
        (  13, N'Harry Potter Büyü Kitabı (unofficial)', NULL, N'Martı', N'Fantastik', NULL, 1),
        (  14, N'Death Note Cilt 4', N'Tsugimi Ohba', N'Akılçelen Yayınları', N'Manga', NULL, 1),
        (  15, N'Chainsaw Man Cilt 45', N'Tatsuki Fujimoto', N'Gerekli Şeyler', N'Manga', NULL, 1),
        (  16, N'Tokyo Ghoul Cilt 5', N'Sui İşida', N'Gerekli Şeyler', N'Manga', NULL, 1),
        (  17, N'Tokyo Ghoul Cilt 7', N'Sui İşida', N'Gerekli Şeyler', N'Manga', NULL, 1),
        (  18, N'Kaguya-Sama Cilt 1', N'Aka Akasaka', N'Akılçelen Yayınları', N'Manga', NULL, 1),
        (  19, N'Kaguya-Sama Cilt 2', N'Aka Akasaka', N'Akılçelen Yayınları', N'Manga', NULL, 1),
        (  20, N'Akame Ga Kill Cilt 1', N'Takahiro', N'Athica Yayınları', N'Manga', NULL, 1),
        (  21, N'Akame Ga Kill Cilt 2', N'Takahiro', N'Athica Yayınları', N'Manga', NULL, 1),
        (  22, N'Açlık Oyunları', N'Suzune Collins', N'DEX Yayınları', N'Fantastik', NULL, 1),
        (  23, N'Açlık Oyunları Ateşi Yakalamak', N'Suzune Collins', N'DEX Yayınları', N'Fantastik', NULL, 1),
        (  24, N'Açlık Oyunları Alaycı Kuş', N'Suzune Collins', N'DEX Yayınları', N'Fantastik', NULL, 0),
        (  25, N'Bambaşka Bir Dünya Üçlü İttifak', N'Maxime Chattam', N'DEX Yayınları', N'Fantastik', NULL, 1),
        (  26, N'Bambaşka Bir Dünya Kraliçe', N'Maxime Chattam', N'DEX Yayınları', N'Fantastik', NULL, 1),
        (  27, N'Caraval', N'Stephanie Garber', N'DEX Yayınları', N'Fantastik', NULL, 0),
        (  28, N'The Witcher Son Dilek', N'Andrzej Sapkowski', N'Pegasus Yayınları', N'Fantastik', NULL, 0),
        (  29, N'The Witcher Kader Kılıcı', N'Andrzej Sapkowski', N'Pegasus Yayınları', N'Fantastik', NULL, 0),
        (  30, N'The Witcher Elflerin Kanı', N'Andrzej Sapkowski', N'Pegasus Yayınları', N'Fantastik', NULL, 0),
        (  31, N'The Witcher Nefret Çağı', N'Andrzej Sapkowski', N'Pegasus Yayınları', N'Fantastik', NULL, 0),
        (  32, N'The Witcher Ateşle İmtihan', N'Andrzej Sapkowski', N'Pegasus Yayınları', N'Fantastik', NULL, 0),
        (  33, N'Yaban', N'Yakup Kadri karaosmanoğlu', N'İletişim Yayınları', N'Roman', 215, 1),
        (  34, N'Esir Şehrin İnsanları', N'Kemal Tahir', N'İthaki Yayınları', N'Roman', 448, 0),
        (  35, N'Dönüşüm', N'Franz Kafka', N'Can Yayınları', N'Kısa Roman', 104, 0),
        (  36, N'Animal Farm', N'George Orwell', NULL, N'Kısa Roman', NULL, 0),
        (  37, N'Hayvan Çiftliği', N'George Orwell', N'Can Yayınları', N'Kısa Roman', 152, 0),
        (  38, N'The Land of The Lost Toys', N'Juliana Horitia Ewing', N'Olympia Yayınları', N'İngilize Practice', 56, 0),
        (  39, N'An Imaginatice Woman', N'George William Cortis', N'Olympia Yayınları', N'İngilize Practice', 56, 0),
        (  40, N'Dünyalar Savaşı', N'H.G. Wells', N'İş Bankası Yayınları', N'Bilim Kurgu', 264, 0),
        (  41, N'Zaman Makinesi', N'H.G. Wells', N'İş Bankası Yayınları', N'Bilim Kurgu', 120, 0),
        (  42, N'Olağanüstü Bir Gece', N'Stefan Zweig', N'İş Bankası Yayınları', N'Psikolojik Kurgu', 80, 0),
        (  43, N'Satranç', N'Stefan Zweig', N'İş Bankası Yayınları', N'Psikolojik Kurgu', 64, 0),
        (  44, N'Kendime Düşünceler', N'Marcus Aurelius', N'İş Bankası Yayınları', N'Felsefe', 156, 0),
        (  45, N'Küçük Prens', N'Antoine de Saint Exupery', N'Nar Çocuk Yayınları', N'Masal', 144, 1),
        (  46, N'Şahane Hatalar: Sınav', N'Liz Ruckdeschel & Sara James', N'April Yayınları', N'Roman', 240, 1),
        (  47, N'Dahi Dedektif Ted Harrod', N'Pierre Varrod', N'Carpe Diem', N'Polisiye', 172, 1),
        (  48, N'Bisiklet Yarışçıları', N'Ferda İzbudak Akıncı', N'Tudem', N'Çocuk Romanı', 160, 1),
        (  49, N'Dokuzuncu Hariciye Kovuşu', N'Peyami Safa', N'Ötüken Nişriyat', N'Otobiyografik Roman', 112, 0),
        (  50, N'Bir Kadının Yaşamından Yirmi Dört Saat', N'Stefan Zweig', N'İş Bankası Yayınları', N'Kısa Roman', 80, 0),
        (  51, N'Fareler ve İnsanlar', N'Jhon Steinbeck', N'Sel Yayınları', N'Kısa Roman', 111, 1),
        (  52, N'Sherlock Holmes Suç Detayda Saklıdır', N'Sir Arthur Canon Doyle', N'Martı', N'Polisiye', 336, 1),
        (  53, N'Sherlock Holmes Şüphe Asla Uyumaz', N'Sir Arthur Canon Doyle', N'Martı', N'Polisiye', 416, 0),
        (  54, N'Sherlock Holmes Akıl Oyunlarının Gölgesinde', N'Sir Arthur Canon Doyle', N'Martı', N'Polisiye', 384, 0),
        (  55, N'Sherlock Holmes Gerçekler Kanıt İster', N'Sir Arthur Canon Doyle', N'Martı', N'Polisiye', 320, 0),
        (  56, N'Bir Haftada Üç Pazar', N'Edgar Allen Poe', N'Ren Kitap', N'Polisiye', 272, 0),
        (  57, N'Kızıl Ölümün Maskesi', N'Edgar Allen Poe', N'Ren Kitap', N'Polisiye', 192, 0),
        (  58, N'444 Basamak', N'Mario Mazzanti', N'Sonsuz Kitap', N'Polisiye', 400, 0),
        (  59, N'Gördüğüne Asla İnanma', N'Mario Mazzanti', N'Sonsuz Kitap', N'Polisiye', 448, 0),
        (  60, N'Öldürmek İçin Mükemmel Bir Gün', N'Mario Mazzanti', N'Sonsuz Kitap', N'Polisiye', 360, 0),
        (  61, N'Arduino', N'Coşkun Taşdenmir', N'Dikeyeksen Yayıncılık', N'Kod/Ders', 280, 1),
        (  62, N'Bilgisayar Ağları', N'Resul Kara', N'Nobel Akademik Yayıncılık', N'Kod/Ders', 218, 1),
        (  63, N'Spider-Man Meydan Okuma Electro ve Sandman', N'Kolektif', N'Marmara Çizgi Yayınları', N'Çizgi Roman', 176, 1),
        (  64, N'Justice League', N'Geoff Johns', N'YKY', N'Çizgi Roman', 168, 1)
     ) AS v (SiraNo, Ad, Yazar, Yayinevi, Tur, SayfaSayisi, OkunduMu);
GO

/* --- 6) IstekListesi / ALMAK ISTEDIKLERIM (100 satir) --- */
INSERT INTO dbo.IstekListesi (SiraNo, Ad, YazarId, YayineviId, TurId, SayfaSayisi, SiteId, Fiyat)
SELECT  v.SiraNo,
        v.Ad,
        (SELECT ya.YazarId    FROM dbo.Yazarlar      AS ya WHERE ya.AdSoyad = v.Yazar),
        (SELECT yv.YayineviId FROM dbo.Yayinevleri   AS yv WHERE yv.Ad      = v.Yayinevi),
        (SELECT t.TurId       FROM dbo.Turler        AS t  WHERE t.Ad       = v.Tur),
        v.SayfaSayisi,
        (SELECT s.SiteId      FROM dbo.SatisSiteleri AS s  WHERE s.Ad       = v.Site),
        v.Fiyat
FROM (VALUES
        (   1, N'Chainsaw Man Chapter 1', N'Tatsuki Fujimoto', N'Gerekli Şeyler', N'Manga', 192, N'Kitap Yurdu', 180),
        (   2, N'Chainsaw Man Chapter 2', N'Tatsuki Fujimoto', N'Gerekli Şeyler', N'Manga', 192, N'Kitap Yurdu', 175),
        (   3, N'Chainsaw Man Chapter 3', N'Tatsuki Fujimoto', N'Gerekli Şeyler', N'Manga', 192, N'Amazon', 180),
        (   4, N'Chainsaw Man Chapter 4', N'Tatsuki Fujimoto', N'Gerekli Şeyler', N'Manga', 192, N'Amazon', 181),
        (   5, N'Chainsaw Man Chapter 6', N'Tatsuki Fujimoto', N'Gerekli Şeyler', N'Manga', 192, N'Kitap Yurdu', 175),
        (   6, N'Chainsaw Man Chapter 7', N'Tatsuki Fujimoto', N'Gerekli Şeyler', N'Manga', 192, N'Kitap Yurdu', 175),
        (   7, N'Chainsaw Man Chapter 8', N'Tatsuki Fujimoto', N'Gerekli Şeyler', N'Manga', 192, N'Kitap Yurdu', 175),
        (   8, N'Chainsaw Man Chapter 9', N'Tatsuki Fujimoto', N'Gerekli Şeyler', N'Manga', 192, N'Kitap Yurdu', 175),
        (   9, N'Chainsaw Man Chapter 10', N'Tatsuki Fujimoto', N'Gerekli Şeyler', N'Manga', 192, N'Kitap Yurdu', 175),
        (  10, N'Chainsaw Man Chapter 11', N'Tatsuki Fujimoto', N'Gerekli Şeyler', N'Manga', 192, N'Kitap Yurdu', 180),
        (  11, N'Chainsaw Man Chapter 12', N'Tatsuki Fujimoto', N'Gerekli Şeyler', N'Manga', 192, N'Kitap Yurdu', 180),
        (  12, N'Chainsaw Man Chapter 13', N'Tatsuki Fujimoto', N'Gerekli Şeyler', N'Manga', 192, N'Kitap Yurdu', 180),
        (  13, N'Chainsaw Man Chapter 14', N'Tatsuki Fujimoto', N'Gerekli Şeyler', N'Manga', 192, N'Kitap Yurdu', 195),
        (  14, N'Chainsaw Man Chapter 15', N'Tatsuki Fujimoto', N'Gerekli Şeyler', N'Manga', 192, N'Kitap Yurdu', 195),
        (  15, N'Chainsaw Man Chapter 16', N'Tatsuki Fujimoto', N'Gerekli Şeyler', N'Manga', 192, N'Kitap Yurdu', 195),
        (  16, N'Spy X Family Cilt 1', N'Tatsuya Endo', N'Gerekli Şeyler', N'Manga', 216, N'Amazon', 180),
        (  17, N'Spy X Family Cilt 2', N'Tatsuya Endo', N'Gerekli Şeyler', N'Manga', 196, N'Amazon', 180),
        (  18, N'Spy X Family Cilt 3', N'Tatsuya Endo', N'Gerekli Şeyler', N'Manga', 196, N'Amazon', 180),
        (  19, N'Spy X Family Cilt 4', N'Tatsuya Endo', N'Gerekli Şeyler', N'Manga', 188, N'Amazon', 180),
        (  20, N'Spy X Family Cilt 5', N'Tatsuya Endo', N'Gerekli Şeyler', N'Manga', 204, N'Amazon', 180),
        (  21, N'Spy X Family Cilt 6', N'Tatsuya Endo', N'Gerekli Şeyler', N'Manga', 204, N'Amazon', 180),
        (  22, N'Spy X Family Cilt 7', N'Tatsuya Endo', N'Gerekli Şeyler', N'Manga', 196, N'Amazon', 180),
        (  23, N'Spy X Family Cilt 8', N'Tatsuya Endo', N'Gerekli Şeyler', N'Manga', 214, N'Amazon', 180),
        (  24, N'Spy X Family Cilt 9', N'Tatsuya Endo', N'Gerekli Şeyler', N'Manga', 212, N'Amazon', 180),
        (  25, N'Spy X Family Cilt 10', N'Tatsuya Endo', N'Gerekli Şeyler', N'Manga', 196, N'Amazon', 180),
        (  26, N'Spy X Family Cilt 11', N'Tatsuya Endo', N'Gerekli Şeyler', N'Manga', 212, N'Amazon', 180),
        (  27, N'Spy X Family Cilt 12', N'Tatsuya Endo', N'Gerekli Şeyler', N'Manga', 204, N'Amazon', 180),
        (  28, N'Spy X Family Cilt 13', N'Tatsuya Endo', N'Gerekli Şeyler', N'Manga', 196, N'Amazon', 180),
        (  29, N'Spy X Family Cilt 14', N'Tatsuya Endo', N'Gerekli Şeyler', N'Manga', 200, N'Amazon', 180),
        (  30, N'Kaguya-Sama Cilt 3', N'Aka Akasaka', N'Akıl Çelen Kitaplar', N'Manga', 208, N'Kitap Yurdu', 145),
        (  31, N'Kaguya-Sama Cilt 4', N'Aka Akasaka', N'Akıl Çelen Kitaplar', N'Manga', 208, N'Kitap Yurdu', 165),
        (  32, N'Kaguya-Sama Cilt 5', N'Aka Akasaka', N'Akıl Çelen Kitaplar', N'Manga', 208, N'Kitap Yurdu', 145),
        (  33, N'Kaguya-Sama Cilt 6', N'Aka Akasaka', N'Akıl Çelen Kitaplar', N'Manga', 208, N'Kitap Yurdu', 165),
        (  34, N'Kaguya-Sama Cilt 7', N'Aka Akasaka', N'Akıl Çelen Kitaplar', N'Manga', 208, N'Kitap Yurdu', 165),
        (  35, N'Kaguya-Sama Cilt 8', N'Aka Akasaka', N'Akıl Çelen Kitaplar', N'Manga', 208, N'Kitap Yurdu', 165),
        (  36, N'Zom100 Cilt 1', N'Haro Aso', N'Marmara Çizgi Yayınları', N'Manga', 160, N'Kitap Yurdu', 170),
        (  37, N'Zom100 Cilt 2', N'Haro Aso', N'Marmara Çizgi Yayınları', N'Manga', 160, N'Amazon', 155),
        (  38, N'Zom100 Cilt 3', N'Haro Aso', N'Marmara Çizgi Yayınları', N'Manga', 160, N'Kitap Yurdu', 170),
        (  39, N'Zom100 Cilt 4', N'Haro Aso', N'Marmara Çizgi Yayınları', N'Manga', 160, N'Kitap Yurdu', 170),
        (  40, N'Zom100 Cilt 5', N'Haro Aso', N'Marmara Çizgi Yayınları', N'Manga', 176, N'Kitap Yurdu', 170),
        (  41, N'Zom100 Cilt 6', N'Haro Aso', N'Marmara Çizgi Yayınları', N'Manga', 160, N'Amazon', 155),
        (  42, N'Zom100 Cilt 7', N'Haro Aso', N'Marmara Çizgi Yayınları', N'Manga', 176, N'Amazon', 145),
        (  43, N'Zom100 Cilt 8', N'Haro Aso', N'Marmara Çizgi Yayınları', N'Manga', 160, N'Amazon', 165),
        (  44, N'Zom100 Cilt 9', N'Haro Aso', N'Marmara Çizgi Yayınları', N'Manga', 176, N'Kitap Yurdu', 170),
        (  45, N'Zom100 Cilt 10', N'Haro Aso', N'Marmara Çizgi Yayınları', N'Manga', 160, N'Kitap Yurdu', 170),
        (  46, N'Kaiju no8 Cilt 1', N'Naoya Matsumoto', N'Kuru Kafa', N'Manga', 204, N'Kitap Yurdu', 150),
        (  47, N'Kaiju no8 Cilt 2', N'Naoya Matsumoto', N'Kuru Kafa', N'Manga', 204, N'Kitap Yurdu', 150),
        (  48, N'Kaiju no8 Cilt 3', N'Naoya Matsumoto', N'Kuru Kafa', N'Manga', 184, N'Kitap Yurdu', 160),
        (  49, N'Kaiju no8 Cilt 4', N'Naoya Matsumoto', N'Kuru Kafa', N'Manga', 192, N'Amazon', 155),
        (  50, N'Kaiju no8 Cilt 5', N'Naoya Matsumoto', N'Kuru Kafa', N'Manga', 195, N'Kitap Yurdu', 160),
        (  51, N'Kaiju no8 Cilt 6', N'Naoya Matsumoto', N'Kuru Kafa', N'Manga', 190, N'Amazon', 160),
        (  52, N'Kaiju no8 Cilt 7', N'Naoya Matsumoto', N'Kuru Kafa', N'Manga', 192, N'Amazon', 165),
        (  53, N'Kaiju no8 Cilt 8', N'Naoya Matsumoto', N'Kuru Kafa', N'Manga', 176, N'Kitap Yurdu', 170),
        (  54, N'Your Name', N'Makota Şinai', N'Gerekli Şeyler', N'Manga', 500, N'Amazon', 504),
        (  57, N'Akame Ga Kill Cilt 3', N'Takahiro', N'Athica Yayınları', N'Manga', 232, N'Kitap Yurdu', 155),
        (  58, N'Akame Ga Kill Cilt 4', N'Takahiro', N'Athica Yayınları', N'Manga', 232, N'Kitap Yurdu', 155),
        (  59, N'Akame Ga Kill Cilt 5', N'Takahiro', N'Athica Yayınları', N'Manga', 232, N'Kitap Yurdu', 155),
        (  60, N'Akame Ga Kill Cilt 6', N'Takahiro', N'Athica Yayınları', N'Manga', 232, N'Kitap Yurdu', 155),
        (  61, N'Akame Ga Kill Cilt 7', N'Takahiro', N'Athica Yayınları', N'Manga', 232, N'Kitap Yurdu', 155),
        (  62, N'Akame Ga Kill Cilt 8', N'Takahiro', N'Athica Yayınları', N'Manga', 232, N'Kitap Yurdu', 155),
        (  63, N'Akame Ga Kill Cilt 9', N'Takahiro', N'Athica Yayınları', N'Manga', 232, N'Kitap Yurdu', 155),
        (  64, N'Akame Ga Kill Cilt 10', N'Takahiro', N'Athica Yayınları', N'Manga', 232, N'Kitap Yurdu', 155),
        (  65, N'Akame Ga Kill Cilt 11', N'Takahiro', N'Athica Yayınları', N'Manga', 232, N'Amazon', 155),
        (  66, N'Akame Ga Kill Cilt 12', N'Takahiro', N'Athica Yayınları', N'Manga', 232, N'Amazon', 155),
        (  67, N'Parasite Cilt 1', N'Hitoshi İwaaki', N'Kayıp Kıta', N'Manga', 288, N'Amazon', 210),
        (  68, N'Parasite Cilt 2', N'Hitoshi İwaaki', N'Kayıp Kıta', N'Manga', 288, N'Amazon', 200),
        (  69, N'Parasite Cilt 3', N'Hitoshi İwaaki', N'Kayıp Kıta', N'Manga', 288, N'Amazon', 190),
        (  70, N'Parasite Cilt 4', N'Hitoshi İwaaki', N'Kayıp Kıta', N'Manga', 288, N'Amazon', 210),
        (  71, N'Parasite Cilt 5', N'Hitoshi İwaaki', N'Kayıp Kıta', N'Manga', 288, N'Amazon', 210),
        (  72, N'Parasite Cilt 6', N'Hitoshi İwaaki', N'Kayıp Kıta', N'Manga', 288, N'Amazon', 210),
        (  73, N'Metro Kutulu Set', N'Dmitry Glukhovsky', N'Panama Yayıncılık', N'Fantastik', 1074, N'Kitap Yurdu', 954),
        (  74, N'Labirent Kutulu Set', N'James Dashner', N'Pegasus Yayınları', N'Fantastik', 2152, N'Kitap Yurdu', 1424),
        (  75, N'Kozmos', N'Carl Sagan', N'Altın Kitaplar', N'Bilim', 384, N'Kitap Yurdu', 320),
        (  76, N'Geleceğin Fiziği', N'Michio Kaku', N'ODTÜ GELİŞTİRME VAKFI YAYINCILIK', N'Bilim', 454, N'Amazon', 290),
        (  77, N'Zamanın Kısa Tarihi', N'Stephan Hawking', N'Alfa Yayınları', N'Bilim', 255, N'Amazon', 290),
        (  78, N'Ay''da İlk İnsanlar', N'H.G. Wells', N'Türkiye İş Bankası', N'Bilim', 256, N'D&R', 90),
        (  79, N'Hayvan Mezarlığı', N'Stephan King', N'Altın Kitaplar', N'Korku', 375, N'Kitap Yurdu', 325),
        (  80, N'Sadist', N'Stephan King', N'Altın Kitaplar', N'Korku', 344, N'Kitap Yurdu', 290),
        (  81, N'Doktor Moreau''nun Adası', N'H.G. Wells', N'Türkiye İş Bankası', N'Bilim', 176, N'D&R', 90),
        (  82, N'Görünmez Adam', N'H.G. Wells', N'Türkiye İş Bankası', N'Bilim', 192, N'D&R', 75),
        (  83, N'Ölüm Bir Varmış Bir Yokmuş', N'Jose Saramago', N'Kırmızı Kedi Yayınları', N'Fantastik', 208, N'Kitap Yurdu', 240),
        (  84, N'Görmek', N'Jose Saramago', N'Kırmızı Kedi Yayınları', N'Fantastik', 296, N'Kitap Yurdu', 250),
        (  85, N'Şeker Portakalı', N'Jose Mauro De Vasconselos', N'Can Yayınları', N'Roman', 184, N'Kitap Yurdu', 225),
        (  86, N'Gece Yarısı Kütüphanesi', N'Matt Haig', N'Domingo Yayınları', N'Roman', 283, N'Kitap Yurdu', 220),
        (  87, N'İnci', N'Jhon Stainback', N'İletişim Yayınları', N'Roman', 92, N'D&R', 165),
        (  88, N'Tokyo Ghoul Cilt 1', N'Sui İshida', N'Gerekli Şeyler', N'Manga', 224, N'Amazon', 180),
        (  89, N'Tokyo Ghoul Cilt 2', N'Sui İshida', N'Gerekli Şeyler', N'Manga', 208, N'Amazon', 180),
        (  90, N'Tokyo Ghoul Cilt 3', N'Sui İshida', N'Gerekli Şeyler', N'Manga', NULL, N'Amazon', NULL),
        (  91, N'Tokyo Ghoul Cilt 4', N'Sui İshida', N'Gerekli Şeyler', N'Manga', 196, N'Amazon', 180),
        (  92, N'Tokyo Ghoul Cilt 6', N'Sui İshida', N'Gerekli Şeyler', N'Manga', 204, N'Amazon', 180),
        (  93, N'Tokyo Ghoul Cilt 8', N'Sui İshida', N'Gerekli Şeyler', N'Manga', 216, N'Amazon', 180),
        (  94, N'Tokyo Ghoul Cilt 9', N'Sui İshida', N'Gerekli Şeyler', N'Manga', 204, N'Amazon', 180),
        (  95, N'Sis Soylu Son İmparatorluk', N'Brandon Sanderson', N'Akıl Çelen Kitaplar', N'Fantastik', 668, N'Kitap Yurdu', 446),
        (  96, N'Sis Soylu Kuşatma', N'Brandon Sanderson', N'Akıl Çelen Kitaplar', N'Fantastik', 773, N'Kitap Yurdu', 480),
        (  97, N'Sis Soylu Çağların Savaşı', N'Brandon Sanderson', N'Akıl Çelen Kitaplar', N'Fantastik', 592, N'Amazon', 495),
        (  98, N'Şahane Hatalar: Talih Kuşu', N'Heather McELHATTON', N'April Yayıncılık', N'Roman', 592, N'Amazon', 500),
        (  99, N'O', N'Stephan King', N'Altın Kitaplar', N'Korku', 1064, N'Kitap Yurdu', 1030),
        ( 100, N'Yüzüklerin Efendisi Yüzük Kardeşliği', N'J.R.R Tolkien', N'Metis Yayınları', N'Roman', 520, N'Kitap Yurdu', 510),
        ( 101, N'Yüzüklerin Efendisi İki Kule', N'J.R.R Tolkien', N'Metis Yayınları', N'Roman', 4332, N'Kitap Yurdu', 435),
        ( 102, N'Yüzüklerin Efendisi Kralın Dönüşlü', N'J.R.R Tolkien', N'Metis Yayınları', N'Roman', 428, N'Kitap Yurdu', 475)
     ) AS v (SiraNo, Ad, Yazar, Yayinevi, Tur, SayfaSayisi, Site, Fiyat);
GO

COMMIT TRANSACTION;
GO

/* --- Aktarim ozeti --- */
SELECT 'Kitaplar' AS Tablo, COUNT(*) AS Satir FROM dbo.Kitaplar
UNION ALL SELECT 'IstekListesi', COUNT(*) FROM dbo.IstekListesi
UNION ALL SELECT 'Yazarlar',     COUNT(*) FROM dbo.Yazarlar
UNION ALL SELECT 'Yayinevleri',  COUNT(*) FROM dbo.Yayinevleri
UNION ALL SELECT 'Turler',       COUNT(*) FROM dbo.Turler
UNION ALL SELECT 'SatisSiteleri',COUNT(*) FROM dbo.SatisSiteleri;
GO
