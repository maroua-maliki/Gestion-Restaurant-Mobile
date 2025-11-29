// Ce fichier peut être envoyé sur Git.
// Il importe les clés depuis un fichier non suivi.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:restaurantapp/firebase_options_secret.dart'; // Importe les clés secrètes

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return androidFirebaseOptions; // Utilise la constante du fichier secret
      case TargetPlatform.iOS:
        // Si vous aviez une config iOS, vous l'importeriez de la même manière.
        // return iosFirebaseOptions;
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS - '
          'run "flutterfire configure" for more details.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }
}
