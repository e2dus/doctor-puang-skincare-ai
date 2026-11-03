/// ============================================================================
/// MAIN.DART - Application Entry Point
/// ============================================================================
///
/// This is the main entry point for the Skincare Recommendation App.
///
/// ## Architecture
/// This app follows Clean Architecture with the following structure:
/// - core/         : Shared utilities, theme, error handling, constants
/// - features/     : Feature modules (auth, product, chat, skincare, settings)
///
/// ## Features
/// - auth          : User authentication (login, signup, logout)
/// - product       : Product catalog, cart, liked/blocked products
/// - chat          : AI chatbot for skincare recommendations
/// - skincare      : Daily skincare routine tracking
/// - settings      : App settings and preferences
///
/// ## State Management
/// Uses Riverpod for state management with ViewModels in each feature.
///
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/main/presentation/pages/main_page.dart';
import 'features/settings/presentation/viewmodels/theme_viewmodel.dart';

/// Application entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 매 앱 실행 시마다 온보딩 상태 초기화
  const storage = FlutterSecureStorage();
  await storage.delete(key: 'onboarding_shown');

  runApp(const ProviderScope(child: MyApp()));
}

/// Secure storage instance for token management
const storage = FlutterSecureStorage();

/// Root application widget
///
/// Configures:
/// - Material Design theme (light/dark)
/// - Navigation routes
/// - Provider scope for state management
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Doctor Puang',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const AuthChecker(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/main': (context) => const MainPage(),
      },
    );
  }
}

/// Checks authentication status on app start
///
/// Routes to:
/// - MainPage if user has valid refresh token
/// - LoginPage if no valid token found
class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAuthentication(),
      builder: (context, snapshot) {
        // Show splash screen with logo while checking
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSplashScreen(context);
        }

        // Route based on authentication status
        if (snapshot.hasData && snapshot.data == true) {
          return const MainPage();
        } else {
          return const LoginPage();
        }
      },
    );
  }

  /// Build logo widget (SVG with PNG fallback)
  Widget _buildLogo() {
    return SizedBox(
      width: 200,
      height: 200,
      child: SvgPicture.asset(
        'assets/images/logo_image.svg',
        fit: BoxFit.contain,
        placeholderBuilder: (context) => Image.asset(
          'assets/images/logo_image.png',
          width: 200,
          height: 200,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  /// Build splash screen with logo
  Widget _buildSplashScreen(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo - Try SVG first, fallback to PNG
            _buildLogo(),
            const SizedBox(height: 32),
            // App name
            Text(
              'Doctor Puang',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
                fontFamily: 'HelveticaNeue93',
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            // Subtitle
            Text(
              'AI Skincare Assistant',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 48),
            // Loading indicator
            CircularProgressIndicator(
              color: theme.colorScheme.primary,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }

  /// Check if user has valid authentication tokens
  /// Returns true only if BOTH access_token and refresh_token exist
  Future<bool> _checkAuthentication() async {
    try {
      final String? accessToken = await storage.read(key: 'access_token');
      final String? refreshToken = await storage.read(key: 'refresh_token');
      
      // 둘 다 있어야만 인증된 것으로 간주
      final isAuthenticated = accessToken != null && 
                              accessToken.isNotEmpty && 
                              refreshToken != null && 
                              refreshToken.isNotEmpty;
      
      debugPrint('🔐 AuthChecker: accessToken=${accessToken != null ? "exists" : "null"}, refreshToken=${refreshToken != null ? "exists" : "null"}, isAuthenticated=$isAuthenticated');
      
      return isAuthenticated;
    } catch (e) {
      debugPrint('❌ Token check error: $e');
      return false;
    }
  }
}
