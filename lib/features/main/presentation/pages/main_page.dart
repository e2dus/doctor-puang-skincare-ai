/// ============================================================================
/// MAIN PAGE
/// ============================================================================
///
/// Main navigation hub with bottom navigation bar.
///
/// ## Screens
/// - Home (index 0): Product rankings and promotions
/// - ChatBot (index 1): AI skincare assistant
/// - Calendar (index 2): Skincare routine tracking
/// - Dashboard (index 3): User statistics (placeholder)
/// - Settings (index 4): App preferences
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../product/presentation/pages/home_page.dart';
import '../../../chat/presentation/pages/chat_bot_page.dart';
import '../../../chat/presentation/viewmodels/chat_bot_state_provider.dart';
import '../../../chat/presentation/viewmodels/survey_message_provider.dart';
import '../../../chat/presentation/viewmodels/skincare_score_provider.dart';
import '../../../skincare/presentation/pages/calendar_page.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../../../settings/presentation/pages/setting_page.dart';
import '../providers/main_page_provider.dart';
import '../../../auth/presentation/pages/onboarding_page.dart';

/// Main page with bottom navigation
class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  int get _selectedIndex => ref.watch(mainPageTabIndexProvider);

  @override
  void initState() {
    super.initState();
    // Show onboarding dialog after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final shouldShow = await OnboardingDialog.shouldShowOnboarding();
        if (shouldShow && mounted) {
          OnboardingDialog.show(context);
        }
      }
    });
  }

  /// Screen widgets for each tab
  final List<Widget> _screens = const [
    HomePage(),
    ChatBotPage(),
    CalendarPage(),
    DashboardPage(),
    SettingPage(),
  ];

  /// Tab titles
  final List<String> _titles = const [
    'Home',
    'ChatBot',
    'Calendar',
    'History',
    'Setting',
  ];

  /// Handle tab selection
  void _onItemTapped(int index) {
    ref.read(mainPageTabIndexProvider.notifier).setTabIndex(index);

    // History 탭을 선택할 때마다 스킨 점수 재계산 시도
    if (index == 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(skincareScoreProvider.notifier).calculateScore();
      });
    }
  }

  /// Handle AppBar back button press (ChatBot only)
  void _handleBackButton() {
    if (_selectedIndex == 1) {
      // ChatBot tab - handle back navigation
      final hasStartedChat = ref.read(chatBotStateProvider);
      if (hasStartedChat) {
        ref.read(chatBotStateProvider.notifier).setHasStartedChat(false);
        ref
            .read(surveyMessageProvider('chatbot_survey').notifier)
            .clearMessages();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasStartedChat = ref.watch(chatBotStateProvider);
    final isChatBotPage = _selectedIndex == 1;

    return Scaffold(
      appBar: _buildAppBar(isChatBotPage, hasStartedChat),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  AppBar _buildAppBar(bool isChatBotPage, bool hasStartedChat) {
    // ChatBot 페이지에서 채팅이 시작된 경우에만 뒤로가기 버튼 표시
    final bool showBackButton = isChatBotPage && hasStartedChat;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _handleBackButton,
              color: isDarkMode ? Colors.white : Colors.black87,
            )
          : null,
      leadingWidth: showBackButton ? 56 : 0,
      title: Text(
        _titles[_selectedIndex],
        style: TextStyle(
          fontFamily: 'HelveticaNeue93',
          fontWeight: FontWeight.w700,
          color: isDarkMode ? Colors.white : Colors.black87,
          fontSize: 20,
          letterSpacing: -0.5,
        ),
      ),
      centerTitle: true,
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: isDarkMode
          ? const Color(0xFF1E1E1E) // AppColors.darkSurface
          : Colors.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: isDarkMode
              ? const Color(0xFF2E2E2E) // 다크모드 구분선
              : const Color(0xFFE0E0E0), // 라이트모드 구분선
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 색상 스키마 (다크모드 지원)
    final Color backgroundColor = isDarkMode
        ? const Color(0xFF1E1E1E) // AppColors.darkSurface
        : const Color(0xFFFFFFFF); // #FFFFFF (White)
    const Color activeColor = Color(0xFF79B4A9); // #79B4A9 (Misty Green) - 동일
    final Color inactiveColor = isDarkMode
        ? const Color(0xFFAAAAAA) // 다크모드: 더 밝은 회색
        : const Color(0xFF888888); // #888888 (Medium Gray)
    final Color separatorColor = isDarkMode
        ? const Color(0xFF2E2E2E) // 다크모드 구분선
        : const Color(0xFFE0E0E0); // #E0E0E0 (아주 옅은 회색)

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(top: BorderSide(color: separatorColor, width: 1)),
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                _selectedIndex == 0 ? Icons.home : Icons.home_outlined,
              ),
              activeIcon: const Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                _selectedIndex == 1
                    ? Icons.chat_bubble
                    : Icons.chat_bubble_outline,
              ),
              activeIcon: const Icon(Icons.chat_bubble),
              label: 'ChatBot',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                _selectedIndex == 2
                    ? Icons.calendar_month
                    : Icons.calendar_month_outlined,
                size: _selectedIndex == 2 ? 28 : 26,
              ),
              activeIcon: const Icon(Icons.calendar_month, size: 28),
              label: 'Calendar',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                _selectedIndex == 3 ? Icons.insights : Icons.insights_outlined,
              ),
              activeIcon: const Icon(Icons.insights),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                _selectedIndex == 4 ? Icons.settings : Icons.settings_outlined,
              ),
              activeIcon: const Icon(Icons.settings),
              label: 'Setting',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: backgroundColor,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: activeColor,
          unselectedItemColor: inactiveColor,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0.2,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
            letterSpacing: 0.2,
          ),
          iconSize: 24,
          showUnselectedLabels: true,
        ),
      ),
    );
  }
}
