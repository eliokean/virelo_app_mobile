import 'package:flutter/material.dart';

class OnboardingProgressIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;
  final ValueChanged<int>? onDotTap;

  const OnboardingProgressIndicator({
    super.key,
    required this.count,
    required this.currentIndex,
    this.onDotTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return GestureDetector(
          onTap: onDotTap != null ? () => onDotTap!(index) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 3.5,
            width: isActive ? 28 : 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: isActive
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.22),
            ),
          ),
        );
      }),
    );
  }
}
