import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: 'AIzaSyAXz9_T6Yc8cfuw3PDB0nCikWZDMcSy6II',
          appId: '1:75242576312:android:521281cd30cab2e654974d',
          messagingSenderId: '75242576312',
          projectId: 'restaurantapp-27bef',
          storageBucket: 'restaurantapp-27bef.firebasestorage.app',
        );
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }
}
