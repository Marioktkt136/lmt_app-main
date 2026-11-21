import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../cubit/shared_files_cubit.dart';
import '../../../core/models/lmt_models.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/lmt_search_bar.dart';
import '../widgets/file_preview_sheet.dart';
import '../widgets/hyperlink_card_widget.dart';
import '../widgets/shared_document_tile.dart';
import '../widgets/upload_shared_file_sheet.dart';

/// Shared Files and Documents View.
///
/// Coordinates filtering, searching, uploading real files from device storage,
/// and downloading/opening files natively.
class DashboardScreen extends StatefulWidget {
  /// Creates a [DashboardScreen].
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  SharedFileType? _selectedCategory;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LmtCubit, LmtState>(
      builder: (context, state) {
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        final primary = AppColors.primaryOf(context);
        final canManageFiles = state.currentUser.role.canManageFiles;

        final filteredFiles = state.sharedFiles.where((f) {
          if (_selectedCategory != null && f.category != _selectedCategory) {
            return false;
          }
          if (_searchQuery.trim().isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          return f.title.toLowerCase().contains(q) ||
              f.description.toLowerCase().contains(q) ||
              f.fileExtension.toLowerCase().contains(q);
        }).toList();

        final cards = filteredFiles
            .where((f) => f.category == SharedFileType.card)
            .toList();
        final docs = filteredFiles
            .where((f) => f.category != SharedFileType.card)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search & Upload Button (Admin & Editor)
            LmtSearchBar(
              hintText: isArabic
                  ? 'ابحث في الملفات، الاسكريبتات، والبطاقات...'
                  : 'Search shared files, docs & cards...',
              onChanged: (v) => setState(() => _searchQuery = v),
              actions: [
                if (canManageFiles) ...[
                  SizedBox(width: 8.w),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: AppColors.cardShadows(
                        context,
                        accent: primary,
                        intensity: 0.85,
                      ),
                    ),
                    child: IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: primary),
                      tooltip: isArabic
                          ? 'رفع ملف من الموبايل أو بطاقة رابط'
                          : 'Upload File from Phone or Add Card',
                      onPressed: () => showUploadSharedFileSheet(context),
                      icon: const Icon(
                        Icons.upload_file_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 8.h),

            // Category Filter Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    selected: _selectedCategory == null,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = null),
                    label: Text(isArabic ? 'الكل' : 'All'),
                  ),
                  SizedBox(width: 6.w),
                  ...SharedFileType.values.map(
                    (cat) => Padding(
                      padding: EdgeInsets.only(right: 6.w),
                      child: ChoiceChip(
                        selected: _selectedCategory == cat,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = cat),
                        label: Text(cat.label(isArabic)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),

            // Content Area
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 4.h),
                children: [
                  // 1. Cards Section (Image & Hyperlink 🔗)
                  if (cards.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Text(
                        isArabic
                            ? 'البطاقات والروابط السريعة (Cards & Hyperlinks 🔗)'
                            : 'Interactive Cards & External Links 🔗',
                        style: AppTypography.h6.copyWith(
                          color: primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(vertical: 6.h),
                      itemCount: cards.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12.w,
                        mainAxisSpacing: 12.h,
                        childAspectRatio: 1.08,
                      ),
                      itemBuilder: (context, index) {
                        final card = cards[index];
                        return HyperlinkCardWidget(
                          file: card,
                          canDelete: canManageFiles,
                          onTap: () => handleSharedFileTap(context, card),
                          onDelete: () => context
                              .read<LmtCubit>()
                              .deleteSharedFile(card.id),
                        );
                      },
                    ),
                    SizedBox(height: 12.h),
                  ],

                  // 2. Documents, PDF, Word/Excel, Paperwork & Images Section
                  if (docs.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Text(
                        isArabic
                            ? 'الملفات والمستندات المشتركة (PDF • Word/Excel • أوراق عمل • صور)'
                            : 'Shared Documents (PDF • Word/Excel • Paperwork • Images)',
                        style: AppTypography.h6.copyWith(
                          color: primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...docs.map(
                      (doc) => SharedDocumentTile(
                        doc: doc,
                        canManageFiles: canManageFiles,
                        onTap: () => handleSharedFileTap(context, doc),
                        onDownload: () =>
                            downloadAndOpenSharedFile(context, doc),
                        onDelete: () => context
                            .read<LmtCubit>()
                            .deleteSharedFile(doc.id),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
