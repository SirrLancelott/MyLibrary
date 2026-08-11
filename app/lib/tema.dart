import 'package:flutter/material.dart';

/// Uygulamanin renk ve tipografi ayarlari tek yerden yonetilir.
class Tema {
  Tema._();

  static const anaRenk = Color(0xFF2E5C8A);
  static const vurgu = Color(0xFFC77D3A);

  static ThemeData olustur(Brightness parlaklik) {
    final renkler = ColorScheme.fromSeed(
      seedColor: anaRenk,
      brightness: parlaklik,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: renkler,
      visualDensity: VisualDensity.comfortable,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        isDense: true,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: renkler.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
