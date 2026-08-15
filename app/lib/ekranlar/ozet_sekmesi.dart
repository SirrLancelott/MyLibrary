import 'package:flutter/material.dart';

import '../modeller/modeller.dart';
import '../servisler/kutuphane_servisi.dart';
import '../widgetlar/ortak.dart';
import '../yerellestirme/ceviri.dart';

/// Kutuphanenin genel durumunu gosteren acilis sekmesi.
class OzetSekmesi extends StatefulWidget {
  const OzetSekmesi({super.key, required this.servis, required this.oturum});

  final KutuphaneServisi servis;
  final Oturum oturum;

  @override
  State<OzetSekmesi> createState() => _OzetSekmesiState();
}

class _OzetSekmesiState extends State<OzetSekmesi> {
  late Future<Ozet> _ozet;

  @override
  void initState() {
    super.initState();
    _ozet = widget.servis.ozetGetir();
  }

  void _tazele() => setState(() => _ozet = widget.servis.ozetGetir());

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final ceviri = Ceviri.of(context);

    return FutureBuilder<Ozet>(
      future: _ozet,
      builder: (context, durum) {
        if (durum.connectionState == ConnectionState.waiting) {
          return const DurumGoruntusu.yukleniyor();
        }

        if (durum.hasError) {
          return DurumGoruntusu.hata('${durum.error}', yenidenDene: _tazele);
        }

        final ozet = durum.data!;
        final okumaOrani = ozet.toplamKitap == 0
            ? 0.0
            : ozet.okunanKitap / ozet.toplamKitap;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ceviri.hosGeldin(widget.oturum.gorunenAd),
                          style: tema.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.oturum.oncekiGiris == null
                              ? ceviri.ilkGiris
                              : ceviri.sonGiris(widget.oturum.oncekiGiris!),
                          style: tema.textTheme.bodyMedium?.copyWith(
                            color: tema.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: ceviri.yenile,
                    onPressed: _tazele,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              LayoutBuilder(
                builder: (context, kisit) {
                  final sutun = kisit.maxWidth > 1100
                      ? 4
                      : kisit.maxWidth > 780
                      ? 3
                      : 2;
                  return GridView.count(
                    crossAxisCount: sutun,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.85,
                    children: [
                      IstatistikKutusu(
                        baslik: ceviri.sahipOlunanKitap,
                        deger: ceviri.sayiBicimi.format(ozet.toplamKitap),
                        simge: Icons.library_books,
                      ),
                      IstatistikKutusu(
                        baslik: ceviri.okudugum,
                        deger: ceviri.sayiBicimi.format(ozet.okunanKitap),
                        simge: Icons.check_circle,
                        renk: Colors.green.shade700,
                        altBilgi: ceviri.yuzde(okumaOrani),
                      ),
                      IstatistikKutusu(
                        baslik: ceviri.okumadigim,
                        deger: ceviri.sayiBicimi.format(ozet.okunmayanKitap),
                        simge: Icons.schedule,
                        renk: Colors.orange.shade800,
                      ),
                      IstatistikKutusu(
                        baslik: ceviri.toplamSayfa,
                        deger: ceviri.sayiBicimi.format(ozet.toplamSayfa),
                        simge: Icons.description_outlined,
                        altBilgi: ceviri.sayfaSayisiGirilmis,
                      ),
                      IstatistikKutusu(
                        baslik: ceviri.istekListesi,
                        deger: ceviri.sayiBicimi.format(ozet.istekAdedi),
                        simge: Icons.shopping_cart,
                        renk: Colors.blueGrey.shade700,
                      ),
                      IstatistikKutusu(
                        baslik: ceviri.tahminiMaliyet,
                        deger: ceviri.paraBicimi.format(ozet.istekToplamTutar),
                        simge: Icons.payments_outlined,
                        renk: tema.colorScheme.tertiary,
                        altBilgi: ceviri.henuzAlinmamis,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ceviri.okumaIlerlemesi,
                        style: tema.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: okumaOrani,
                          minHeight: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ceviri.okumaOzeti(
                          ozet.toplamKitap,
                          ozet.okunanKitap,
                          ozet.okunmayanKitap,
                        ),
                        style: tema.textTheme.bodyMedium?.copyWith(
                          color: tema.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
