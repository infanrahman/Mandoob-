import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/localization/app_localizations.dart';

enum DateFilterPreset {
  all,
  today,
  yesterday,
  thisWeek,
  thisMonth,
  custom,
}

class DateFilterHelper {
  static bool matches(DateTime date, DateFilterPreset preset, DateTimeRange? customRange) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    switch (preset) {
      case DateFilterPreset.all:
        return true;
      case DateFilterPreset.today:
        return !date.isBefore(todayStart) && !date.isAfter(todayEnd);
      case DateFilterPreset.yesterday:
        final yStart = todayStart.subtract(const Duration(days: 1));
        final yEnd = DateTime(yStart.year, yStart.month, yStart.day, 23, 59, 59, 999);
        return !date.isBefore(yStart) && !date.isAfter(yEnd);
      case DateFilterPreset.thisWeek:
        // Week starts from Saturday (day 6) in Saudi Arabia or 7 days back
        final weekStart = todayStart.subtract(Duration(days: (now.weekday + 1) % 7));
        return !date.isBefore(weekStart) && !date.isAfter(todayEnd);
      case DateFilterPreset.thisMonth:
        return date.year == now.year && date.month == now.month;
      case DateFilterPreset.custom:
        if (customRange == null) return true;
        final start = DateTime(customRange.start.year, customRange.start.month, customRange.start.day);
        final end = DateTime(customRange.end.year, customRange.end.month, customRange.end.day, 23, 59, 59, 999);
        return !date.isBefore(start) && !date.isAfter(end);
    }
  }

  static String getLabel(DateFilterPreset preset, DateTimeRange? customRange, bool isArabic) {
    switch (preset) {
      case DateFilterPreset.all:
        return isArabic ? 'كافة التواريخ' : 'All Time';
      case DateFilterPreset.today:
        return isArabic ? 'اليوم' : 'Today';
      case DateFilterPreset.yesterday:
        return isArabic ? 'أمس' : 'Yesterday';
      case DateFilterPreset.thisWeek:
        return isArabic ? 'هذا الأسبوع' : 'This Week';
      case DateFilterPreset.thisMonth:
        return isArabic ? 'هذا الشهر' : 'This Month';
      case DateFilterPreset.custom:
        if (customRange == null) return isArabic ? 'تاريخ مخصص' : 'Custom Range';
        final s = '${customRange.start.day}/${customRange.start.month}';
        final e = '${customRange.end.day}/${customRange.end.month}';
        return '$s - $e';
    }
  }
}

class DateFilterBar extends StatelessWidget {
  final DateFilterPreset selectedPreset;
  final DateTimeRange? customRange;
  final ValueChanged<DateFilterPreset> onPresetChanged;
  final ValueChanged<DateTimeRange?> onCustomRangeChanged;

  const DateFilterBar({
    super.key,
    required this.selectedPreset,
    required this.customRange,
    required this.onPresetChanged,
    required this.onCustomRangeChanged,
  });

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
      initialDateRange: customRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onCustomRangeChanged(picked);
      onPresetChanged(DateFilterPreset.custom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLanguage();
    final isArabic = lang.isArabic;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          _buildChip(
            context,
            label: isArabic ? 'الكل' : 'All',
            preset: DateFilterPreset.all,
            icon: Icons.calendar_today_outlined,
          ),
          const SizedBox(width: 6),
          _buildChip(
            context,
            label: isArabic ? 'اليوم' : 'Today',
            preset: DateFilterPreset.today,
            icon: Icons.today_rounded,
          ),
          const SizedBox(width: 6),
          _buildChip(
            context,
            label: isArabic ? 'أمس' : 'Yesterday',
            preset: DateFilterPreset.yesterday,
            icon: Icons.history_rounded,
          ),
          const SizedBox(width: 6),
          _buildChip(
            context,
            label: isArabic ? 'هذا الأسبوع' : 'This Week',
            preset: DateFilterPreset.thisWeek,
            icon: Icons.date_range_rounded,
          ),
          const SizedBox(width: 6),
          _buildChip(
            context,
            label: isArabic ? 'هذا الشهر' : 'This Month',
            preset: DateFilterPreset.thisMonth,
            icon: Icons.calendar_month_rounded,
          ),
          const SizedBox(width: 6),
          // Custom Date Range Chip
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _pickCustomRange(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: selectedPreset == DateFilterPreset.custom
                    ? AppColors.primary
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selectedPreset == DateFilterPreset.custom
                      ? AppColors.primary
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
                boxShadow: selectedPreset == DateFilterPreset.custom
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit_calendar_rounded,
                    size: 14,
                    color: selectedPreset == DateFilterPreset.custom ? Colors.white : AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    selectedPreset == DateFilterPreset.custom && customRange != null
                        ? '${customRange!.start.day}/${customRange!.start.month} - ${customRange!.end.day}/${customRange!.end.month}'
                        : (isArabic ? 'تحديد فترة...' : 'Custom Range...'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selectedPreset == DateFilterPreset.custom ? FontWeight.bold : FontWeight.w600,
                      color: selectedPreset == DateFilterPreset.custom ? Colors.white : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required DateFilterPreset preset,
    required IconData icon,
  }) {
    final isSelected = selectedPreset == preset;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onPresetChanged(preset),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
