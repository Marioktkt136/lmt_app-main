import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/device_file_helper.dart';
import '../cubit/posts_cubit.dart';
import '../widgets/media_picker_strip.dart';
import '../widgets/poll_options_editor.dart';
import '../widgets/post_type_selector.dart';

/// Opens the modal bottom sheet for creating a Simple, Poll, or Media post,
/// preselecting [initialType]. Publishing calls `LmtCubit.createPost`.
void showCreatePostModal(
  BuildContext context, {
  required PostCategoryType initialType,
}) {
  final cubit = context.read<LmtCubit>();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surfaceOf(context),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (_) => CreatePostSheet(cubit: cubit, initialType: initialType),
  );
}

/// Body of the create-post bottom sheet. Owns and disposes its text
/// controllers; supports picking real images or videos from the device gallery.
class CreatePostSheet extends StatefulWidget {
  /// Cubit used to publish the post.
  final LmtCubit cubit;

  /// Type selected when the sheet opens.
  final PostCategoryType initialType;

  /// Creates a [CreatePostSheet].
  const CreatePostSheet({
    super.key,
    required this.cubit,
    required this.initialType,
  });

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  late PostCategoryType _type = widget.initialType;
  final _contentCtrl = TextEditingController();
  late final List<TextEditingController> _optionCtrls;
  String? _pickedMediaPath;
  String? _pickedFileName;
  bool _isVideo = false;

  @override
  void initState() {
    super.initState();
    final isArabic =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'ar';
    _optionCtrls = [
      TextEditingController(text: isArabic ? 'جاي أكيد 🎭' : 'Attending 🎭'),
      TextEditingController(text: isArabic ? 'مش جاي للأسف' : 'Cannot attend'),
      TextEditingController(),
    ];
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickMediaFromGallery({required bool pickVideo}) async {
    final file = await DeviceFileHelper.pickFileSafely(
      context,
      type: pickVideo ? FileType.video : FileType.image,
    );
    if (file != null && file.path != null) {
      final savedPath = await DeviceFileHelper.persistPickedFile(
        file.path!,
        file.name,
      );
      if (!mounted) return;
      final ext = (file.extension ?? '').toLowerCase();
      final isVidFile = pickVideo ||
          ['mp4', 'mov', 'mkv', 'webm', 'avi', '3gp'].contains(ext);
      setState(() {
        _pickedMediaPath = savedPath;
        _pickedFileName = file.name;
        _isVideo = isVidFile;
      });
    }
  }

  void _publish(bool isArabic) {
    if (_contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'اكتب محتوى المنشور أولاً'
                : 'Please write some content first',
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_type == PostCategoryType.media &&
        (_pickedMediaPath == null || _pickedMediaPath!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'يرجى اختيار صورة أو فيديو من المعرض أولاً 📱'
                : 'Please pick an image or video from your gallery first 📱',
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    widget.cubit.createPost(
      type: _type,
      content: _contentCtrl.text,
      mediaPath: _type == PostCategoryType.media ? _pickedMediaPath : null,
      isVideo: _type == PostCategoryType.media && _isVideo,
      videoUrl: null,
      pollOptionsText: _type == PostCategoryType.poll
          ? _optionCtrls.map((c) => c.text).toList()
          : const [],
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Padding(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
      ),
      child: SingleChildScrollView(
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArabic
                    ? 'إنشاء منشور جديد في التايم لاين 📢'
                    : 'Create New Timeline Post 📢',
                style: AppTypography.h4.copyWith(
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              SizedBox(height: 12.h),
              PostTypeSelector(
                selected: _type,
                onChanged: (t) => setState(() => _type = t),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: _contentCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: isArabic ? 'محتوى المنشور' : 'Post Content',
                  hintText: isArabic
                      ? 'اكتب تفاصيل الإعلان أو موعد البروفة...'
                      : 'Write your announcement or post details...',
                ),
              ),
              SizedBox(height: 12.h),
              if (_type == PostCategoryType.poll)
                PollOptionsEditor(controllers: _optionCtrls),
              if (_type == PostCategoryType.media)
                MediaPickerStrip(
                  pickedMediaPath: _pickedMediaPath,
                  pickedFileName: _pickedFileName,
                  isVideo: _isVideo,
                  onPickImageFromGallery: () =>
                      _pickMediaFromGallery(pickVideo: false),
                  onPickVideoFromGallery: () =>
                      _pickMediaFromGallery(pickVideo: true),
                  onClearMedia: () => setState(() {
                    _pickedMediaPath = null;
                    _pickedFileName = null;
                    _isVideo = false;
                  }),
                ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => _publish(isArabic),
                  icon: const Icon(Icons.publish_rounded),
                  label:
                      Text(isArabic ? 'نشر في التايم لاين' : 'Publish Post'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
