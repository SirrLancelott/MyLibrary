import 'package:flutter/material.dart';

import '../servisler/api_servisi.dart';
import '../widgetlar/ortak.dart';

/// Giris yapmis kullanicinin kendi sifresini degistirdigi ekran.
/// Sifre basariyla degisince sunucudaki oturum dusurulur ve
/// [basarili] geri cagrisi ile giris ekranina donulur.
class SifreDegistirSekmesi extends StatefulWidget {
  const SifreDegistirSekmesi({
    super.key,
    required this.api,
    required this.basarili,
  });

  final ApiServisi api;
  final ValueChanged<String> basarili;

  @override
  State<SifreDegistirSekmesi> createState() => _SifreDegistirSekmesiState();
}

class _SifreDegistirSekmesiState extends State<SifreDegistirSekmesi> {
  final _form = GlobalKey<FormState>();
  final _mevcut = TextEditingController();
  final _yeni = TextEditingController();
  final _yeniTekrar = TextEditingController();

  bool _yukleniyor = false;
  bool _gizli = true;

  @override
  void dispose() {
    _mevcut.dispose();
    _yeni.dispose();
    _yeniTekrar.dispose();
    super.dispose();
  }

  Future<void> _kaydet() async {
    if (!_form.currentState!.validate()) return;

    setState(() => _yukleniyor = true);
    try {
      final mesaj = await widget.api.sifreDegistir(_mevcut.text, _yeni.text);
      if (!mounted) return;
      widget.basarili(mesaj);
    } on ApiHatasi catch (hata) {
      if (!mounted) return;
      bilgiGoster(context, hata.mesaj, hata: true);
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.password, color: tema.colorScheme.primary),
                        const SizedBox(width: 12),
                        Text('Şifre değiştir',
                            style: tema.textTheme.titleLarge),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Yeni şifre veritabanında PBKDF2 ile hash’lenerek '
                      'saklanır; düz metin olarak hiçbir yerde tutulmaz.',
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _mevcut,
                      obscureText: _gizli,
                      decoration: const InputDecoration(
                        labelText: 'Mevcut şifre',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (deger) => (deger == null || deger.isEmpty)
                          ? 'Mevcut şifrenizi girin'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _yeni,
                      obscureText: _gizli,
                      decoration: InputDecoration(
                        labelText: 'Yeni şifre',
                        prefixIcon: const Icon(Icons.lock_reset),
                        suffixIcon: IconButton(
                          tooltip: _gizli ? 'Göster' : 'Gizle',
                          icon: Icon(_gizli
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _gizli = !_gizli),
                        ),
                      ),
                      validator: (deger) {
                        if (deger == null || deger.length < 4) {
                          return 'Yeni şifre en az 4 karakter olmalı';
                        }
                        if (deger == _mevcut.text) {
                          return 'Yeni şifre eskisiyle aynı olamaz';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _yeniTekrar,
                      obscureText: _gizli,
                      decoration: const InputDecoration(
                        labelText: 'Yeni şifre (tekrar)',
                        prefixIcon: Icon(Icons.lock_reset),
                      ),
                      validator: (deger) => deger != _yeni.text
                          ? 'Şifreler eşleşmiyor'
                          : null,
                      onFieldSubmitted: (_) => _kaydet(),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _yukleniyor ? null : _kaydet,
                      icon: _yukleniyor
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                          _yukleniyor ? 'Kaydediliyor…' : 'Şifreyi güncelle'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Şifre değiştikten sonra güvenlik gereği oturumunuz '
                      'kapatılır ve yeni şifrenizle tekrar giriş yaparsınız.',
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
    );
  }
}
