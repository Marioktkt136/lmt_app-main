import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/colors.dart';
import '../utils/device_file_helper.dart';

/// Global reusable circular avatar supporting both bundled assets and local device files.
class LmtAvatar extends StatelessWidget {
  /// The asset or local device file path of the image.
  final String imagePath;

  /// The radius of the circular avatar.
  final double radius;

  /// Optional small badge widget positioned at the bottom-right corner.
  final Widget? badge;

  /// Whether to render an elevated shadow around the avatar.
  final bool showShadow;

  /// Creates an [LmtAvatar].
  const LmtAvatar({
    super.key,
    required this.imagePath,
    this.radius = 22,
    this.badge,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryOf(context);

    final avatar = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: showShadow
            ? AppColors.cardShadows(
                context,
                accent: primary,
                intensity: 0.55,
              )
            : null,
      ),
      child: CircleAvatar(
        radius: radius.r,
        backgroundColor: primary.withValues(alpha: 0.14),
        backgroundImage: DeviceFileHelper.imageProviderFor(imagePath),
        onBackgroundImageError: (_, _) {},
      ),
    );

    if (badge == null) return avatar;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        avatar,
        badge!,
      ],
    );
  }
}
