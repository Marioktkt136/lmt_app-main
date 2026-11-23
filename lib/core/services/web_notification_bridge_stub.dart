/// No-op stub for non-Web platforms (Android, iOS, Desktop, and VM tests).
class WebNotificationBridge {
  WebNotificationBridge._();

  static bool get isSupported => false;

  static String get permissionStatus => 'unsupported';

  static Future<String> requestPermission() async => 'unsupported';

  static Future<void> playToneAsset(String assetPath) async {}

  static Future<void> showNotification({
    required String idKey,
    required String title,
    required String body,
    required String toneAssetPath,
    String? payload,
    void Function(String? payload)? onTap,
  }) async {}
}
