import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for `lmt-temp-cloud-2026` ("LMT Temp Cloud DB"),
/// derived directly from the downloaded `google-services.json` and
/// `GoogleService-Info.plist`.
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for $defaultTargetPlatform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC3g6uNTC3QLnORGQwFQA02Q0jiaFMyoxs',
    appId: '1:688051545067:android:5330474d85a5a04d1b2fae',
    messagingSenderId: '688051545067',
    projectId: 'lmt-temp-cloud-2026',
    storageBucket: 'lmt-temp-cloud-2026.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDJDs26ARMqJX4DzPDJZd8R-hIDht3yq10',
    appId: '1:688051545067:ios:9e2a04c9040faf901b2fae',
    messagingSenderId: '688051545067',
    projectId: 'lmt-temp-cloud-2026',
    storageBucket: 'lmt-temp-cloud-2026.firebasestorage.app',
    iosBundleId: 'com.example.lmt',
  );
}
