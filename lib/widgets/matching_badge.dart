import 'package:flutter/material.dart';

import '../models/matching_models.dart';

/// Compact, reusable match badge for trip cards.
class MatchingBadge extends StatelessWidget {
  const MatchingBadge({
    super.key,
    required this.result,
  });

  final MatchingResult result;

  @override
  Widget build(BuildContext context) {
    final palette = _badgePaletteForScore(result.score);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            result.score >= 80 ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            size: 14,
            color: palette.foreground,
          ),
          const SizedBox(width: 6),
          Text(
            result.badgeLabel,
            style: TextStyle(
              color: palette.foreground,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  _BadgePalette _badgePaletteForScore(double score) {
    if (score >= 80) {
      return const _BadgePalette(
        background: Color(0x261FB173),
        foreground: Color(0xFF1FB173),
      );
    }

    if (score >= 50) {
      return const _BadgePalette(
        background: Color(0x1A3C2E8A),
        foreground: Color(0xFF3C2E8A),
      );
    }

    return const _BadgePalette(
      background: Color(0x1F9CA3AF),
      foreground: Color(0xFF6B7280),
    );
  }
}

class _BadgePalette {
  final Color background;
  final Color foreground;

  const _BadgePalette({
    required this.background,
    required this.foreground,
  });
}
