import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/colors.dart';

/// Labelled text field used by the login form.
///
/// Shows an asset [prefixIcon]; when [suffixIcon] is given it renders a
/// 48dp tappable suffix (used for password visibility) with [suffixTooltip].
class LoginTextField extends StatelessWidget {
  /// Creates a login text field.
  const LoginTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.prefixIcon,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
    this.suffixTooltip,
    this.onSuffixTap,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.autofillHints,
  });

  /// Label shown above the field.
  final String label;

  /// Placeholder text.
  final String hint;

  /// Controller owning the text.
  final TextEditingController controller;

  /// Asset path for the leading icon.
  final String prefixIcon;

  /// Form validator.
  final String? Function(String?)? validator;

  /// Hides the text when true.
  final bool obscureText;

  /// Optional asset path for the trailing icon.
  final String? suffixIcon;

  /// Tooltip / semantic label of the trailing icon.
  final String? suffixTooltip;

  /// Called when the trailing icon is tapped.
  final VoidCallback? onSuffixTap;

  /// Keyboard action button.
  final TextInputAction textInputAction;

  /// Called when the keyboard action is pressed.
  final ValueChanged<String>? onSubmitted;

  /// Autofill hints for password managers.
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    final borderColor = AppColors.isDark(context)
        ? AppColors.secondaryDark
        : AppColors.backgroundDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        SizedBox(height: 6.h),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          autofillHints: autofillHints,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Padding(
              padding: const EdgeInsets.all(10),
              child: Image.asset(prefixIcon, width: 20, height: 20),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 40, minHeight: 48),
            suffixIcon: suffixIcon == null
                ? null
                : IconButton(
                    tooltip: suffixTooltip,
                    constraints:
                        const BoxConstraints(minWidth: 48, minHeight: 48),
                    onPressed: onSuffixTap,
                    icon: Image.asset(suffixIcon!, width: 20, height: 20),
                  ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: borderColor),
            ),
          ),
        ),
      ],
    );
  }
}
