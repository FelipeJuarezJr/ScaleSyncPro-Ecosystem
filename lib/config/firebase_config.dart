import 'package:firebase_core/firebase_core.dart';

/// Firebase Configuration for ScaleSyncPro
/// Single Firebase project handles both authentication and all data operations.

class FirebaseConfig {
  // ScaleSyncPro Firebase — Auth + Firestore + Storage
  static const FirebaseOptions scaleSyncPro = FirebaseOptions(
    apiKey: 'AIzaSyCgE2e8RPN0JOWR8MFA1HTfDos3qmmkmEg',
    appId: '1:123833527982:web:36b21425fc1127c290473f',
    messagingSenderId: '123833527982',
    projectId: 'scalesync-pro',
    authDomain: 'scalesync-pro.firebaseapp.com',
    storageBucket: 'scalesync-pro.firebasestorage.app',
    measurementId: 'G-9BCWD33SRY',
  );

  // Google OAuth Web Client ID for Google Sign-In on Android
  // Find in: Firebase Console → Authentication → Sign-in method → Google → Web client ID
  // Or: Google Cloud Console → APIs & Services → Credentials → OAuth 2.0 Client IDs
  // ⚠️ Update this to the scalesync-pro project's OAuth client ID
  static const String googleWebClientId =
      '123833527982-e7ha4fbrpj65kh5qml854bqh272hivvu.apps.googleusercontent.com';
}
