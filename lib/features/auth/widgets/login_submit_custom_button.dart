
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lmt/core/theme/colors.dart';
import 'package:lmt/core/widgets/custom_button.dart';

class LoginSubmitCustomButtom extends StatelessWidget {
  const LoginSubmitCustomButtom({
    super.key,
    required this.submit,
    required this.isDark,
  });

  final VoidCallback submit;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: 'login_button'.tr(),
        onPressed: submit,
        color: isDark ? AppColors.secondaryDark : AppColors.primary,
      ),
    );
  }
}
