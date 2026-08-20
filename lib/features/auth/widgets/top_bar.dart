 import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lmt/core/theme/colors.dart';
import 'package:lmt/core/utils/app_assets.dart';

Widget buildTopBar(bool isDark, ui.VoidCallback? toggleTheme, ui.VoidCallback? toggleLanguage) {
    return Row(
      textDirection: ui.TextDirection.ltr,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.secondary : AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2), // Shadow color
                offset: Offset(4, 6), // X,Y position
                blurRadius: 10, // Softness
                spreadRadius: 2, // Size spread
              ),
            ],
          ),
          child: IconButton(
            onPressed: toggleTheme,

            icon: isDark
                ? Image.asset(AppAssets.darkModeIcon, width: 30.w, height: 30.w)
                : Image.asset(
                    AppAssets.lightModeIcon,
                    width: 30.w,
                    height: 30.w,
                  ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.secondary : AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2), // Shadow color
                offset: Offset(4, 6), // X,Y position
                blurRadius: 10, // Softness
                spreadRadius: 2, // Size spread
              ),
            ],
          ),
          child: IconButton(
            onPressed: toggleLanguage,
            icon: Image.asset(
              AppAssets.languageModeIcon,
              width: 24.w,
              height: 24.w,
            ),
          ),
        ),
      ],
    );
  }
