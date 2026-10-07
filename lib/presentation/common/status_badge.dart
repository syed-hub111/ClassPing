import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool isSmall;

  const StatusBadge({
    super.key,
    required this.status,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label = status;

    switch (status.toUpperCase()) {
      case 'PRESENT':
        bg = AppTheme.presentLight;
        fg = const Color(0xFF047857);
        label = 'Present';
        break;
      case 'LATE':
        bg = AppTheme.lateLight;
        fg = const Color(0xFFB45309);
        label = 'Late';
        break;
      case 'ABSENT':
        bg = AppTheme.absentLight;
        fg = const Color(0xFFB91C1C);
        label = 'Absent';
        break;
      case 'PENDING':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        label = 'Pending';
        break;
      case 'LOCKED':
        bg = const Color(0xFFE0E7FF);
        fg = const Color(0xFF4338CA);
        label = 'Locked';
        break;
      case 'MISSED_DEADLINE':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        label = 'Missed Deadline';
        break;
      case 'COMPLETED_AFTER_DEADLINE':
        bg = const Color(0xFFEDE9FE);
        fg = const Color(0xFF6D28D9);
        label = 'Completed Late';
        break;
      case 'WITHIN_DEADLINE':
        bg = AppTheme.presentLight;
        fg = const Color(0xFF047857);
        label = 'On Time';
        break;
      case 'ACTIVE':
        bg = AppTheme.presentLight;
        fg = const Color(0xFF047857);
        label = 'Active';
        break;
      case 'COMPLETED':
        bg = const Color(0xFFE2E8F0);
        fg = const Color(0xFF475569);
        label = 'Completed';
        break;
      case 'DISCONTINUED':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        label = 'Discontinued';
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 3 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: isSmall ? 11 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
