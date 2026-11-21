import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/colors.dart';
import '../../../core/widgets/custom_button.dart';

/// Full-width primary "Log in" button with a built-in loading state.
///
/// While [isLoading] is true the button is disabled and shows a spinner, so
/// double submissions are impossible.
class LoginSubmitButton extends StatelessWidget {
  /// Creates the submit button.
  const LoginSubmitButton({
    super.key,
    required this.onPressed,
    required this.isDark,
    this.isLoading = false,
  });

  /// Called when the user taps the button.
  final VoidCallback onPressed;

  /// Whether the dark theme is active (changes the fill colour).
  final bool isDark;

  /// Shows a spinner and disables taps when true.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'login_button'.tr(),
      child: CustomButton(
        text: 'login_button'.tr(),
        onPressed: onPressed,
        isLoading: isLoading,
        color: isDark ? AppColors.secondaryDark : AppColors.primary,
      ),
    );
  }
}
