import 'package:material_ui/material_ui.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // لون التطبيق الأساسي من تصميمك
    final primaryColor = Color(0xFF4A65C6);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,

        title: const Text(
          'الإشعارات',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.white),
            tooltip: 'تحديد الكل كمقروء',
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 10, // عدد الإشعارات
        itemBuilder: (context, index) {
          bool isUnread = index < 2; // تجربة: أول إشعارين غير مقروءين

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isUnread ? Colors.blue[50] : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isUnread ? primaryColor.withValues(alpha: 0.3) : Colors.transparent,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: isUnread ? primaryColor : Colors.grey[300],
                child: Icon(
                  Icons.notifications_active,
                  color: isUnread ? Colors.white : Colors.grey[600],
                ),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'تحديث جديد من الخلوة',
                    style: TextStyle(
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                      fontSize: 15,
                    ),
                  ),
                  Text('منذ 10 د', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
              subtitle: const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'تم إضافة محتوى جديد في قسم الخلوة اليومية، يمكنك الاطلاع عليه الآن.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13),
                ),
              ),
              onTap: () {
                // فتح تفاصيل الإشعار أو التوجيه للقسم المطلوب
              },
            ),
          );
        },
      ),
    );
  }
}
