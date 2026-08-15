import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../servisler/kutuphane_servisi.dart';
import '../widgetlar/ortak.dart';
import '../yerellestirme/ceviri.dart';
import 'ana_ekran.dart';

/// Uygulamanin giris ekrani. Kullanici adi ve sifre veritabanindaki
/// dbo.Kullanicilar tablosundan dogrulanir.
class GirisEkrani extends StatefulWidget {
  const GirisEkrani({
    super.key,
    required this.servis,
    required this.temaDegistir,
    required this.dilDegistir,
    this.sifreDegisti = false,
    this.baslangicKullaniciAdi,
  });

  final KutuphaneServisi servis;
  final VoidCallback temaDegistir;
  final VoidCallback dilDegistir;

  /// Sifre degistirdikten sonra buraya donuldugunde bilgi kutusu cikar.
  /// Metin degil bayrak tasinir ki dil degisince mesaj da cevrilsin.
  final bool sifreDegisti;
  final String? baslangicKullaniciAdi;

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  final _form = GlobalKey<FormState>();
  late final _kullaniciAdi = TextEditingController(
    text: widget.baslangicKullaniciAdi ?? '',
  );
  final _sifre = TextEditingController();
  final _sifreOdak = FocusNode();

  bool _yukleniyor = false;
  bool _sifreGizli = true;

  /// Metin degil hatanin kendisi tutulur: dil degisirse mesaj da degissin.
  KutuphaneHatasi? _hata;

  @override
  void initState() {
    super.initState();
    if (widget.baslangicKullaniciAdi != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _sifreOdak.requestFocus(),
      );
    }
  }

  @override
  void dispose() {
    _kullaniciAdi.dispose();
    _sifre.dispose();
    _sifreOdak.dispose();
    super.dispose();
  }

  Future<void> _girisYap() async {
    if (!_form.currentState!.validate()) return;

    setState(() {
      _yukleniyor = true;
      _hata = null;
    });

    try {
      final oturum = await widget.servis.girisYap(
        _kullaniciAdi.text.trim(),
        _sifre.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AnaEkran(
            servis: widget.servis,
            oturum: oturum,
            temaDegistir: widget.temaDegistir,
            dilDegistir: widget.dilDegistir,
          ),
        ),
      );
    } on KutuphaneHatasi catch (hata) {
      setState(() {
        _hata = hata;
        _sifre.clear();
      });
      _sifreOdak.requestFocus();
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final ceviri = Ceviri.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    tema.colorScheme.primaryContainer,
                    tema.colorScheme.surface,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DilDugmesi(dilDegistir: widget.dilDegistir),
                IconButton(
                  tooltip: ceviri.temaDegistir,
                  onPressed: widget.temaDegistir,
                  icon: const Icon(Icons.brightness_6_outlined),
                ),
              ],
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Form(
                      key: _form,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            size: 56,
                            color: tema.colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            ceviri.uygulamaAdi,
                            textAlign: TextAlign.center,
                            style: tema.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ceviri.altBaslik,
                            textAlign: TextAlign.center,
                            style: tema.textTheme.bodyMedium?.copyWith(
                              color: tema.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 28),
                          if (widget.sifreDegisti) ...[
                            _BilgiKutusu(
                              metin: ceviri.sifreGuncellendiMesaji,
                              renk: tema.colorScheme.primary,
                              simge: Icons.check_circle_outline,
                            ),
                            const SizedBox(height: 16),
                          ],
                          TextFormField(
                            controller: _kullaniciAdi,
                            autofocus: widget.baslangicKullaniciAdi == null,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: ceviri.kullaniciAdi,
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                            validator: (deger) =>
                                (deger == null || deger.trim().isEmpty)
                                ? ceviri.kullaniciAdiGiriniz
                                : null,
                            onFieldSubmitted: (_) => _sifreOdak.requestFocus(),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _sifre,
                            focusNode: _sifreOdak,
                            obscureText: _sifreGizli,
                            decoration: InputDecoration(
                              labelText: ceviri.sifre,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _sifreGizli
                                    ? ceviri.goster
                                    : ceviri.gizle,
                                icon: Icon(
                                  _sifreGizli
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () =>
                                    setState(() => _sifreGizli = !_sifreGizli),
                              ),
                            ),
                            validator: (deger) =>
                                (deger == null || deger.isEmpty)
                                ? ceviri.sifreGiriniz
                                : null,
                            onFieldSubmitted: (_) => _girisYap(),
                          ),
                          if (_hata != null) ...[
                            const SizedBox(height: 16),
                            _BilgiKutusu(
                              metin: ceviri.hataMetni(_hata!),
                              renk: tema.colorScheme.error,
                              simge: Icons.error_outline,
                            ),
                          ],
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: _yukleniyor ? null : _girisYap,
                            icon: _yukleniyor
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.login),
                            label: Text(
                              _yukleniyor
                                  ? ceviri.kontrolEdiliyor
                                  : ceviri.girisYap,
                            ),
                          ),
                          // Varsayilan sifre ipucu yalnizca gelistirme
                          // derlemesinde gorunur; yayin surumunde gizlenir.
                          if (kDebugMode) ...[
                            const SizedBox(height: 20),
                            Text(
                              ceviri.varsayilanKullanici,
                              textAlign: TextAlign.center,
                              style: tema.textTheme.bodySmall?.copyWith(
                                color: tema.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BilgiKutusu extends StatelessWidget {
  const _BilgiKutusu({
    required this.metin,
    required this.renk,
    required this.simge,
  });

  final String metin;
  final Color renk;
  final IconData simge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: renk.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(simge, color: renk, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              metin,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: renk),
            ),
          ),
        ],
      ),
    );
  }
}
