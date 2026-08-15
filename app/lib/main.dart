import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'ekranlar/giris_ekrani.dart';
import 'servisler/kutuphane_servisi.dart';
import 'tema.dart';
import 'veritabani/veritabani.dart';
import 'yerellestirme/ceviri.dart';

void main() {
  runApp(const BenimKutuphanemUygulamasi());
}

class BenimKutuphanemUygulamasi extends StatefulWidget {
  const BenimKutuphanemUygulamasi({super.key, this.servis});

  /// Testlerde bellek ici veritabani gecmek icin. Bos birakilirsa
  /// diskteki gercek veritabani acilir.
  final KutuphaneServisi? servis;

  @override
  State<BenimKutuphanemUygulamasi> createState() =>
      _BenimKutuphanemUygulamasiState();
}

class _BenimKutuphanemUygulamasiState extends State<BenimKutuphanemUygulamasi> {
  /// Tek bir servis ornegi tum ekranlarca paylasilir; acik veritabani
  /// baglantisi ve giris yapmis kullanici bilgisi burada durur.
  KutuphaneServisi? _servis;
  String? _acilisHatasi;
  ThemeMode _temaModu = ThemeMode.light;

  /// Arayuz dili. Tema gibi bu da yalnizca acik oturum boyunca tutulur;
  /// uygulama yeniden baslayinca Turkce'den acilir.
  Dil _dil = Dil.turkce;

  @override
  void initState() {
    super.initState();
    if (widget.servis != null) {
      _servis = widget.servis;
      return;
    }
    try {
      _servis = KutuphaneServisi.ac();
    } catch (hata) {
      _acilisHatasi = '$hata';
    }
  }

  @override
  void dispose() {
    // Disaridan verilen servisin sahibi biz degiliz, onu kapatmayiz.
    if (widget.servis == null) _servis?.kapat();
    super.dispose();
  }

  void _temayiDegistir() {
    setState(() {
      _temaModu = _temaModu == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  void _diliDegistir() => setState(() => _dil = _dil.digeri);

  @override
  Widget build(BuildContext context) {
    final ceviri = Ceviri.icin(_dil);

    // DilKapsami MaterialApp'in ustunde durur: Navigator'in ittigi
    // sayfalar ve showDialog ile acilan pencereler de onun altinda kalir,
    // dil degisince hepsi birden yenilenir.
    return DilKapsami(
      dil: _dil,
      child: MaterialApp(
        title: ceviri.uygulamaAdi,
        debugShowCheckedModeBanner: false,
        theme: Tema.olustur(Brightness.light),
        darkTheme: Tema.olustur(Brightness.dark),
        themeMode: _temaModu,
        locale: _dil.locale,
        // Material'in kendi metinleri (metin secme menusu, tarih secici…)
        // de secili dile uysun.
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: Dil.values.map((d) => d.locale),
        home: _servis == null
            ? _AcilisHatasi(mesaj: _acilisHatasi ?? ceviri.bilinmeyenHata)
            : GirisEkrani(
                servis: _servis!,
                temaDegistir: _temayiDegistir,
                dilDegistir: _diliDegistir,
              ),
      ),
    );
  }
}

/// Veritabani dosyasi acilamadiginda gosterilir (izin sorunu, dolu disk vb.).
class _AcilisHatasi extends StatelessWidget {
  const _AcilisHatasi({required this.mesaj});

  final String mesaj;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final ceviri = Ceviri.of(context);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.storage_outlined,
                  size: 56,
                  color: tema.colorScheme.error,
                ),
                const SizedBox(height: 20),
                Text(
                  ceviri.veritabaniAcilamadi,
                  style: tema.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  ceviri.veriKlasoruAciklamasi,
                  textAlign: TextAlign.center,
                  style: tema.textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                SelectableText(
                  Veritabani.varsayilanYol,
                  textAlign: TextAlign.center,
                  style: tema.textTheme.bodySmall?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tema.colorScheme.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    mesaj,
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: tema.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
