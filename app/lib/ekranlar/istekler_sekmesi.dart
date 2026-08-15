import 'dart:async';

import 'package:flutter/material.dart';

import '../modeller/modeller.dart';
import '../servisler/kutuphane_servisi.dart';
import '../widgetlar/istek_dialog.dart';
import '../widgetlar/ortak.dart';
import '../yerellestirme/ceviri.dart';

/// "Almak istediklerim" listesi.
class IsteklerSekmesi extends StatefulWidget {
  const IsteklerSekmesi({
    super.key,
    required this.servis,
    required this.referanslar,
    required this.veriDegisti,
  });

  final KutuphaneServisi servis;
  final Referanslar referanslar;
  final VoidCallback veriDegisti;

  @override
  State<IsteklerSekmesi> createState() => _IsteklerSekmesiState();
}

class _IsteklerSekmesiState extends State<IsteklerSekmesi> {
  final _arama = TextEditingController();
  Timer? _aramaGecikmesi;

  List<Istek>? _istekler;

  /// Metin degil hatanin kendisi tutulur: dil degisirse mesaj da degissin.
  KutuphaneHatasi? _hata;
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
      final gelen = await widget.servis.istekleriGetir(
        arama: _arama.text.trim().isEmpty ? null : _arama.text.trim(),
        tur: _turFiltresi,
        site: _siteFiltresi,
      );
      if (!mounted) return;
      setState(() {
        _istekler = gelen;
        _yukleniyor = false;
      });
    } on KutuphaneHatasi catch (hata) {
      if (!mounted) return;
      setState(() {
        _hata = hata;
        _yukleniyor = false;
      });
    }
  }

  void _aramaDegisti(String _) {
    _aramaGecikmesi?.cancel();
    _aramaGecikmesi = Timer(const Duration(milliseconds: 350), _yukle);
  }

  Future<void> _islemSarmala(
    Future<void> Function() islem,
    String mesaj,
  ) async {
    try {
      await islem();
      if (!mounted) return;
      bilgiGoster(context, mesaj);
      widget.veriDegisti();
      await _yukle();
    } on KutuphaneHatasi catch (hata) {
      if (!mounted) return;
      bilgiGoster(context, Ceviri.of(context).hataMetni(hata), hata: true);
    }
  }

  Future<void> _ekle() async {
    final ceviri = Ceviri.of(context);
    final yeni = await IstekDialog.goster(
      context,
      referanslar: widget.referanslar,
    );
    if (yeni == null) return;
    await _islemSarmala(
      () => widget.servis.istekEkle(yeni),
      ceviri.istekEklendi(yeni.ad),
    );
  }

  Future<void> _duzenle(Istek istek) async {
    final ceviri = Ceviri.of(context);
    final guncel = await IstekDialog.goster(
      context,
      referanslar: widget.referanslar,
      mevcut: istek,
    );
    if (guncel == null) return;
    await _islemSarmala(
      () => widget.servis.istekGuncelle(istek.istekId, guncel),
      ceviri.kayitGuncellendi,
    );
  }

  Future<void> _sil(Istek istek) async {
    final ceviri = Ceviri.of(context);
    final onay = await onayIste(
      context,
      baslik: ceviri.kayitSilinsinMi,
      mesaj: ceviri.istekSilmeUyarisi(istek.ad),
    );
    if (!onay) return;
    await _islemSarmala(
      () => widget.servis.istekSil(istek.istekId),
      ceviri.kayitSilindi,
    );
  }

  Future<void> _kitapligaTasi(Istek istek) async {
    final ceviri = Ceviri.of(context);
    final onay = await onayIste(
      context,
      baslik: ceviri.kitapligaTasinsinMi,
      mesaj: ceviri.tasimaUyarisi(istek.ad),
      onayla: ceviri.tasi,
    );
    if (!onay) return;
    await _islemSarmala(
      () => widget.servis.istegiKitapligaTasi(istek.istekId),
      ceviri.kitapligaTasindi(istek.ad),
    );
  }

  double get _toplamTutar => (_istekler ?? [])
      .where((i) => !i.satinAlindi)
      .fold(0.0, (toplam, i) => toplam + (i.fiyat ?? 0));

  @override
  Widget build(BuildContext context) {
    final ceviri = Ceviri.of(context);

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
                    hintText: ceviri.kitapAraIpucu,
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
                  decoration: InputDecoration(labelText: ceviri.tur),
                  items: [
                    DropdownMenuItem(value: null, child: Text(ceviri.tumu)),
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
                  decoration: InputDecoration(labelText: ceviri.alinacakSite),
                  items: [
                    DropdownMenuItem(value: null, child: Text(ceviri.tumu)),
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
                label: Text(ceviri.tureGoreGrupla),
                selected: _turlereGoreGrupla,
                onSelected: (deger) =>
                    setState(() => _turlereGoreGrupla = deger),
              ),
              if (_istekler != null) ...[
                Chip(
                  avatar: const Icon(Icons.filter_list, size: 16),
                  label: Text(ceviri.kayitAdedi(_istekler!.length)),
                ),
                Chip(
                  avatar: const Icon(Icons.payments_outlined, size: 16),
                  label: Text(ceviri.toplamTutar(_toplamTutar)),
                ),
              ],
              IconButton.filledTonal(
                tooltip: ceviri.yenile,
                onPressed: _yukle,
                icon: const Icon(Icons.refresh),
              ),
              FilledButton.icon(
                onPressed: _ekle,
                icon: const Icon(Icons.add_shopping_cart),
                label: Text(ceviri.istekEkleDugmesi),
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
      return DurumGoruntusu.hata(
        Ceviri.of(context).hataMetni(_hata!),
        yenidenDene: _yukle,
      );
    }
    if (_istekler!.isEmpty) {
      return DurumGoruntusu.bos(Ceviri.of(context).istekBulunamadi);
    }

    if (!_turlereGoreGrupla) {
      return _izgara(_istekler!, kaydirilabilir: true);
    }

    final gruplar = _turlereGoreAyir(
      _istekler!,
      Ceviri.of(context).turBelirtilmemis,
    );
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
  /// [turuYok] basligi cagirandan gelir, secili dile gore degisir.
  static List<_TurGrubu> _turlereGoreAyir(
    List<Istek> kayitlar,
    String turuYok,
  ) {
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
    final ceviri = Ceviri.of(context);

    return Row(
      children: [
        Icon(
          Icons.category_outlined,
          size: 20,
          color: tema.colorScheme.primary,
        ),
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
            ceviri.grupOzeti(grup.kayitlar.length, grup.tutar),
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
    final ceviri = Ceviri.of(context);
    final soluk = tema.textTheme.bodySmall?.copyWith(
      color: tema.colorScheme.onSurfaceVariant,
    );

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
                      style: tema.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (istek.satinAlindi)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, right: 8),
                      child: Icon(
                        Icons.check_circle,
                        size: 18,
                        color: Colors.green.shade600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                istek.yazar ?? ceviri.yazarBelirtilmemis,
                style: soluk,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                [
                  if (istek.yayinevi != null) istek.yayinevi!,
                  if (istek.tur != null) istek.tur!,
                  if (istek.sayfaSayisi != null)
                    ceviri.sayfaAdedi(istek.sayfaSayisi!),
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
                      ceviri.paraBicimi.format(istek.fiyat),
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
                          horizontal: 8,
                          vertical: 3,
                        ),
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
                    tooltip: ceviri.kitapligaTasi,
                    icon: const Icon(Icons.move_down, size: 20),
                    onPressed: kitapligaTasi,
                  ),
                  IconButton(
                    tooltip: ceviri.sil,
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: tema.colorScheme.error,
                    ),
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
