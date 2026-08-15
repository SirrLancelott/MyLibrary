import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../modeller/modeller.dart';
import '../yerellestirme/ceviri.dart';
import 'ortak.dart';

/// Istek listesi kaydi ekleme / duzenleme penceresi.
class IstekDialog extends StatefulWidget {
  const IstekDialog({super.key, required this.referanslar, this.mevcut});

  final Referanslar referanslar;
  final Istek? mevcut;

  static Future<Istek?> goster(
    BuildContext context, {
    required Referanslar referanslar,
    Istek? mevcut,
  }) => showDialog<Istek>(
    context: context,
    builder: (_) => IstekDialog(referanslar: referanslar, mevcut: mevcut),
  );

  @override
  State<IstekDialog> createState() => _IstekDialogState();
}

class _IstekDialogState extends State<IstekDialog> {
  final _form = GlobalKey<FormState>();

  late final _ad = TextEditingController(text: widget.mevcut?.ad ?? '');
  late final _yazar = TextEditingController(text: widget.mevcut?.yazar ?? '');
  late final _yayinevi = TextEditingController(
    text: widget.mevcut?.yayinevi ?? '',
  );
  late final _tur = TextEditingController(text: widget.mevcut?.tur ?? '');
  late final _site = TextEditingController(text: widget.mevcut?.site ?? '');
  late final _sayfa = TextEditingController(
    text: widget.mevcut?.sayfaSayisi?.toString() ?? '',
  );
  late final _fiyat = TextEditingController(
    text: widget.mevcut?.fiyat?.toStringAsFixed(2).replaceAll('.', ',') ?? '',
  );

  late bool _satinAlindi = widget.mevcut?.satinAlindi ?? false;

  bool get _duzenlemeMi => widget.mevcut != null;

  @override
  void dispose() {
    _ad.dispose();
    _yazar.dispose();
    _yayinevi.dispose();
    _tur.dispose();
    _site.dispose();
    _sayfa.dispose();
    _fiyat.dispose();
    super.dispose();
  }

  String? _bosaCevir(TextEditingController denetleyici) {
    final metin = denetleyici.text.trim();
    return metin.isEmpty ? null : metin;
  }

  /// "249,90" ve "249.90" yazimlarinin ikisini de kabul eder.
  static double? _fiyatCoz(String metin) {
    final temiz = metin.trim().replaceAll(' ', '').replaceAll(',', '.');
    return temiz.isEmpty ? null : double.tryParse(temiz);
  }

  void _kaydet() {
    if (!_form.currentState!.validate()) return;

    Navigator.pop(
      context,
      Istek(
        istekId: widget.mevcut?.istekId ?? 0,
        siraNo: widget.mevcut?.siraNo ?? 0,
        ad: _ad.text.trim(),
        yazar: _bosaCevir(_yazar),
        yayinevi: _bosaCevir(_yayinevi),
        tur: _bosaCevir(_tur),
        sayfaSayisi: int.tryParse(_sayfa.text.trim()),
        site: _bosaCevir(_site),
        fiyat: _fiyatCoz(_fiyat.text),
        satinAlindi: _satinAlindi,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ceviri = Ceviri.of(context);

    return AlertDialog(
      title: Text(
        _duzenlemeMi ? ceviri.istegiDuzenle : ceviri.istekListesineEkle,
      ),
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
                  decoration: InputDecoration(
                    labelText: ceviri.kitapAdiZorunlu,
                    prefixIcon: const Icon(Icons.menu_book_outlined),
                  ),
                  validator: (deger) => (deger == null || deger.trim().isEmpty)
                      ? ceviri.kitapAdiGerekli
                      : null,
                ),
                const SizedBox(height: 16),
                OneriliAlan(
                  denetleyici: _yazar,
                  etiket: ceviri.sutunYazar,
                  oneriler: widget.referanslar.yazarlar,
                  simge: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                OneriliAlan(
                  denetleyici: _yayinevi,
                  etiket: ceviri.sutunYayinevi,
                  oneriler: widget.referanslar.yayinevleri,
                  simge: Icons.apartment_outlined,
                ),
                const SizedBox(height: 16),
                OneriliAlan(
                  denetleyici: _tur,
                  etiket: ceviri.tur,
                  oneriler: widget.referanslar.turler,
                  simge: Icons.category_outlined,
                ),
                const SizedBox(height: 16),
                OneriliAlan(
                  denetleyici: _site,
                  etiket: ceviri.alinacakSite,
                  oneriler: widget.referanslar.siteler,
                  simge: Icons.storefront_outlined,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _sayfa,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: ceviri.sayfaSayisi,
                          prefixIcon: const Icon(Icons.description_outlined),
                        ),
                        validator: (deger) {
                          if (deger == null || deger.trim().isEmpty) {
                            return null;
                          }
                          final sayi = int.tryParse(deger.trim());
                          if (sayi == null || sayi <= 0) {
                            return ceviri.sifirdanBuyuk;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _fiyat,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        decoration: InputDecoration(
                          labelText: ceviri.fiyat,
                          prefixIcon: const Icon(Icons.payments_outlined),
                        ),
                        validator: (deger) {
                          if (deger == null || deger.trim().isEmpty) {
                            return null;
                          }
                          final fiyat = _fiyatCoz(deger);
                          if (fiyat == null || fiyat < 0) {
                            return ceviri.gecerliFiyat;
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(ceviri.satinAlindiIsaretle),
                  subtitle: Text(ceviri.satinAlindiAciklama),
                  value: _satinAlindi,
                  onChanged: (deger) => setState(() => _satinAlindi = deger),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(ceviri.vazgec),
        ),
        FilledButton.icon(
          onPressed: _kaydet,
          icon: const Icon(Icons.save_outlined),
          label: Text(_duzenlemeMi ? ceviri.guncelle : ceviri.ekle),
        ),
      ],
    );
  }
}
