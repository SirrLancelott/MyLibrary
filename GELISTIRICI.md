# Geliştirici notları

Kullanım rehberi için [README.md](README.md). Bu dosya kodu derleyecek,
paketleyecek veya değiştirecek kişiler içindir.

Kişisel kitap koleksiyonunu ve istek listesini yöneten **Flutter masaüstü (Windows)**
uygulaması. Veri, uygulamanın içine gömülü **SQLite** ile tek bir dosyada tutulur.

```
BenimKutuphanem.exe  ──►  %LOCALAPPDATA%\BenimKutuphanem\kutuphane.db
     (Flutter)                        (SQLite, tek dosya)
```

Sunucu süreci yok, veritabanı kurulumu yok, harici bağımlılık yok.

> **Mimari notu.** Proje önce SQL Server Express + yerel bir .NET REST API ile
> yazılmıştı. API'nin varlık sebebi, Dart'taki ODBC paketinin (`dart_odbc`) MSSQL
> sürücüsüyle **metin parametrelerini bağlayamamasıydı** (`HY104 Invalid precision
> value`) — bu da SQL injection'a kapalı bir giriş sorgusu yazmayı imkânsız
> kılıyordu. SQLite'a geçince bu kısıt ortadan kalktı: Dart parametreleri sorunsuz
> bağlıyor, dolayısıyla araya sunucu koymak gereksizleşti ve API katmanı kaldırıldı.
> Eski yığın git geçmişinde duruyor.

---

## 1. Gereksinimler

| Bileşen | Sürüm | Not |
|---|---|---|
| Flutter SDK | 3.44+ | Windows masaüstü desteği açık |
| Visual Studio | 2022/2026 | "Desktop development with C++" iş yükü |
| Python | 3.10+ | İkon üretimi, veri anlık görüntüsü, eski veri taşıma |

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

### 2.3 Dağıtım paketi (boş veritabanı)

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
  BenimKutuphanem.zip       <- dağıtılacak dosya (~13 MB)
```

Betik, paketin eksiksiz olduğunu doğrular ve pakete **hiçbir `.db` dosyası
girmediğini** kontrol eder; dağıtılan kopya boş bir kütüphaneyle başlar,
kişisel kitap listesi gönderilmez.

Bu ZIP, GitHub'da bir **Release**'e ek olarak yüklenir; README'deki indirme
bağlantısı `releases/latest/download/BenimKutuphanem.zip` adresini gösterir,
yani her yeni sürümde bağlantı kendiliğinden güncel kalır.

### 2.4 Kişisel paket (dolu veritabanı)

```bat
paketle_kisisel.bat
```

Aynı uygulamayı, **bu bilgisayardaki gerçek kitap listesiyle** birlikte
`dagitim_kisisel/` altına paketler. Kendi ikinci bilgisayarınıza kurmak içindir,
dağıtılmaz.

Veritabanı kopyası `tools/veri_anlik_goruntu.py` ile alınır: uygulama WAL kipinde
çalıştığı için `kutuphane.db` dosyasını elle kopyalamak yetmez, son yazılanlar
`-wal` dosyasında durur. Betik `VACUUM INTO` ile tek parça, WAL'siz, tutarlı bir
kopya üretir; kaynağı salt okunur açar.

Paketin içindeki `kur.bat` hedef bilgisayarda bir kez çalıştırılır: veritabanını
`%LOCALAPPDATA%` altına yerleştirir, orada zaten bir kütüphane varsa önce sorar
ve eskisini `yedek-<tarih-saat>` klasörüne taşır.

**Varsayılan giriş:** `admin / 1234` — ilk girişten sonra **Şifre** sekmesinden
değiştirilmelidir. Bu ipucu giriş ekranında yalnızca debug derlemesinde görünür.

### 2.5 Uygulama kimliği

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

## 3. Dil desteği

Arayüz Türkçe ve İngilizce. Tüm metinler tek dosyada:
[`app/lib/yerellestirme/ceviri.dart`](app/lib/yerellestirme/ceviri.dart)

İki dil yan yana durur (`_i ? 'English' : 'Türkçe'`), böylece yeni bir metin
eklenirken ikisini birden yazmak zorunludur ve çeviri atlanamaz.

- Dil, `MaterialApp`'in üstündeki `DilKapsami` (InheritedWidget) ile taşınır;
  `Navigator`'ın ittiği sayfalar ve `showDialog` pencereleri de altında kaldığı
  için dil değişince hepsi birden yenilenir.
- `Ceviri.of(context)` kapsam bulamazsa Türkçe'ye düşer — tek bir widget'ı
  saran testler `DilKapsami` eklemek zorunda kalmaz.
- Para, sayı ve tarih biçimleri dile bağlıdır (`1.234,50` ↔ `1,234.50`).
  Tutarlar her iki dilde de **₺** kalır; veri Türkiye'den, kur çevirisi yapılmaz.
- Servis katmanının `BuildContext`'i yoktur. Hatalar `HataKodu` ile fırlatılır,
  metni arayüz seçer. Ekranlar hata *metnini* değil `KutuphaneHatasi` nesnesinin
  kendisini saklar; böylece hata ekrandayken dil değişirse mesaj da çevrilir.

Veritabanı içeriği (kitap adı, yazar, tür, yayınevi, site) çevrilmez —
kullanıcının kendi verisidir.

---

## 4. Veriler nerede

```
%LOCALAPPDATA%\BenimKutuphanem\kutuphane.db
```

Exe'nin yanında **değil**, kullanıcının veri klasöründe tutulur: Program Files
altına yazma izni yoktur ve uygulama güncellenince veri yerinde kalmalıdır.

WAL kipi açıktır, bu yüzden yanında `-wal` ve `-shm` dosyaları görülebilir.

---

## 5. Veritabanı şeması

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

## 6. Klasör yapısı

```
MyLibrary/
├── app/
│   ├── lib/
│   │   ├── main.dart                  Uygulama girişi, tema ve dil kipi
│   │   ├── tema.dart                  Renk ve tipografi
│   │   ├── modeller/                  Veri modelleri
│   │   ├── veritabani/
│   │   │   ├── sema.dart              SQLite şeması (tek kaynak)
│   │   │   └── veritabani.dart        Dosya yolu, açılış, kucuk() işlevi
│   │   ├── guvenlik/sifre_servisi.dart       PBKDF2-HMAC-SHA256
│   │   ├── servisler/kutuphane_servisi.dart  Tüm sorgular, HataKodu
│   │   ├── yerellestirme/ceviri.dart  Türkçe + İngilizce metinler
│   │   ├── ekranlar/                  Giriş, ana ekran, dört sekme
│   │   └── widgetlar/                 Diyaloglar ve ortak parçalar
│   └── test/                          50 test
├── tools/
│   ├── ikon_olustur.py                Uygulama ikonunu üretir
│   ├── veri_anlik_goruntu.py          Veritabanının tutarlı kopyasını alır
│   └── mssql_to_sqlite.py             Eski SQL Server verisini taşır
├── dagitim_sablonu/
│   ├── OKUBENI.txt                    Pakete kopyalanan kullanıcı rehberi
│   ├── KISISEL-KURULUM.txt            Kişisel paketin rehberi
│   └── kur.bat                        Kişisel pakette veritabanını yerleştirir
├── derle.bat                          Sürüm derlemesi
├── paketle.bat                        Dağıtım paketi + ZIP (boş veritabanı)
└── paketle_kisisel.bat                Kişisel paket + ZIP (dolu veritabanı)
```

`dagitim/` ve `dagitim_kisisel/` klasörleri betikler tarafından üretilir ve
sürüm denetimine girmez.

---

## 7. Testler

```bash
cd app && flutter test
```

50 test:

| Dosya | Kapsam |
|---|---|
| `sifre_servisi_test.dart` | PBKDF2 — .NET'in ürettiği gerçek hash'lerle uyumluluk |
| `kutuphane_servisi_test.dart` | Veri katmanının tamamı, bellek içi SQLite üzerinde |
| `istekler_sekmesi_test.dart` | İstek sekmesi: liste, gruplama, tür filtresi, toplam tutar |
| `widget_test.dart` | Giriş akışı: doğrulama, hatalı şifre, başarılı giriş |
| `dil_test.dart` | Dil değişimi, servis hatalarının çevrilmesi, sayı/para/tarih biçimleri |

Testler bellek içi veritabanı kullanır; diskteki gerçek veriye dokunmaz.

---

## 8. SQL Server sürümünden geçiş

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
