import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/lmt_card.dart';

/// Displays the Year & 12-Months selector strip inside [FullMonthsCalendarPage]
/// and automatically scrolls the focused month chip into view.
class CalendarMonthSelectorCard extends StatefulWidget {
  /// Currently focused month (`DateTime(year, month, 1)`).
  final DateTime focusedMonth;

  /// All calendar events used to compute per-month event count badges.
  final List<CalendarEventModel> calendarEvents;

  /// Moves the focused month by `+1` or `-1`.
  final ValueChanged<int> onChangeMonthDelta;

  /// Selects a specific month number (`1..12`).
  final ValueChanged<int> onSelectMonth;

  /// Creates a [CalendarMonthSelectorCard].
  const CalendarMonthSelectorCard({
    super.key,
    required this.focusedMonth,
    required this.calendarEvents,
    required this.onChangeMonthDelta,
    required this.onSelectMonth,
  });

  @override
  State<CalendarMonthSelectorCard> createState() =>
      _CalendarMonthSelectorCardState();
}

class _CalendarMonthSelectorCardState extends State<CalendarMonthSelectorCard> {
  final List<GlobalKey> _monthKeys = List.generate(12, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    _scrollToFocusedMonth(animate: false);
  }

  @override
  void didUpdateWidget(covariant CalendarMonthSelectorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusedMonth.month != widget.focusedMonth.month ||
        oldWidget.focusedMonth.year != widget.focusedMonth.year) {
      _scrollToFocusedMonth(animate: true);
    }
  }

  void _scrollToFocusedMonth({required bool animate}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final index = (widget.focusedMonth.month - 1).clamp(0, 11);
      final targetCtx = _monthKeys[index].currentContext;
      if (targetCtx != null && targetCtx.mounted) {
        Scrollable.ensureVisible(
          targetCtx,
          alignment: 0.5,
          duration: animate
              ? const Duration(milliseconds: 260)
              : const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final accentGreen = AppColors.accentGreenOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return LmtCard(
      padding: EdgeInsets.all(12.w),
      borderRadius: 20.r,
      accentColor: primary,
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => widget.onChangeMonthDelta(-1),
                icon: Icon(Icons.chevron_left_rounded, color: primary),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(widget.focusedMonth),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTypography.h4.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isArabic
                          ? 'تصفح كل شهور السنة لمعرفة الأحداث القادمة'
                          : 'Browse all months of the year for upcoming events',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => widget.onChangeMonthDelta(1),
                icon: Icon(Icons.chevron_right_rounded, color: primary),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          SizedBox(
            height: 44.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: 12,
              separatorBuilder: (_, _) => SizedBox(width: 8.w),
              itemBuilder: (context, idx) {
                final m = idx + 1;
                final monthDate = DateTime(widget.focusedMonth.year, m, 1);
                final isSelectedMonth = widget.focusedMonth.month == m;
                final countInMonth = widget.calendarEvents
                    .where((e) => e.occursInMonth(widget.focusedMonth.year, m))
                    .length;

                return KeyedSubtree(
                  key: _monthKeys[idx],
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14.r),
                    onTap: () => widget.onSelectMonth(m),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: isSelectedMonth
                            ? primary
                            : AppColors.surfaceOf(context),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: isSelectedMonth
                              ? primary
                              : (countInMonth > 0
                                  ? accentGreen
                                  : AppColors.borderOf(context)),
                          width: countInMonth > 0 ? 1.5 : 1,
                        ),
                        boxShadow: AppColors.cardShadows(
                          context,
                          accent: isSelectedMonth ? primary : accentGreen,
                          intensity: isSelectedMonth ? 0.8 : 0.4,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('MMM').format(monthDate),
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: isSelectedMonth
                                  ? Colors.white
                                  : textPrimary,
                            ),
                          ),
                          if (countInMonth > 0) ...[
                            SizedBox(width: 5.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 5.w,
                                vertical: 1.h,
                              ),
                              decoration: BoxDecoration(
                                color: isSelectedMonth
                                    ? Colors.white
                                    : accentGreen,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                '$countInMonth',
                                style: TextStyle(
                                  fontSize: 9.5.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isSelectedMonth
                                      ? primary
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
