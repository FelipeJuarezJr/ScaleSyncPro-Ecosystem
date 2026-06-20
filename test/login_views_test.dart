import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scalesync_pro_ecosystem/features/ScaleSyncMarketplace/views/market_login_view.dart';
import 'package:scalesync_pro_ecosystem/features/ScaleSyncSocial/views/social_login_view.dart';
import 'package:scalesync_pro_ecosystem/services/auth_service.dart';

class MockAuthService extends ChangeNotifier implements AuthService {
  @override
  User? get currentUser => null;

  @override
  bool get isAuthenticated => false;

  @override
  Map<String, dynamic>? get userData => null;

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {}

  @override
  Future<void> createUserWithEmailAndPassword(String name, String email, String password) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> resetPassword(String email) async {}
}

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
  });

  testWidgets('MarketLoginView renders with correct branding and fields', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthService>.value(
        value: mockAuthService,
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaleFactor: 0.6),
            child: MarketLoginView(),
          ),
        ),
      ),
    );

    // Verify Title Branding
    expect(find.text('ScaleSync Marketplace'), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign in to list items and message breeders'), findsOneWidget);

    // Verify Fields & Buttons
    expect(find.widgetWithText(TextFormField, 'Enter your email'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Enter your password'), findsOneWidget);
    expect(find.text('Remember me'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('SocialLoginView renders with correct branding and fields', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthService>.value(
        value: mockAuthService,
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaleFactor: 0.6),
            child: SocialLoginView(),
          ),
        ),
      ),
    );

    // Verify Title Branding
    expect(find.text('ScaleSync Social'), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign in to join the community and share updates'), findsOneWidget);

    // Verify Fields & Buttons
    expect(find.widgetWithText(TextFormField, 'Enter your email'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Enter your password'), findsOneWidget);
    expect(find.text('Remember me'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
