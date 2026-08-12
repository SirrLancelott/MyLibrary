import 'dart:async';

import 'package:flutter/material.dart';

import '../modeller/modeller.dart';
import '../servisler/kutuphane_servisi.dart';
import '../widgetlar/kitap_dialog.dart';
import '../widgetlar/ortak.dart';

/// "Sahip olduklarim" listesi: arama, filtre, ekleme, duzenleme, silme.
class KitaplarSekmesi extends StatefulWidget {
  const KitaplarSekmesi({
    super.key,
    required this.servis,
    required this.referanslar,
    required this.veriDegisti,
  });

  final KutuphaneServisi servis;
  final Referanslar referanslar;
  final VoidCallback veriDegisti;

  @override
  State<KitaplarSekmesi> createState() => _KitaplarSekmesiState();
}

class _KitaplarSekmesiState extends State<KitaplarSekmesi> {
  final _arama = TextEditingController();
  Timer? _aramaGecikmesi;

  List<Kitap>? _kitaplar;
  String? _hata;
  bool _yukleniyor = true;

  String? _turFiltresi;
  bool? _okunduFiltresi;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  @override
  void dispose() {
    _aramaGecikmesi?.cancel();
    _arama.dispose();
    super.dispose();
  }

  Future<void> _yukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });

    try {
      final gelen = await widget.servis.kitaplariGetir(
        arama: _arama.text.trim().isEmpty ? null : _arama.text.trim(),
        tur: _turFiltresi,
        okundu: _okunduFiltresi,
      );
      if (!mounted) return;
      setState(() {
        _kitaplar = gelen;
        _yukleniyor = false;
      });
    } on KutuphaneHatasi catch (hata) {
      if (!mounted) return;
      setState(() {
        _hata = hata.mesaj;
        _yukleniyor = false;
      });
    }
  }

  void _aramaDegisti(String _) {
    _aramaGecikmesi?.cancel();
    _aramaGecikmesi = Timer(const Duration(milliseconds: 350), _yukle);
  }

  Future<void> _kitapEkle() async {
    final yeni = await KitapDialog.goster(
      context,
      referanslar: widget.referanslar,
    );
    if (yeni == null) return;

    try {
      await widget.servis.kitapEkle(yeni);
      if (!mounted) return;
      bilgiGoster(context, '“${yeni.ad}” kitaplığa eklendi.');
      widget.veriDegisti();
      await _yukle();
    } on KutuphaneHatasi catch (hata) {
      _hatayiGoster(hata);
    }
  }

  Future<void> _kitapDuzenle(Kitap kitap) async {
    final guncel = await KitapDialog.goster(
      context,
      referanslar: widget.referanslar,
      mevcut: kitap,
    );
    if (guncel == null) return;

    try {
      await widget.servis.kitapGuncelle(kitap.kitapId, guncel);
      if (!mounted) return;
      bilgiGoster(context, 'Kitap güncellendi.');
      widget.veriDegisti();
      await _yukle();
    } on KutuphaneHatasi catch (hata) {
      _hatayiGoster(hata);
    }
  }

  Future<void> _okunduDegistir(Kitap kitap, bool deger) async {
    try {
      await widget.servis.kitapGuncelle(
        kitap.kitapId,
        kitap.kopyala(okunduMu: deger),
      );
      widget.veriDegisti();
      await _yukle();
    } on KutuphaneHatasi catch (hata) {
      _hatayiGoster(hata);
    }
  }

  Future<void> _kitapSil(Kitap kitap) async {
    final onay = await onayIste(
      context,
      baslik: 'Kitap silinsin mi?',
      mesaj: '“${kitap.ad}” kitaplığından kalıcı olarak silinecek.',
    );
    if (!onay) return;

    try {
      await widget.servis.kitapSil(kitap.kitapId);
      if (!mounted) return;
      bilgiGoster(context, 'Kitap silindi.');
      widget.veriDegisti();
      await _yukle();
    } on KutuphaneHatasi catch (hata) {
      _hatayiGoster(hata);
    }
  }

  void _hatayiGoster(KutuphaneHatasi hata) {
    if (!mounted) return;
    bilgiGoster(context, hata.mesaj, hata: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AracCubugu(
          arama: _arama,
          aramaDegisti: _aramaDegisti,
          turler: widget.referanslar.turler,
          turFiltresi: _turFiltresi,
          turDegisti: (deger) {
            setState(() => _turFiltresi = deger);
            _yukle();
          },
          okunduFiltresi: _okunduFiltresi,
          okunduDegisti: (deger) {
            setState(() => _okunduFiltresi = deger);
            _yukle();
          },
          adet: _kitaplar?.length,
          ekle: _kitapEkle,
          yenile: _yukle,
        ),
        const Divider(height: 1),
        Expanded(child: _icerik()),
      ],
    );
  }

  Widget _icerik() {
    if (_yukleniyor && _kitaplar == null) {
      return const DurumGoruntusu.yukleniyor();
    }
    if (_hata != null) {
      return DurumGoruntusu.hata(_hata!, yenidenDene: _yukle);
    }
    if (_kitaplar!.isEmpty) {
      return const DurumGoruntusu.bos(
        'Bu filtrelerle eşleşen kitap yok.\nAramayı temizleyip tekrar deneyin.',
      );
    }

    return Column(
      children: [
        const _BaslikSatiri(),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            itemCount: _kitaplar!.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, sira) {
              final kitap = _kitaplar![sira];
              return _KitapSatiri(
                kitap: kitap,
                cift: sira.isEven,
                okunduDegisti: (deger) => _okunduDegistir(kitap, deger),
                duzenle: () => _kitapDuzenle(kitap),
                sil: () => _kitapSil(kitap),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AracCubugu extends StatelessWidget {
  const _AracCubugu({
    required this.arama,
    required this.aramaDegisti,
    required this.turler,
    required this.turFiltresi,
    required this.turDegisti,
    required this.okunduFiltresi,
    required this.okunduDegisti,
    required this.adet,
    required this.ekle,
    required this.yenile,
  });

  final TextEditingController arama;
  final ValueChanged<String> aramaDegisti;
  final List<String> turler;
  final String? turFiltresi;
  final ValueChanged<String?> turDegisti;
  final bool? okunduFiltresi;
  final ValueChanged<bool?> okunduDegisti;
  final int? adet;
  final VoidCallback ekle;
  final VoidCallback yenile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 280,
            child: TextField(
              controller: arama,
              onChanged: aramaDegisti,
              decoration: InputDecoration(
                hintText: 'Kitap adı veya yazar ara…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: arama.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          arama.clear();
                          aramaDegisti('');
                        },
                      ),
              ),
            ),
          ),
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<String?>(
              initialValue: turFiltresi,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Tür'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Tümü')),
                for (final tur in turler)
                  DropdownMenuItem(value: tur, child: Text(tur)),
              ],
              onChanged: turDegisti,
            ),
          ),
          SegmentedButton<bool?>(
            segments: const [
              ButtonSegment(value: null, label: Text('Hepsi')),
              ButtonSegment(
                value: true,
                label: Text('Okudum'),
                icon: Icon(Icons.check, size: 16),
              ),
              ButtonSegment(
                value: false,
                label: Text('Okumadım'),
                icon: Icon(Icons.schedule, size: 16),
              ),
            ],
            selected: {okunduFiltresi},
            onSelectionChanged: (secim) => okunduDegisti(secim.first),
            showSelectedIcon: false,
          ),
          if (adet != null)
            Chip(
              avatar: const Icon(Icons.filter_list, size: 16),
              label: Text('$adet kayıt'),
            ),
          const SizedBox(width: 4),
          IconButton.filledTonal(
            tooltip: 'Yenile',
            onPressed: yenile,
            icon: const Icon(Icons.refresh),
          ),
          FilledButton.icon(
            onPressed: ekle,
            icon: const Icon(Icons.add),
            label: const Text('Kitap ekle'),
          ),
        ],
      ),
    );
  }
}

class _BaslikSatiri extends StatelessWidget {
  const _BaslikSatiri();

  @override
  Widget build(BuildContext context) {
    final stil = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          SizedBox(width: 44, child: Text('#', style: stil)),
          Expanded(flex: 4, child: Text('Kitap adı', style: stil)),
          Expanded(flex: 3, child: Text('Yazar', style: stil)),
          Expanded(flex: 3, child: Text('Yayınevi', style: stil)),
          Expanded(flex: 2, child: Text('Tür', style: stil)),
          SizedBox(width: 70, child: Text('Sayfa', style: stil)),
          SizedBox(width: 96, child: Text('Okundu', style: stil)),
          SizedBox(width: 96, child: Text('İşlem', style: stil)),
        ],
      ),
    );
  }
}

class _KitapSatiri extends StatelessWidget {
  const _KitapSatiri({
    required this.kitap,
    required this.cift,
    required this.okunduDegisti,
    required this.duzenle,
    required this.sil,
  });

  final Kitap kitap;
  final bool cift;
  final ValueChanged<bool> okunduDegisti;
  final VoidCallback duzenle;
  final VoidCallback sil;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final soluk = tema.textTheme.bodyMedium?.copyWith(
      color: tema.colorScheme.onSurfaceVariant,
    );

    return InkWell(
      onTap: duzenle,
      child: Container(
        color: cift ? null : tema.colorScheme.surfaceContainerLow,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Text('${kitap.siraNo}', style: soluk),
            ),
            Expanded(
              flex: 4,
              child: Text(
                kitap.ad,
                style: const TextStyle(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(kitap.yazar ?? '—',
                  style: soluk, overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: 3,
              child: Text(kitap.yayinevi ?? '—',
                  style: soluk, overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: 2,
              child: kitap.tur == null
                  ? Text('—', style: soluk)
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: tema.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          kitap.tur!,
                          style: tema.textTheme.labelSmall?.copyWith(
                            color: tema.colorScheme.onSecondaryContainer,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
            ),
            SizedBox(
              width: 70,
              child: Text(
                kitap.sayfaSayisi == null
                    ? '—'
                    : sayiBicimi.format(kitap.sayfaSayisi),
                style: soluk,
              ),
            ),
            SizedBox(
              width: 96,
              child: Switch(
                value: kitap.okunduMu,
                onChanged: okunduDegisti,
              ),
            ),
            SizedBox(
              width: 96,
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Düzenle',
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: duzenle,
                  ),
                  IconButton(
                    tooltip: 'Sil',
                    icon: Icon(Icons.delete_outline,
                        size: 20, color: tema.colorScheme.error),
                    onPressed: sil,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
