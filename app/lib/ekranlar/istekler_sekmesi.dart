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

  /// "Ilk 10" listesi, siraya gore. Filtrelerden etkilenmez.
  List<Istek> _ilkOn = const [];

  /// Metin degil hatanin kendisi tutulur: dil degisirse mesaj da degissin.
  KutuphaneHatasi? _hata;
  bool _yukleniyor = true;
  String? _turFiltresi;
  String? _siteFiltresi;

  /// Kartlari ture gore basliklar altinda toplar.
  bool _turlereGoreGrupla = false;

  /// Izgara yerine siralanabilir "Ilk 10" listesini gosterir.
  bool _ilkOnGorunumu = false;

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
      final ilkOn = await widget.servis.ilkOnuGetir();
      if (!mounted) return;
      setState(() {
        _istekler = gelen;
        _ilkOn = ilkOn;
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

  Future<void> _ilkOnDegistir(Istek istek) async {
    final ceviri = Ceviri.of(context);
    if (istek.ilkOndaMi) {
      await _islemSarmala(
        () => widget.servis.ilkOndanCikar(istek.istekId),
        ceviri.ilkOndanCikarildi(istek.ad),
      );
    } else {
      await _islemSarmala(
        () => widget.servis.ilkOnaEkle(istek.istekId),
        ceviri.ilkOnaEklendi(istek.ad),
      );
    }
  }

  /// Ogeyi [eskiSira]dan alip [yeniSira]ya koyar (ikisi de 0'dan baslar;
  /// yeniSira, oge listeden cikarildiktan sonraki konumdur).
  Future<void> _ilkOnuYenidenSirala(int eskiSira, int yeniSira) async {
    if (yeniSira == eskiSira) return;

    // Surukleme bittigi anda yeni sira gorunsun; veritabani ardindan yazilir.
    final liste = [..._ilkOn];
    liste.insert(yeniSira, liste.removeAt(eskiSira));
    setState(() => _ilkOn = liste);

    try {
      await widget.servis.ilkOnuSirala([for (final i in liste) i.istekId]);
    } on KutuphaneHatasi catch (hata) {
      if (!mounted) return;
      bilgiGoster(context, Ceviri.of(context).hataMetni(hata), hata: true);
    }
    if (mounted) await _yukle();
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
                avatar: const Icon(Icons.star_outline, size: 18),
                label: Text('${ceviri.ilkOn} (${_ilkOn.length})'),
                selected: _ilkOnGorunumu,
                onSelected: (deger) => setState(() => _ilkOnGorunumu = deger),
              ),
              if (!_ilkOnGorunumu)
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
    if (_ilkOnGorunumu) return _ilkOnListesi();
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
          ilkOnDegistir: () => _ilkOnDegistir(istek),
        );
      },
    );
  }

  Widget _ilkOnListesi() {
    final ceviri = Ceviri.of(context);
    final tema = Theme.of(context);

    if (_ilkOn.isEmpty) return DurumGoruntusu.bos(ceviri.ilkOnBos);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                ceviri.ilkOnDoluluk(_ilkOn.length, ilkOnSiniri),
                style: tema.textTheme.bodySmall?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                buildDefaultDragHandles: false,
                itemCount: _ilkOn.length,
                onReorderItem: _ilkOnuYenidenSirala,
                itemBuilder: (context, sira) {
                  final istek = _ilkOn[sira];
                  return _IlkOnSatiri(
                    key: ValueKey(istek.istekId),
                    sira: sira,
                    istek: istek,
                    yukari: sira == 0
                        ? null
                        : () => _ilkOnuYenidenSirala(sira, sira - 1),
                    asagi: sira == _ilkOn.length - 1
                        ? null
                        : () => _ilkOnuYenidenSirala(sira, sira + 1),
                    cikar: () => _ilkOnDegistir(istek),
                    duzenle: () => _duzenle(istek),
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
    required this.ilkOnDegistir,
  });

  final Istek istek;
  final VoidCallback duzenle;
  final VoidCallback sil;
  final VoidCallback kitapligaTasi;
  final VoidCallback ilkOnDegistir;

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
                  if (istek.oncelik != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _SiraRozeti(sira: istek.oncelik!, kucuk: true),
                    ),
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
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.check_circle,
                        size: 18,
                        color: Colors.green.shade600,
                      ),
                    ),
                  // Alt satirdaki fiyat ve site etiketine yer kalsin diye
                  // yildiz basligin yaninda, kucuk boyutta durur.
                  IconButton(
                    tooltip: istek.ilkOndaMi
                        ? ceviri.ilkOndanCikar
                        : ceviri.ilkOnaEkle,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 24,
                    ),
                    icon: Icon(
                      istek.ilkOndaMi ? Icons.star : Icons.star_border,
                      size: 20,
                      color: istek.ilkOndaMi ? Colors.amber.shade700 : null,
                    ),
                    onPressed: ilkOnDegistir,
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

/// "Ilk 10" sira numarasi. Ilk uc sira ana renkle vurgulanir.
class _SiraRozeti extends StatelessWidget {
  const _SiraRozeti({required this.sira, this.kucuk = false});

  /// 1'den baslar.
  final int sira;
  final bool kucuk;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final ustSira = sira <= 3;
    final boyut = kucuk ? 22.0 : 32.0;

    return Container(
      width: boyut,
      height: boyut,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ustSira
            ? tema.colorScheme.primary
            : tema.colorScheme.secondaryContainer,
      ),
      child: Text(
        '$sira',
        style: (kucuk ? tema.textTheme.labelSmall : tema.textTheme.titleSmall)
            ?.copyWith(
              fontWeight: FontWeight.bold,
              color: ustSira
                  ? tema.colorScheme.onPrimary
                  : tema.colorScheme.onSecondaryContainer,
            ),
      ),
    );
  }
}

/// "Ilk 10" gorunumundeki tek satir: tutamak, sira, kitap bilgisi ve
/// yukari / asagi / cikar dugmeleri. Tutamaktan surukleyerek de siralanir.
class _IlkOnSatiri extends StatelessWidget {
  const _IlkOnSatiri({
    super.key,
    required this.sira,
    required this.istek,
    required this.yukari,
    required this.asagi,
    required this.cikar,
    required this.duzenle,
  });

  /// 0'dan baslar (ReorderableListView konumu).
  final int sira;
  final Istek istek;
  final VoidCallback? yukari;
  final VoidCallback? asagi;
  final VoidCallback cikar;
  final VoidCallback duzenle;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final ceviri = Ceviri.of(context);
    final soluk = tema.textTheme.bodySmall?.copyWith(
      color: tema.colorScheme.onSurfaceVariant,
    );

    final ayrinti = [
      istek.yazar ?? ceviri.yazarBelirtilmemis,
      if (istek.fiyat != null) ceviri.paraBicimi.format(istek.fiyat),
      if (istek.site != null) istek.site!,
    ].join(' • ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: duzenle,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: sira,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.drag_indicator,
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                _SiraRozeti(sira: sira + 1),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        istek.ad,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tema.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ayrinti,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: soluk,
                      ),
                    ],
                  ),
                ),
                if (istek.satinAlindi)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.check_circle,
                      size: 18,
                      color: Colors.green.shade600,
                    ),
                  ),
                IconButton(
                  tooltip: ceviri.yukariTasi,
                  icon: const Icon(Icons.arrow_upward, size: 20),
                  onPressed: yukari,
                ),
                IconButton(
                  tooltip: ceviri.asagiTasi,
                  icon: const Icon(Icons.arrow_downward, size: 20),
                  onPressed: asagi,
                ),
                IconButton(
                  tooltip: ceviri.ilkOndanCikar,
                  icon: Icon(Icons.star, size: 20, color: Colors.amber.shade700),
                  onPressed: cikar,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
