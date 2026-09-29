import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../yerellestirme/ceviri.dart';

/// Sag ustteki dil dugmesi. Uzerinde gecilecek dilin kisa adi yazar:
/// Turkce arayuzde "EN", Ingilizce arayuzde "TR".
class DilDugmesi extends StatelessWidget {
  const DilDugmesi({super.key, required this.dilDegistir});

  final VoidCallback dilDegistir;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final ceviri = Ceviri.of(context);
    final hedef = ceviri.dil.digeri;

    return Tooltip(
      message: ceviri.dileGec(hedef),
      child: TextButton(
        onPressed: dilDegistir,
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 36),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          foregroundColor: tema.colorScheme.primary,
        ),
        child: Text(
          hedef.kisaAd,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }
}

/// Yukleniyor / hata / bos durumlarini tek bicimde gosterir.
class DurumGoruntusu extends StatelessWidget {
  const DurumGoruntusu.yukleniyor({super.key})
    : _tur = _Tur.yukleniyor,
      mesaj = null,
      yenidenDene = null;

  const DurumGoruntusu.hata(this.mesaj, {super.key, this.yenidenDene})
    : _tur = _Tur.hata;

  const DurumGoruntusu.bos(this.mesaj, {super.key})
    : _tur = _Tur.bos,
      yenidenDene = null;

  final _Tur _tur;
  final String? mesaj;
  final VoidCallback? yenidenDene;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    if (_tur == _Tur.yukleniyor) {
      return const Center(child: CircularProgressIndicator());
    }

    final hataMi = _tur == _Tur.hata;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hataMi ? Icons.cloud_off_outlined : Icons.inbox_outlined,
              size: 48,
              color: hataMi
                  ? tema.colorScheme.error
                  : tema.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              mesaj ?? '',
              textAlign: TextAlign.center,
              style: tema.textTheme.bodyMedium?.copyWith(
                color: hataMi
                    ? tema.colorScheme.error
                    : tema.colorScheme.onSurfaceVariant,
              ),
            ),
            if (yenidenDene != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: yenidenDene,
                icon: const Icon(Icons.refresh),
                label: Text(Ceviri.of(context).yenidenDene),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _Tur { yukleniyor, hata, bos }

/// Ozet ekranindaki sayi kutulari.
class IstatistikKutusu extends StatelessWidget {
  const IstatistikKutusu({
    super.key,
    required this.baslik,
    required this.deger,
    required this.simge,
    this.renk,
    this.altBilgi,
  });

  final String baslik;
  final String deger;
  final IconData simge;
  final Color? renk;
  final String? altBilgi;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final vurgu = renk ?? tema.colorScheme.primary;

    // Yerlesim dar pencerede de tasmamali: baslik ve alt bilgi sabit
    // yukseklikte kalir, ortadaki sayi kalan alani doldurup gerekirse
    // kucultulur. Boylece kutu ne kadar basik olursa olsun icerik sigar.
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: vurgu.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(simge, color: vurgu, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    baslik,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tema.textTheme.labelLarge?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    deger,
                    style: tema.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: vurgu,
                    ),
                  ),
                ),
              ),
            ),
            if (altBilgi != null)
              Text(
                altBilgi!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tema.textTheme.bodySmall?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Serbest metin girisine izin veren, mevcut degerleri oneren alan.
/// (Yeni bir yazar/yayinevi yazildiginda servis onu otomatik olusturur.)
///
/// Tab tusu yazilani kayitli degerle tamamlar ve sonraki alana gecer:
/// "orh" + Tab -> "Orhan Pamuk". Yalnizca basi yazilanla eslesen bir deger
/// varsa tamamlanir; "Ali" yazip Tab'a basmak "Sabahattin Ali" olmaz,
/// boylece yeni bir ad girerken kayitli bir adin ustune yazilmaz. Ok
/// tuslariyla listeden bir secenek isaretlenmisse Tab onu alir.
class OneriliAlan extends StatefulWidget {
  const OneriliAlan({
    super.key,
    required this.denetleyici,
    required this.etiket,
    required this.oneriler,
    this.simge,
  });

  final TextEditingController denetleyici;
  final String etiket;
  final List<String> oneriler;
  final IconData? simge;

  @override
  State<OneriliAlan> createState() => _OneriliAlanState();
}

class _OneriliAlanState extends State<OneriliAlan> {
  late final _odak = FocusNode(onKeyEvent: _tusaBasildi);

  /// Acik oneri listesinde ok tuslariyla isaretlenen satir.
  /// optionsViewBuilder her cizimde gunceller.
  int _isaretliSira = 0;

  static const _enFazlaOneri = 8;

  @override
  void dispose() {
    _odak.dispose();
    super.dispose();
  }

  /// Karsilastirma icin sadelestirir. Dart'in toLowerCase'i "İ"yi
  /// "i + nokta" yapar, "I"yi de "ı" degil "i" yapar; ikisi de
  /// Turkce yazimda eslesmeyi bozmasin diye "ı" ve "i" ayni sayilir.
  static String _sade(String metin) => metin
      .trim()
      .toLowerCase()
      .replaceAll('̇', '')
      .replaceAll('ı', 'i');

  /// Once basi yazilanla baslayanlar, sonra icinde gecenler.
  List<String> _eslesenler(String girdi) {
    final aranan = _sade(girdi);
    if (aranan.isEmpty) return widget.oneriler.take(_enFazlaOneri).toList();

    final basta = <String>[];
    final icinde = <String>[];
    for (final oneri in widget.oneriler) {
      final sade = _sade(oneri);
      if (sade.startsWith(aranan)) {
        basta.add(oneri);
      } else if (sade.contains(aranan)) {
        icinde.add(oneri);
      }
    }
    return [...basta, ...icinde].take(_enFazlaOneri).toList();
  }

  /// Tab'a basildiginda yazilacak deger; tamamlanacak bir sey yoksa null.
  String? _tamamlanacakDeger() {
    final yazilan = widget.denetleyici.text;
    if (yazilan.trim().isEmpty) return null;

    final secenekler = _eslesenler(yazilan);
    if (secenekler.isEmpty) return null;

    // Kullanici ok tuslariyla bir satir sectiyse o gecerli.
    if (_isaretliSira > 0 && _isaretliSira < secenekler.length) {
      return secenekler[_isaretliSira];
    }

    final ilk = secenekler.first;
    return _sade(ilk).startsWith(_sade(yazilan)) ? ilk : null;
  }

  KeyEventResult _tusaBasildi(FocusNode _, KeyEvent olay) {
    if (olay is! KeyDownEvent ||
        olay.logicalKey != LogicalKeyboardKey.tab ||
        HardwareKeyboard.instance.isShiftPressed) {
      return KeyEventResult.ignored;
    }

    final deger = _tamamlanacakDeger();
    if (deger != null && deger != widget.denetleyici.text) {
      widget.denetleyici.value = TextEditingValue(
        text: deger,
        selection: TextSelection.collapsed(offset: deger.length),
      );
    }

    // Tus yutulmaz: odak her durumda bir sonraki alana gecer.
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.denetleyici,
      focusNode: _odak,
      optionsBuilder: (deger) => _eslesenler(deger.text),
      fieldViewBuilder: (context, denetleyici, odak, gonder) => TextField(
        controller: denetleyici,
        focusNode: odak,
        // Enter isaretli oneriyi secer.
        onSubmitted: (_) => gonder(),
        decoration: InputDecoration(
          labelText: widget.etiket,
          prefixIcon: widget.simge == null ? null : Icon(widget.simge),
        ),
      ),
      optionsViewBuilder: (context, sec, secenekler) {
        final isaretli = AutocompleteHighlightedOption.of(context);
        _isaretliSira = isaretli;

        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220, maxWidth: 360),
              // Satirlar odak almaz: Tab oneri listesine degil sonraki
              // alana gecsin. Klavyeyle secim ok tuslariyla yapilir.
              child: ExcludeFocus(
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: [
                    for (final (sira, secenek) in secenekler.indexed)
                      ListTile(
                        dense: true,
                        selected: sira == isaretli,
                        selectedTileColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.08),
                        title: Text(secenek),
                        onTap: () => sec(secenek),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

void bilgiGoster(BuildContext context, String mesaj, {bool hata = false}) {
  final tema = Theme.of(context);
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(mesaj),
        behavior: SnackBarBehavior.floating,
        width: 480,
        backgroundColor: hata ? tema.colorScheme.error : null,
      ),
    );
}

/// Evet / hayir onay penceresi.
/// [onayla] verilmezse dugme "Sil" / "Delete" yazar.
Future<bool> onayIste(
  BuildContext context, {
  required String baslik,
  required String mesaj,
  String? onayla,
}) async {
  final sonuc = await showDialog<bool>(
    context: context,
    builder: (context) {
      final ceviri = Ceviri.of(context);
      return AlertDialog(
        title: Text(baslik),
        content: Text(mesaj),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(ceviri.vazgec),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(onayla ?? ceviri.sil),
          ),
        ],
      );
    },
  );
  return sonuc ?? false;
}
