import 'package:flutter/material.dart';

import '../modeller/modeller.dart';
import '../servisler/api_servisi.dart';
import '../widgetlar/ortak.dart';

/// Kutuphanenin genel durumunu gosteren acilis sekmesi.
class OzetSekmesi extends StatefulWidget {
  const OzetSekmesi({
    super.key,
    required this.api,
    required this.oturum,
    required this.oturumDustu,
  });

  final ApiServisi api;
  final Oturum oturum;
  final VoidCallback oturumDustu;

  @override
  State<OzetSekmesi> createState() => _OzetSekmesiState();
}

class _OzetSekmesiState extends State<OzetSekmesi> {
  late Future<Ozet> _ozet;

  @override
  void initState() {
    super.initState();
    _ozet = widget.api.ozetGetir();
  }

  void _tazele() => setState(() => _ozet = widget.api.ozetGetir());

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return FutureBuilder<Ozet>(
      future: _ozet,
      builder: (context, durum) {
        if (durum.connectionState == ConnectionState.waiting) {
          return const DurumGoruntusu.yukleniyor();
        }

        if (durum.hasError) {
          final hata = durum.error;
          if (hata is ApiHatasi && hata.oturumDustu) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => widget.oturumDustu());
            return const DurumGoruntusu.yukleniyor();
          }
          return DurumGoruntusu.hata('$hata', yenidenDene: _tazele);
        }

        final ozet = durum.data!;
        final okumaOrani =
            ozet.toplamKitap == 0 ? 0.0 : ozet.okunanKitap / ozet.toplamKitap;

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
                          'Hoş geldin, ${widget.oturum.gorunenAd}',
                          style: tema.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.oturum.oncekiGiris == null
                              ? 'Bu, ilk girişin. İyi okumalar!'
                              : 'Son giriş: '
                                  '${tarihBicimi.format(widget.oturum.oncekiGiris!)}',
                          style: tema.textTheme.bodyMedium?.copyWith(
                            color: tema.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Yenile',
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
                        baslik: 'Sahip olduğum kitap',
                        deger: sayiBicimi.format(ozet.toplamKitap),
                        simge: Icons.library_books,
                      ),
                      IstatistikKutusu(
                        baslik: 'Okuduğum',
                        deger: sayiBicimi.format(ozet.okunanKitap),
                        simge: Icons.check_circle,
                        renk: Colors.green.shade700,
                        altBilgi: '%${(okumaOrani * 100).toStringAsFixed(0)}',
                      ),
                      IstatistikKutusu(
                        baslik: 'Okumadığım',
                        deger: sayiBicimi.format(ozet.okunmayanKitap),
                        simge: Icons.schedule,
                        renk: Colors.orange.shade800,
                      ),
                      IstatistikKutusu(
                        baslik: 'Toplam sayfa',
                        deger: sayiBicimi.format(ozet.toplamSayfa),
                        simge: Icons.description_outlined,
                        altBilgi: 'Sayfa sayısı girilmiş kitaplar',
                      ),
                      IstatistikKutusu(
                        baslik: 'İstek listesi',
                        deger: sayiBicimi.format(ozet.istekAdedi),
                        simge: Icons.shopping_cart,
                        renk: Colors.blueGrey.shade700,
                      ),
                      IstatistikKutusu(
                        baslik: 'Tahmini maliyet',
                        deger: paraBicimi.format(ozet.istekToplamTutar),
                        simge: Icons.payments_outlined,
                        renk: tema.colorScheme.tertiary,
                        altBilgi: 'Henüz alınmamış kitaplar',
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
                      Text('Okuma ilerlemesi',
                          style: tema.textTheme.titleMedium),
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
                        '${ozet.toplamKitap} kitabın ${ozet.okunanKitap} tanesini '
                        'okudun, ${ozet.okunmayanKitap} tanesi seni bekliyor.',
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
