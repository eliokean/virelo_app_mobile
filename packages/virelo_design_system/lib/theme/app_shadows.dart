import 'package:flutter/material.dart';

class AppShadows {
  AppShadows._();

  /// Carte hero (niveau 3) — légère brillance + ombre douce
  static const List<BoxShadow> heroCard = [
    BoxShadow(
      color: Color(0x3300E5A0),
      blurRadius: 32,
      spreadRadius: -8,
      offset: Offset(0, 16),
    ),
    BoxShadow(
      color: Color(0x20000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  /// Carte standard (niveau 1)
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x18000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// Bottom sheet / Modal
  static const List<BoxShadow> modal = [
    BoxShadow(
      color: Color(0x60000000),
      blurRadius: 48,
      offset: Offset(0, -8),
    ),
  ];

  /// Bouton CTA (glow vert)
  static const List<BoxShadow> ctaButton = [
    BoxShadow(
      color: Color(0x4000E5A0),
      blurRadius: 20,
      spreadRadius: -4,
      offset: Offset(0, 8),
    ),
  ];
}
