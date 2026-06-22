import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scalesync_pro_ecosystem/features/ScaleSyncSocial/views/social_feed_view.dart';
import 'package:scalesync_pro_ecosystem/services/auth_service.dart';
import 'package:scalesync_pro_ecosystem/services/theme_service.dart';

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return MockHttpClient();
  }
}

class MockHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => MockHttpClientRequest();
  
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockHttpClientRequest implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async => MockHttpClientResponse();
  
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;
  
  @override
  int get contentLength => transparentImage.length;
  
  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;
  
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(transparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final List<int> transparentImage = [
  0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00, 0x01, 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00,
  0xFF, 0xFF, 0xFF, 0x21, 0xF9, 0x04, 0x01, 0x00, 0x00, 0x00, 0x00, 0x2C, 0x00, 0x00, 0x00, 0x00,
  0x01, 0x00, 0x01, 0x00, 0x00, 0x02, 0x02, 0x4C, 0x01, 0x00, 0x3B
];

class FakeUser implements User {
  @override
  final String uid;
  @override
  final String? displayName;
  @override
  final String? email;

  FakeUser({required this.uid, this.displayName, this.email});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAuthService extends ChangeNotifier implements AuthService {
  bool _authenticated = false;
  Map<String, dynamic>? _userData;
  User? _currentUser;

  void setAuthenticated(bool val, {Map<String, dynamic>? data}) {
    _authenticated = val;
    _userData = data;
    if (val) {
      _currentUser = FakeUser(
        uid: 'test_uid_123',
        displayName: data?['name'] ?? 'Test User',
        email: data?['email'] ?? 'test@example.com',
      );
    } else {
      _currentUser = null;
    }
    notifyListeners();
  }

  @override
  User? get currentUser => _currentUser;

  @override
  bool get isAuthenticated => _authenticated;

  @override
  Map<String, dynamic>? get userData => _userData;

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

class MockThemeService extends ChangeNotifier implements ThemeService {
  @override
  bool get isDarkMode => true;

  @override
  Future<void> toggleTheme() async {}

  @override
  Future<void> setThemeMode(bool isDark) async {}
}

void main() {
  late MockAuthService mockAuthService;
  late MockThemeService mockThemeService;

  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  setUp(() {
    mockAuthService = MockAuthService();
    mockThemeService = MockThemeService();
  });

  testWidgets('SocialFeedView bottom navigation switches tabs on mobile', (WidgetTester tester) async {
    // Set screen size to mobile
    tester.binding.window.physicalSizeTestValue = const Size(400, 800);
    tester.binding.window.devicePixelRatioTestValue = 1.0;

    await tester.pumpWidget(
      ProviderScope(
        child: legacy_provider.MultiProvider(
          providers: [
            legacy_provider.ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
            legacy_provider.ChangeNotifierProvider<ThemeService>.value(value: mockThemeService),
          ],
          child: const MaterialApp(
            home: SocialFeedView(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    // Verify bottom navigation items are present
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Broadcast'), findsOneWidget);
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Initial state: Feed should be visible
    expect(find.text('Herpetarium Feed'), findsOneWidget);

    // Switch to Discover tab
    await tester.tap(find.text('Discover'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Trending Tags'), findsOneWidget);
    expect(find.text('Breeder Spotlights'), findsOneWidget);
    expect(find.text('Trending Broadcasts'), findsOneWidget);

    // Switch to Messages tab
    await tester.tap(find.text('Messages'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Breeder Messages'), findsOneWidget);

    // Switch to Profile tab
    await tester.tap(find.text('Profile'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('My Collection Log & Broadcasts'), findsOneWidget);

    // Switch back to Home tab
    await tester.tap(find.text('Home'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Herpetarium Feed'), findsOneWidget);

    // Reset window size override
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
  });

  testWidgets('SocialFeedView displays username between Pro Badge and menu in header on mobile and desktop', (WidgetTester tester) async {
    // 1. Mobile view test
    tester.binding.window.physicalSizeTestValue = const Size(400, 800);
    tester.binding.window.devicePixelRatioTestValue = 1.0;

    mockAuthService.setAuthenticated(true, data: {'name': 'MobileBreeder'});

    await tester.pumpWidget(
      ProviderScope(
        child: legacy_provider.MultiProvider(
          providers: [
            legacy_provider.ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
            legacy_provider.ChangeNotifierProvider<ThemeService>.value(value: mockThemeService),
          ],
          child: const MaterialApp(
            home: SocialFeedView(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    // Verify username "MobileBreeder" is displayed
    expect(find.text('MobileBreeder'), findsOneWidget);
    // Verify "Pro" badge is displayed
    expect(find.text('Pro'), findsOneWidget);

    // 2. Desktop view test
    tester.binding.window.physicalSizeTestValue = const Size(1200, 800);
    
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify username "MobileBreeder" is still displayed
    expect(find.text('MobileBreeder'), findsOneWidget);
    expect(find.text('Pro'), findsOneWidget);

    // Reset window size override
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
  });
}
