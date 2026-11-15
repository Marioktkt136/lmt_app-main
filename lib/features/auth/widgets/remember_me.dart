import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';
import 'package:lmt/core/theme/colors.dart';

class RememberMe extends StatelessWidget {
  const RememberMe({
    super.key,
    required this.isDark,
    required this.rememberMe,
    required this.onRememberMeChanged,
  });

  final bool isDark;
  final bool rememberMe;
  final ValueChanged<bool?> onRememberMeChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          focusColor: isDark ? AppColors.secondary : AppColors.primary,
          activeColor: isDark ? AppColors.secondary : AppColors.primary,
          value: rememberMe,
          onChanged: onRememberMeChanged,
        ),
        Text('remember_me'.tr(), style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
