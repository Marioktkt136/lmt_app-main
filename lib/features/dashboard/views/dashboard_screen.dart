import 'package:material_ui/material_ui.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lmt/core/routes/app_router.dart';
import 'package:lmt/core/routes/routes.dart';
import 'package:lmt/features/dashboard/widgets/dashboard_card.dart';
import 'package:lmt/features/dashboard/widgets/dashboard_item_model.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openLink(String url) async {
  if (url.trim().isEmpty) {
    debugPrint("URL is empty");
    return;
  }

  final Uri uri = Uri.parse(url);

  try {
    final bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  } catch (e) {
    debugPrint("Could not launch $url: $e");
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<DashboardItemModel> items = [
      DashboardItemModel(
        title: 'اسكريبتات',
        imagePath: 'assets/images/post.png',
        onTap: () => openLink(
          "https://docs.google.com/spreadsheets/d/1OIzUep2K6-TXfmP-z6q3Fm_BfnXQOg3615n1cl3rrQs/edit?usp=sharing",
        ),
      ),
      DashboardItemModel(
        title: 'الخلوة',
        imagePath: 'assets/images/pray.png',
        onTap: () {
          AppRouter.navigateTo(context, Routes.khelwa);
        },
      ),
      DashboardItemModel(
        title: 'خدماتنا',
        imagePath: 'assets/images/calendar.png',
        onTap: () => openLink(""),
      ),
      DashboardItemModel(
        title: 'فورم',
        imagePath: 'assets/images/form.png',
        onTap: () => openLink("https://forms.gle/ZYtUriGzQnqiYrVL6"),
      ),
      DashboardItemModel(
        title: 'درايف',
        imagePath: 'assets/images/drive.png',
        onTap: () => openLink(
          "https://drive.google.com/drive/folders/1Y3wdKNkWGBOb2Pw2CN-0XcIOHkSoJEyZ?usp=sharing",
        ),
      ),
      DashboardItemModel(
        title: 'يوتيوب',
        imagePath: 'assets/images/youtube.png',
        onTap: () => AppRouter.navigateTo(context, Routes.youtube),
      ),
    ];

    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 20.h,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return DashboardCard(item: item);
      },
    );
  }
}
