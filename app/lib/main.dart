import 'package:flutter/material.dart';

import 'ekranlar/giris_ekrani.dart';
import 'servisler/api_servisi.dart';
import 'tema.dart';

void main() {
  runApp(const BenimKutuphanemUygulamasi());
}

class BenimKutuphanemUygulamasi extends StatefulWidget {
  const BenimKutuphanemUygulamasi({super.key});

  @override
  State<BenimKutuphanemUygulamasi> createState() =>
      _BenimKutuphanemUygulamasiState();
}

class _BenimKutuphanemUygulamasiState extends State<BenimKutuphanemUygulamasi> {
  /// Tek bir API servisi tum ekranlarca paylasilir (token burada tutulur).
  final _api = ApiServisi();
  ThemeMode _temaModu = ThemeMode.light;

  void _temayiDegistir() {
    setState(() {
      _temaModu =
          _temaModu == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Benim Kütüphanem',
      debugShowCheckedModeBanner: false,
      theme: Tema.olustur(Brightness.light),
      darkTheme: Tema.olustur(Brightness.dark),
      themeMode: _temaModu,
      home: GirisEkrani(api: _api, temaDegistir: _temayiDegistir),
    );
  }
}
