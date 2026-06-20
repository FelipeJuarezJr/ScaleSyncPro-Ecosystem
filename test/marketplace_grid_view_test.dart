import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scalesync_pro_ecosystem/features/ScaleSyncMarketplace/views/marketplace_grid_view.dart';
import 'package:scalesync_pro_ecosystem/services/auth_service.dart';
import 'package:scalesync_pro_ecosystem/services/theme_service.dart';

// ==========================================
// HTTP Overrides Mock to allow NetworkImages
// ==========================================
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

  testWidgets('MarketplaceGridView renders custom search, hero banner, categories, and grids', (WidgetTester tester) async {
    // Provide mocked listings data stream
    final testListing = MarketplaceListing(
      listingId: 'listing_1',
      sellerId: 'seller_1',
      sellerName: 'Sunset Morphs',
      animalId: 'animal_1',
      title: 'High-End Ball Python',
      price: 450.0,
      morphs: ['Pastel', 'Clown'],
      imageUrls: [],
      listingDate: DateTime.now(),
      verifiedPedigreeSnapshot: [120.0, 150.0, 180.0],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          marketplaceListingsProvider.overrideWith((ref) => Stream.value([testListing])),
        ],
        child: legacy_provider.MultiProvider(
          providers: [
            legacy_provider.ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
            legacy_provider.ChangeNotifierProvider<ThemeService>.value(value: mockThemeService),
          ],
          child: const MaterialApp(
            home: MarketplaceGridView(),
          ),
        ),
      ),
    );

    // Wait for the stream to emit data
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Sticky Top Nav logo and title
    expect(find.text('ScaleSync Marketplace'), findsOneWidget);

    // Verify Search Box hint text
    expect(find.text('Search reptiles, morphs, sellers...'), findsOneWidget);

    // Verify Hero Banner overline and headers
    expect(find.text('LIVE ANIMALS'), findsOneWidget);
    expect(find.text('2,400+ verified listings'), findsOneWidget);

    // Verify Category pills
    expect(find.text('Snakes'), findsOneWidget);
    expect(find.text('Geckos'), findsOneWidget);

    // Verify Listing Card content
    expect(find.text('Ball Python'), findsOneWidget);
    expect(find.text('Pastel'), findsOneWidget);
    expect(find.text('\$450'), findsOneWidget);
    expect(find.text('Sunset Morphs'), findsOneWidget);

    // Verify Bottom Navigation Bar tabs
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Browse'), findsOneWidget);
    expect(find.text('Sell'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
