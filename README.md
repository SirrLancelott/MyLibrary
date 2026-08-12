# Benim Kütüphanem — Kütüphane Otomasyon Sistemi

Kişisel kitap koleksiyonunu ve istek listesini yöneten **Flutter masaüstü (Windows)**
uygulaması. Veri, uygulamanın içine gömülü **SQLite** ile tek bir dosyada tutulur.

```
BenimKutuphanem.exe  ──►  %LOCALAPPDATA%\BenimKutuphanem\kutuphane.db
     (Flutter)                        (SQLite, tek dosya)
```

Sunucu süreci yok, veritabanı kurulumu yok, harici bağımlılık yok.
Kullanıcı ZIP'i açıp exe'ye çift tıklar.

> **Mimari notu.** Proje önce SQL Server Express + yerel bir .NET REST API ile
> yazılmıştı. API'nin varlık sebebi, Dart'taki ODBC paketinin (`dart_odbc`) MSSQL
> sürücüsüyle **metin parametrelerini bağlayamamasıydı** (`HY104 Invalid precision
> value`) — bu da SQL injection'a kapalı bir giriş sorgusu yazmayı imkânsız
> kılıyordu. SQLite'a geçince bu kısıt ortadan kalktı: Dart parametreleri sorunsuz
> bağlıyor, dolayısıyla araya sunucu koymak gereksizleşti ve API katmanı kaldırıldı.
> Eski yığın git geçmişinde duruyor.

---

## 1. Gereksinimler

**Uygulamayı kullanmak için:** hiçbir şey. (Windows 10/11 x64 ve Visual C++
Redistributable — çoğu makinede zaten kurulu.)

**Geliştirmek için:**

| Bileşen | Sürüm | Not |
|---|---|---|
| Flutter SDK | 3.44+ | Windows masaüstü desteği açık |
| Visual Studio | 2022/2026 | "Desktop development with C++" iş yükü |
| Python | 3.10+ | Yalnızca ikon üretimi / eski veri taşıma için |

---

## 2. Çalıştırma ve derleme

### 2.1 Geliştirirken

```bash
cd app && flutter run -d windows
```

Hot reload açıktır; `r` ile anında yenilenir.

### 2.2 Sürüm derlemesi

```bat
derle.bat
```

Çıktı: `app\build\windows\x64\runner\Release\BenimKutuphanem.exe`

### 2.3 Dağıtım paketi

```bat
paketle.bat
```

Üretilenler:

```
dagitim/
  BenimKutuphanem/          <- klasör
    BenimKutuphanem.exe
    flutter_windows.dll
    sqlite3.dll
    data/
    OKUBENI.txt             son kullanıcı rehberi
  BenimKutuphanem.zip       <- gönderilecek dosya (~13 MB)
```

Betik, paketin eksiksiz olduğunu doğrular ve pakete **hiçbir `.db` dosyası
girmediğini** kontrol eder; dağıtılan kopya boş bir kütüphaneyle başlar,
kişisel kitap listesi gönderilmez.

**Varsayılan giriş:** `admin / 1234` — ilk girişten sonra **Şifre** sekmesinden
değiştirilmelidir. Bu ipucu giriş ekranında yalnızca debug derlemesinde görünür.

### 2.4 Uygulama kimliği

| | Değer |
|---|---|
| Çalıştırılabilir dosya | `BenimKutuphanem.exe` |
| Pencere başlığı | Benim Kütüphanem |
| İkon | Mavi degrade zeminde açık kitap |

İkon, giriş ekranındaki logoyla aynı Material simgesinden (`menu_book_rounded`)
üretilir:

```bash
python tools/ikon_olustur.py
```

16'dan 256 piksele yedi boyut tek `.ico` içine gömülür. İkon değiştikten sonra
`flutter clean` gerekir; aksi hâlde Windows eski ikonu önbellekten gösterir.

---

## 3. Veriler nerede

```
%LOCALAPPDATA%\BenimKutuphanem\kutuphane.db
```

Exe'nin yanında **değil**, kullanıcının veri klasöründe tutulur: Program Files
altına yazma izni yoktur ve uygulama güncellenince veri yerinde kalmalıdır.

- **Yedek:** `kutuphane.db` dosyasını kopyalayın.
- **Geri yükleme:** uygulama kapalıyken dosyayı geri koyun.
- Uygulama silinse de bu dosya silinmez.

WAL kipi açıktır, bu yüzden yanında `-wal` ve `-shm` dosyaları görülebilir;
yedek alırken uygulamanın kapalı olması yeterlidir.

---

## 4. Veritabanı şeması

Tanım tek yerde: [`app/lib/veritabani/sema.dart`](app/lib/veritabani/sema.dart)

```
Kullanicilar                       Yazarlar ──┐
  KullaniciId (PK)                 Yayinevleri├──► Kitaplar (sahip olduklarım)
  KullaniciAdi (UNIQUE)            Turler   ──┤       SiraNo, Ad, SayfaSayisi, OkunduMu
  SifreHash  (PBKDF2)                         │
  AdSoyad, Aktif                   SatisSiteleri──► IstekListesi (almak istediklerim)
  OlusturmaTarihi                                     SiraNo, Ad, SayfaSayisi,
  SonGirisTarihi                                      FiyatKurus, SatinAlindi
  SifreDegistirmeTarihi
```

Okuma için view'lar: `vw_Kitaplar`, `vw_IstekListesi`, `vw_Ozet`.
Uygulama tabloları doğrudan okumaz, bu view'ları kullanır.

### Fiyat neden kuruş

SQLite'ta ondalık sayı tipi yoktur; `REAL` kullanmak ikili gösterim nedeniyle
yuvarlama hatası biriktirir. Tutarlar `FiyatKurus` sütununda **tam sayı kuruş**
olarak saklanır (249.90 TL → 24990), arayüze çıkarken 100'e bölünür. Böylece
T-SQL sürümündeki `DECIMAL(10,2)` hassasiyeti korunur.

### Türkçe arama

SQLite'ın yerleşik `lower()` işlevi yalnızca ASCII harfleri küçültür; "İSTANBUL"
aramada eşleşmezdi. Dart'ın Unicode farkındalığını SQL'e taşıyan bir `kucuk()`
işlevi tanımlanır ([`veritabani.dart`](app/lib/veritabani/veritabani.dart)) ve
arama sorgularında hem sütuna hem terime uygulanır.

### Şifre saklama

Düz şifre hiçbir yerde tutulmaz. Biçim:

```
PBKDF2-SHA256$100000$<base64 salt>$<base64 hash>
```

Her kullanıcının kendine ait rastgele salt'ı vardır; doğrulama sabit zamanlı
karşılaştırma ile yapılır ([`sifre_servisi.dart`](app/lib/guvenlik/sifre_servisi.dart)).

Biçim, .NET sürümündekiyle **birebir aynıdır** — SQL Server döneminde üretilmiş
hash'ler bu sürümde de doğrulanır, yani mevcut şifreler geçişten sonra çalışmaya
devam eder. Bu, `test/sifre_servisi_test.dart` içinde gerçek hash'lerle test edilir.

---

## 5. Klasör yapısı

```
MyLibrary/
├── app/
│   ├── lib/
│   │   ├── main.dart                  Uygulama girişi, tema kipi
│   │   ├── tema.dart                  Renk ve tipografi
│   │   ├── modeller/                  Veri modelleri
│   │   ├── veritabani/
│   │   │   ├── sema.dart              SQLite şeması (tek kaynak)
│   │   │   └── veritabani.dart        Dosya yolu, açılış, kucuk() işlevi
│   │   ├── guvenlik/sifre_servisi.dart  PBKDF2-HMAC-SHA256
│   │   ├── servisler/kutuphane_servisi.dart  Tüm sorgular
│   │   ├── ekranlar/                  Giriş, ana ekran, dört sekme
│   │   └── widgetlar/                 Diyaloglar ve ortak parçalar
│   └── test/                          43 test
├── tools/
│   ├── ikon_olustur.py                Uygulama ikonunu üretir
│   └── mssql_to_sqlite.py             Eski SQL Server verisini taşır
├── dagitim_sablonu/OKUBENI.txt        Pakete kopyalanan kullanıcı rehberi
├── derle.bat                          Sürüm derlemesi
└── paketle.bat                        Dağıtım paketi + ZIP
```

`dagitim/` klasörü `paketle.bat` tarafından üretilir ve sürüm denetimine girmez.

---

## 6. Testler

```bash
cd app && flutter test
```

43 test, üç katmanda:

| Dosya | Kapsam |
|---|---|
| `sifre_servisi_test.dart` | PBKDF2 — .NET'in ürettiği gerçek hash'lerle uyumluluk |
| `kutuphane_servisi_test.dart` | Veri katmanının tamamı, bellek içi SQLite üzerinde |
| `istekler_sekmesi_test.dart` | İstek sekmesi: liste, gruplama, tür filtresi, toplam tutar |
| `widget_test.dart` | Giriş akışı: doğrulama, hatalı şifre, başarılı giriş |

Testler bellek içi veritabanı kullanır; diskteki gerçek veriye dokunmaz.

---

## 7. SQL Server sürümünden geçiş

Eski kurulumdaki veriyi taşımak için (SQL Server hâlâ kuruluysa):

```bash
python tools/mssql_to_sqlite.py --kuru
```

`--kuru` yalnızca sayıları raporlar. Gerçek taşıma:

```bash
python tools/mssql_to_sqlite.py
```

Kullanıcılar (şifre hash'leri dahil), referans tabloları, kitaplar ve istek
listesi taşınır; `Fiyat` alanı kuruşa çevrilir. Betik şemayı gerekirse kendisi
kurar ve şema tanımını `sema.dart` dosyasından okur, böylece kopya şema tutulmaz.

---

## 8. Sık karşılaşılan sorunlar

**Uygulama açılmıyor** — Visual C++ Redistributable (x64) eksik olabilir.

**"Veritabanı açılamadı" ekranı** — Ekranda yazan klasöre yazma izni yok veya
disk dolu. Hata metni ekranda görünür.

**Windows "bilinmeyen yayımcı" uyarısı** — Uygulama dijital olarak imzalanmadığı
için normaldir. Kod imzalama sertifikası alınırsa kaybolur.

**Şifre unutuldu** — Veritabanı dosyası silinirse uygulama sıfırdan başlar
(`admin / 1234`), ancak kitaplar da gider. Önce dosyanın kopyasını alın.
