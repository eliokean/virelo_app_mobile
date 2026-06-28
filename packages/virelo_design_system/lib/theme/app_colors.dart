import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Fond ────────────────────────────────────────────────────
  /// Fond global de l'app (noir encre, pas pur noir)
  static const Color background     = Color(0xFF0D0F14);
  
  /// Fond des cartes élevées (hero wallet)
  static const Color surfaceHero    = Color(0xFF161A22);
  
  /// Fond des cartes secondaires (transactions, liste)
  static const Color surfaceCard    = Color(0xFF1C2030);
  
  /// Séparateurs et bordures subtiles
  static const Color surfaceBorder  = Color(0xFF252A38);

  // ── Accent — "Le vert Virelo" ────────────────────────────────
  /// Couleur signature — CTA, succès, badge positif
  static const Color accent         = Color(0xFF00E5A0);
  
  /// Accent atténué pour les fonds de badge
  static const Color accentMuted    = Color(0x1400E5A0); // 8% opacity
  
  /// Accent sombre pour hover/pressed
  static const Color accentDark     = Color(0xFF00B87F);

  // ── Texte ────────────────────────────────────────────────────
  static const Color textPrimary    = Color(0xFFF0F2F7);   // Blanc cassé
  static const Color textSecondary  = Color(0xFF8B93A8);   // Gris slate
  static const Color textTertiary   = Color(0xFF4A5168);   // Gris discret
  static const Color textInverse    = Color(0xFF0D0F14);   // Pour texte sur accent

  // ── États sémantiques ────────────────────────────────────────
  static const Color success        = Color(0xFF00E5A0);   // = accent
  static const Color successMuted   = Color(0x1A00E5A0); // 10% opacity
  static const Color warning        = Color(0xFFFFB547);
  static const Color warningMuted   = Color(0x1AFFB547);
  static const Color error          = Color(0xFFFF4D6A);
  static const Color errorMuted     = Color(0x1AFF4D6A);
  static const Color info           = Color(0xFF4C9EFF);
  static const Color infoMuted      = Color(0x1A4C9EFF);

  // ── Spéciaux ─────────────────────────────────────────────────
  /// Overlay pour modales et bottom sheets
  static const Color scrim          = Color(0xCC0D0F14);   // 80% opacity
  
  /// Badge offline
  static const Color offline        = Color(0xFFFFB547);
  
  /// NFC actif (pulse animée)
  static const Color nfcPulse       = Color(0xFF00E5A0);

  // ── Dégradés ─────────────────────────────────────────────────
  // Dégradé hero carte solde (fond)
  static const Gradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF161A22), Color(0xFF0F1520)],
    stops: [0.0, 1.0],
  );

  // Dégradé NFC pulse (anneau animé)
  static const Gradient nfcGradient = RadialGradient(
    colors: [Color(0x5500E5A0), Color(0x0000E5A0)],
    stops: [0.0, 1.0],
  );

  // Dégradé montant positif (vert → transparent, pour le graph mini)
  static const Gradient chartPositive = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x4000E5A0), Color(0x0000E5A0)],
  );
}
