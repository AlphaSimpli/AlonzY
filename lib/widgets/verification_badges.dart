import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../theme/app_theme.dart';

/// Compact verification status row: email, phone and government ID badges.
///
/// Reused in profile headers and driver cards so users can instantly gauge
/// how trusted another member is.
class VerificationBadges extends StatelessWidget {
  const VerificationBadges({
    super.key,
    required this.user,
    this.compact = false,
  });

  final AppUser user;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _Badge(
          icon: Icons.alternate_email,
          label: compact ? null : 'Email',
          verified: user.emailVerified,
          compact: compact,
        ),
        _Badge(
          icon: Icons.phone,
          label: compact ? null : 'Phone',
          verified: user.phoneVerified,
          compact: compact,
        ),
        _Badge(
          icon: Icons.badge_outlined,
          label: compact ? null : _idLabel(user.govtIdStatus),
          verified: user.govtIdVerified,
          pending: user.govtIdStatus == 'pending',
          compact: compact,
        ),
      ],
    );
  }

  static String _idLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Gov ID · pending';
      case 'verified':
        return 'Gov ID';
      default:
        return 'Gov ID';
    }
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.verified,
    this.label,
    this.pending = false,
    this.compact = false,
  });

  final IconData icon;
  final String? label;
  final bool verified;
  final bool pending;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = verified
        ? AppColors.success
        : pending
            ? AppColors.warning
            : AppColors.textSecondary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 3 : 6,
      ),
      decoration: BoxDecoration(
        color: verified
            ? AppColors.success.withValues(alpha: 0.12)
            : pending
                ? AppColors.warning.withValues(alpha: 0.12)
                : AppColors.divider.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            verified
                ? Icons.verified
                : pending
                    ? Icons.hourglass_top
                    : icon,
            size: compact ? 12 : 14,
            color: color,
          ),
          if (label != null && !compact) ...[
            const SizedBox(width: 4),
            Text(
              label!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}