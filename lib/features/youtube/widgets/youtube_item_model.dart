import 'dart:ui';

class YoutubeItemModel {
  final String title;
  final String imagePath;
  final VoidCallback? onTap;

  YoutubeItemModel({required this.title, required this.imagePath, this.onTap});
}
