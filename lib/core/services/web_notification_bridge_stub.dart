/// No-op stub for non-Web platforms (Android, iOS, Desktop, and VM tests).
class WebNotificationBridge {
  WebNotificationBridge._();

  static void init([Iterable<String> toneAssetPaths = const []]) {}

  static Future<void> unlockFromUserGesture() async {}

  static bool get isSupported => false;

  static String get permissionStatus => 'unsupported';

  static Future<String> requestPermission() async => 'unsupported';

  static Future<bool> playToneAsset(String assetPath) async => false;

  static Future<bool> showNotification({
    required String idKey,
    required String title,
    required String body,
    required String toneAssetPath,
    String? payload,
    void Function(String? payload)? onTap,
  }) async =>
      false;
}
