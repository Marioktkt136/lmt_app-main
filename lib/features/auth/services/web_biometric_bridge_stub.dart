/// No-op stub for Mobile/Desktop/VM where `local_auth` handles biometrics.
class WebBiometricBridge {
  WebBiometricBridge._();

  static Future<void> warmUp() async {}

  static Future<({String status, String? message})> authenticate({
    required String userId,
    required String username,
    required String localizedReason,
  }) async {
    return (status: 'pluginMissing', message: null);
  }
}
