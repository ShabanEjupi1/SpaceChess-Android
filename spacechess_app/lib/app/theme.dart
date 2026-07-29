import 'package:flutter/material.dart';

/// Ngjyrat e SpaceChess — të njëjtat si te faqja, që një lojtar që kalon nga
/// shfletuesi te aplikacioni të mos ndiejë se ndërroi produkt.
abstract final class Palette {
  static const Color background = Color(0xFF0E1116);
  static const Color surface = Color(0xFF171B22);
  static const Color surfaceHigh = Color(0xFF212732);
  static const Color accent = Color(0xFF6EA8FE);
  static const Color text = Color(0xFFE7EAF0);
  static const Color textDim = Color(0xFF9AA4B2);

  /// Tabela. Kutitë e errëta janë të ngrohta e jo gri: një tabelë gri mbi një
  /// sfond gri e humb kufirin, dhe sytë e lodhur e humbin rreshtin.
  static const Color light = Color(0xFFE8D7B5);
  static const Color dark = Color(0xFF9C7B4E);

  static const Color lastMove = Color(0x66F2C14E);
  static const Color check = Color(0xAAE05252);

  static const Color whitePiece = Color(0xFFFAFAF7);
  static const Color blackPiece = Color(0xFF33312E);
}

ThemeData buildTheme() {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: Palette.accent,
    brightness: Brightness.dark,
  ).copyWith(
    surface: Palette.background,
    primary: Palette.accent,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Palette.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: Palette.background,
      foregroundColor: Palette.text,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: const CardThemeData(
      color: Palette.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    dialogTheme: const DialogThemeData(backgroundColor: Palette.surface),
    bottomSheetTheme:
        const BottomSheetThemeData(backgroundColor: Palette.surface),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: Palette.text,
        side: const BorderSide(color: Palette.surfaceHigh),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textTheme: const TextTheme().apply(
      bodyColor: Palette.text,
      displayColor: Palette.text,
    ),
  );
}
