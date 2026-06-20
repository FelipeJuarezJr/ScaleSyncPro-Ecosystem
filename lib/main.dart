import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/firebase_config.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_app_screen.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'utils/theme.dart';
import 'core/network/domain_guard.dart';
import 'features/ScaleSyncMarketplace/views/marketplace_grid_view.dart';
import 'features/ScaleSyncMarketplace/views/market_login_view.dart';
import 'features/ScaleSyncSocial/views/social_feed_view.dart';
import 'features/ScaleSyncSocial/views/social_login_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: FirebaseConfig.scaleSyncPro,
    );
    debugPrint('✅ Firebase initialized: ${FirebaseConfig.scaleSyncPro.projectId}');
  } catch (e) {
    if (e.toString().contains('duplicate-app') || e.toString().contains('[DEFAULT]')) {
      debugPrint('✅ Firebase already initialized (native platform)');
    } else {
      debugPrint('❌ Firebase initialization error: $e');
      rethrow;
    }
  }

  await SharedPreferences.getInstance();

  debugPrint('🚀 Starting ScaleSyncPro app...');
  runApp(const ProviderScope(child: ScaleSyncProApp()));
}

class ScaleSyncProApp extends StatelessWidget {
  const ScaleSyncProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return legacy_provider.MultiProvider(
      providers: [
        legacy_provider.ChangeNotifierProvider(create: (_) => AuthService()),
        legacy_provider.ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: legacy_provider.Consumer2<AuthService, ThemeService>(
        builder: (context, authService, themeService, child) {
          Widget getHomeWidget() {
            final target = DomainGuard.currentTarget;
            final loggedIn = authService.isAuthenticated;
            switch (target) {
              case AppViewTarget.market:
                return loggedIn
                    ? const MarketplaceGridView()
                    : const MarketLoginView();
              case AppViewTarget.social:
                return loggedIn
                    ? const SocialFeedView()
                    : const SocialLoginView();
              case AppViewTarget.pro:
                return loggedIn
                    ? const MainAppScreen()
                    : const LoginScreen();
            }
          }

          return MaterialApp(
            title: 'ScaleSyncPro',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: getHomeWidget(),
          );
        },
      ),
    );
  }
}