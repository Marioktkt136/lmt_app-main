import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lmt/core/theme/colors.dart';

Widget buildTextField({
  required bool isDark,
  required String label,
  required String hint,
  required TextEditingController controller,
  required String prefixIcon,
  TextInputType keyboardType = TextInputType.text,
  String? Function(String?)? validator,
  bool obscureText = false,
  String? suffixIcon,
  VoidCallback? onSuffixTap,
  required BuildContext context,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      SizedBox(height: 6.h),
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(10),
            child: Image.asset(prefixIcon, width: 20, height: 20),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          suffixIcon: suffixIcon == null
              ? null
              : InkWell(
                  onTap: onSuffixTap,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(suffixIcon, width: 20, height: 20),
                  ),
                ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark
                  ? AppColors.secondaryDark
                  : AppColors.backgroundDark,
            ),
          ),
        ),
      ),
    ],
  );
}
