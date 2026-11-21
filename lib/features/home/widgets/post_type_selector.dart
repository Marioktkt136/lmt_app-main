import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';

/// Segmented-style selector for the [PostCategoryType] inside the create-post
/// sheet. Stateless: the parent owns the selected value.
class PostTypeSelector extends StatelessWidget {
  /// Currently selected type.
  final PostCategoryType selected;

  /// Called with the newly chosen type.
  final ValueChanged<PostCategoryType> onChanged;

  /// Creates a [PostTypeSelector].
  const PostTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final items = <(PostCategoryType, String, IconData)>[
      (PostCategoryType.simple, isArabic ? 'نصي' : 'Simple', Icons.article_outlined),
      (PostCategoryType.poll, isArabic ? 'استطلاع' : 'Poll', Icons.poll_outlined),
      (
        PostCategoryType.media,
        isArabic ? 'صورة/فيديو' : 'Media',
        Icons.perm_media_outlined,
      ),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(width: 6.w),
          Expanded(
            child: ChoiceChip(
              materialTapTargetSize: MaterialTapTargetSize.padded,
              avatar: Icon(items[i].$3, size: 16.sp),
              selected: selected == items[i].$1,
              onSelected: (_) => onChanged(items[i].$1),
              label: Text(items[i].$2, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ],
    );
  }
}
