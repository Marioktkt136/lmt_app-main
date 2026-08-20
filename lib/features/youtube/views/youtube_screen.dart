import 'package:lmt/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lmt/core/widgets/app_bar.dart';
import 'package:lmt/features/youtube/widgets/youtube_item.dart';
import 'package:lmt/features/youtube/widgets/youtube_item_model.dart';

class YoutubeScreen extends StatelessWidget {
  const YoutubeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    List<YoutubeItemModel> items = [
      YoutubeItemModel(title: "جابل نور", imagePath: "", onTap: () {}),
      YoutubeItemModel(title: "جابل نور", imagePath: "", onTap: () {}),
      YoutubeItemModel(title: "جابل نور", imagePath: "", onTap: () {}),
      YoutubeItemModel(title: "جابل نور", imagePath: "", onTap: () {}),
      YoutubeItemModel(title: "جابل نور", imagePath: "", onTap: () {}),
      YoutubeItemModel(title: "جابل نور", imagePath: "", onTap: () {}),
      YoutubeItemModel(title: "جابل نور", imagePath: "", onTap: () {}),
      YoutubeItemModel(title: "جابل نور", imagePath: "", onTap: () {}),
      YoutubeItemModel(title: "جابل نور", imagePath: "", onTap: () {}),
    ];

    return Scaffold(
      backgroundColor: AppColors.primaryLight,

      body: SafeArea(
        child: Column(
          children: [
            const Padding(padding: EdgeInsets.symmetric(horizontal: 6.0), child: CustomAppBar()),
            Row(children: [
              
            ],),
            Expanded(
              child: GridView.builder(
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
                  return YoutubeItem(item: item);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
