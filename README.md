# Benim Kütüphanem — Kütüphane Otomasyon Sistemi

`BenimKutuphanem_Renkli.xlsx` dosyasındaki kişisel kitap listesini MSSQL'e taşıyan,
üzerine kullanıcı girişli bir **Flutter masaüstü (Windows)** uygulaması koyan proje.

```
Flutter (Windows)  ──HTTP/JSON──►  KutuphaneApi (.NET 10)  ──SqlClient──►  SQL Server Express
   app/                              backend/KutuphaneApi/                    BenimKutuphanem
```

Flutter'dan SQL Server'a doğrudan bağlanılmıyor; arada küçük bir yerel REST API var.
Sebebi: Dart tarafındaki ODBC paketi (`dart_odbc`) MSSQL sürücüsüyle **metin
parametrelerini bağlayamıyor** (`HY104 Invalid precision value`), bu da parametreli —
yani SQL injection'a kapalı — bir giriş sorgusu yazmayı imkânsız kılıyor. API katmanı
`Microsoft.Data.SqlClient` ile bunu doğru şekilde yapıyor. API yalnızca `127.0.0.1`
üzerinde dinler, dışarıya açık değildir.

---

## 1. Gereksinimler

| Bileşen | Sürüm | Not |
|---|---|---|
| SQL Server Express | 2019+ | `.\SQLEXPRESS`, Windows kimlik doğrulaması |
| sqlcmd | 17+ | SQL Server Client SDK ile gelir |
| .NET SDK | 10.0 | API için |
| Flutter | 3.44+ | Windows masaüstü desteği açık |
| Visual Studio | 2022/2026 | "Desktop development with C++" iş yükü |
| Python + openpyxl | 3.10+ | Yalnızca Excel'i yeniden aktarmak isterseniz |

---

## 2. Kurulum (sırayla)

### 2.1 Veritabanı

```bat
sql\00_veritabani_kur.bat
```

Bu betik sırasıyla şunları yapar:

1. `BenimKutuphanem` veritabanı yoksa oluşturur.
2. `sql/01_sema.sql` — tabloları, view'ları, indeksleri ve başlangıç kullanıcılarını kurar.
3. `sql/02_veri.sql` — Excel'deki 164 satırı aktarır.
4. `dbo.vw_Ozet` ile sonucu gösterir.

Elle çalıştırmak isterseniz:

```bash
sqlcmd -S .\SQLEXPRESS -E -d BenimKutuphanem -i sql\01_sema.sql
```

```bash
sqlcmd -S .\SQLEXPRESS -E -d BenimKutuphanem -f 65001 -i sql\02_veri.sql
```

> `-f 65001` şart: `02_veri.sql` UTF-8'dir, bu olmadan Türkçe karakterler bozulur.

### 2.2 Derleme

```bat
derle.bat
```

API'yi `backend\yayin\` klasörüne, masaüstü uygulamasını
`app\build\windows\x64\runner\Release\BenimKutuphanem.exe` olarak derler.

### 2.3 Çalıştırma

```bat
baslat.bat
```

Önce API'yi başlatır, hazır olmasını bekler, sonra uygulamayı açar.

**Varsayılan kullanıcılar:** `admin / 1234` ve `emir / 1234`
İlk girişten sonra uygulamadaki **Şifre** sekmesinden değiştirin.

### 2.4 Uygulama kimliği

| | Değer |
|---|---|
| Çalıştırılabilir dosya | `BenimKutuphanem.exe` |
| Pencere başlığı | Benim Kütüphanem |
| Ürün adı / açıklama | Benim Kütüphanem — Kütüphane Otomasyon Sistemi |
| İkon | Mavi degrade zeminde açık kitap, `app/windows/runner/resources/app_icon.ico` |

İkon, uygulamanın giriş ekranındaki logoyla aynı Material simgesinden
(`menu_book_rounded`) üretiliyor; böylece pencere başlığı, görev çubuğu ve
uygulama içindeki logo birbiriyle tutarlı oluyor. Yeniden üretmek için:

```bash
python tools/ikon_olustur.py
```

Betik 16'dan 256 piksele kadar yedi boyutu tek `.ico` dosyasına gömüyor ve
`tools/ikon_onizleme.png` dosyasına bir kontrol görüntüsü yazıyor. 32 piksel ve
altındaki boyutlarda simge, küçükken okunabilir kalması için daha dolgun
çiziliyor. İkon veya isim değiştirildikten sonra `flutter clean` yapıp yeniden
derlemek gerekir; aksi hâlde Windows eski ikonu önbellekten göstermeye devam
eder.

---

## 3. Veritabanı şeması

Excel'deki iki blok (`SAHİP OLDUKLARIM` ve `ALMAK İSTEDİKLERİM`) iki ana tabloya,
tekrar eden metin sütunları da ortak referans tablolarına ayrıldı.

```
Kullanicilar                       Yazarlar ──┐
  KullaniciId (PK)                 Yayinevleri├──► Kitaplar (sahip olduklarım)
  KullaniciAdi (UNIQUE)            Turler   ──┤       SiraNo, Ad, SayfaSayisi, OkunduMu
  SifreHash  (PBKDF2)                         │
  AdSoyad, Aktif                   SatisSiteleri──► IstekListesi (almak istediklerim)
  OlusturmaTarihi                                     SiraNo, Ad, SayfaSayisi,
  SonGirisTarihi                                      Fiyat, SatinAlindi
  SifreDegistirmeTarihi
```

Okuma için hazır view'lar: `vw_Kitaplar`, `vw_IstekListesi`, `vw_Ozet`.
Uygulama tabloları doğrudan okumaz, bu view'ları kullanır.

### Şifre saklama

`SifreHash` sütununda düz şifre **tutulmaz**. Biçim:

```
PBKDF2-SHA256$100000$<base64 salt>$<base64 hash>
```

Her kullanıcının kendine ait rastgele salt'ı vardır; doğrulama sabit zamanlı
karşılaştırma ile yapılır (`backend/KutuphaneApi/Guvenlik/SifreServisi.cs`).

---

## 4. Excel aktarımı

| | Excel | SQL |
|---|---|---|
| Sahip olduklarım | 64 satır | `Kitaplar` — 64 |
| Almak istediklerim | 102 satır | `IstekListesi` — 100 |
| Yazar / Yayınevi / Tür / Site | metin sütunu | 51 / 35 / 16 / 3 referans satırı |

Aktarım sırasında yapılanlar:

- Tüm metinlerin başındaki/sonundaki boşluklar kırpıldı
  (`"Kitap Yurdu "` → `"Kitap Yurdu"`, `"İletişim Yayınları "` → `"İletişim Yayınları"`).
- `Okunma Durumu` sütunu bit'e çevrildi: `Okundu`/`OKUNDU` → `1`, `Okunmadı` → `0`.
- Excel'deki `Numara` sütunu `SiraNo` olarak birebir korundu.
- **İstek listesindeki 55 ve 56 numaralı satırlar aktarılmadı**: bu satırlarda
  yalnızca numara var, kitap adı dâhil tüm alanlar boş. Diğer satırların
  numaraları değiştirilmedi, yani `SiraNo` 54'ten 57'ye atlar.
- Boş bırakılmış alanlar (yazar, sayfa sayısı, fiyat) `NULL` olarak aktarıldı.

Excel değişirse yeniden üretmek için:

```bash
python tools/excel_to_sql.py
```

Aktarımın Excel ile birebir aynı olduğunu satır satır doğrulamak için:

```bash
python tools/dogrula.py
```

---

## 5. API uçları

Tümü `http://127.0.0.1:5199` altında. `/api/giris` dışındaki her uç
`Authorization: Bearer <token>` başlığı ister.

| Yöntem | Uç | Açıklama |
|---|---|---|
| GET | `/api/durum` | API ayakta mı |
| POST | `/api/giris` | `{kullaniciAdi, sifre}` → token |
| POST | `/api/cikis` | Oturumu kapatır |
| POST | `/api/sifre-degistir` | `{mevcutSifre, yeniSifre}` |
| GET | `/api/ozet` | Ana ekran sayıları |
| GET | `/api/referanslar` | Yazar / yayınevi / tür / site listeleri |
| GET | `/api/kitaplar` | `?arama=&tur=&okundu=` |
| POST / PUT / DELETE | `/api/kitaplar[/{id}]` | Kitap ekle / güncelle / sil |
| GET | `/api/istekler` | `?arama=&tur=&site=&satinAlindi=` |
| POST / PUT / DELETE | `/api/istekler[/{id}]` | İstek ekle / güncelle / sil |
| POST | `/api/istekler/{id}/kitapliga-tasi` | İsteği `Kitaplar`'a taşır |

Ekleme/güncellemede yazar, yayınevi, tür ve site **ad olarak** gönderilir; API
referans tablosunda arar, yoksa oluşturur. Böylece arayüzde serbest metin
yazılabiliyor.

---

## 6. Klasör yapısı

```
MyLibrary/
├── sql/
│   ├── 00_veritabani_kur.bat   Tek tıkla kurulum
│   ├── 01_sema.sql             Tablolar, view'lar, başlangıç kullanıcıları
│   └── 02_veri.sql             Excel verisi (otomatik üretilir)
├── tools/
│   ├── excel_to_sql.py         Excel → 02_veri.sql
│   └── dogrula.py              Excel ↔ SQL karşılaştırması
├── backend/KutuphaneApi/
│   ├── Program.cs              Uç noktalar
│   ├── Veri/KutuphaneDeposu.cs Parametreli SQL sorguları
│   ├── Guvenlik/               PBKDF2 + oturum yönetimi
│   └── Modeller/
├── app/lib/
│   ├── main.dart
│   ├── modeller/               JSON karşılıkları
│   ├── servisler/api_servisi.dart
│   ├── ekranlar/               Giriş, ana ekran, sekmeler
│   └── widgetlar/              Diyaloglar ve ortak parçalar
├── derle.bat
└── baslat.bat
```

---

## 7. Sık karşılaşılan sorunlar

**"Sunucuya ulaşılamadı"** — API çalışmıyor. `baslat.bat` kullanın veya
`backend\yayin\KutuphaneApi.exe` dosyasını elle çalıştırıp hata mesajına bakın.

**"Veritabanına erişilemedi"** — `MSSQL$SQLEXPRESS` servisi durmuş olabilir:

```bash
powershell -Command "Get-Service MSSQL`$SQLEXPRESS"
```

**Şifreyi unuttum** — SSMS'ten `dbo.Kullanicilar` tablosundaki `SifreHash` alanına
`1234` şifresinin hash'ini yazın:

```sql
UPDATE dbo.Kullanicilar
SET    SifreHash = N'PBKDF2-SHA256$100000$ag7l3wLCVUH2vIEBkBKOaw==$LcOhbxSQQQorEC/CJ2y5+O6z/8/s9mttel3OfPW/2W4='
WHERE  KullaniciAdi = N'admin';
```

**Türkçe karakterler bozuk görünüyor** — `02_veri.sql` dosyasını `sqlcmd`'ye
`-f 65001` parametresi olmadan verdiniz. Betiği `-f 65001` ile tekrar çalıştırın.
