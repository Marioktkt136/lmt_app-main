import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/app_assets.dart';
import '../../../core/widgets/adaptive_layout.dart';
import '../widgets/youtube_item.dart';
import '../widgets/youtube_item_model.dart';

class YoutubeScreen extends StatelessWidget {
  const YoutubeScreen({super.key});

  Future<void> _openYoutubeVideo(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final primary = AppColors.primaryOf(context);

    final List<YoutubeItemModel> items = [
      YoutubeItemModel(
        title: 'مسرحية جبل نور 🎭',
        imagePath: AppAssets.actIcon,
        onTap: () => _openYoutubeVideo('https://www.youtube.com'),
      ),
      YoutubeItemModel(
        title: 'عرض تغيروا 2026 🎬',
        imagePath: AppAssets.appLogo,
        onTap: () => _openYoutubeVideo('https://www.youtube.com'),
      ),
      YoutubeItemModel(
        title: 'بانتومايم الرسالة الاخيرة ✨',
        imagePath: AppAssets.youtubeIcon,
        onTap: () => _openYoutubeVideo('https://www.youtube.com'),
      ),
      YoutubeItemModel(
        title: 'اسكتش صوت الضمير 🎤',
        imagePath: AppAssets.videoIcon,
        onTap: () => _openYoutubeVideo('https://www.youtube.com'),
      ),
      YoutubeItemModel(
        title: 'كواليس وبروفات الفريق 🎥',
        imagePath: AppAssets.picturesIcon,
        onTap: () => _openYoutubeVideo('https://www.youtube.com'),
      ),
      YoutubeItemModel(
        title: 'عرض خدمة عين شمس 🌟',
        imagePath: AppAssets.prayIcon,
        onTap: () => _openYoutubeVideo('https://www.youtube.com'),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: Text(
          isArabic
              ? 'عروض فريق الرسالة الاخيرة (YouTube)'
              : 'L.M.T Theater YouTube Channel',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: AdaptiveContentBox(
        maxWidth: 960,
        child: GridView.builder(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
          physics: const BouncingScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 240,
            crossAxisSpacing: 16.w,
            mainAxisSpacing: 20.h,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return YoutubeItem(item: item);
          },
        ),
      ),
    );
  }
}
