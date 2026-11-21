import 'package:material_ui/material_ui.dart';

import '../theme/colors.dart';

/// Shows a localized confirmation dialog for destructive actions
/// (delete / remove) and resolves to `true` only when the user confirms.
///
/// Usage: `if (await confirmDestructiveAction(context, title: ..., message: ...))`.
/// Rules: the cancel button is the default/safe action; the confirm button is
/// rendered in [AppColors.error]. Dismissing the dialog resolves to `false`.
Future<bool> confirmDestructiveAction(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
}) async {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(isArabic ? 'إلغاء' : 'Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: Text(confirmLabel ?? (isArabic ? 'حذف' : 'Delete')),
        ),
      ],
    ),
  );
  return result ?? false;
}
