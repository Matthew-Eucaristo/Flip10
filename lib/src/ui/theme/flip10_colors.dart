import 'package:flutter/material.dart';

/// The Flip10 hand-drawn palette. All UI colors are sourced from this file.
class Flip10Colors {
  const Flip10Colors._();

  static const Color background = Color(0xFF121612);
  static const Color backgroundDeep = Color(0xFF0C100C);
  static const Color backgroundSoft = Color(0xFF182018);
  static const Color panel = Color(0xFF1B211C);
  static const Color panelDeep = Color(0xFF141A15);

  static const Color felt = Color(0xFF116B47);
  static const Color feltDeep = Color(0xFF0A422D);

  static const Color wood = Color(0xFF7B4D2A);
  static const Color woodLight = Color(0xFFB7834D);
  static const Color woodDeep = Color(0xFF3B2110);

  static const Color ivory = Color(0xFFF4E3BD);
  static const Color ivoryTop = Color(0xFFFBEFCB);
  static const Color ivoryBottom = Color(0xFFD5BD8A);

  static const Color ink = Color(0xFF201610);
  static const Color brass = Color(0xFFD7A941);
  static const Color brassTop = Color(0xFFF4D271);
  static const Color brassDeep = Color(0xFF7E5A12);

  static const Color closed = Color(0xFF302820);
  static const Color warning = Color(0xFFE56E4F);
  static const Color accent = Color(0xFF76D7A6);
  static const Color accentDeep = Color(0xFF0A2A1B);

  /// Player accent colors. Index by PlayerBoard.index.
  static const List<Color> playerColors = [
    Color(0xFF4FA3FF),
    Color(0xFFE85C4A),
    Color(0xFFF0C84B),
    Color(0xFF39B879),
  ];

  static Color playerColor(int index) =>
      playerColors[index % playerColors.length];

  /// Brand seed.
  static const Color brandSeed = Color(0xFF1E6F4B);
}
