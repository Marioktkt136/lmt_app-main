import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../cubit/settings_cubit.dart';

/// Displays the Slogan & Verse of the Year card with an edit action for
/// Admins and Editors.
class SettingsBrandingCard extends StatelessWidget {
  /// The current application state.
  final LmtState state;

  /// Whether the active locale is Arabic.
  final bool isArabic;

  /// Creates a [SettingsBrandingCard].
  const SettingsBrandingCard({
    super.key,
    required this.state,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final canEdit = state.currentUser.role.canDoAnything ||
        state.currentUser.role == UserRole.editor;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: AppColors.cardDecoration(
        context,
        radius: 22.r,
        accentColor: primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isArabic
                      ? 'شعار وآية السنة (Slogan & Verse of the Year)'
                      : 'Slogan & Verse of the Year',
                  style: AppTypography.h6.copyWith(
                    color: primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (canEdit)
                IconButton(
                  tooltip: isArabic ? 'تعديل الشعار والآية' : 'Edit Slogan',
                  onPressed: () => _showEditBrandingDialog(context, state),
                  icon: Icon(Icons.edit_outlined, color: primary),
                ),
            ],
          ),
          Text(
            state.sloganOfYear,
            style: AppTypography.h4.copyWith(color: primary),
          ),
          SizedBox(height: 4.h),
          Text(
            state.verseOfYear,
            style: TextStyle(
              fontSize: 12.5.sp,
              color: textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditBrandingDialog(BuildContext context, LmtState state) {
    final sloganCtrl = TextEditingController(text: state.sloganOfYear);
    final verseCtrl = TextEditingController(text: state.verseOfYear);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isArabic
              ? 'تحديث شعار وآية السنة'
              : 'Update Slogan & Verse of the Year',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: sloganCtrl,
              decoration: InputDecoration(
                labelText:
                    isArabic ? 'شعار السنة (Slogan)' : 'Slogan of the Year',
              ),
            ),
            SizedBox(height: 10.h),
            TextField(
              controller: verseCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: isArabic ? 'آية السنة (Verse)' : 'Verse of the Year',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<LmtCubit>().updateYearBranding(
                    slogan: sloganCtrl.text.trim(),
                    verse: verseCtrl.text.trim(),
                  );
              Navigator.pop(ctx);
            },
            child: Text(isArabic ? 'حفظ' : 'Save'),
          ),
        ],
      ),
    );
  }
}
