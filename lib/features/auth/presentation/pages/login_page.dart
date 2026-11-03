import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../../core/theme/app_colors.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'signup_page.dart';
import '../../../settings/presentation/viewmodels/user_profile_viewmodel.dart';
import '../../../chat/presentation/viewmodels/survey_data_provider.dart';
import '../../../chat/presentation/viewmodels/survey_message_provider.dart';
import '../../../chat/presentation/viewmodels/recommend_message_provider.dart';
import '../../../chat/presentation/viewmodels/budget_message_provider.dart';

/// Login page for user authentication
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _getErrorMessage(String? errorMessage) {
    if (errorMessage == null || errorMessage.isEmpty) {
      return 'Login failed';
    }

    // API 응답 형식: "error_code: Description"
    if (errorMessage.contains('EMPTY_FIELD')) {
      return 'Please fill in all required fields';
    }
    if (errorMessage.contains('INVALID_EMAIL')) {
      return 'Invalid email format';
    }
    if (errorMessage.contains('INVALID_PASSWORD')) {
      return 'Invalid password';
    }
    if (errorMessage.contains('USER_NOT_FOUND')) {
      return 'User not found';
    }
    if (errorMessage.contains('SERVER_ERROR')) {
      return 'Server error occurred';
    }
    if (errorMessage.contains('NETWORK_ERROR')) {
      return 'Please check your network connection';
    }

    return errorMessage;
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showToast(
        "Please fill in all required fields",
        isDarkMode: Theme.of(context).brightness == Brightness.dark,
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await ref
        .read(authProvider.notifier)
        .signIn(_emailController.text, _passwordController.text);

    setState(() => _isLoading = false);

    if (success && mounted) {
      _showToast(
        "Login successful!",
        isDarkMode: Theme.of(context).brightness == Brightness.dark,
      );

      // 로그인 성공 시 모든 챗봇 메시지 초기화
      try {
        ref.read(surveyMessageProvider('chatbot_survey').notifier).clearMessages();
        ref.read(aiMessageProvider('chatbot_find_skincare').notifier).clearMessages();
        ref.read(budgetMessageProvider('chatbot_budget_routine').notifier).clearMessages();
        print('✅ LoginPage: All chatbot messages cleared after login');
      } catch (e) {
        print('⚠️ LoginPage: Error clearing chatbot messages: $e');
      }

      // 로그인 성공 후 사용자 정보 미리 받아오기
      print('🔄 LoginPage: Pre-fetching user profile after successful login');
      Future.delayed(const Duration(milliseconds: 500), () async {
        if (mounted) {
          // userProfileProvider를 미리 로드하여 설정 페이지에서 빠르게 표시되도록
          try {
            final profile = await ref.refresh(userProfileProvider.future);
            print(
              '✅ LoginPage: Profile loaded - ${profile.username} (${profile.email})',
            );

            // 서버에서 받은 프로필로 survey_data 동기화
            final hasSkinData =
                profile.skinType != null || profile.skinCondition != null;
            final hasCategories =
                profile.categories != null && profile.categories!.isNotEmpty;

            if (hasSkinData || hasCategories) {
              print('🔄 LoginPage: Syncing survey_data from server profile');
              final surveyNotifier = ref.read(surveyDataProvider.notifier);

              if (profile.skinType != null && profile.skinType!.isNotEmpty) {
                surveyNotifier.setPrimaryType(profile.skinType!);
                print('   - primaryType: ${profile.skinType}');
              }

              if (profile.skinCondition != null &&
                  profile.skinCondition!.isNotEmpty) {
                surveyNotifier.setSecondaryType(profile.skinCondition!);
                print('   - secondaryType: ${profile.skinCondition}');
              }

              if (hasCategories) {
                surveyNotifier.setCategories(profile.categories!);
                print('   - categories: ${profile.categories}');
              }

              print('✅ LoginPage: Survey data synced from server');
            }
          } catch (e) {
            print('⚠️ LoginPage: Error pre-fetching profile: $e');
            // 오류가 발생해도 계속 진행 (프로필 로딩은 선택사항)
          }
        }
      });

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/main',
        (Route<dynamic> route) => false,
      );
    } else {
      final errorMessage = ref.read(authProvider).errorMessage;
      final displayMessage = _getErrorMessage(errorMessage);
      _showToast(
        displayMessage,
        isDarkMode: Theme.of(context).brightness == Brightness.dark,
      );
    }
  }

  /// Show toast message with dark mode support
  void _showToast(String message, {required bool isDarkMode}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.black87,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: isDarkMode
          ? theme.scaffoldBackgroundColor
          : Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/images/logo_image.png",
                width: 400,
                height: 400,
              ),
              Form(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 80.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Enter email',
                          labelStyle: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.teal,
                            fontSize: 15.0,
                          ),
                          filled: true,
                          fillColor: isDarkMode
                              ? Colors.grey[900]
                              : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: isDarkMode
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.teal,
                              width: 2,
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Enter password',
                          labelStyle: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.teal,
                            fontSize: 15.0,
                          ),
                          filled: true,
                          fillColor: isDarkMode
                              ? Colors.grey[900]
                              : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: isDarkMode
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.teal,
                              width: 2,
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.text,
                        obscureText: true,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 40.0),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Login'),
                      ),
                      const SizedBox(height: 10.0),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignUpPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode
                              ? Colors.grey[800]
                              : Colors.white,
                          foregroundColor: AppColors.primary,
                          minimumSize: const Size(double.infinity, 50),
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                            side: BorderSide(
                              color: isDarkMode
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
