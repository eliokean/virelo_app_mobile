# Virelo — Design System
### Application mobile de paiement · NFC + QR · Offline-First

> **Version** : 1.0.0 · **Plateforme** : Android (Flutter)  
> **Philosophie** : Rapide, minimaliste, premium. Chaque pixel au service du geste de paiement.

---

## Table des matières

1. [Identité visuelle & principes](#1-identité-visuelle--principes)
2. [Palette de couleurs](#2-palette-de-couleurs)
3. [Typographie](#3-typographie)
4. [Espacements & grille](#4-espacements--grille)
5. [Élévations & ombres](#5-élévations--ombres)
6. [Iconographie](#6-iconographie)
7. [Composants — Atomes](#7-composants--atomes)
8. [Composants — Molécules](#8-composants--molécules)
9. [Composants — Organismes](#9-composants--organismes)
10. [Écrans — Anatomie](#10-écrans--anatomie)
11. [Flows NFC & QR Code — Détail complet](#11-flows-nfc--qr-code--détail-complet)
12. [Animations & motion](#12-animations--motion)
13. [États & feedback](#13-états--feedback)
14. [Implémentation Flutter](#14-implémentation-flutter)
15. [Checklist qualité](#15-checklist-qualité)

---

## 1. Identité visuelle & principes

### 1.1 Positionnement

Virelo est une application de paiement mobile destinée aux marchés à fort trafic en Afrique de l'Ouest.  
Elle doit inspirer **confiance**, **vitesse** et **inclusion** — pas ressembler à une banque traditionnelle.

**Métaphore de design** : *L'argent qui coule.* Fluide, directionnel, instantané.  
Chaque interaction doit se sentir aussi naturelle que tendre un billet — mais en une seconde.

### 1.2 Principes fondateurs

| Principe | Signification concrète |
|----------|----------------------|
| **Vitesse visible** | Les actions primaires sont toujours en un geste. Aucun écran à plus de 2 taps de la home |
| **Clarté des chiffres** | Les montants sont toujours lisibles, même sur un écran en plein soleil. Taille min. 32sp |
| **Offline en premier** | L'UI ne doit jamais être bloquée par l'absence de réseau. Badge clair, jamais d'erreur fatale |
| **Densité intentionnelle** | L'espace blanc est une ressource. Pas de padding généreux pour "faire propre". Chaque espace encode une hiérarchie |
| **Confiance par cohérence** | Même composant, même comportement, partout. Zéro surprise |

### 1.3 Ton & voix

- **Court** : "Paiement reçu" — pas "Votre paiement a bien été reçu par le destinataire"
- **Actif** : "Envoyer", "Encaisser", "Vérifier" — verbes, pas noms
- **Sans faute** : Montants toujours formatés. Jamais `5000` — toujours `5 000 XOF`
- **Neutre sur l'échec** : "Solde insuffisant. Rechargez." — pas "Oups !"

---

## 2. Palette de couleurs

### 2.1 Tokens principaux

```dart
// lib/core/theme/app_colors.dart

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
  static const Color accentMuted    = Color(0xFF00E5A014); // 8% opacity
  
  /// Accent sombre pour hover/pressed
  static const Color accentDark     = Color(0xFF00B87F);

  // ── Texte ────────────────────────────────────────────────────
  static const Color textPrimary    = Color(0xFFF0F2F7);   // Blanc cassé
  static const Color textSecondary  = Color(0xFF8B93A8);   // Gris slate
  static const Color textTertiary   = Color(0xFF4A5168);   // Gris discret
  static const Color textInverse    = Color(0xFF0D0F14);   // Pour texte sur accent

  // ── États sémantiques ────────────────────────────────────────
  static const Color success        = Color(0xFF00E5A0);   // = accent
  static const Color successMuted   = Color(0xFF00E5A01A); // 10% opacity
  static const Color warning        = Color(0xFFFFB547);
  static const Color warningMuted   = Color(0xFFFFB5471A);
  static const Color error          = Color(0xFFFF4D6A);
  static const Color errorMuted     = Color(0xFFFF4D6A1A);
  static const Color info           = Color(0xFF4C9EFF);
  static const Color infoMuted      = Color(0xFF4C9EFF1A);

  // ── Spéciaux ─────────────────────────────────────────────────
  /// Overlay pour modales et bottom sheets
  static const Color scrim          = Color(0xCC0D0F14);   // 80% opacity
  
  /// Badge offline
  static const Color offline        = Color(0xFFFFB547);
  
  /// NFC actif (pulse animée)
  static const Color nfcPulse       = Color(0xFF00E5A0);
}
```

### 2.2 Sémantique des couleurs

| Couleur | Hex | Utilisation |
|---------|-----|-------------|
| Background | `#0D0F14` | Fond de tous les écrans |
| Surface Hero | `#161A22` | Carte principale (solde, NFC actif) |
| Surface Card | `#1C2030` | Cartes transaction, listes |
| Surface Border | `#252A38` | Dividers, bordures de champs |
| **Accent** | **`#00E5A0`** | **CTA principal, succès, badges positifs** |
| Accent Muted | `#00E5A0` @ 8% | Fond de badge, chip sélectionné |
| Text Primary | `#F0F2F7` | Titres, montants, labels importants |
| Text Secondary | `#8B93A8` | Sous-titres, métadonnées |
| Text Tertiary | `#4A5168` | Placeholders, infos désactivées |
| Warning | `#FFB547` | Badge offline, alertes non-critiques |
| Error | `#FF4D6A` | Erreurs, montant négatif, solde insuffisant |
| Info | `#4C9EFF` | Informations, en cours |

### 2.3 Dégradés

```dart
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
```

---

## 3. Typographie

### 3.1 Choix typographiques

| Rôle | Police | Justification |
|------|--------|---------------|
| **Display** (gros montants) | `Inter` — weight 700 | Chiffres tabular, lisiblité maximale en toutes conditions |
| **UI** (labels, boutons) | `Inter` — weight 500/600 | Cohérence système, chiffres propres |
| **Body** (texte courant) | `Inter` — weight 400 | Neutralité, lisibilité |
| **Mono** (IDs, codes OTP) | `JetBrains Mono` | Distinction claire, caractère technique |

> **Règle d'or** : Les montants utilisent toujours `fontFeatures: [FontFeature.tabularFigures()]`  
> pour que les chiffres s'alignent parfaitement dans les listes.

### 3.2 Échelle typographique

```dart
// lib/core/theme/app_text_styles.dart

class AppTextStyles {
  AppTextStyles._();

  // ── Display ──────────────────────────────────────────────────
  
  /// Montant principal (hero). Ex: "12 329"
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -1.5,
    fontFeatures: [FontFeature.tabularFigures()],
    height: 1.0,
  );

  /// Montant secondaire (carte, historique gros). Ex: "2 432,43"
  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -1.0,
    fontFeatures: [FontFeature.tabularFigures()],
    height: 1.1,
  );

  /// Montant transaction. Ex: "-500 XOF"
  static const TextStyle displaySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    fontFeatures: [FontFeature.tabularFigures()],
    height: 1.2,
  );

  // ── Titres ────────────────────────────────────────────────────

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.3,
  );

  // ── Corps ────────────────────────────────────────────────────

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // ── Labels & UI ───────────────────────────────────────────────

  static const TextStyle labelLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.1,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
    letterSpacing: 0.3,
  );

  // ── Bouton ────────────────────────────────────────────────────

  static const TextStyle button = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    height: 1.0,
  );

  // ── Mono (OTP, IDs) ───────────────────────────────────────────

  static const TextStyle monoLarge = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 8.0,
    color: AppColors.textPrimary,
  );

  static const TextStyle monoSmall = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 1.0,
    color: AppColors.textTertiary,
  );
}
```

### 3.3 Formatage des montants

```dart
// lib/core/utils/amount_formatter.dart

class AmountFormatter {
  AmountFormatter._();

  /// "12329.5" → "12 329"  (partie entière, espace comme séparateur)
  static String formatWhole(double amount) {
    final intPart = amount.toInt();
    final str = intPart.toString();
    final result = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) result.write('\u202F'); // espace fine
      result.write(str[i]);
    }
    return result.toString();
  }

  /// "12329.5" → "12 329,50 XOF"
  static String formatFull(double amount, {String currency = 'XOF'}) {
    final whole    = formatWhole(amount.floorToDouble());
    final decimals = ((amount - amount.floorToDouble()) * 100).round();
    return '$whole,${decimals.toString().padLeft(2, '0')} $currency';
  }

  /// Pour afficher la variation : "+4,2%" ou "-1,5%"
  static String formatVariation(double percent) {
    final sign = percent >= 0 ? '+' : '';
    return '$sign${percent.toStringAsFixed(1)}%';
  }
}
```

---

## 4. Espacements & grille

### 4.1 Tokens d'espacement

```dart
// lib/core/constants/app_spacing.dart

class AppSpacing {
  AppSpacing._();

  // Unité de base : 4dp
  static const double xs   =  4.0;   // 4dp  — séparateur minimal
  static const double sm   =  8.0;   // 8dp  — espace interne compact
  static const double md   = 12.0;   // 12dp — espace standard entre éléments
  static const double lg   = 16.0;   // 16dp — padding horizontal écran
  static const double xl   = 20.0;   // 20dp — espace section
  static const double xxl  = 24.0;   // 24dp — espace entre sections majeures
  static const double xxxl = 32.0;   // 32dp — marge en haut des écrans
  static const double huge = 48.0;   // 48dp — espacement hors norme (onboarding)

  // Padding horizontal de l'écran
  static const double screenH = 20.0;
  
  // Rayon de bordure
  static const double radiusXs  =  6.0;
  static const double radiusSm  =  8.0;
  static const double radiusMd  = 12.0;
  static const double radiusLg  = 16.0;
  static const double radiusXl  = 20.0;
  static const double radiusFull = 999.0;
}
```

### 4.2 Grille de l'écran

```
┌─────────────────────────────────┐  ← StatusBar (système)
│  20dp │ ←── contenu ──→ │ 20dp  │  ← padding horizontal = AppSpacing.screenH
│       │                 │       │
│       │   SafeArea      │       │
│       │   top           │       │
│       │                 │       │
│  ╔════════════════════╗  │       │
│  ║   Hero Card         ║  │       │  ← radius 20dp
│  ║   full-bleed        ║  │       │  ← margin: 0 horizontal sur hero
│  ╚════════════════════╝  │       │
│       │                 │       │
│       │  Section grid   │       │
│       │  12dp gap       │       │
│       │                 │       │
│       │  List items     │       │
│       │  0 horizontal   │       │  ← full width avec padding interne
│       │                 │       │
└─────────────────────────────────┘
         ↑
      Bottom Nav = 60dp + safe area
```

### 4.3 Dimensions fixes

| Élément | Valeur |
|---------|--------|
| AppBar height | 56dp |
| Bottom Nav height | 60dp + safe area |
| Bouton primaire height | 52dp |
| Bouton secondaire height | 44dp |
| Chip height | 32dp |
| Avatar petit | 36dp |
| Avatar moyen | 44dp |
| Avatar grand | 56dp |
| Icône de nav | 24dp |
| Icône dans bouton | 20dp |
| Touch target minimum | 44dp |

---

## 5. Élévations & ombres

Virelo utilise un système d'élévation par **lumière ambiante** — pas des ombres dures.  
Sur fond sombre, l'élévation se traduit par une **légère surbrillance de la surface**.

```dart
// lib/core/theme/app_shadows.dart

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
  static List<BoxShadow> ctaButton = [
    const BoxShadow(
      color: Color(0x4000E5A0),
      blurRadius: 20,
      spreadRadius: -4,
      offset: Offset(0, 8),
    ),
  ];
}
```

---

## 6. Iconographie

### 6.1 Bibliothèque recommandée

- **Package** : `lucide_icons` (lignes fines, cohérentes, moderne)
- **Taille standard** : 20dp dans les composants, 24dp standalone
- **Stroke** : 1.5dp — JAMAIS les icônes remplies Material sauf exception

### 6.2 Icônes clés de Virelo

| Action | Icône Lucide | Contexte |
|--------|-------------|---------|
| Envoyer | `LucideIcons.arrowUpRight` | CTA paiement |
| Recevoir | `LucideIcons.arrowDownLeft` | CTA encaissement |
| NFC | `LucideIcons.wifi` (rotation 45°) | Mode NFC actif |
| QR Code | `LucideIcons.qrCode` | Fallback QR |
| Wallet | `LucideIcons.wallet` | Nav bottom |
| Historique | `LucideIcons.clock` | Nav bottom |
| Profil | `LucideIcons.user` | Nav bottom |
| Recharger | `LucideIcons.plus` | Action recharge |
| Sync | `LucideIcons.refreshCw` | Télécollecte |
| Offline | `LucideIcons.wifiOff` | Badge offline |
| Biométrie | `LucideIcons.fingerprint` | Auth biométrique |
| Succès | `LucideIcons.checkCircle2` | Confirmation |
| Erreur | `LucideIcons.xCircle` | Échec |

---

## 7. Composants — Atomes

### 7.1 Bouton primaire (CTA)

```
┌─────────────────────────────────┐
│  ●  Envoyer de l'argent         │  h=52dp, radius=12dp
└─────────────────────────────────┘
  bg: accent (#00E5A0)
  text: textInverse (#0D0F14), Inter 600 15sp
  icon: 20dp, left avec gap 8dp
  shadow: ctaButton (glow vert)
  pressed: opacity 0.85 + scale 0.98
  disabled: opacity 0.30, no shadow
```

```dart
// Implémentation Flutter
class VireloPrimaryButton extends StatelessWidget {
  final String    label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool      isLoading;

  const VireloPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: onPressed != null ? AppShadows.ctaButton : null,
      ),
      child: Material(
        color: onPressed != null
          ? AppColors.accent
          : AppColors.accent.withOpacity(0.30),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: isLoading ? null : onPressed,
          child: SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: isLoading
                ? const Center(
                    child: SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textInverse,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 20, color: AppColors.textInverse),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Text(
                        label,
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.textInverse,
                        ),
                      ),
                    ],
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
```

### 7.2 Bouton secondaire

```
┌─────────────────────────────────┐
│  ●  Demander de l'argent        │  h=52dp, radius=12dp
└─────────────────────────────────┘
  bg: surfaceCard (#1C2030)
  border: surfaceBorder (#252A38), 1dp
  text: textPrimary, Inter 600 15sp
  pressed: bg → surfaceBorder
```

### 7.3 Bouton action rapide (icône + label)

```
    ┌────────┐
    │   ↗    │   44×44dp, radius=12dp
    └────────┘
    Envoyer
  
  bg: surfaceCard
  icon: accent, 22dp
  label: Inter 500 12sp, textSecondary
  pressed: bg → surfaceBorder
```

```dart
class VireloActionButton extends StatelessWidget {
  final IconData icon;
  final String   label;
  final VoidCallback? onPressed;
  final Color?   iconColor;

  const VireloActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Icon(
              icon,
              size: 22,
              color: iconColor ?? AppColors.accent,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          )),
        ],
      ),
    );
  }
}
```

### 7.4 Badge

```dart
// Variants : success | warning | error | info | offline

class VireloBadge extends StatelessWidget {
  final String  label;
  final BadgeVariant variant;

  const VireloBadge({super.key, required this.label, required this.variant});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (variant) {
      BadgeVariant.success => (AppColors.successMuted,  AppColors.success),
      BadgeVariant.warning => (AppColors.warningMuted,  AppColors.warning),
      BadgeVariant.error   => (AppColors.errorMuted,    AppColors.error),
      BadgeVariant.info    => (AppColors.infoMuted,     AppColors.info),
      BadgeVariant.offline => (AppColors.warningMuted,  AppColors.warning),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5, height: 5,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

enum BadgeVariant { success, warning, error, info, offline }
```

### 7.5 Champ de texte

```
┌─────────────────────────────────┐
│ 🔍  Rechercher une transaction  │  h=48dp, radius=12dp
└─────────────────────────────────┘
  bg: surfaceCard (#1C2030)
  border-normal: transparent
  border-focus: accent 1.5dp
  text: Inter 400 15sp, textPrimary
  hint: textTertiary
  prefix-icon: textTertiary, 18dp
```

```dart
class VireloTextField extends StatelessWidget {
  final String        hint;
  final IconData?     prefixIcon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String?       Function(String?)? validator;
  final void Function(String)? onChanged;

  const VireloTextField({
    super.key,
    required this.hint,
    this.prefixIcon,
    this.controller,
    this.keyboardType,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:   controller,
      keyboardType: keyboardType,
      validator:    validator,
      onChanged:    onChanged,
      style: AppTextStyles.bodyLarge,
      decoration: InputDecoration(
        hintText:  hint,
        hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textTertiary),
        filled:    true,
        fillColor: AppColors.surfaceCard,
        prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 18, color: AppColors.textTertiary)
          : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }
}
```

### 7.6 Avatar

```dart
class VireloAvatar extends StatelessWidget {
  final String?    imageUrl;
  final String?    initials;  // Fallback si pas d'image
  final double     size;
  final bool       isOnline;

  const VireloAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = 44,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.surfaceBorder, width: 1),
            image: imageUrl != null
              ? DecorationImage(
                  image: NetworkImage(imageUrl!),
                  fit: BoxFit.cover,
                )
              : null,
          ),
          child: imageUrl == null
            ? Center(
                child: Text(
                  initials ?? '?',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : null,
        ),
        if (isOnline)
          Positioned(
            right: 1, bottom: 1,
            child: Container(
              width: size * 0.26,
              height: size * 0.26,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}
```

---

## 8. Composants — Molécules

### 8.1 Carte Solde Hero

```
┌─────────────────────────────────────────┐
│  Bonjour Eliott 👋          [⚙]  [🔔]  │  ← 24dp padding
│  Votre portefeuille                     │
│                                         │
│  🇨🇮 XOF                                │
│  12 329 ,50                             │  ← displayLarge + displaySmall
│                                         │
│  [+4,2% ce mois]                        │  ← VireloBadge success
│                                         │
│  ──────────────────────────────────── │
│                                         │
│  [↗ Envoyer]  [⟳]  [↙ Recevoir]       │  ← 3 VireloActionButton
│                                         │
└─────────────────────────────────────────┘
  bg: surfaceHero
  radius: 20dp
  shadow: heroCard (glow vert subtil)
  padding: 24dp
```

```dart
class WalletHeroCard extends StatelessWidget {
  final double  balance;
  final double  variation;     // ex: 4.2 (%)
  final bool    isOffline;
  final bool    isBalanceHidden;
  final VoidCallback onToggleBalance;
  final VoidCallback onSend;
  final VoidCallback onReceive;
  final VoidCallback onExchange;

  const WalletHeroCard({
    super.key,
    required this.balance,
    required this.variation,
    required this.isOffline,
    required this.isBalanceHidden,
    required this.onToggleBalance,
    required this.onSend,
    required this.onReceive,
    required this.onExchange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppShadows.heroCard,
        border: Border.all(color: AppColors.surfaceBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête ─────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Portefeuille', style: AppTextStyles.labelMedium),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Text('🇨🇮  ', style: TextStyle(fontSize: 14)),
                        Text('XOF', style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w600,
                        )),
                      ],
                    ),
                  ],
                ),
              ),
              if (isOffline) ...[
                const VireloBadge(label: 'Hors ligne', variant: BadgeVariant.offline),
                const SizedBox(width: AppSpacing.sm),
              ],
              GestureDetector(
                onTap: onToggleBalance,
                child: Icon(
                  isBalanceHidden
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Montant ─────────────────────────────────────────
          if (isBalanceHidden)
            Text('••••••', style: AppTextStyles.displayLarge.copyWith(
              letterSpacing: 8,
            ))
          else
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: AmountFormatter.formatWhole(balance),
                    style: AppTextStyles.displayLarge,
                  ),
                  TextSpan(
                    text: ',${((balance - balance.floorToDouble()) * 100).round().toString().padLeft(2, '0')}',
                    style: AppTextStyles.displayMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: AppSpacing.md),

          // ── Badge variation ─────────────────────────────────
          VireloBadge(
            label: AmountFormatter.formatVariation(variation),
            variant: variation >= 0
              ? BadgeVariant.success
              : BadgeVariant.error,
          ),

          const SizedBox(height: AppSpacing.xxl),

          // ── Séparateur ──────────────────────────────────────
          Divider(color: AppColors.surfaceBorder, height: 1),

          const SizedBox(height: AppSpacing.xl),

          // ── Actions rapides ──────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              VireloActionButton(
                icon: Icons.arrow_upward_rounded,
                label: 'Envoyer',
                onPressed: onSend,
              ),
              VireloActionButton(
                icon: Icons.swap_horiz_rounded,
                label: 'Convertir',
                onPressed: onExchange,
                iconColor: AppColors.info,
              ),
              VireloActionButton(
                icon: Icons.arrow_downward_rounded,
                label: 'Recevoir',
                onPressed: onReceive,
                iconColor: AppColors.accent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

### 8.2 Tuile de transaction

```
┌──────────────────────────────────────────┐
│  [Avatar]  Dribbbia               -15 XOF│  ← h=64dp
│  [●  NFC]  Hier · 14:32                  │  ← badgeVariant + date
└──────────────────────────────────────────┘
  padding: 12dp vertical, 0 horizontal
  séparateur: Divider 0.5dp surfaceBorder
```

```dart
class TransactionTile extends StatelessWidget {
  final String  name;
  final String  date;
  final double  amount;
  final bool    isCredit;     // true = reçu, false = envoyé
  final String? avatarUrl;
  final String  method;       // 'NFC' | 'QR' | 'CARTE' | 'RECHARGE'

  const TransactionTile({
    super.key,
    required this.name,
    required this.date,
    required this.amount,
    required this.isCredit,
    this.avatarUrl,
    required this.method,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Avatar
          VireloAvatar(imageUrl: avatarUrl, initials: name[0], size: 42),
          const SizedBox(width: AppSpacing.md),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.labelLarge),
                const SizedBox(height: 3),
                Row(
                  children: [
                    VireloBadge(
                      label: method,
                      variant: BadgeVariant.info,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(date, style: AppTextStyles.bodySmall),
                  ],
                ),
              ],
            ),
          ),

          // Montant
          Text(
            '${isCredit ? '+' : '-'}${AmountFormatter.formatFull(amount)}',
            style: AppTextStyles.displaySmall.copyWith(
              color: isCredit ? AppColors.success : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
```

### 8.3 Carte NFC active (côté marchand)

```
┌─────────────────────────────────────────────┐
│                                             │
│         ○  ○  ○    ← 3 anneaux pulse       │
│        ○ [NFC] ○   ← icône centrale 72dp   │
│         ○  ○  ○                             │
│                                             │
│    NFC actif                                │  ← labelLarge, textPrimary
│    Approchez le téléphone du client         │  ← bodyMedium, textSecondary
│                                             │
│    ┌────────────────────────────────────┐   │
│    │  500 XOF                           │   │  ← surfaceCard, radius 12dp
│    └────────────────────────────────────┘   │
│                                             │
│    [Basculer en QR Code]                    │  ← bouton secondaire
│                                             │
└─────────────────────────────────────────────┘
  bg: surfaceHero  |  radius: 24dp
  Anneaux: AppColors.nfcPulse, voir §12 NfcPulseAnimation
```

```dart
// lib/features/transfer/presentation/widgets/nfc_active_card.dart

class NfcActiveCard extends StatelessWidget {
  final double       amount;
  final bool         isListening;
  final VoidCallback onSwitchToQr;
  final VoidCallback onCancel;

  const NfcActiveCard({
    super.key,
    required this.amount,
    required this.isListening,
    required this.onSwitchToQr,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.surfaceHero,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceBorder, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Animation NFC ────────────────────────────────────
          NfcPulseAnimation(isActive: isListening),

          const SizedBox(height: AppSpacing.xl),

          // ── Statut ───────────────────────────────────────────
          Text(
            isListening ? 'NFC actif' : 'NFC en attente...',
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isListening
              ? 'Approchez le téléphone du client'
              : 'Activation en cours...',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Montant à encaisser ──────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.surfaceBorder, width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('À encaisser', style: AppTextStyles.labelMedium),
                Text(
                  AmountFormatter.formatFull(amount),
                  style: AppTextStyles.displaySmall.copyWith(
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Fallback QR ──────────────────────────────────────
          OutlinedButton.icon(
            onPressed: onSwitchToQr,
            icon: const Icon(Icons.qr_code, size: 18),
            label: const Text('Client sans NFC ? Afficher un QR'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### 8.4 QR Code display (côté client)

```
┌──────────────────────────────────────────┐
│                                          │
│  ┌────────────────────────────────────┐  │
│  │  ▐█▌ ▄▄▄ ▐█▌                      │  │
│  │  █ █ █ █ █ █   QR chiffré AES-256 │  │
│  │  ▐█▌ ▀▀▀ ▐█▌                      │  │
│  └────────────────────────────────────┘  │
│                                          │
│  Montrez ce QR au marchand               │  ← bodyMedium, centré
│  Valable 90 secondes   [●●●●●●●●○○]     │  ← timer + progress bar
│                                          │
│  [Actualiser]                            │  ← si expiré
│                                          │
└──────────────────────────────────────────┘
  bg: surfaceCard  |  radius: 20dp
  QR: fond blanc, modules accent (#00E5A0), yeux primaryDark
  Timer bar: accent → error au fil du temps
```

```dart
// lib/features/transfer/presentation/widgets/qr_display_card.dart

class QrDisplayCard extends StatefulWidget {
  final String       encryptedData;  // payload AES-256
  final double       amount;
  final int          expirySeconds;  // 90s par défaut
  final VoidCallback onExpired;
  final VoidCallback onRefresh;

  const QrDisplayCard({
    super.key,
    required this.encryptedData,
    required this.amount,
    this.expirySeconds = 90,
    required this.onExpired,
    required this.onRefresh,
  });

  @override
  State<QrDisplayCard> createState() => _QrDisplayCardState();
}

class _QrDisplayCardState extends State<QrDisplayCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _timerCtrl;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _timerCtrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.expirySeconds),
    )
      ..forward()
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _isExpired = true);
          widget.onExpired();
        }
      });
  }

  @override
  void dispose() {
    _timerCtrl.dispose();
    super.dispose();
  }

  /// Couleur de la barre de progression : vert → orange → rouge
  Color _timerColor(double progress) {
    if (progress < 0.5) return AppColors.accent;
    if (progress < 0.8) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.surfaceBorder, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── En-tête ──────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Code de paiement', style: AppTextStyles.labelLarge),
              VireloBadge(label: 'QR', variant: BadgeVariant.info),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── QR Code ──────────────────────────────────────────
          AnimatedOpacity(
            opacity: _isExpired ? 0.2 : 1.0,
            duration: AppDurations.standard,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: QrImageView(
                data: widget.encryptedData,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF0D0F14),
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Montant ──────────────────────────────────────────
          Text(
            AmountFormatter.formatFull(widget.amount),
            style: AppTextStyles.displayMedium,
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Timer bar ────────────────────────────────────────
          if (!_isExpired)
            AnimatedBuilder(
              animation: _timerCtrl,
              builder: (_, __) {
                final remaining = (1 - _timerCtrl.value);
                final secs = (remaining * widget.expirySeconds).round();
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Valable encore',
                          style: AppTextStyles.bodySmall,
                        ),
                        Text(
                          '${secs}s',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: _timerColor(_timerCtrl.value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      child: LinearProgressIndicator(
                        value: remaining,
                        minHeight: 4,
                        backgroundColor: AppColors.surfaceBorder,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _timerColor(_timerCtrl.value),
                        ),
                      ),
                    ),
                  ],
                );
              },
            )
          else
            // ── QR expiré ────────────────────────────────────
            Column(
              children: [
                const VireloBadge(label: 'Expiré', variant: BadgeVariant.error),
                const SizedBox(height: AppSpacing.md),
                VireloPrimaryButton(
                  label: 'Générer un nouveau code',
                  icon: Icons.refresh,
                  onPressed: () {
                    setState(() => _isExpired = false);
                    _timerCtrl.reset();
                    _timerCtrl.forward();
                    widget.onRefresh();
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}
```

---

### 8.5 Sélecteur de mode de paiement

```
┌──────────────────────────────────────────┐
│  [📶 NFC]          [▣ QR Code]           │  ← SegmentedControl
│  ●──────────────────────────────────○    │  ← tab active = accent bg
└──────────────────────────────────────────┘
  h=44dp, radius=12dp
  tab active: bg accentMuted, border accent 1dp, text accent
  tab inactive: bg surfaceCard, text textTertiary
```

```dart
// lib/features/transfer/presentation/widgets/payment_mode_selector.dart

enum PaymentMode { nfc, qr }

class PaymentModeSelector extends StatelessWidget {
  final PaymentMode selected;
  final void Function(PaymentMode) onChanged;

  const PaymentModeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.surfaceBorder, width: 0.5),
      ),
      child: Row(
        children: [
          _Tab(
            icon:     Icons.wifi,          // NFC stylisé
            label:    'NFC',
            isActive: selected == PaymentMode.nfc,
            onTap:    () => onChanged(PaymentMode.nfc),
          ),
          _Tab(
            icon:     Icons.qr_code_2,
            label:    'QR Code',
            isActive: selected == PaymentMode.qr,
            onTap:    () => onChanged(PaymentMode.qr),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final IconData icon;
  final String   label;
  final bool     isActive;
  final VoidCallback onTap;

  const _Tab({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          decoration: BoxDecoration(
            color: isActive ? AppColors.accentMuted : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: isActive ? AppColors.accent : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? AppColors.accent : AppColors.textTertiary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isActive ? AppColors.accent : AppColors.textTertiary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### 8.6 Scanner QR (côté marchand)

```
┌──────────────────────────────────────────┐
│                                          │
│  ╔══════════════════════════════════╗    │
│  ║                                  ║    │
│  ║    [Viseur animé — coins vert]   ║    │  ← viewfinder
│  ║                                  ║    │
│  ╚══════════════════════════════════╝    │
│                                          │
│  Scannez le QR Code du client           │  ← bodyMedium centré
│  [──────────────── ou ────────────────]  │
│  [Saisir le code manuellement]           │  ← textButton
│                                          │
└──────────────────────────────────────────┘
  Overlay de scan : fond semi-transparent
  Coins du viewfinder : AppColors.accent, 3dp, 20dp longueur
  Animation de scan : ligne horizontale qui descend (accent, blur)
```

```dart
// lib/features/transfer/presentation/widgets/qr_scanner_widget.dart

class QrScannerWidget extends StatefulWidget {
  final void Function(String code) onDetected;

  const QrScannerWidget({super.key, required this.onDetected});

  @override
  State<QrScannerWidget> createState() => _QrScannerWidgetState();
}

class _QrScannerWidgetState extends State<QrScannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanCtrl;
  late Animation<double>   _scanLine;
  bool _detected = false;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLine = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      onDetect: (capture) {
        if (_detected) return;
        final barcode = capture.barcodes.firstOrNull;
        if (barcode?.rawValue != null) {
          _detected = true;
          _scanCtrl.stop();
          widget.onDetected(barcode!.rawValue!);
        }
      },
      overlay: _ScannerOverlay(scanLineAnimation: _scanLine),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  final Animation<double> scanLineAnimation;

  const _ScannerOverlay({required this.scanLineAnimation});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fond semi-transparent hors viewfinder
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            AppColors.background.withOpacity(0.7),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(color: Colors.transparent),
              Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Coins du viewfinder
        Center(
          child: SizedBox(
            width: 240,
            height: 240,
            child: CustomPaint(painter: _ViewfinderPainter()),
          ),
        ),

        // Ligne de scan animée
        Center(
          child: SizedBox(
            width: 220,
            height: 220,
            child: AnimatedBuilder(
              animation: scanLineAnimation,
              builder: (_, __) => Align(
                alignment: Alignment(0, scanLineAnimation.value * 2 - 1),
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.accent,
                        AppColors.accent,
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.2, 0.8, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLen = 24.0;
    const r = 12.0;

    // Coin haut-gauche
    canvas.drawLine(Offset(r, 0), Offset(cornerLen, 0), paint);
    canvas.drawLine(Offset(0, r), Offset(0, cornerLen), paint);
    canvas.drawArc(const Rect.fromLTWH(0, 0, r * 2, r * 2), 
      3.14159, 3.14159 / 2, false, paint);

    // Coin haut-droit
    canvas.drawLine(Offset(size.width - cornerLen, 0), Offset(size.width - r, 0), paint);
    canvas.drawLine(Offset(size.width, r), Offset(size.width, cornerLen), paint);
    canvas.drawArc(Rect.fromLTWH(size.width - r * 2, 0, r * 2, r * 2),
      -3.14159 / 2, 3.14159 / 2, false, paint);

    // Coin bas-gauche
    canvas.drawLine(Offset(0, size.height - cornerLen), Offset(0, size.height - r), paint);
    canvas.drawLine(Offset(r, size.height), Offset(cornerLen, size.height), paint);
    canvas.drawArc(Rect.fromLTWH(0, size.height - r * 2, r * 2, r * 2),
      3.14159 / 2, 3.14159 / 2, false, paint);

    // Coin bas-droit
    canvas.drawLine(Offset(size.width, size.height - cornerLen),
      Offset(size.width, size.height - r), paint);
    canvas.drawLine(Offset(size.width - cornerLen, size.height),
      Offset(size.width - r, size.height), paint);
    canvas.drawArc(
      Rect.fromLTWH(size.width - r * 2, size.height - r * 2, r * 2, r * 2),
      0, 3.14159 / 2, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

---

## 9. Composants — Organismes

### 9.1 Bottom Navigation

```
┌────────────────────────────────────────────┐
│  [💼 Wallet]    [🕐 Activité]   [👤 Profil]│  h=60dp + safeArea
└────────────────────────────────────────────┘
  bg: surfaceHero
  top-border: surfaceBorder 0.5dp
  icône active: accent + dot indicator 4dp
  icône inactive: textTertiary
  label actif: Inter 500 11sp accent
  label inactif: Inter 400 11sp textTertiary
```

```dart
class VireloBottomNav extends StatelessWidget {
  final int         currentIndex;
  final void Function(int) onTap;

  const VireloBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    (Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, 'Wallet'),
    (Icons.access_time_outlined, Icons.access_time_filled, 'Activité'),
    (Icons.person_outline, Icons.person, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceHero,
        border: Border(
          top: BorderSide(color: AppColors.surfaceBorder, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(
              _items.length,
              (i) => Expanded(child: _NavItem(
                icon:     _items[i].$1,
                iconFill: _items[i].$2,
                label:    _items[i].$3,
                isActive: currentIndex == i,
                onTap:    () => onTap(i),
              )),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData iconFill;
  final String   label;
  final bool     isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.iconFill,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? iconFill : icon,
            size: 22,
            color: isActive ? AppColors.accent : AppColors.textTertiary,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? AppColors.accent : AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 2),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isActive ? 4 : 0,
            height: isActive ? 4 : 0,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
```

### 9.2 Bottom Sheet de confirmation de paiement

Utilisée dans **les deux flows** (NFC et QR). Le contenu s'adapte selon la méthode détectée.

```
╔═════════════════════════════════════════╗
║  ─────────  (drag handle)               ║
║                                         ║
║  Confirmer le paiement                  ║  ← headlineMedium
║                                         ║
║  [Avatar]  Koffi Kouamé                 ║  ← VireloAvatar 44dp
║            Marchand GbakaSud            ║  ← bodySmall textSecondary
║                                         ║
║  ┌─────────────────────────────────┐    ║
║  │  5 000 XOF          [● NFC]    │    ║  ← badge méthode dynamique
║  └─────────────────────────────────┘    ║
║                                         ║
║  ┌─────────────────────────────────┐    ║
║  │  Solde après  :  7 329,50 XOF  │    ║  ← surfaceCard, textSecondary
║  └─────────────────────────────────┘    ║
║                                         ║
║  [🖐  Valider avec l'empreinte]         ║  ← CTA accent
║  [Annuler]                              ║  ← TextButton error
║                                         ║
╚═════════════════════════════════════════╝
  bg: surfaceCard  |  radius top: 24dp  |  shadow: modal
  Badge méthode : BadgeVariant.info → "NFC" ou "QR CODE"
```

```dart
// lib/features/transfer/presentation/widgets/payment_confirm_sheet.dart

class PaymentConfirmSheet extends StatelessWidget {
  final String      merchantName;
  final String?     merchantAvatarUrl;
  final double      amount;
  final double      balanceAfter;
  final PaymentMode method;
  final VoidCallback onConfirm;   // déclenche local_auth
  final VoidCallback onCancel;

  const PaymentConfirmSheet({
    super.key,
    required this.merchantName,
    this.merchantAvatarUrl,
    required this.amount,
    required this.balanceAfter,
    required this.method,
    required this.onConfirm,
    required this.onCancel,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String      merchantName,
    String?              merchantAvatarUrl,
    required double      amount,
    required double      balanceAfter,
    required PaymentMode method,
    required VoidCallback onConfirm,
  }) {
    return showModalBottomSheet<bool>(
      context:      context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PaymentConfirmSheet(
        merchantName:      merchantName,
        merchantAvatarUrl: merchantAvatarUrl,
        amount:            amount,
        balanceAfter:      balanceAfter,
        method:            method,
        onConfirm:         onConfirm,
        onCancel:          () => Navigator.pop(context, false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Titre
              Text('Confirmer le paiement',
                style: AppTextStyles.headlineMedium),
              const SizedBox(height: AppSpacing.xxl),

              // Marchand
              Row(
                children: [
                  VireloAvatar(
                    imageUrl: merchantAvatarUrl,
                    initials: merchantName[0],
                    size: 44,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(merchantName, style: AppTextStyles.labelLarge),
                      Text('Marchand', style: AppTextStyles.bodySmall),
                    ],
                  ),
                  const Spacer(),
                  VireloBadge(
                    label: method == PaymentMode.nfc ? 'NFC' : 'QR Code',
                    variant: BadgeVariant.info,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Montant
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHero,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Text(
                  AmountFormatter.formatFull(amount),
                  style: AppTextStyles.displayMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Solde après
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHero,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Solde après', style: AppTextStyles.bodySmall),
                    Text(
                      AmountFormatter.formatFull(balanceAfter),
                      style: AppTextStyles.labelMedium.copyWith(
                        color: balanceAfter >= 0
                          ? AppColors.textPrimary
                          : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // CTA biométrie
              VireloPrimaryButton(
                label: 'Valider avec l\'empreinte',
                icon: Icons.fingerprint,
                onPressed: onConfirm,
              ),
              const SizedBox(height: AppSpacing.md),

              TextButton(
                onPressed: onCancel,
                child: Text(
                  'Annuler',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 10. Écrans — Anatomie

### 10.1 Home (Wallet)

```
StatusBar (dark icons on background)
├── SafeArea top
│   ├── [20dp] AppBar custom
│   │   ├── "Bonjour, [Prénom]" — headlineMedium
│   │   └── [Avatar 32dp] + [Notification 🔔]
│   │
│   ├── [16dp gap]
│   │
│   ├── [0dp H margin] WalletHeroCard
│   │
│   ├── [20dp gap]
│   │
│   ├── [20dp H] Section "Envoyer à nouveau"
│   │   ├── Label row : "Récents" + "Voir tout →"
│   │   └── HorizontalList(AvatarChip × 5)
│   │
│   ├── [20dp gap]
│   │
│   ├── [20dp H] Section "Activité récente"
│   │   ├── Label row : "Activité récente" + "Voir tout →"
│   │   └── ListView(TransactionTile × N)
│   │
│   └── [80dp bottom padding] (éviter la nav)
│
└── VireloBottomNav
```

### 10.2 Paiement NFC (Marchand)

```
AppBar: "Encaisser" + [X fermer]
├── [Champ montant centré]  
│   ├── "500" — displayLarge centré
│   ├── "XOF" — labelMedium, textTertiary
│   └── Clavier numérique custom (bg surfaceCard)
│
├── [Divider]
│
└── NFC Zone (full-width, flex 1)
    ├── NfcPulseWidget (animé, voir §11)
    ├── "Approchez le téléphone du client"  — bodyMedium centré
    └── [Bouton "Afficher QR Code"] — bouton secondaire
```

### 10.3 Auth — Saisie OTP

```
AppBar: ← retour
├── [40dp top]
├── "Code envoyé au" — bodyMedium textSecondary
├── "+225 07 00 00 00 00" — headlineMedium
├── [24dp gap]
│
├── OTP Input (6 cases)
│   ├── Case active: border accent 2dp
│   ├── Case remplie: bg accentMuted
│   └── Case vide: bg surfaceCard
│
├── [32dp gap]
│
├── "Renvoyer le code dans 0:45" — bodySmall
│   (timer countdown, puis lien actif en accent)
│
└── [CTA désactivé jusqu'à 6 chiffres]
    "Vérifier"
```

### 10.4 Succès paiement

```
Plein écran · bg background
├── [Flex center]
│   ├── Lottie ou icône checkCircle 80dp (accent, animé)
│   ├── [16dp]
│   ├── "Paiement envoyé" — headlineLarge
│   ├── "5 000 XOF" — displayMedium
│   ├── [8dp]
│   ├── "à Koffi Kouamé · il y a 2s" — bodyMedium textSecondary
│   └── [Badge success "Via NFC"]
│
└── [bottom 32dp] Deux boutons
    ├── "Voir le reçu" — bouton primaire
    └── "Retour à l'accueil" — bouton secondaire
```

---

## 11. Flows NFC & QR Code — Détail complet

Cette section est le cœur du produit. Elle décrit **les deux flows de paiement** bout en bout — du côté marchand et du côté client — avec les états, les transitions et les composants à afficher à chaque étape.

---

### 11.1 Tableau des cas d'usage

| Situation terrain | Flow client | Flow marchand |
|-------------------|------------|---------------|
| Client avec NFC + réseau | NFC actif → biométrie → paiement direct | Encaissement NFC → confirmation sonore |
| Client avec NFC, sans réseau | NFC actif → biométrie → paiement offline (token local) | Encaissement NFC → stockage SQLite → badge "En attente" |
| Client sans NFC (QR écran) | Affiche QrDisplayCard → montre au marchand | Scanner QR → confirmation → encaissement |
| Client sans smartphone (carte physique RFID) | Carte passive → PIN | Scan carte → demande PIN → encaissement |

---

### 11.2 Flow NFC — Côté marchand (Encaisseur)

```
ÉTAPE 1 — Saisie du montant
════════════════════════════════════════════════════
AppBar: "Encaisser"                     [X]
─────────────────────────────────────────────────────
[24dp top]

  ┌─────────────────────────────────────────┐
  │                                         │
  │         5 0 0                           │  ← displayLarge centré
  │              XOF                        │  ← labelMedium textTertiary
  │                                         │
  └─────────────────────────────────────────┘

  [16dp gap]

  ┌──── Clavier numérique custom ──────────┐
  │   1      2      3                      │
  │   4      5      6                      │
  │   7      8      9                      │
  │   ×      0      ⌫                      │
  └────────────────────────────────────────┘
  bg: surfaceCard, chaque touche h=64dp
  touche ⌫ : textTertiary
  touche × : efface tout

[bottom fixed]
  [Continuer — Encaisser 500 XOF]  ← CTA accent, disabled si montant = 0

════════════════════════════════════════════════════
ÉTAPE 2 — Sélection du mode d'encaissement
════════════════════════════════════════════════════
(seulement si le marchand le souhaite — sinon NFC par défaut)

  PaymentModeSelector  [NFC]  [QR Code]

  → Si NFC sélectionné : → ÉTAPE 3A
  → Si QR sélectionné  : → ÉTAPE 3B

════════════════════════════════════════════════════
ÉTAPE 3A — Attente NFC
════════════════════════════════════════════════════

  NfcActiveCard(
    amount: 500,
    isListening: true,
  )

  États visuels :
  ┌──────────────────────────────────────────┐
  │  En attente...   Anneaux pulse accent    │  ← état initial
  │  Détecté !       Anneaux → flash vert    │  ← NFC détecté
  │  Erreur          Anneaux → flash rouge   │  ← échec HCE
  └──────────────────────────────────────────┘

  Transition : détection NFC → 150ms → ouvrir PaymentConfirmSheet

════════════════════════════════════════════════════
ÉTAPE 4 — Confirmation & biométrie (client)
════════════════════════════════════════════════════

  PaymentConfirmSheet(
    method: PaymentMode.nfc,
    amount: 500,
    balanceAfter: 7329.50,
  )
  → Appui "Valider" → local_auth.authenticate()
  → Succès biométrie → ÉTAPE 5
  → Échec biométrie → shake animation sur le bouton + message inline

════════════════════════════════════════════════════
ÉTAPE 5 — Résultat
════════════════════════════════════════════════════

  → Réseau disponible  : API call → PaymentSuccessPage
  → Pas de réseau      : stockage SQLite → PaymentSuccessPage
                         avec badge "Synchronisation en attente"
```

---

### 11.3 Flow QR Code — Côté client (Payeur)

```
ÉTAPE 1 — Déclencher le QR depuis la Home
════════════════════════════════════════════════════

  WalletHeroCard → bouton "Payer" → ReceiverPaymentPage
  ou : notification NFC non disponible → proposition auto QR

════════════════════════════════════════════════════
ÉTAPE 2 — Saisie du montant (si pas encore saisi)
════════════════════════════════════════════════════

  Même clavier numérique custom que côté marchand
  [Générer le QR Code]  ← CTA accent

════════════════════════════════════════════════════
ÉTAPE 3 — Affichage du QR
════════════════════════════════════════════════════

  QrDisplayCard(
    encryptedData: token_AES256,   ← token généré localement
    amount: 500,
    expirySeconds: 90,
  )

  États :
  ┌────────────────────────────────────────────┐
  │  Actif (0–45s)   barre verte              │
  │  Urgent (45–72s) barre orange             │
  │  Critique (72–90s) barre rouge + pulse    │
  │  Expiré          QR flouté + bouton regen │
  └────────────────────────────────────────────┘

  Comportement :
  - Luminosité écran → 100% automatiquement
  - Rotation bloquée en portrait
  - Retour arrière désactivé pendant l'affichage

════════════════════════════════════════════════════
ÉTAPE 4 — Confirmation biométrie (côté client)
════════════════════════════════════════════════════

  Dès que le marchand scanne :
  → Le téléphone client reçoit une notification locale
  → PaymentConfirmSheet(method: PaymentMode.qr) s'ouvre
  → Même flow biométrie que NFC

════════════════════════════════════════════════════
ÉTAPE 5 — Résultat
════════════════════════════════════════════════════

  Même PaymentSuccessPage que flow NFC
  Badge différent : "Via QR Code"
```

---

### 11.4 Flow QR Code — Côté marchand (Scanner)

```
ÉTAPE 1 — Basculer en mode scan
════════════════════════════════════════════════════

  Sur NfcActiveCard → [Client sans NFC ? Afficher un QR]
  → Transition animée → QrScannerPage

════════════════════════════════════════════════════
ÉTAPE 2 — Scan
════════════════════════════════════════════════════

  QrScannerWidget(
    onDetected: (code) { ... }
  )

  États du scanner :
  ┌──────────────────────────────────────────┐
  │  Cherche...    Ligne verte descend       │  ← searching
  │  Trouvé !      Flash vert + bip sonore   │  ← detected (200ms)
  │  QR invalide   Flash rouge + message     │  ← invalid token
  │  QR expiré     Bande rouge + message     │  ← expired
  └──────────────────────────────────────────┘

  En cas de QR invalide ou expiré :
  SnackBar error : "Code invalide — demandez au client d'en générer un nouveau"
  Scanner reste actif pour un nouveau scan

════════════════════════════════════════════════════
ÉTAPE 3 — Validation locale du token
════════════════════════════════════════════════════

  1. Déchiffrement AES-256 du payload
  2. Vérification : montant cohérent, token non utilisé, non expiré
  3. Si valide → PaymentConfirmSheet(method: PaymentMode.qr)
  4. Si invalide → retour scanner avec message d'erreur

════════════════════════════════════════════════════
ÉTAPE 4 — Encaissement
════════════════════════════════════════════════════

  Identique à flow NFC côté marchand :
  → Réseau : API call immédiat
  → Offline : stockage SQLite + badge "En attente"
```

---

### 11.5 Écran — Paiement NFC (page complète côté marchand)

```dart
// lib/features/transfer/presentation/pages/receive_payment_page.dart

class ReceivePaymentPage extends StatefulWidget {
  const ReceivePaymentPage({super.key});

  @override
  State<ReceivePaymentPage> createState() => _ReceivePaymentPageState();
}

class _ReceivePaymentPageState extends State<ReceivePaymentPage> {
  final _amountBuffer = StringBuffer();
  double   _amount = 0;
  PaymentMode _mode = PaymentMode.nfc;
  bool     _nfcListening = false;

  // ── Clavier numérique ───────────────────────────────────────
  void _onKey(String key) {
    setState(() {
      if (key == '⌫') {
        if (_amountBuffer.isNotEmpty) {
          final s = _amountBuffer.toString();
          _amountBuffer.clear();
          _amountBuffer.write(s.substring(0, s.length - 1));
        }
      } else if (key == '×') {
        _amountBuffer.clear();
      } else if (_amountBuffer.length < 7) {
        _amountBuffer.write(key);
      }
      _amount = double.tryParse(_amountBuffer.toString()) ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TransferBloc>(),
      child: BlocConsumer<TransferBloc, TransferState>(
        listener: (ctx, state) {
          if (state is TransferSuccess) {
            NfcManager.instance.stopSession();
            setState(() => _nfcListening = false);
            context.pushReplacement(
              RouteNames.paymentSuccess,
              extra: state.transaction,
            );
          }
          if (state is TransferError) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ));
          }
        },
        builder: (context, state) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Encaisser'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => context.pop(),
            ),
            actions: [
              // Indicateur offline
              StreamBuilder<bool>(
                stream: sl<ConnectivityService>().onConnectivityChanged,
                builder: (_, snap) {
                  final online = snap.data ?? true;
                  if (online) return const SizedBox.shrink();
                  return const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: VireloBadge(
                      label: 'Hors ligne',
                      variant: BadgeVariant.offline,
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // ── Montant ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  children: [
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: _amountBuffer.isEmpty
                            ? '0'
                            : AmountFormatter.formatWhole(_amount),
                          style: AppTextStyles.displayLarge,
                        ),
                        const TextSpan(
                          text: '  XOF',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Sélecteur de mode ──────────────────────
                    PaymentModeSelector(
                      selected: _mode,
                      onChanged: (m) {
                        if (_nfcListening) {
                          NfcManager.instance.stopSession();
                        }
                        setState(() {
                          _mode = m;
                          _nfcListening = false;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const Divider(height: 32, indent: 24, endIndent: 24),

              // ── Zone NFC ou Scanner ──────────────────────────
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppDurations.standard,
                  child: _mode == PaymentMode.nfc
                    ? _NfcSection(
                        key: const ValueKey('nfc'),
                        amount:      _amount,
                        isListening: _nfcListening,
                        isEnabled:   _amount > 0,
                        onToggle:    _amount > 0
                          ? () => _nfcListening
                            ? _stopNfc()
                            : _startNfc(context)
                          : null,
                        onSwitchQr:  () => setState(() {
                          _mode = PaymentMode.qr;
                          if (_nfcListening) _stopNfc();
                        }),
                      )
                    : _QrScanSection(
                        key: const ValueKey('qr'),
                        onDetected: (code) => _processQrPayment(context, code),
                      ),
                ),
              ),
            ],
          ),

          // ── Clavier numérique (affiché si NFC non actif) ───
          bottomSheet: !_nfcListening && _mode == PaymentMode.nfc
            ? _NumericKeypad(onKey: _onKey)
            : null,
        ),
      ),
    );
  }

  void _startNfc(BuildContext context) {
    setState(() => _nfcListening = true);
    NfcManager.instance.startSession(
      onDiscovered: (tag) async {
        final id = tag.data['nfca']?['identifier'] as List<int>?;
        if (id != null) {
          final clientId = id
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join(':');
          // Ouvrir bottom sheet de confirmation
          final confirmed = await PaymentConfirmSheet.show(
            context,
            merchantName:  'Mon Commerce',
            amount:        _amount,
            balanceAfter:  0, // TODO : récupérer du wallet
            method:        PaymentMode.nfc,
            onConfirm:     () {},
          );
          if (confirmed == true) {
            context.read<TransferBloc>().add(InitiateNfcPayment(
              merchantId: 'MERCHANT_ID',
              clientId:   clientId,
              amount:     _amount,
            ));
          }
        }
      },
    );
  }

  void _stopNfc() {
    NfcManager.instance.stopSession();
    setState(() => _nfcListening = false);
  }

  void _processQrPayment(BuildContext context, String rawCode) {
    // 1. Déchiffrer le token QR
    // 2. Valider (non expiré, montant cohérent)
    // 3. Ouvrir PaymentConfirmSheet
    // 4. Lancer le use case
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }
}

// ── Sous-widgets de la page ──────────────────────────────────

class _NfcSection extends StatelessWidget {
  final double       amount;
  final bool         isListening;
  final bool         isEnabled;
  final VoidCallback? onToggle;
  final VoidCallback  onSwitchQr;

  const _NfcSection({
    super.key,
    required this.amount,
    required this.isListening,
    required this.isEnabled,
    required this.onToggle,
    required this.onSwitchQr,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          NfcPulseAnimation(isActive: isListening),
          const SizedBox(height: AppSpacing.xl),
          Text(
            isListening
              ? 'Approchez le téléphone du client'
              : isEnabled
                ? 'Appuyez pour activer le NFC'
                : 'Saisissez un montant d\'abord',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          VireloPrimaryButton(
            label: isListening ? 'Annuler' : 'Activer le NFC',
            icon:  isListening ? Icons.close : Icons.nfc,
            onPressed: onToggle,
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: onSwitchQr,
            icon:  const Icon(Icons.qr_code_2, size: 18),
            label: const Text('Client sans NFC ? Scanner un QR'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
        ],
      ),
    );
  }
}

class _QrScanSection extends StatelessWidget {
  final void Function(String) onDetected;

  const _QrScanSection({super.key, required this.onDetected});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        QrScannerWidget(onDetected: onDetected),
        Positioned(
          bottom: 24,
          left: 24,
          right: 24,
          child: Text(
            'Scannez le QR Code affiché\nsur le téléphone du client',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _NumericKeypad extends StatelessWidget {
  final void Function(String) onKey;

  const _NumericKeypad({required this.onKey});

  static const _keys = [
    ['1','2','3'],
    ['4','5','6'],
    ['7','8','9'],
    ['×','0','⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceCard,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _keys.map((row) => Row(
          children: row.map((k) => Expanded(
            child: GestureDetector(
              onTap: () => onKey(k),
              child: Container(
                height: 60,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: (k == '⌫' || k == '×')
                    ? AppColors.surfaceBorder
                    : AppColors.surfaceHero,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Center(
                  child: Text(
                    k,
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: (k == '⌫' || k == '×')
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          )).toList(),
        )).toList(),
      ),
    );
  }
}
```

---

### 11.6 Écran — QR Code client (page complète côté payeur)

```dart
// lib/features/transfer/presentation/pages/send_qr_page.dart

class SendQrPage extends StatefulWidget {
  final double amount;
  const SendQrPage({super.key, required this.amount});

  @override
  State<SendQrPage> createState() => _SendQrPageState();
}

class _SendQrPageState extends State<SendQrPage> {
  late String _token;
  bool        _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _generateToken();
    // Passer la luminosité à 100% pendant l'affichage
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
    ));
  }

  Future<void> _generateToken() async {
    setState(() => _isGenerating = true);
    final crypto = sl<CryptoUtils>();
    final payload = jsonEncode({
      'client_id': 'USER_ID', // TODO : depuis le wallet
      'amount':    widget.amount,
      'ts':        DateTime.now().millisecondsSinceEpoch,
      'nonce':     const Uuid().v4(),
    });
    _token = await crypto.encrypt(payload);
    setState(() => _isGenerating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payer par QR Code'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            children: [
              Text(
                'Montrez ce code au marchand',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ── QR ou spinner ────────────────────────────────
              Expanded(
                child: Center(
                  child: _isGenerating
                    ? const CircularProgressIndicator(
                        color: AppColors.accent,
                      )
                    : QrDisplayCard(
                        encryptedData: _token,
                        amount:        widget.amount,
                        expirySeconds: 90,
                        onExpired:     () {/* handled internally */},
                        onRefresh:     _generateToken,
                      ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Info offline ─────────────────────────────────
              StreamBuilder<bool>(
                stream: sl<ConnectivityService>().onConnectivityChanged,
                builder: (_, snap) {
                  final online = snap.data ?? true;
                  if (online) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.warningMuted,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.wifi_off,
                          size: 16, color: AppColors.warning),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Hors ligne — le paiement sera synchronisé '
                            'dès le retour du réseau',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### 11.7 Récapitulatif des composants par flow

| Composant | Flow NFC | Flow QR Client | Flow QR Marchand |
|-----------|----------|----------------|-----------------|
| `PaymentModeSelector` | ✅ sélection | — | ✅ sélection |
| `NfcActiveCard` | ✅ attente tap | — | — |
| `NfcPulseAnimation` | ✅ dans NfcActiveCard | — | — |
| `QrDisplayCard` | — | ✅ affichage | — |
| `QrScannerWidget` | — | — | ✅ scan |
| `_ViewfinderPainter` | — | — | ✅ dans scanner |
| `PaymentConfirmSheet` | ✅ biométrie | ✅ biométrie | ✅ biométrie |
| `_NumericKeypad` | ✅ saisie montant | ✅ saisie montant | ✅ saisie montant |
| `VireloBadge` offline | ✅ AppBar | ✅ banner bas | ✅ AppBar |
| `TransactionTile` | ✅ historique | ✅ historique | ✅ historique |

---

## 12. Animations & motion

### 11.1 Système de durées

```dart
class AppDurations {
  AppDurations._();

  static const Duration instant    = Duration(milliseconds:  80); // Feedback tactile
  static const Duration fast       = Duration(milliseconds: 150); // Boutons, chips
  static const Duration standard   = Duration(milliseconds: 250); // Transitions UI
  static const Duration emphasized = Duration(milliseconds: 400); // Page transitions
  static const Duration slow       = Duration(milliseconds: 600); // Révélations
  static const Duration pulse      = Duration(seconds: 2);        // NFC pulsation
}
```

### 11.2 Courbes recommandées

```dart
class AppCurves {
  AppCurves._();

  static const Curve standard  = Curves.easeInOut;
  static const Curve enter     = Curves.easeOut;
  static const Curve exit      = Curves.easeIn;
  static const Curve spring    = Curves.elasticOut; // Pour les succès
  static const Curve decelerate = Curves.decelerate;
}
```

### 11.3 Animation NFC Pulse

```dart
class NfcPulseAnimation extends StatefulWidget {
  final bool isActive;
  const NfcPulseAnimation({super.key, required this.isActive});

  @override
  State<NfcPulseAnimation> createState() => _NfcPulseAnimationState();
}

class _NfcPulseAnimationState extends State<NfcPulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;
  late Animation<double>   _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppDurations.pulse,
    );
    _scale = Tween<double>(begin: 0.8, end: 1.4).animate(
      CurvedAnimation(parent: _ctrl, curve: AppCurves.decelerate),
    );
    _opacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    if (widget.isActive) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(NfcPulseAnimation old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.isActive && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160, height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 3 anneaux de pulse décalés
          for (int i = 0; i < 3; i++)
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                final delay = i / 3;
                final t = (_ctrl.value + delay) % 1.0;
                return Opacity(
                  opacity: (1 - t) * (widget.isActive ? 0.5 : 0),
                  child: Transform.scale(
                    scale: 0.5 + t * 1.0,
                    child: Container(
                      width: 160, height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accent,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          // Icône centrale
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.accentMuted,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent, width: 1.5),
            ),
            child: const Icon(Icons.nfc, size: 36, color: AppColors.accent),
          ),
        ],
      ),
    );
  }
}
```

### 11.4 Transition de page

```dart
// lib/config/routes/page_transitions.dart

Page<T> vireloPage<T>(Widget child, GoRouterState state) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppDurations.emphasized,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: AppCurves.enter).animate(animation),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(CurveTween(curve: AppCurves.enter).animate(animation)),
          child: child,
        ),
      );
    },
  );
}
```

### 11.5 Feedback succès (montant)

```dart
// Animation du montant qui "saute" après paiement réussi
class AmountSuccessAnimation extends StatefulWidget { /* ... */ }
// Séquence :
// 0ms   → scale 1.0, color textPrimary
// 100ms → scale 1.15, color accent
// 300ms → scale 1.0, color accent
// Usage: sur la page PaymentSuccess, le montant pulse une fois
```

---

## 12. États & feedback

### 12.1 États des composants

| État | Traitement visuel |
|------|------------------|
| Default | Couleurs nominales |
| Hover (desktop) | bg +5% luminosité |
| Pressed | opacity 0.85 + scale 0.98, duration 80ms |
| Focused | border accent 2dp |
| Disabled | opacity 0.35, cursor not-allowed |
| Loading | Spinner CPI 20dp blanc, contenu masqué |
| Error | border error + texte d'erreur sous le champ |
| Success | border success + icône ✓ |

### 12.2 Messages d'erreur

```dart
// Convention : jamais de SnackBar pour les erreurs de formulaire.
// Toujours inline, sous le champ concerné.

// Pour les erreurs système (réseau, serveur) : SnackBar bottom
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Row(children: [
      const Icon(Icons.error_outline, color: Colors.white, size: 18),
      const SizedBox(width: 8),
      Text(message, style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
    ]),
    backgroundColor: AppColors.error,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    ),
    duration: const Duration(seconds: 4),
  ),
);
```

### 12.3 État offline

```dart
// Banner offline — affiché en haut de l'écran Home si pas de réseau
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.standard,
      color: AppColors.warningMuted,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, size: 14, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text(
              'Mode hors ligne · Les paiements sont sauvegardés localement',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 13. Implémentation Flutter

### 13.1 ThemeData complet

```dart
// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: const ColorScheme.dark(
        primary:    AppColors.accent,
        onPrimary:  AppColors.textInverse,
        secondary:  AppColors.info,
        surface:    AppColors.surfaceCard,
        onSurface:  AppColors.textPrimary,
        error:      AppColors.error,
        onError:    Colors.white,
        surfaceContainerHighest: AppColors.surfaceHero,
      ),

      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Inter',

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor:  AppColors.background,
        elevation:        0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(
          color: AppColors.textPrimary,
          size: 22,
        ),
      ),

      // Bouton primaire
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.textInverse,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: AppTextStyles.button,
          elevation: 0,
        ),
      ),

      // Bouton outlined (secondaire)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppColors.surfaceBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: AppTextStyles.labelLarge.copyWith(
            color: AppColors.accent,
          ),
        ),
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceCard,
        hintStyle: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.textTertiary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
      ),

      // Card
      cardTheme: CardTheme(
        color: AppColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: const BorderSide(color: AppColors.surfaceBorder, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceBorder,
        thickness: 0.5,
        space: 0,
      ),

      // BottomNavigationBar (remplacé par composant custom)
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceHero,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceCard,
        contentTextStyle: AppTextStyles.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }
}
```

### 13.2 `main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_localizations.dart';
import 'config/di/injection.dart';
import 'config/env/env_dev.dart';
import 'config/routes/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Verrouiller en portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar transparente
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0D0F14),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialiser les dépendances
  final env = EnvDev();
  await initDependencies(baseUrl: env.baseUrl);

  runApp(VireloApp(env: env));
}

class VireloApp extends StatelessWidget {
  final env;
  const VireloApp({super.key, required this.env});

  @override
  Widget build(BuildContext context) {
    final router = AppRouter(sl()).router;

    return MaterialApp.router(
      title: 'Virelo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'CI'),
        Locale('en'),
        Locale('sw'),
      ],
      locale: const Locale('fr', 'CI'),
    );
  }
}
```

---

## 14. Checklist qualité

### 14.1 Visual QA

- [ ] Tous les textes sont lisibles sur fond sombre (ratio contraste ≥ 4.5:1 WCAG AA)
- [ ] Les montants utilisent `fontFeatures: [FontFeature.tabularFigures()]`
- [ ] Les montants sont toujours formatés avec `AmountFormatter` (jamais bruts)
- [ ] Le badge offline est visible sur tous les écrans principaux
- [ ] Les animations respectent `MediaQuery.of(context).disableAnimations`
- [ ] Touch targets ≥ 44dp sur tous les éléments interactifs
- [ ] Aucun overflow de texte sur les noms longs (Expanded + overflow ellipsis)
- [ ] Status bar transparente et icônes claires (light) sur fond sombre

### 14.2 Cohérence design

- [ ] Seul `AppColors` est utilisé (aucune `Color(0xFF...)` inline dans les widgets)
- [ ] Seul `AppTextStyles` est utilisé (aucun `TextStyle` inline)
- [ ] Seul `AppSpacing` est utilisé pour les paddings/gaps
- [ ] `AppShadows` est utilisé pour toutes les ombres
- [ ] `AppDurations` + `AppCurves` pour toutes les animations
- [ ] `VireloPrimaryButton` pour tous les CTA primaires
- [ ] `VireloActionButton` pour les actions rapides de la carte hero

### 14.3 Correspondance Règles de Gestion

| RG | Composant visuel |
|----|-----------------|
| RG 1 — Biométrie | `BottomSheet` confirmation paiement + prompt `local_auth` |
| RG 2 — Offline-First | `OfflineBanner` + badge `warningMuted` sur carte hero |
| RG 3 — Solde embarqué | `BalanceCard` en mode offline affiche `localBalance` |
| RG 4 — Télécollecte | Icône `sync` animée dans l'AppBar quand sync en cours |
| RG 5 — QR fallback | `QrDisplayWidget` accessible depuis la carte hero |
| RG 6 — Recharge | `DepositPage` avec grille des 4 opérateurs |

---

*Design System Virelo — v1.0.0 — YAO Moye Eliott Kenan · ESATIC / GENIUS GROUPS · 2025-2026*
