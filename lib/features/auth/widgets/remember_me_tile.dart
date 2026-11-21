import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/colors.dart';

/// "Remember me" checkbox row; the whole row (48dp high) is tappable.
class RememberMeTile extends StatelessWidget {
  /// Creates the tile.
  const RememberMeTile({
    super.key,
    required this.isDark,
    required this.value,
    required this.onChanged,
  });

  /// Whether the dark theme is active.
  final bool isDark;

  /// Current checked state.
  final bool value;

  /// Called with the new value when toggled.
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppColors.secondary : AppColors.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(!value),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            Checkbox(
              focusColor: color,
              activeColor: color,
              value: value,
              onChanged: onChanged,
            ),
            Text(
              'remember_me'.tr(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
