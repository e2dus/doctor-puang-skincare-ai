import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/theme/app_colors.dart';

/// Onboarding page for first-time users
///
/// Shows app introduction and guides users through key features
class OnboardingDialog extends StatefulWidget {
  const OnboardingDialog({super.key});

  /// Check if onboarding should be shown
  /// Returns true if user hasn't seen onboarding yet
  static Future<bool> shouldShowOnboarding() async {
    try {
      const storage = FlutterSecureStorage();
      final shown = await storage.read(key: 'onboarding_shown');
      return shown != 'true';
    } catch (e) {
      // If error, show onboarding to be safe
      return true;
    }
  }

  /// Show onboarding dialog
  static Future<void> show(BuildContext context) async {
    if (!context.mounted) return;

    final shouldShow = await shouldShowOnboarding();
    if (!shouldShow) return;

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const OnboardingDialog(),
    );
  }

  @override
  State<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<OnboardingDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: 'Welcome to Doctor Puang!',
      description:
          'AI-powered skincare assistant that helps you find the perfect products for your skin.',
      icon: Icons.spa,
    ),
    OnboardingPageData(
      title: 'Personalized Recommendations',
      description:
          'Get AI-powered product recommendations based on your skin type and preferences.',
      icon: Icons.auto_awesome,
    ),
    OnboardingPageData(
      title: 'Track Your Routine',
      description:
          'Manage your daily skincare routine and track your progress with our calendar feature.',
      icon: Icons.calendar_today,
    ),
    OnboardingPageData(
      title: 'Discover Products',
      description:
          'Browse, like, and save your favorite skincare products. Build your perfect routine!',
      icon: Icons.shopping_bag,
    ),
    OnboardingPageData(
      title: 'AI Chat Assistant',
      description:
          'Chat with our AI assistant to get personalized skincare advice and product recommendations.',
      icon: Icons.chat_bubble_outline,
    ),
    OnboardingPageData(
      title: '',
      description: '',
      icon: Icons.help_outline,
      isSpecialPage: true,
      imagePath: 'assets/images/1.png',
    ),
    OnboardingPageData(
      title: '',
      description: '',
      icon: Icons.help_outline,
      isSpecialPage: true,
      imagePath: 'assets/images/2.png',
    ),
    OnboardingPageData(
      title: '',
      description: '',
      icon: Icons.help_outline,
      isSpecialPage: true,
      imagePath: 'assets/images/3.png',
    ),
    OnboardingPageData(
      title: '',
      description: '',
      icon: Icons.help_outline,
      isSpecialPage: true,
      imagePath: 'assets/images/4.png',
    ),
    OnboardingPageData(
      title: 'Your Skincare Journey',
      description:
          'Track your progress, see your skincare score, and compare with friends. Start your journey today!',
      icon: Icons.trending_up,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding({bool dontShowAgain = false}) async {
    // "Don't show again" 선택 시 영구적으로 저장
    if (dontShowAgain) {
      try {
        const storage = FlutterSecureStorage();
        await storage.write(key: 'onboarding_shown', value: 'true');
      } catch (e) {
        debugPrint('Error saving onboarding preference: $e');
      }
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _skipOnboarding() async {
    await _completeOnboarding();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: screenSize.width * 0.9,
        height: screenSize.height * 0.88,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 750),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Skip button at top
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _skipOnboarding,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => _buildPageIndicator(index == _currentPage),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  if (_pages[index].isSpecialPage) {
                    return _buildSpecialPage(
                      context,
                      screenSize,
                      _pages[index].imagePath ?? 'assets/images/1.png',
                    );
                  }
                  return _buildPageContent(_pages[index], screenSize);
                },
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentPage > 0)
                        TextButton(
                          onPressed: _previousPage,
                          child: const Text(
                            'Previous',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 80),
                      ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _currentPage == _pages.length - 1
                              ? 'Get Started'
                              : 'Next',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Don't show again button
                  TextButton(
                    onPressed: () => _completeOnboarding(dontShowAgain: true),
                    child: const Text(
                      "Don't show again",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildPageContent(OnboardingPageData pageData, Size screenSize) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(pageData.icon, size: 70, color: AppColors.primary),
          ),
          const SizedBox(height: 40),
          // Title
          Text(
            pageData.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // Description
          Text(
            pageData.description,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialPage(
    BuildContext context,
    Size screenSize,
    String imagePath,
  ) {
    // Dialog의 실제 크기 계산
    final double dialogWidth = screenSize.width * 0.9 > 500
        ? 500
        : screenSize.width * 0.9;
    final double dialogHeight = screenSize.height * 0.88 > 750
        ? 750
        : screenSize.height * 0.88;

    // 챗봇 버튼 위치 (BottomNavigationBar의 ChatBot 탭 위치)
    // 일반적으로 화면 하단 중앙에서 두 번째 위치
    final double bottomNavHeight = 60.0;
    final double bottomNavItemWidth = dialogWidth / 5;
    final double chatBotButtonCenterX =
        dialogWidth / 5 * 1.5; // 두 번째 탭 (index 1)
    final double chatBotButtonTop = dialogHeight - bottomNavHeight - 20;

    return Stack(
      children: [
        // 배경 이미지 - 잘리지 않도록 contain 사용
        Positioned.fill(
          child: Container(
            color: Colors.white,
            child: Center(
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                width: dialogWidth,
                height: dialogHeight,
              ),
            ),
          ),
        ),
        // 챗봇 버튼 하이라이트 박스
        Positioned(
          top: chatBotButtonTop - 30,
          left: chatBotButtonCenterX - bottomNavItemWidth / 2,
          child: Container(
            width: bottomNavItemWidth,
            height: bottomNavHeight + 20,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary, width: 3),
            ),
          ),
        ),
        // 화살표와 설명
        Positioned(
          top: chatBotButtonTop - 100,
          left: chatBotButtonCenterX,
          child: Column(
            children: [
              // 화살표
              Icon(Icons.arrow_downward, color: Colors.white, size: 40),
              const SizedBox(height: 8),
              // 설명 텍스트
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(0, 0, 0, 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Please tap this button to enter your information',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Data class for onboarding page content
class OnboardingPageData {
  final String title;
  final String description;
  final IconData icon;
  final bool isSpecialPage;
  final String? imagePath;

  const OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
    this.isSpecialPage = false,
    this.imagePath,
  });
}
