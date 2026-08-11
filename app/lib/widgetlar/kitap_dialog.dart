import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../modeller/modeller.dart';
import 'ortak.dart';

/// Kitap ekleme / duzenleme penceresi.
/// Kaydedilirse doldurulmus [Kitap], iptal edilirse null doner.
class KitapDialog extends StatefulWidget {
  const KitapDialog({super.key, required this.referanslar, this.mevcut});

  final Referanslar referanslar;
  final Kitap? mevcut;

  static Future<Kitap?> goster(
    BuildContext context, {
    required Referanslar referanslar,
    Kitap? mevcut,
  }) =>
      showDialog<Kitap>(
        context: context,
        builder: (_) => KitapDialog(referanslar: referanslar, mevcut: mevcut),
      );

  @override
  State<KitapDialog> createState() => _KitapDialogState();
}

class _KitapDialogState extends State<KitapDialog> {
  final _form = GlobalKey<FormState>();

  late final _ad = TextEditingController(text: widget.mevcut?.ad ?? '');
  late final _yazar = TextEditingController(text: widget.mevcut?.yazar ?? '');
  late final _yayinevi =
      TextEditingController(text: widget.mevcut?.yayinevi ?? '');
  late final _tur = TextEditingController(text: widget.mevcut?.tur ?? '');
  late final _sayfa = TextEditingController(
      text: widget.mevcut?.sayfaSayisi?.toString() ?? '');

  late bool _okundu = widget.mevcut?.okunduMu ?? false;

  bool get _duzenlemeMi => widget.mevcut != null;

  @override
  void dispose() {
    _ad.dispose();
    _yazar.dispose();
    _yayinevi.dispose();
    _tur.dispose();
    _sayfa.dispose();
    super.dispose();
  }

  String? _bosaCevir(TextEditingController denetleyici) {
    final metin = denetleyici.text.trim();
    return metin.isEmpty ? null : metin;
  }

  void _kaydet() {
    if (!_form.currentState!.validate()) return;

    Navigator.pop(
      context,
      Kitap(
        kitapId: widget.mevcut?.kitapId ?? 0,
        siraNo: widget.mevcut?.siraNo ?? 0,
        ad: _ad.text.trim(),
        yazar: _bosaCevir(_yazar),
        yayinevi: _bosaCevir(_yayinevi),
        tur: _bosaCevir(_tur),
        sayfaSayisi: int.tryParse(_sayfa.text.trim()),
        okunduMu: _okundu,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_duzenlemeMi ? 'Kitabı düzenle' : 'Yeni kitap ekle'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _ad,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Kitap adı *',
                    prefixIcon: Icon(Icons.menu_book_outlined),
                  ),
                  validator: (deger) => (deger == null || deger.trim().isEmpty)
                      ? 'Kitap adı zorunludur'
                      : null,
                ),
                const SizedBox(height: 16),
                OneriliAlan(
                  denetleyici: _yazar,
                  etiket: 'Yazar',
                  oneriler: widget.referanslar.yazarlar,
                  simge: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                OneriliAlan(
                  denetleyici: _yayinevi,
                  etiket: 'Yayınevi',
                  oneriler: widget.referanslar.yayinevleri,
                  simge: Icons.apartment_outlined,
                ),
                const SizedBox(height: 16),
                OneriliAlan(
                  denetleyici: _tur,
                  etiket: 'Tür',
                  oneriler: widget.referanslar.turler,
                  simge: Icons.category_outlined,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _sayfa,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Sayfa sayısı',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  validator: (deger) {
                    if (deger == null || deger.trim().isEmpty) return null;
                    final sayi = int.tryParse(deger.trim());
                    if (sayi == null || sayi <= 0) {
                      return 'Sayfa sayısı 0’dan büyük olmalı';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Bu kitabı okudum'),
                  value: _okundu,
                  onChanged: (deger) => setState(() => _okundu = deger),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Yazar, yayınevi ve tür listede yoksa yazdığınız değer '
                    'otomatik olarak eklenir.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton.icon(
          onPressed: _kaydet,
          icon: const Icon(Icons.save_outlined),
          label: Text(_duzenlemeMi ? 'Güncelle' : 'Ekle'),
        ),
      ],
    );
  }
}
