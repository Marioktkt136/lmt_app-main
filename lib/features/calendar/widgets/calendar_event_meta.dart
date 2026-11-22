import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../helpers/calendar_date_utils.dart';

/// Date/time (including multi-day range) and clickable Google Maps location
/// line of a [CalendarEventModel] card.
class CalendarEventMeta extends StatelessWidget {
  /// Event to describe.
  final CalendarEventModel evt;

  /// Creates a [CalendarEventMeta].
  const CalendarEventMeta({super.key, required this.evt});

  Future<void> _openInGoogleMaps() async {
    final url = evt.googleMapsUrl;
    if (url == null) return;
    final uri = Uri.parse(url);
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);
    final accentGreen = AppColors.accentGreenOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);

    final style = TextStyle(
      fontSize: 11.5.sp,
      fontWeight: FontWeight.w600,
      color: textPrimary,
    );

    final dateText = evt.isMultiDay
        ? '${CalendarDateUtils.format(context, 'dd/MM/yyyy', evt.eventDateTime)} → ${CalendarDateUtils.format(context, 'dd/MM/yyyy', evt.endDateTime!)} (${evt.durationInDays} ${isArabic ? 'أيام' : 'days'})'
        : CalendarDateUtils.format(
            context,
            'EEE, dd/MM/yyyy • hh:mm a',
            evt.eventDateTime,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              evt.isMultiDay
                  ? Icons.date_range_rounded
                  : Icons.access_time_filled_rounded,
              size: 15.sp,
              color: primary,
            ),
            SizedBox(width: 5.w),
            Expanded(child: Text(dateText, style: style)),
          ],
        ),
        if (evt.hasLocation) ...[
          SizedBox(height: 6.h),
          InkWell(
            borderRadius: BorderRadius.circular(10.r),
            onTap: _openInGoogleMaps,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: accentGreen.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: accentGreen.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 15.sp,
                    color: AppColors.error,
                  ),
                  SizedBox(width: 4.w),
                  Flexible(
                    child: Text(
                      evt.location!,
                      style: style,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Icon(
                    Icons.map_rounded,
                    size: 14.sp,
                    color: accentGreen,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    'Google Maps',
                    style: TextStyle(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.bold,
                      color: accentGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
