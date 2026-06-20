import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/firebase_config.dart';

/// AuthService — all authentication is handled through the ScaleSyncPro Firebase project.
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  /// Extract user data from the authenticated Firebase user
  Map<String, dynamic>? get userData {
    final user = currentUser;
    if (user == null) return null;

    return {
      'name': user.displayName ?? user.email?.split('@')[0] ?? 'User',
      'email': user.email ?? '',
      'uid': user.uid,
      'photoURL': user.photoURL,
    };
  }

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      notifyListeners();
    });
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> createUserWithEmailAndPassword(
    String name,
    String email,
    String password,
  ) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (userCredential.user != null && name.isNotEmpty) {
      await userCredential.user!.updateDisplayName(name);
      await userCredential.user!.reload();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Sign in with Google through the ScaleSyncPro Firebase project.
  /// Web: uses Firebase Auth native popup (no extra package needed).
  /// Android: uses google_sign_in package with OAuth credential exchange.
  Future<void> signInWithGoogle() async {
    try {
      if (kDebugMode) {
        print('Starting Google Sign-In... (Platform: ${kIsWeb ? 'Web' : 'Android'})');
      }

      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        await _auth.signInWithPopup(googleProvider);

        if (kDebugMode) {
          print('✅ Google Sign-In successful (Web popup)');
        }
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
          serverClientId: FirebaseConfig.googleWebClientId,
        );

        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          if (kDebugMode) print('Google Sign-In cancelled by user');
          return;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await _auth.signInWithCredential(credential);

        if (kDebugMode) {
          print('✅ Google Sign-In successful (Android)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Google Sign-In error: $e');
        if (e is FirebaseAuthException) {
          print('Firebase Auth Code: ${e.code}');
          print('Firebase Auth Message: ${e.message}');
          if (e.code == 'unauthorized-domain') {
            print('⚠️ UNAUTHORIZED DOMAIN: This production domain is not in Firebase Auth authorized domains.');
            print('   Fix: Firebase Console → Authentication → Settings → Authorized domains');
            print('   Add: scalesync-marketplace.web.app and scalesync-social.web.app');
            print('   Also: Google Cloud Console → APIs & Services → Credentials → OAuth Web Client');
            print('   Add both domains to Authorized JavaScript Origins + redirect URIs');
          }
        } else if (e.toString().contains('ApiException: 10')) {
          print('⚠️ DEVELOPER_ERROR (10): Check that:');
          print('   1. SHA-1 fingerprint is registered in scalesync-pro Firebase Console');
          print('   2. Package name matches: com.example.scalesyncpro_firestore');
          print('   3. OAuth Web Client ID in FirebaseConfig.googleWebClientId is correct');
        }
      }
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}