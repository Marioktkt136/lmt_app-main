import 'dart:ui';

class DashboardItemModel {
  final String title;
  final String imagePath;
  final VoidCallback? onTap;

  DashboardItemModel({required this.title, required this.imagePath, this.onTap});
}
