# Benim Kütüphanem

Sahip olduğunuz kitapları ve almak istediklerinizi tek yerde tutan, Windows için
küçük bir masaüstü uygulaması. Kurulum gerektirmez, internet bağlantısı istemez;
verileriniz yalnızca kendi bilgisayarınızda kalır.

---

## İndirin

**[BenimKutuphanem.zip — buradan indirebilirsiniz](https://github.com/SirrLancelott/MyLibrary/releases/latest/download/BenimKutuphanem.zip)**

Windows 10 / 11 (64-bit) · ~13 MB · kurulum yok

Tüm sürümler: [Releases sayfası](https://github.com/SirrLancelott/MyLibrary/releases)

---

## Kurulum

1. ZIP dosyasını bir klasöre **tamamen çıkarın**
   (ZIP'in içinden çift tıklayarak çalıştırmayın).
2. `BenimKutuphanem.exe` dosyasına çift tıklayın.
3. Hepsi bu. Kurulum sihirbazı, sunucu penceresi, veritabanı kurulumu yok.

Windows "bilinmeyen yayımcı" uyarısı verirse **Daha fazla bilgi → Yine de çalıştır**
deyin. Uygulama dijital olarak imzalanmadığı için normaldir.

---

## İlk giriş

```
Kullanıcı adı:  admin
Şifre:          1234
```

> Girdikten sonra **Şifre** sekmesinden şifrenizi değiştirin.

Uygulama ilk açıldığında kütüphane boştur. **Kitaplarım** sekmesindeki
*Kitap ekle* düğmesiyle kendi kitaplarınızı girmeye başlayabilirsiniz.

---

## Ne yapabilirsiniz

| Sekme | |
|---|---|
| **Özet** | Kaç kitabınız var, kaçını okudunuz, toplam kaç sayfa, istek listenizin tahmini maliyeti |
| **Kitaplarım** | Sahip olduğunuz kitaplar — arama, türe ve okundu durumuna göre filtreleme, ekleme, düzenleme, silme |
| **İstek Listem** | Almak istedikleriniz; fiyat ve satış sitesiyle. Türe göre gruplanabilir |
| **Şifre** | Şifre değiştirme |

Birkaç küçük kolaylık:

- Satırdaki anahtarla bir kitabı anında **okudum** olarak işaretleyebilirsiniz.
- İstek listesindeki bir kitabı satın alınca tek düğmeyle **Kitaplarım**'a taşıyabilirsiniz.
- Yazar, yayınevi, tür ve site alanlarında listede olmayan bir değer yazarsanız
  sistem onu kendisi ekler.
- Arama Türkçe büyük/küçük harf ayrımı yapmaz: `istanbul` yazarak `İSTANBUL`
  geçen kitapları bulursunuz.

---

## Dil ve tema

Sağ üstteki iki düğme:

- **EN** — arayüzü İngilizceye çevirir. İngilizceyken **TR** yazar ve geri döner.
  Kendi girdiğiniz kitap adları, yazar ve tür bilgileri çevrilmez, olduğu gibi kalır.
- 🌗 — açık ve koyu tema arasında geçiş yapar.

İkisi de uygulama kapanınca sıfırlanır; program Türkçe ve açık temayla açılır.

---

## Verileriniz nerede

Bütün kitaplarınız tek bir dosyada durur:

```
%LOCALAPPDATA%\BenimKutuphanem\kutuphane.db
```

Bu yolu Çalıştır penceresine (**Windows + R**) yapıştırıp klasörü açabilirsiniz.

- **Yedek almak:** uygulama kapalıyken `kutuphane.db` dosyasını kopyalayın.
- **Geri yüklemek:** yine uygulama kapalıyken dosyayı yerine koyun.
- Uygulamayı silseniz de bu dosya silinmez; verileriniz durur.
- Yeni sürüme geçerken de yerinde kalır, kitaplarınızı tekrar girmezsiniz.

Yanında `-wal` ve `-shm` uzantılı dosyalar görebilirsiniz; bunlar uygulamanın
çalışma dosyalarıdır, yedek alırken uygulamanın kapalı olması yeterlidir.

---

## Bir sorun çıkarsa

| Belirti | Ne yapmalı |
|---|---|
| Uygulama hiç açılmıyor | Visual C++ Redistributable (x64) eksik olabilir. Microsoft'un sitesinden ücretsiz kurup tekrar deneyin |
| "Veritabanı açılamadı" ekranı | Ekranda yazan klasöre yazma izni yok veya disk dolu. Hata metni ekranda görünür |
| "Bilinmeyen yayımcı" uyarısı | Normaldir; **Daha fazla bilgi → Yine de çalıştır** |
| Şifremi unuttum | Veritabanı dosyasını silerseniz uygulama sıfırdan başlar (`admin / 1234`) — ama kitaplarınız da gider. Önce dosyanın kopyasını alın |

---

Uygulamayı derlemek, paketlemek veya koda bakmak isteyenler için:
[GELISTIRICI.md](GELISTIRICI.md)
