import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../../core/theme/app_colors.dart';
import '../viewmodels/auth_viewmodel.dart';

/// Sign up page for new user registration
class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _errorTimer;

  @override
  void dispose() {
    _errorTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _setError(String message) {
    _errorTimer?.cancel();
    setState(() => _errorMessage = message);
    _errorTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _errorMessage = null);
      }
    });
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    // Basic email validation regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  String _getErrorMessage(String? errorMessage) {
    if (errorMessage == null || errorMessage.isEmpty) {
      return 'Sign up failed';
    }

    print('📱 SignUpPage: Error message = $errorMessage');

    // API 응답 형식: "error_code" 또는 "error_code: Description"
    if (errorMessage.contains('USER_EXISTS')) {
      return 'Email already registered';
    }
    if (errorMessage.contains('409')) {
      return 'Email already registered';
    }
    if (errorMessage.contains('EMPTY_FIELD')) {
      return 'Please fill in all required fields';
    }
    if (errorMessage.contains('Unknown Type')) {
      return 'Please fill in all required fields';
    }
    if (errorMessage.contains('400')) {
      return 'Invalid request. Please fill in all fields correctly';
    }
    if (errorMessage.contains('500')) {
      return 'Server error occurred';
    }
    if (errorMessage.contains('INVALID_EMAIL')) {
      return 'Invalid email format';
    }
    if (errorMessage.contains('WEAK_PASSWORD')) {
      return 'Password is too weak';
    }
    if (errorMessage.contains('SERVER_ERROR')) {
      return 'Server error occurred';
    }

    return 'Error: $errorMessage';
  }

  Future<void> _handleSignUp() async {
    if (_isLoading) return;

    // Clear previous error
    _errorTimer?.cancel();
    setState(() => _errorMessage = null);

    // Validation
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_nameController.text.isEmpty) {
      _setError("Name is required");
      return;
    }

    if (_nameController.text.length > 8) {
      _setError("Username must be 8 characters or less");
      return;
    }

    if (_emailController.text.isEmpty) {
      _setError("Email is required");
      return;
    }

    // Validate email format
    if (!_isValidEmail(_emailController.text.trim())) {
      _setError("Invalid email format. Please try again.");
      return;
    }

    if (_passwordController.text.isEmpty) {
      _setError("Password is required");
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _setError("Passwords do not match. Please try again.");
      return;
    }

    setState(() => _isLoading = true);

    final success = await ref
        .read(authProvider.notifier)
        .signUp(
          _emailController.text,
          _passwordController.text,
          username: _nameController.text,
        );

    setState(() => _isLoading = false);

    if (success && mounted) {
      _showToast("Sign up completed successfully!", isDarkMode: isDarkMode);
      // 회원가입 성공 후 로그인 페이지로 이동
      Navigator.of(context).pushReplacementNamed('/login');
    } else {
      final errorMessage = ref.read(authProvider).errorMessage;
      print('📱 SignUpPage: Signup failed with error: $errorMessage');
      final displayMessage = _getErrorMessage(errorMessage);
      _showToast(displayMessage, isDarkMode: isDarkMode);
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

    InputDecoration _buildInputDecoration(String label) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDarkMode ? Colors.grey[400] : Colors.black87,
          fontSize: 14,
        ),
        floatingLabelStyle: TextStyle(
          color: isDarkMode ? Colors.grey[200] : Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: isDarkMode ? Colors.grey[900] : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey.shade400,
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode
          ? theme.scaffoldBackgroundColor
          : Colors.white,
      appBar: AppBar(
        title: Text(
          'Sign Up',
          style: TextStyle(
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
        ),
        backgroundColor: isDarkMode
            ? theme.scaffoldBackgroundColor
            : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : AppColors.textPrimary,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/images/logo_image.png",
                  width: 200,
                  height: 200,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: _buildInputDecoration('Name'),
                  maxLength: 8,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: _buildInputDecoration('Email'),
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: _buildInputDecoration('Password'),
                  obscureText: true,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  decoration: _buildInputDecoration('Confirm Password'),
                  obscureText: true,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
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
                      : const Text('Sign Up'),
                ),
                // Error message display
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
