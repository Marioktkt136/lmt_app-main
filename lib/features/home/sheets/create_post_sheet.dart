import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/device_file_helper.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../cubit/posts_cubit.dart';
import '../widgets/media_picker_strip.dart';
import '../widgets/poll_options_editor.dart';
import '../widgets/post_type_selector.dart';

/// Opens the modal bottom sheet for creating a Simple, Poll, or Media post,
/// preselecting [initialType]. Publishing calls `LmtCubit.createPost`.
void showCreatePostModal(BuildContext context, {required PostCategoryType initialType}) {
  final cubit = context.read<LmtCubit>();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: AdaptiveBreakpoints.bottomSheetConstraints(context),
    backgroundColor: AppColors.surfaceOf(context),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
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
  const CreatePostSheet({super.key, required this.cubit, required this.initialType});

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
  bool _allowMultiplePollChoices = false;

  @override
  void initState() {
    super.initState();
    // final isArabic = WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'ar';
    _optionCtrls = [
      TextEditingController(text: ''),
      TextEditingController(text: ''),
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

  void _addPollOption() {
    setState(() {
      _optionCtrls.add(TextEditingController());
    });
  }

  void _removePollOption(int index) {
    if (_optionCtrls.length <= 2 || index < 0 || index >= _optionCtrls.length) {
      return;
    }
    setState(() {
      final removed = _optionCtrls.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _pickMediaFromGallery() async {
    final file = await DeviceFileHelper.pickFileSafely(
      context,
      type: FileType.media,
    );
    if (file != null && file.path != null) {
      final savedPath =
          await DeviceFileHelper.persistPickedFile(file.path!, file.name);
      if (!mounted) return;
      final isVidFile = DeviceFileHelper.isVideoPath(savedPath) ||
          DeviceFileHelper.isVideoPath(file.name);
      setState(() {
        _pickedMediaPath = savedPath;
        _pickedFileName = file.name;
        _isVideo = isVidFile;
      });
    }
  }

  void _publish(bool isArabic) {
    void showValidationAlert(String message) {
      showDialog<void>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(isArabic ? 'تنبيه' : 'Notice'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(isArabic ? 'حسناً' : 'OK'),
            ),
          ],
        ),
      );
    }

    if (_contentCtrl.text.trim().isEmpty) {
      showValidationAlert(
        isArabic ? 'اكتب محتوى المنشور أولاً' : 'Please write some content first',
      );
      return;
    }

    if (_type == PostCategoryType.media &&
        (_pickedMediaPath == null || _pickedMediaPath!.isEmpty)) {
      showValidationAlert(
        isArabic
            ? 'يرجى اختيار صورة أو فيديو من المعرض أولاً 📱'
            : 'Please pick an image or video from your gallery first 📱',
      );
      return;
    }

    if (_type == PostCategoryType.poll) {
      final nonEmptyCount =
          _optionCtrls.where((c) => c.text.trim().isNotEmpty).length;
      if (nonEmptyCount < 2) {
        showValidationAlert(
          isArabic
              ? 'يرجى إدخال خيارين على الأقل للاستطلاع'
              : 'Please enter at least 2 poll options',
        );
        return;
      }
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
      allowMultiplePollChoices:
          _type == PostCategoryType.poll && _allowMultiplePollChoices,
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
                isArabic ? 'إنشاء منشور جديد في التايم لاين 📢' : 'Create New Timeline Post 📢',
                style: AppTypography.h4.copyWith(color: AppColors.textPrimaryOf(context)),
              ),
              SizedBox(height: 12.h),
              PostTypeSelector(selected: _type, onChanged: (t) => setState(() => _type = t)),
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
              if (_type == PostCategoryType.poll) ...[
                PollOptionsEditor(
                  controllers: _optionCtrls,
                  onAddOption: _addPollOption,
                  onRemoveOption: _removePollOption,
                ),
                SizedBox(height: 10.h),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryOf(context).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color:
                          AppColors.primaryOf(context).withValues(alpha: 0.25),
                    ),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
                    value: _allowMultiplePollChoices,
                    onChanged: (v) =>
                        setState(() => _allowMultiplePollChoices = v),
                    activeThumbColor: AppColors.primaryOf(context),
                    title: Text(
                      isArabic
                          ? 'السماح بأكثر من اختيار في الاستطلاع'
                          : 'Allow multiple poll choices',
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    subtitle: Text(
                      isArabic
                          ? (_allowMultiplePollChoices
                              ? 'يمكن للأعضاء اختيار أكثر من إجابة ✓'
                              : 'اختيار إجابة واحدة فقط لكل عضو')
                          : (_allowMultiplePollChoices
                              ? 'Members can select multiple options ✓'
                              : 'Single choice only per member'),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ),
                ),
              ],
              if (_type == PostCategoryType.media)
                MediaPickerStrip(
                  pickedMediaPath: _pickedMediaPath,
                  pickedFileName: _pickedFileName,
                  isVideo: _isVideo,
                  onPickFromGallery: _pickMediaFromGallery,
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
                  label: Text(isArabic ? 'نشر في التايم لاين' : 'Publish Post'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
