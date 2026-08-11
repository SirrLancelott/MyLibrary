import 'package:flutter/material.dart';

import '../modeller/modeller.dart';
import '../servisler/api_servisi.dart';
import 'giris_ekrani.dart';
import 'istekler_sekmesi.dart';
import 'kitaplar_sekmesi.dart';
import 'ozet_sekmesi.dart';
import 'sifre_degistir_sekmesi.dart';

/// Giris sonrasi ana pencere: solda menu, sagda secili sekme.
class AnaEkran extends StatefulWidget {
  const AnaEkran({
    super.key,
    required this.api,
    required this.oturum,
    required this.temaDegistir,
  });

  final ApiServisi api;
  final Oturum oturum;
  final VoidCallback temaDegistir;

  @override
  State<AnaEkran> createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran> {
  int _secili = 0;

  /// Referans listeleri (yazar, yayinevi, tur, site) bir kez cekilir,
  /// duzenleme pencerelerindeki oneriler bunlardan beslenir.
  Referanslar _referanslar = Referanslar.bos;

  /// Kitap/istek degistiginde ozet sekmesinin tazelenmesi icin sayac.
  int _tazelemeSayaci = 0;

  @override
  void initState() {
    super.initState();
    _referanslariYukle();
  }

  Future<void> _referanslariYukle() async {
    try {
      final gelen = await widget.api.referanslariGetir();
      if (mounted) setState(() => _referanslar = gelen);
    } on ApiHatasi {
      // Oneriler olmadan da form calisir; sessizce gec.
    }
  }

  void _veriDegisti() {
    setState(() => _tazelemeSayaci++);
    _referanslariYukle();
  }

  Future<void> _cikisYap({String? mesaj}) async {
    await widget.api.cikisYap();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GirisEkrani(
          api: widget.api,
          temaDegistir: widget.temaDegistir,
          acilisMesaji: mesaj,
          baslangicKullaniciAdi: widget.oturum.kullaniciAdi,
        ),
      ),
    );
  }

  /// Oturum sunucuda dustuyse (401) kullaniciyi giris ekranina dondurur.
  void oturumDustu() {
    _cikisYap(mesaj: 'Oturum süresi doldu, lütfen tekrar giriş yapın.');
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    final sayfalar = [
      OzetSekmesi(
        key: ValueKey('ozet_$_tazelemeSayaci'),
        api: widget.api,
        oturum: widget.oturum,
        oturumDustu: oturumDustu,
      ),
      KitaplarSekmesi(
        api: widget.api,
        referanslar: _referanslar,
        veriDegisti: _veriDegisti,
        oturumDustu: oturumDustu,
      ),
      IsteklerSekmesi(
        api: widget.api,
        referanslar: _referanslar,
        veriDegisti: _veriDegisti,
        oturumDustu: oturumDustu,
      ),
      SifreDegistirSekmesi(
        api: widget.api,
        basarili: (mesaj) => _cikisYap(mesaj: mesaj),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: tema.colorScheme.surfaceContainerHighest,
        title: Row(
          children: [
            Icon(Icons.menu_book_rounded, color: tema.colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Benim Kütüphanem'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: tema.colorScheme.primaryContainer,
                  child: Text(
                    widget.oturum.gorunenAd.characters.first.toUpperCase(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: tema.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(widget.oturum.gorunenAd),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Açık / koyu tema',
            onPressed: widget.temaDegistir,
            icon: const Icon(Icons.brightness_6_outlined),
          ),
          IconButton(
            tooltip: 'Çıkış yap',
            onPressed: () => _cikisYap(),
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _secili,
            onDestinationSelected: (i) => setState(() => _secili = i),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Özet'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.library_books_outlined),
                selectedIcon: Icon(Icons.library_books),
                label: Text('Kitaplarım'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.shopping_cart_outlined),
                selectedIcon: Icon(Icons.shopping_cart),
                label: Text('İstek Listem'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.password_outlined),
                selectedIcon: Icon(Icons.password),
                label: Text('Şifre'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: sayfalar[_secili]),
        ],
      ),
    );
  }
}
