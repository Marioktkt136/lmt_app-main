import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lmt/core/theme/colors.dart';

class PostBottom extends StatelessWidget {
  const PostBottom({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            child: Icon(Icons.favorite_border_rounded, size: 20.sp, color: AppColors.textSecondary),
          ),
          InkWell(
            child: Icon(Icons.insert_comment_outlined, size: 20.sp, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
