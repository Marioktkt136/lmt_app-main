import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lmt/core/theme/colors.dart';
import 'package:lmt/core/theme/typography.dart';
import 'package:lmt/core/utils/app_assets.dart';
import 'package:lmt/features/home/widgets/post_bottom.dart';
import 'package:lmt/features/home/widgets/post_header.dart';

class PollPostCard extends StatefulWidget {
  const PollPostCard({super.key});
  @override
  State<PollPostCard> createState() => PollPostCardState();
}

class PollPostCardState extends State<PollPostCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.backgroundDark.withValues(alpha: 0.2)),
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PostHeader(name: 'Mario Naiem', timeAgo: 'منذ يومين', avatarPath: AppAssets.accountIcon),
          SizedBox(height: 8.h),
          Text(
            'عندنا خدمة في جمعية عين شمس الجمعة الجاية مين جاي ؟',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
          SizedBox(height: 12.h),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2.h,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
              // overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Column(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('جاي', style: AppTypography.caption),
                    Row(
                      children: [
                        Text('12', style: AppTypography.caption),
                        Expanded(
                          child: Slider(
                            value: 0.75,
                            onChanged: null,
                            min: 0,
                            max: 1,
                            inactiveColor: Colors.grey.shade300,
                            activeColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('مش جاي', style: AppTypography.caption),
                    Row(
                      children: [
                        Text('2', style: AppTypography.caption),
                        Expanded(
                          child: Slider(
                            value: 0.25,
                            onChanged: null,
                            min: 0,
                            max: 1,
                            inactiveColor: Colors.grey.shade300,
                            activeColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          PostBottom(),
        ],
      ),
    );
  }
}
