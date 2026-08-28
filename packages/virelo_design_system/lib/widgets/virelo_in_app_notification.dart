import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../constants/app_spacing.dart';

enum InAppNotificationType { success, payment, info, error }

class VireloInAppNotification {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  /// Global navigator key pour pouvoir afficher la notification sans avoir le BuildContext sous la main
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Affiche une notification In-App animée depuis le haut de l'écran
  static void show({
    BuildContext? context,
    required String title,
    required String message,
    String? amount,
    InAppNotificationType type = InAppNotificationType.payment,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
  }) {
    OverlayState? overlayState;
    if (context != null) {
      overlayState = Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.maybeOf(context);
    }
    overlayState ??= navigatorKey.currentState?.overlay;

    if (overlayState == null) {
      debugPrint("VireloInAppNotification: OverlayState introuvable.");
      return;
    }

    // Vibration haptique
    HapticFeedback.mediumImpact();

    // Fermer toute notification existante
    _currentEntry?.remove();
    _dismissTimer?.cancel();
    _currentEntry = null;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _InAppNotificationWidget(
        title: title,
        message: message,
        amount: amount,
        type: type,
        onTap: () {
          _dismiss();
          onTap?.call();
        },
        onDismiss: _dismiss,
      ),
    );

    _currentEntry = entry;
    overlayState.insert(entry);

    _dismissTimer = Timer(duration, () {
      _dismiss();
    });
  }

  /// Ferme la notification actuelle avec animation
  static void _dismiss() {
    _dismissTimer?.cancel();
    if (_currentEntry != null) {
      _currentEntry?.remove();
      _currentEntry = null;
    }
  }
}

class _InAppNotificationWidget extends StatefulWidget {
  final String title;
  final String message;
  final String? amount;
  final InAppNotificationType type;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _InAppNotificationWidget({
    required this.title,
    required this.message,
    this.amount,
    required this.type,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_InAppNotificationWidget> createState() => _InAppNotificationWidgetState();
}

class _InAppNotificationWidgetState extends State<_InAppNotificationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _accentColor {
    switch (widget.type) {
      case InAppNotificationType.payment:
      case InAppNotificationType.success:
        return const Color(0xFF00E5A0); // Vert Virelo
      case InAppNotificationType.error:
        return const Color(0xFFFF4D6A);
      case InAppNotificationType.info:
        return const Color(0xFF4C9EFF);
    }
  }

  IconData get _iconData {
    switch (widget.type) {
      case InAppNotificationType.payment:
        return LucideIcons.arrowDownLeft;
      case InAppNotificationType.success:
        return LucideIcons.checkCircle2;
      case InAppNotificationType.error:
        return LucideIcons.alertCircle;
      case InAppNotificationType.info:
        return LucideIcons.bell;
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 10,
      left: AppSpacing.screenH,
      right: AppSpacing.screenH,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _offsetAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Dismissible(
              key: const Key('in_app_notification'),
              direction: DismissDirection.up,
              onDismissed: (_) => widget.onDismiss(),
              child: GestureDetector(
                onTap: widget.onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161A22),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _accentColor.withOpacity(0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: _accentColor.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Icône badge
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _accentColor.withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _iconData,
                          color: _accentColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),

                      // Textes
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  widget.title,
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (widget.amount != null)
                                  Text(
                                    '+ ${widget.amount} FCFA',
                                    style: AppTextStyles.labelLarge.copyWith(
                                      color: _accentColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.message,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Petite poignée de fermeture
                      Icon(
                        LucideIcons.chevronUp,
                        color: Colors.white.withOpacity(0.3),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
