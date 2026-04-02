import 'package:flutter/material.dart';
import '../../core/theme/app_theme_data.dart';

enum StatusType { upToDate, dueSoon, overdue, inactive, unknown }

class StatusBadge extends StatelessWidget {
  final StatusType status;
  final String? label;

  const StatusBadge({
    super.key,
    required this.status,
    this.label,
  });

  factory StatusBadge.fromStatus(String? statusString, {String? label}) {
    StatusType status;
    switch (statusString?.toLowerCase()) {
      case 'up_to_date':
      case 'up to date':
      case 'active':
      case 'completed':
        status = StatusType.upToDate;
        break;
      case 'due_soon':
      case 'due soon':
      case 'upcoming':
        status = StatusType.dueSoon;
        break;
      case 'overdue':
      case 'cancelled':
        status = StatusType.overdue;
        break;
      case 'inactive':
        status = StatusType.inactive;
        break;
      default:
        status = StatusType.unknown;
    }
    return StatusBadge(status: status, label: label);
  }

  @override
  Widget build(BuildContext context) {
    final (color, bgColor, icon) = _getStyle(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label ?? _getLabel(status),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, IconData) _getStyle(StatusType status) {
    switch (status) {
      case StatusType.upToDate:
        return (PawThemeData.successGreen, PawThemeData.successGreen.withValues(alpha: 0.15), Icons.check_circle);
      case StatusType.dueSoon:
        return (PawThemeData.alertAmber, PawThemeData.alertAmber.withValues(alpha: 0.15), Icons.schedule);
      case StatusType.overdue:
        return (PawThemeData.alertRed, PawThemeData.alertRed.withValues(alpha: 0.15), Icons.error);
      case StatusType.inactive:
        return (Colors.grey, Colors.grey.withValues(alpha: 0.15), Icons.pause_circle);
      case StatusType.unknown:
        return (Colors.grey, Colors.grey.withValues(alpha: 0.15), Icons.help);
    }
  }

  String _getLabel(StatusType status) {
    switch (status) {
      case StatusType.upToDate:
        return 'Up to date';
      case StatusType.dueSoon:
        return 'Due soon';
      case StatusType.overdue:
        return 'Overdue';
      case StatusType.inactive:
        return 'Inactive';
      case StatusType.unknown:
        return 'Unknown';
    }
  }
}
