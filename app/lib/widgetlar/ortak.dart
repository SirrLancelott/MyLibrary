import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final paraBicimi = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
final sayiBicimi = NumberFormat.decimalPattern('tr_TR');
final tarihBicimi = DateFormat('dd.MM.yyyy HH:mm');

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
                label: const Text('Yeniden dene'),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
                    style: tema.textTheme.labelLarge?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                deger,
                style: tema.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold, color: vurgu),
              ),
            ),
            if (altBilgi != null) ...[
              const SizedBox(height: 4),
              Text(
                altBilgi!,
                style: tema.textTheme.bodySmall?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Serbest metin girisine izin veren, mevcut degerleri oneren alan.
/// (Yeni bir yazar/yayinevi yazildiginda API onu otomatik olusturur.)
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
  final _odak = FocusNode();

  @override
  void dispose() {
    _odak.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.denetleyici,
      focusNode: _odak,
      optionsBuilder: (deger) {
        final metin = deger.text.trim().toLowerCase();
        if (metin.isEmpty) return widget.oneriler.take(8);
        return widget.oneriler
            .where((o) => o.toLowerCase().contains(metin))
            .take(8);
      },
      fieldViewBuilder: (context, denetleyici, odak, gonder) => TextField(
        controller: denetleyici,
        focusNode: odak,
        decoration: InputDecoration(
          labelText: widget.etiket,
          prefixIcon: widget.simge == null ? null : Icon(widget.simge),
        ),
      ),
      optionsViewBuilder: (context, sec, secenekler) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220, maxWidth: 360),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                for (final secenek in secenekler)
                  ListTile(
                    dense: true,
                    title: Text(secenek),
                    onTap: () => sec(secenek),
                  ),
              ],
            ),
          ),
        ),
      ),
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
Future<bool> onayIste(
  BuildContext context, {
  required String baslik,
  required String mesaj,
  String onayla = 'Sil',
}) async {
  final sonuc = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(baslik),
      content: Text(mesaj),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(onayla),
        ),
      ],
    ),
  );
  return sonuc ?? false;
}
