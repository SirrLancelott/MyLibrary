import 'package:flutter/material.dart';

import '../servisler/api_servisi.dart';
import 'ana_ekran.dart';

/// Uygulamanin giris ekrani. Kullanici adi ve sifre veritabanindaki
/// dbo.Kullanicilar tablosundan dogrulanir.
class GirisEkrani extends StatefulWidget {
  const GirisEkrani({
    super.key,
    required this.api,
    required this.temaDegistir,
    this.acilisMesaji,
    this.baslangicKullaniciAdi,
  });

  final ApiServisi api;
  final VoidCallback temaDegistir;

  /// Sifre degistirdikten sonra buraya donuldugunde gosterilecek bilgi.
  final String? acilisMesaji;
  final String? baslangicKullaniciAdi;

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  final _form = GlobalKey<FormState>();
  late final _kullaniciAdi =
      TextEditingController(text: widget.baslangicKullaniciAdi ?? '');
  final _sifre = TextEditingController();
  final _sifreOdak = FocusNode();

  bool _yukleniyor = false;
  bool _sifreGizli = true;
  String? _hata;

  @override
  void initState() {
    super.initState();
    if (widget.baslangicKullaniciAdi != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _sifreOdak.requestFocus());
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
      final oturum = await widget.api.girisYap(
        _kullaniciAdi.text.trim(),
        _sifre.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AnaEkran(
            api: widget.api,
            oturum: oturum,
            temaDegistir: widget.temaDegistir,
          ),
        ),
      );
    } on ApiHatasi catch (hata) {
      setState(() {
        _hata = hata.mesaj;
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
            child: IconButton(
              tooltip: 'Açık / koyu tema',
              onPressed: widget.temaDegistir,
              icon: const Icon(Icons.brightness_6_outlined),
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
                            'Benim Kütüphanem',
                            textAlign: TextAlign.center,
                            style: tema.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kütüphane Otomasyon Sistemi',
                            textAlign: TextAlign.center,
                            style: tema.textTheme.bodyMedium?.copyWith(
                              color: tema.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 28),
                          if (widget.acilisMesaji != null) ...[
                            _BilgiKutusu(
                              metin: widget.acilisMesaji!,
                              renk: tema.colorScheme.primary,
                              simge: Icons.check_circle_outline,
                            ),
                            const SizedBox(height: 16),
                          ],
                          TextFormField(
                            controller: _kullaniciAdi,
                            autofocus: widget.baslangicKullaniciAdi == null,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Kullanıcı adı',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (deger) =>
                                (deger == null || deger.trim().isEmpty)
                                    ? 'Kullanıcı adı giriniz'
                                    : null,
                            onFieldSubmitted: (_) => _sifreOdak.requestFocus(),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _sifre,
                            focusNode: _sifreOdak,
                            obscureText: _sifreGizli,
                            decoration: InputDecoration(
                              labelText: 'Şifre',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _sifreGizli ? 'Göster' : 'Gizle',
                                icon: Icon(_sifreGizli
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined),
                                onPressed: () =>
                                    setState(() => _sifreGizli = !_sifreGizli),
                              ),
                            ),
                            validator: (deger) =>
                                (deger == null || deger.isEmpty)
                                    ? 'Şifre giriniz'
                                    : null,
                            onFieldSubmitted: (_) => _girisYap(),
                          ),
                          if (_hata != null) ...[
                            const SizedBox(height: 16),
                            _BilgiKutusu(
                              metin: _hata!,
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
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.login),
                            label: Text(
                                _yukleniyor ? 'Kontrol ediliyor…' : 'Giriş yap'),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Varsayılan kullanıcı:  admin / 1234',
                            textAlign: TextAlign.center,
                            style: tema.textTheme.bodySmall?.copyWith(
                              color: tema.colorScheme.onSurfaceVariant,
                            ),
                          ),
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
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: renk),
            ),
          ),
        ],
      ),
    );
  }
}
