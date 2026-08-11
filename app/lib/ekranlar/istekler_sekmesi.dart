import 'dart:async';

import 'package:flutter/material.dart';

import '../modeller/modeller.dart';
import '../servisler/api_servisi.dart';
import '../widgetlar/istek_dialog.dart';
import '../widgetlar/ortak.dart';

/// "Almak istediklerim" listesi.
class IsteklerSekmesi extends StatefulWidget {
  const IsteklerSekmesi({
    super.key,
    required this.api,
    required this.referanslar,
    required this.veriDegisti,
    required this.oturumDustu,
  });

  final ApiServisi api;
  final Referanslar referanslar;
  final VoidCallback veriDegisti;
  final VoidCallback oturumDustu;

  @override
  State<IsteklerSekmesi> createState() => _IsteklerSekmesiState();
}

class _IsteklerSekmesiState extends State<IsteklerSekmesi> {
  final _arama = TextEditingController();
  Timer? _aramaGecikmesi;

  List<Istek>? _istekler;
  String? _hata;
  bool _yukleniyor = true;
  String? _turFiltresi;
  String? _siteFiltresi;

  /// Kartlari ture gore basliklar altinda toplar.
  bool _turlereGoreGrupla = false;

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
      final gelen = await widget.api.istekleriGetir(
        arama: _arama.text.trim().isEmpty ? null : _arama.text.trim(),
        tur: _turFiltresi,
        site: _siteFiltresi,
      );
      if (!mounted) return;
      setState(() {
        _istekler = gelen;
        _yukleniyor = false;
      });
    } on ApiHatasi catch (hata) {
      if (!mounted) return;
      if (hata.oturumDustu) {
        widget.oturumDustu();
        return;
      }
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

  Future<void> _islemSarmala(Future<void> Function() islem, String mesaj) async {
    try {
      await islem();
      if (!mounted) return;
      bilgiGoster(context, mesaj);
      widget.veriDegisti();
      await _yukle();
    } on ApiHatasi catch (hata) {
      if (!mounted) return;
      if (hata.oturumDustu) {
        widget.oturumDustu();
      } else {
        bilgiGoster(context, hata.mesaj, hata: true);
      }
    }
  }

  Future<void> _ekle() async {
    final yeni = await IstekDialog.goster(context,
        referanslar: widget.referanslar);
    if (yeni == null) return;
    await _islemSarmala(
        () => widget.api.istekEkle(yeni), '“${yeni.ad}” istek listesine eklendi.');
  }

  Future<void> _duzenle(Istek istek) async {
    final guncel = await IstekDialog.goster(context,
        referanslar: widget.referanslar, mevcut: istek);
    if (guncel == null) return;
    await _islemSarmala(
        () => widget.api.istekGuncelle(istek.istekId, guncel), 'Kayıt güncellendi.');
  }

  Future<void> _sil(Istek istek) async {
    final onay = await onayIste(
      context,
      baslik: 'Kayıt silinsin mi?',
      mesaj: '“${istek.ad}” istek listesinden kalıcı olarak silinecek.',
    );
    if (!onay) return;
    await _islemSarmala(
        () => widget.api.istekSil(istek.istekId), 'Kayıt silindi.');
  }

  Future<void> _kitapligaTasi(Istek istek) async {
    final onay = await onayIste(
      context,
      baslik: 'Kitaplığa taşınsın mı?',
      mesaj: '“${istek.ad}” istek listesinden çıkarılıp "Kitaplarım" '
          'listesine okunmadı olarak eklenecek.',
      onayla: 'Taşı',
    );
    if (!onay) return;
    await _islemSarmala(() => widget.api.istegiKitapligaTasi(istek.istekId),
        '“${istek.ad}” kitaplığa taşındı.');
  }

  double get _toplamTutar => (_istekler ?? [])
      .where((i) => !i.satinAlindi)
      .fold(0.0, (toplam, i) => toplam + (i.fiyat ?? 0));

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _arama,
                  onChanged: _aramaDegisti,
                  decoration: InputDecoration(
                    hintText: 'Kitap adı veya yazar ara…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _arama.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _arama.clear();
                              _aramaDegisti('');
                            },
                          ),
                  ),
                ),
              ),
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<String?>(
                  initialValue: _turFiltresi,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Tür'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tümü')),
                    for (final tur in widget.referanslar.turler)
                      DropdownMenuItem(value: tur, child: Text(tur)),
                  ],
                  onChanged: (deger) {
                    setState(() => _turFiltresi = deger);
                    _yukle();
                  },
                ),
              ),
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<String?>(
                  initialValue: _siteFiltresi,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Alınacak site'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tümü')),
                    for (final site in widget.referanslar.siteler)
                      DropdownMenuItem(value: site, child: Text(site)),
                  ],
                  onChanged: (deger) {
                    setState(() => _siteFiltresi = deger);
                    _yukle();
                  },
                ),
              ),
              FilterChip(
                avatar: const Icon(Icons.segment, size: 18),
                label: const Text('Türe göre grupla'),
                selected: _turlereGoreGrupla,
                onSelected: (deger) =>
                    setState(() => _turlereGoreGrupla = deger),
              ),
              if (_istekler != null) ...[
                Chip(
                  avatar: const Icon(Icons.filter_list, size: 16),
                  label: Text('${_istekler!.length} kayıt'),
                ),
                Chip(
                  avatar: const Icon(Icons.payments_outlined, size: 16),
                  label: Text('Toplam ${paraBicimi.format(_toplamTutar)}'),
                ),
              ],
              IconButton.filledTonal(
                tooltip: 'Yenile',
                onPressed: _yukle,
                icon: const Icon(Icons.refresh),
              ),
              FilledButton.icon(
                onPressed: _ekle,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('İstek ekle'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _icerik()),
      ],
    );
  }

  Widget _icerik() {
    if (_yukleniyor && _istekler == null) {
      return const DurumGoruntusu.yukleniyor();
    }
    if (_hata != null) {
      return DurumGoruntusu.hata(_hata!, yenidenDene: _yukle);
    }
    if (_istekler!.isEmpty) {
      return const DurumGoruntusu.bos('Bu filtrelerle eşleşen kayıt yok.');
    }

    if (!_turlereGoreGrupla) {
      return _izgara(_istekler!, kaydirilabilir: true);
    }

    final gruplar = _turlereGoreAyir(_istekler!);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: gruplar.length,
      itemBuilder: (context, sira) {
        final grup = gruplar[sira];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GrupBasligi(grup: grup),
            const SizedBox(height: 12),
            _izgara(grup.kayitlar, kaydirilabilir: false),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _izgara(List<Istek> kayitlar, {required bool kaydirilabilir}) {
    return GridView.builder(
      padding: kaydirilabilir ? const EdgeInsets.all(20) : EdgeInsets.zero,
      shrinkWrap: !kaydirilabilir,
      physics: kaydirilabilir ? null : const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisExtent: 176,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: kayitlar.length,
      itemBuilder: (context, sira) {
        final istek = kayitlar[sira];
        return _IstekKarti(
          istek: istek,
          duzenle: () => _duzenle(istek),
          sil: () => _sil(istek),
          kitapligaTasi: () => _kitapligaTasi(istek),
        );
      },
    );
  }

  /// Kayitlari ture gore ayirir; turu bos olanlar en sona konur.
  static List<_TurGrubu> _turlereGoreAyir(List<Istek> kayitlar) {
    const turuYok = 'Tür belirtilmemiş';
    final harita = <String, List<Istek>>{};

    for (final istek in kayitlar) {
      harita.putIfAbsent(istek.tur ?? turuYok, () => []).add(istek);
    }

    final adlar = harita.keys.toList()
      ..sort((a, b) {
        if (a == turuYok) return 1;
        if (b == turuYok) return -1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });

    return [
      for (final ad in adlar)
        _TurGrubu(
          ad: ad,
          kayitlar: harita[ad]!,
          tutar: harita[ad]!
              .where((i) => !i.satinAlindi)
              .fold(0.0, (toplam, i) => toplam + (i.fiyat ?? 0)),
        ),
    ];
  }
}

class _TurGrubu {
  const _TurGrubu({
    required this.ad,
    required this.kayitlar,
    required this.tutar,
  });

  final String ad;
  final List<Istek> kayitlar;
  final double tutar;
}

class _GrupBasligi extends StatelessWidget {
  const _GrupBasligi({required this.grup});

  final _TurGrubu grup;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Row(
      children: [
        Icon(Icons.category_outlined, size: 20, color: tema.colorScheme.primary),
        const SizedBox(width: 10),
        Text(
          grup.ad,
          style: tema.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: tema.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: tema.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${grup.kayitlar.length} kitap • ${paraBicimi.format(grup.tutar)}',
            style: tema.textTheme.labelSmall?.copyWith(
              color: tema.colorScheme.onSecondaryContainer,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Divider(color: tema.colorScheme.outlineVariant)),
      ],
    );
  }
}

class _IstekKarti extends StatelessWidget {
  const _IstekKarti({
    required this.istek,
    required this.duzenle,
    required this.sil,
    required this.kitapligaTasi,
  });

  final Istek istek;
  final VoidCallback duzenle;
  final VoidCallback sil;
  final VoidCallback kitapligaTasi;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final soluk = tema.textTheme.bodySmall
        ?.copyWith(color: tema.colorScheme.onSurfaceVariant);

    return Card(
      child: InkWell(
        onTap: duzenle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      istek.ad,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tema.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (istek.satinAlindi)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, right: 8),
                      child: Icon(Icons.check_circle,
                          size: 18, color: Colors.green.shade600),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(istek.yazar ?? 'Yazar belirtilmemiş',
                  style: soluk, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(
                [
                  if (istek.yayinevi != null) istek.yayinevi!,
                  if (istek.tur != null) istek.tur!,
                  if (istek.sayfaSayisi != null) '${istek.sayfaSayisi} sayfa',
                ].join(' • '),
                style: soluk,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                children: [
                  if (istek.fiyat != null)
                    Text(
                      paraBicimi.format(istek.fiyat),
                      style: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: tema.colorScheme.primary,
                      ),
                    ),
                  if (istek.site != null) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: tema.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          istek.site!,
                          style: tema.textTheme.labelSmall?.copyWith(
                            color: tema.colorScheme.onSecondaryContainer,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    tooltip: 'Kitaplığa taşı',
                    icon: const Icon(Icons.move_down, size: 20),
                    onPressed: kitapligaTasi,
                  ),
                  IconButton(
                    tooltip: 'Sil',
                    icon: Icon(Icons.delete_outline,
                        size: 20, color: tema.colorScheme.error),
                    onPressed: sil,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
