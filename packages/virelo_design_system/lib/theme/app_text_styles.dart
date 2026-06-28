import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── Display ──────────────────────────────────────────────────
  
  /// Montant principal (hero). Ex: "12 329"
  static TextStyle displayLarge = GoogleFonts.inter(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -1.5,
    fontFeatures: const [FontFeature.tabularFigures()],
    height: 1.0,
  );

  /// Montant secondaire (carte, historique gros). Ex: "2 432,43"
  static TextStyle displayMedium = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -1.0,
    fontFeatures: const [FontFeature.tabularFigures()],
    height: 1.1,
  );

  /// Montant transaction. Ex: "-500 XOF"
  static TextStyle displaySmall = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    fontFeatures: const [FontFeature.tabularFigures()],
    height: 1.2,
  );

  // ── Titres ────────────────────────────────────────────────────

  static TextStyle headlineLarge = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.25,
  );

  static TextStyle headlineMedium = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.3,
  );

  // ── Corps ────────────────────────────────────────────────────

  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // ── Labels & UI ───────────────────────────────────────────────

  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
  );

  static TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.1,
  );

  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
    letterSpacing: 0.3,
  );

  // ── Bouton ────────────────────────────────────────────────────

  static TextStyle button = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    height: 1.0,
  );

  // ── Mono (OTP, IDs) ───────────────────────────────────────────

  static TextStyle monoLarge = GoogleFonts.jetBrainsMono(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 8.0,
    color: AppColors.textPrimary,
  );

  static TextStyle monoSmall = GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 1.0,
    color: AppColors.textTertiary,
  );
}
