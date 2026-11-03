/// ============================================================================
/// SETTING PAGE
/// ============================================================================
///
/// User settings and preferences page.
///
/// ## Features
/// - User profile display
/// - Notification toggle
/// - Dark mode toggle
/// - Navigation to product lists (liked, cart, blocked, no-recommend)
/// - Logout functionality
/// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../viewmodels/theme_viewmodel.dart';
import '../viewmodels/user_profile_viewmodel.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../../screens/blocked_products_page.dart';
import '../../../../screens/cart_products_page.dart';
import '../../../../screens/no_recommend_page.dart';
import '../../../liked_products/presentation/widgets/liked_products_page.dart';
import '../../../liked_products/presentation/providers/liked_products_provider.dart';
import '../../../product/presentation/viewmodels/cart_viewmodel.dart';
import '../../../product/presentation/viewmodels/blocked_products_viewmodel.dart';
import '../../../product/presentation/viewmodels/no_recommend_viewmodel.dart';
import '../../../chat/presentation/viewmodels/survey_data_provider.dart';
import '../../../chat/presentation/viewmodels/skin_types_data.dart';
import '../../../chat/presentation/viewmodels/survey_message_provider.dart';
import '../../../chat/presentation/viewmodels/recommend_message_provider.dart';
import '../../../chat/presentation/viewmodels/budget_message_provider.dart';
import '../../../main/presentation/providers/main_page_provider.dart';
import 'edit_profile_page.dart';

const _storage = FlutterSecureStorage();

/// Settings page widget
class SettingPage extends ConsumerStatefulWidget {
  const SettingPage({super.key});

  @override
  ConsumerState<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends ConsumerState<SettingPage> {
  bool notificationsEnabled = true;

  // 앱 버전 관리
  String _currentVersion = '1.0.0';
  String _latestVersion = '1.5.0';

  @override
  void initState() {
    super.initState();
    // 페이지 로드 시 사용자 정보 새로 받아오기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔄 SettingPage: Refreshing user profile on page load');
      final _ = ref.refresh(userProfileProvider);
    });
  }

  /// Logout and navigate to login page
  Future<void> _logout(BuildContext context) async {
    print('🔓 SettingPage._logout: Clearing all local storage data');

    try {
      // 1. FlutterSecureStorage의 모든 데이터 삭제
      await _clearAllSecureStorage();

      // 2. SharedPreferences의 모든 데이터 삭제
      await _clearAllSharedPreferences();
      print('🔓 SettingPage._logout: Clearing tokens and user data');

      // Survey 데이터 삭제 (현재 사용자의 데이터)
      await ref.read(surveyDataProvider.notifier).clear();

      // 모든 챗봇 메시지 초기화 및 provider 무효화
      try {
        // 메시지 초기화
        ref
            .read(surveyMessageProvider('chatbot_survey').notifier)
            .clearMessages();
        ref
            .read(aiMessageProvider('chatbot_find_skincare').notifier)
            .clearMessages();
        ref
            .read(budgetMessageProvider('chatbot_budget_routine').notifier)
            .clearMessages();

        // Provider 무효화하여 완전히 제거
        ref.invalidate(surveyMessageProvider('chatbot_survey'));
        ref.invalidate(aiMessageProvider('chatbot_find_skincare'));
        ref.invalidate(budgetMessageProvider('chatbot_budget_routine'));

        print('✅ Chatbot messages cleared and providers invalidated');
      } catch (e) {
        print('⚠️ Error clearing chatbot messages: $e');
      }

      // 토큰 및 사용자 정보 삭제
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
      await _storage.delete(key: 'user_email');

      // 3. Provider 상태 초기화
      await _clearAllProviderStates();

      // 4. 프로필 캐시 무효화
      ref.invalidate(userProfileProvider);

      // 5. 탭 인덱스를 0(Homepage)으로 초기화
      ref.read(mainPageTabIndexProvider.notifier).setTabIndex(0);

      print('✅ All local data cleared successfully');
    } catch (e) {
      print('❌ Error clearing local data: $e');
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  /// Clear all FlutterSecureStorage data
  Future<void> _clearAllSecureStorage() async {
    try {
      // 알려진 모든 키 삭제 (onboarding_shown은 유지 - "Don't show again" 선택 시 영구 저장)
      final keysToDelete = [
        'access_token',
        'refresh_token',
        'user_email',
        'theme_mode',
        'cart_items',
        'blocked_products',
        'no_recommend_products',
        // 'onboarding_shown', // Don't show again 설정 유지
      ];

      // 사용자별 survey_data 키도 삭제
      final userEmail = await _storage.read(key: 'user_email');
      if (userEmail != null && userEmail.isNotEmpty) {
        keysToDelete.add('survey_data_$userEmail');
      }
      keysToDelete.add('survey_data'); // fallback 키도 삭제

      // 모든 키 삭제
      for (final key in keysToDelete) {
        await _storage.delete(key: key);
      }

      print('✅ FlutterSecureStorage cleared');
    } catch (e) {
      print('❌ Error clearing FlutterSecureStorage: $e');
    }
  }

  /// Clear all SharedPreferences data
  Future<void> _clearAllSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('✅ SharedPreferences cleared');
    } catch (e) {
      print('❌ Error clearing SharedPreferences: $e');
    }
  }

  /// Clear all Provider states
  Future<void> _clearAllProviderStates() async {
    try {
      // Survey 데이터 삭제
      await ref.read(surveyDataProvider.notifier).clear();

      // 좋아요 제품 삭제
      await ref.read(likedProductsNotifierProvider.notifier).clearAll();

      // 장바구니 비우기
      ref.read(cartProvider.notifier).clearCart();

      // 차단 제품 초기화 (Provider 상태만 초기화, 저장소는 이미 삭제됨)
      ref.invalidate(blockedProductsProvider);

      // 추천 안함 제품 초기화
      ref.invalidate(noRecommendProductsProvider);

      print('✅ All Provider states cleared');
    } catch (e) {
      print('❌ Error clearing Provider states: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeNotifier = ref.read(themeProvider.notifier);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          children: [
            _buildProfileCard(theme, isDark, context),
            const SizedBox(height: 24),
            _buildNotificationToggle(theme, isDark),
            _buildDivider(isDark),
            _buildDarkModeToggle(theme, isDark, themeNotifier),
            _buildDivider(isDark),
            _buildListTile(
              theme: theme,
              isDark: isDark,
              title: 'like',
              subtitle: 'checking the liked list',
              icon: Icons.favorite_border,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LikedProductsPage()),
                );
              },
            ),
            _buildDivider(isDark),
            _buildListTile(
              theme: theme,
              isDark: isDark,
              title: 'cart products',
              subtitle: 'view your cart products',
              icon: Icons.shopping_cart_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartProductsPage()),
                );
              },
            ),
            _buildDivider(isDark),
            _buildListTile(
              theme: theme,
              isDark: isDark,
              title: 'blocking products',
              subtitle: 'view your blocking products',
              icon: Icons.block_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BlockedProductsPage(),
                  ),
                );
              },
            ),
            _buildDivider(isDark),
            _buildListTile(
              theme: theme,
              isDark: isDark,
              title: 'no recommend products',
              subtitle: 'view your no recommend products',
              icon: Icons.thumb_down_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NoRecommendPage()),
                );
              },
            ),
            _buildDivider(isDark),
            _buildCounselingTile(theme, isDark),
            _buildDivider(isDark),
            _buildAppUpdateTile(theme, isDark),
            _buildDivider(isDark),
            _buildCreditsTile(theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(ThemeData theme, bool isDark, BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return userProfileAsync.when(
      data: (userProfile) {
        // 안전한 첫 글자 추출
        String getFirstLetter(String? str) {
          if (str == null || str.isEmpty) return 'U';
          return str.substring(0, 1).toUpperCase();
        }

        final firstLetter =
            userProfile.username != null && userProfile.username!.isNotEmpty
            ? getFirstLetter(userProfile.username)
            : getFirstLetter(userProfile.email);
        print(userProfile);
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.grey[800]!.withOpacity(0.3)
                  : Colors.grey[200]!,
              width: 1,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isDark
                    ? Colors.grey[700]!.withOpacity(0.5)
                    : theme.colorScheme.primary.withOpacity(0.1),
                child: Text(
                  firstLetter,
                  style: TextStyle(
                    color: isDark
                        ? Colors.grey[300]
                        : theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username 또는 "비어있음" 표시
                    Text(
                      userProfile.username?.isNotEmpty == true
                          ? userProfile.username!
                          : '비어있음',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[100] : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // 이메일 정보
                    Text(
                      userProfile.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Skin 정보
                    Text(
                      _buildSubtitle(userProfile),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // 설문 완료 여부 확인 (survey_data 또는 서버 프로필 데이터)
              Consumer(
                builder: (context, ref, child) {
                  final surveyData = ref.watch(surveyDataProvider);

                  // survey_data 또는 서버 프로필에 피부 정보가 있으면 설문 완료로 간주
                  final hasLocalData = surveyData.isComplete;
                  final hasServerData =
                      (userProfile.skinType != null &&
                          userProfile.skinType!.isNotEmpty) ||
                      (userProfile.categories != null &&
                          userProfile.categories!.isNotEmpty);
                  final isSurveyComplete = hasLocalData || hasServerData;

                  print('🔍 Setting page: Survey complete check');
                  print(
                    '   hasLocalData: $hasLocalData (primaryType: ${surveyData.primaryType}, categories: ${surveyData.categories})',
                  );
                  print(
                    '   hasServerData: $hasServerData (skinType: ${userProfile.skinType}, categories: ${userProfile.categories})',
                  );
                  print('   isSurveyComplete: $isSurveyComplete');

                  return Row(
                    children: [
                      // Edit 버튼을 Stack으로 감싸서 자물쇠 오버레이 추가
                      Stack(
                        children: [
                          ElevatedButton(
                            onPressed: isSurveyComplete
                                ? () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditProfilePage(
                                          userProfile: userProfile,
                                        ),
                                      ),
                                    );
                                    if (result == true && mounted) {
                                      ref.invalidate(userProfileProvider);
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSurveyComplete
                                  ? theme.colorScheme.primary
                                  : Colors.grey[400],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            child: const Text('Edit'),
                          ),
                          // 설문 미완료 시 자물쇠 오버레이
                          if (!isSurveyComplete)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.lock,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _showLogoutDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF79B4A9),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.grey[800]!.withOpacity(0.3)
                : Colors.grey[200]!,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (error, stack) {
        print('❌ Profile Card Error: $error');
        // 에러 시 기본 프로필 표시 (API 미지원인 경우 대체)
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.grey[800]!.withOpacity(0.3)
                  : Colors.grey[200]!,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isDark
                    ? Colors.grey[700]!.withOpacity(0.5)
                    : theme.colorScheme.primary.withOpacity(0.1),
                child: Text(
                  'U',
                  style: TextStyle(
                    color: isDark
                        ? Colors.grey[300]
                        : theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[100] : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Profile loading...',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final _ = await ref.refresh(userProfileProvider.future);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _showLogoutDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF79B4A9),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _buildSubtitle(UserProfile userProfile) {
    final parts = <String>[];

    // 설문 데이터 가져오기
    final surveyData = ref.watch(surveyDataProvider);

    // Skin Type - 설문 데이터 우선, 없으면 프로필 데이터
    final koreanSkinType = surveyData.primaryType ?? userProfile.skinType;
    if (koreanSkinType != null && koreanSkinType.isNotEmpty) {
      // 한국어를 영어로 변환
      final englishSkinType =
          {
            '지성': 'OILY',
            '건성': 'DRY',
            '복합성': 'COMBINATION',
            '민감성': 'SENSITIVE',
          }[koreanSkinType] ??
          koreanSkinType;
      parts.add('Skin: $englishSkinType');
    } else {
      parts.add('Skin: Not set');
    }

    // Skin Condition - 설문 데이터 우선, 없으면 프로필 데이터
    final koreanCondition =
        surveyData.secondaryType ?? userProfile.skinCondition;
    if (koreanCondition != null && koreanCondition.isNotEmpty) {
      // 한국어 컨디션을 영어로 변환
      final englishCondition =
          skinSubTypeDetails[koreanCondition]?['english'] ?? koreanCondition;
      parts.add('Condition: $englishCondition');
    } else {
      parts.add('Condition: Not set');
    }

    return parts.join(' | ');
  }

  Future<void> _showEditProfileDialog(
    BuildContext context,
    UserProfile userProfile,
  ) async {
    final usernameController = TextEditingController(
      text: userProfile.username ?? '',
    );
    final skinTypeController = TextEditingController(
      text: userProfile.skinType ?? '',
    );
    final skinConditionController = TextEditingController(
      text: userProfile.skinCondition ?? '',
    );
    final ageController = TextEditingController(
      text: userProfile.age?.toString() ?? '',
    );
    final genderController = TextEditingController(
      text: userProfile.gender ?? '',
    );

    // Survey 데이터 가져오기
    final surveyData = ref.read(surveyDataProvider);

    // Skin Type 옵션 (영어)
    final skinTypeOptions = ['OILY', 'DRY', 'COMBINATION', 'SENSITIVE'];

    // 한국어-영어 변환 맵
    final koreanToEnglish = {
      '지성': 'OILY',
      '건성': 'DRY',
      '복합성': 'COMBINATION',
      '민감성': 'SENSITIVE',
    };
    final englishToKorean = {
      'OILY': '지성',
      'DRY': '건성',
      'COMBINATION': '복합성',
      'SENSITIVE': '민감성',
    };

    // 초기 선택값 설정 (survey 데이터 또는 userProfile에서)
    String? initialSkinType = surveyData.primaryType ?? userProfile.skinType;
    if (initialSkinType != null) {
      // 한국어로 저장된 경우 영어로 변환
      if (koreanToEnglish.containsKey(initialSkinType)) {
        initialSkinType = koreanToEnglish[initialSkinType];
      } else if (!skinTypeOptions.contains(initialSkinType.toUpperCase())) {
        // 알 수 없는 형식이면 null로 설정
        initialSkinType = null;
      } else {
        initialSkinType = initialSkinType.toUpperCase();
      }
    }

    String? initialSkinCondition =
        surveyData.secondaryType ?? userProfile.skinCondition;

    // 초기 화장품 목록 설정 (survey 데이터에서)
    Set<String> initialSelectedCosmetics = surveyData.categories.toSet();

    // 한국어 Skin Condition을 영어로 변환하는 맵 생성
    Map<String, String> koreanToEnglishCondition = {};
    skinSubTypeDetails.forEach((korean, details) {
      koreanToEnglishCondition[korean] = details['english'] ?? korean;
    });

    // 영어 Skin Condition을 한국어로 변환하는 맵 생성
    Map<String, String> englishToKoreanCondition = {};
    skinSubTypeDetails.forEach((korean, details) {
      final english = details['english'] ?? korean;
      englishToKoreanCondition[english] = korean;
    });

    // 초기 Skin Condition을 영어로 변환
    String? initialSkinConditionEnglish;
    if (initialSkinCondition != null) {
      initialSkinConditionEnglish =
          koreanToEnglishCondition[initialSkinCondition] ??
          initialSkinCondition;
    }

    // 선택된 skin type에 따른 skin condition 옵션 (영어로 반환)
    List<String> getSkinConditionOptionsEnglish(String? skinType) {
      if (skinType == null) return [];
      // 영어로 된 skin type을 한국어로 변환
      final koreanSkinType = englishToKorean[skinType] ?? skinType;
      final koreanConditions = skinSubTypes[koreanSkinType] ?? [];
      // 한국어 조건을 영어로 변환
      return koreanConditions
          .map((korean) => koreanToEnglishCondition[korean] ?? korean)
          .toList();
    }

    // 상태 변수 (함수 스코프 밖에서 선언)
    String? selectedSkinType = initialSkinType;
    String? selectedSkinCondition = initialSkinConditionEnglish; // 영어로 저장
    Set<String> selectedCosmetics = Set.from(initialSelectedCosmetics);
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // 선택된 skin type에 따른 condition 옵션 (영어)
            final conditionOptions = getSkinConditionOptionsEnglish(
              selectedSkinType,
            );

            return AlertDialog(
              title: const Text('Edit Profile'),
              contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(labelText: 'Username'),
                    ),
                    const SizedBox(height: 12),
                    // Skin Type 드롭다운
                    DropdownButtonFormField<String>(
                      value: selectedSkinType,
                      decoration: const InputDecoration(
                        labelText: 'Skin Type',
                        border: OutlineInputBorder(),
                      ),
                      items: skinTypeOptions.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        selectedSkinType = newValue;
                        // Skin type이 변경되면 condition 초기화
                        selectedSkinCondition = null;
                        setDialogState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    // Skin Condition 드롭다운
                    DropdownButtonFormField<String>(
                      value: selectedSkinCondition,
                      decoration: const InputDecoration(
                        labelText: 'Skin Condition',
                        border: OutlineInputBorder(),
                      ),
                      items: conditionOptions.map((String condition) {
                        return DropdownMenuItem<String>(
                          value: condition,
                          child: Text(condition),
                        );
                      }).toList(),
                      onChanged: conditionOptions.isEmpty
                          ? null
                          : (String? newValue) {
                              selectedSkinCondition = newValue;
                              setDialogState(() {});
                            },
                      hint: conditionOptions.isEmpty
                          ? const Text('Select Skin Type first')
                          : null,
                    ),
                    const SizedBox(height: 12),
                    // 화장품 목록 다중 선택
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Cosmetics (Select multiple)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          LimitedBox(
                            maxHeight: 150,
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: cosmeticTypes.map((cosmetic) {
                                  final isSelected = selectedCosmetics.contains(
                                    cosmetic,
                                  );

                                  return CheckboxListTile(
                                    title: Text(cosmetic),
                                    value: isSelected,
                                    onChanged: (bool? value) {
                                      if (value == true) {
                                        selectedCosmetics.add(cosmetic);
                                      } else {
                                        selectedCosmetics.remove(cosmetic);
                                      }
                                      setDialogState(() {});
                                    },
                                    dense: true,
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ageController,
                      decoration: const InputDecoration(labelText: 'Age'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: genderController,
                      decoration: const InputDecoration(labelText: 'Gender'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setDialogState(() => isLoading = true);

                          // 영어로 선택된 skin type을 한국어로 변환
                          final koreanSkinType = selectedSkinType != null
                              ? (englishToKorean[selectedSkinType] ??
                                    selectedSkinType)
                              : null;

                          // 영어로 선택된 skin condition을 한국어로 변환
                          final koreanSkinCondition =
                              selectedSkinCondition != null
                              ? (englishToKoreanCondition[selectedSkinCondition] ??
                                    selectedSkinCondition)
                              : null;

                          final updatedProfile = UserProfile(
                            id: userProfile.id,
                            email: userProfile.email,
                            username: usernameController.text.isNotEmpty
                                ? usernameController.text
                                : null,
                            skinType: koreanSkinType,
                            skinCondition: koreanSkinCondition,
                            age: ageController.text.isNotEmpty
                                ? int.tryParse(ageController.text)
                                : null,
                            gender: genderController.text.isNotEmpty
                                ? genderController.text
                                : null,
                          );

                          try {
                            await ref.read(
                              updateUserProfileProvider(updatedProfile).future,
                            );

                            // Survey 데이터도 업데이트
                            final surveyNotifier = ref.read(
                              surveyDataProvider.notifier,
                            );
                            // 영어로 선택된 skin type을 한국어로 변환해서 저장
                            if (selectedSkinType != null) {
                              final koreanSkinType =
                                  englishToKorean[selectedSkinType] ??
                                  selectedSkinType;
                              surveyNotifier.setPrimaryType(koreanSkinType);
                            }
                            if (selectedSkinCondition != null) {
                              final koreanSkinCondition =
                                  englishToKoreanCondition[selectedSkinCondition] ??
                                  selectedSkinCondition;
                              surveyNotifier.setSecondaryType(
                                koreanSkinCondition,
                              );
                            }
                            surveyNotifier.setCategories(
                              selectedCosmetics.toList(),
                            );

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Profile updated successfully'),
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: ${e.toString()}')),
                            );
                          } finally {
                            setDialogState(() => isLoading = false);
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout? All local data will be cleared.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => _logout(context),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark
          ? Colors.grey[800]!.withOpacity(0.5) // 다크모드: 더 부드러운 구분선
          : Colors.grey[200]!,
    );
  }

  Widget _buildNotificationToggle(ThemeData theme, bool isDark) {
    return Container(
      color: Colors.transparent,
      child: SwitchListTile.adaptive(
        title: Text(
          'notification',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[200] : Colors.black87,
          ),
        ),
        subtitle: Text(
          'allow notifications',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
        secondary: Icon(
          Icons.notifications_none,
          color: isDark ? Colors.grey[400] : Colors.grey[700],
        ),
        value: notificationsEnabled,
        activeColor: const Color(0xFF79B4A9), // Misty Green
        onChanged: (v) => setState(() => notificationsEnabled = v),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildDarkModeToggle(
    ThemeData theme,
    bool isDark,
    ThemeNotifier themeNotifier,
  ) {
    return Container(
      color: Colors.transparent,
      child: SwitchListTile.adaptive(
        title: Text(
          'dark mode',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[200] : Colors.black87,
          ),
        ),
        subtitle: Text(
          'choosing the theme of my app',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
        secondary: Icon(
          Icons.dark_mode_outlined,
          color: isDark ? Colors.grey[400] : Colors.grey[700],
        ),
        value: isDark,
        activeColor: const Color(0xFF79B4A9), // Misty Green
        onChanged: (v) => themeNotifier.toggleTheme(v),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildListTile({
    required ThemeData theme,
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      color: Colors.transparent,
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[200] : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
        leading: Icon(
          icon,
          color: isDark ? Colors.grey[400] : Colors.grey[700],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isDark ? Colors.grey[600] : Colors.grey[400],
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildCounselingTile(ThemeData theme, bool isDark) {
    return Container(
      color: Colors.transparent,
      child: ListTile(
        title: Text(
          'counseling',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[200] : Colors.black87,
          ),
        ),
        subtitle: Text(
          'provide 24/7 professional counseling.',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
        leading: Icon(
          Icons.support_agent_outlined,
          color: isDark ? Colors.grey[400] : Colors.grey[700],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF79B4A9), // Misty Green으로 변경
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ],
        ),
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Contact Us',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              content: const Text(
                'If you have any inquiries, please send them to:\n\nmobilepuang@cau.ac.kr',
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildAppUpdateTile(ThemeData theme, bool isDark) {
    return Container(
      color: Colors.transparent,
      child: ListTile(
        title: Text(
          'App update',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[200] : Colors.black87,
          ),
        ),
        subtitle: Text(
          '$_currentVersion(250201)',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
        leading: Icon(
          Icons.system_update_alt_outlined,
          color: isDark ? Colors.grey[400] : Colors.grey[700],
        ),
        onTap: () => _showUpdateDialog(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  /// Credits / Sources tile
  Widget _buildCreditsTile(ThemeData theme, bool isDark) {
    return Container(
      color: Colors.transparent,
      child: ListTile(
        title: Text(
          'sources',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[200] : Colors.black87,
          ),
        ),
        subtitle: Text(
          'view assets and credits',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
        leading: Icon(
          Icons.info_outline,
          color: isDark ? Colors.grey[400] : Colors.grey[700],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isDark ? Colors.grey[600] : Colors.grey[400],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () {
          showDialog(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text(
                  'Credits',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                content: const Text(
                  'Rive coin made by NorbertC\nchat_bot_icon made by musaadanur',
                  style: TextStyle(fontSize: 16),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Close'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// 앱 업데이트 다이얼로그 표시
  void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Update Available',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: Text(
          'You can now update this app from $_currentVersion to $_latestVersion',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Maybe Later',
              style: TextStyle(color: Colors.blue[600], fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _performUpdate(context);
            },
            child: Text(
              'Update',
              style: TextStyle(
                color: Colors.blue[600],
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 업데이트 수행
  void _performUpdate(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Updating...'),
              ],
            ),
          ),
        ),
      ),
    );

    // 3초 후 업데이트 완료
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pop(context); // 로딩 다이얼로그 닫기
      setState(() {
        _currentVersion = _latestVersion;
        // 다음 버전 설정 (예: 1.5.0 -> 2.0.0)
        final parts = _latestVersion.split('.');
        final major = int.parse(parts[0]);
        final minor = int.parse(parts[1]);
        if (minor >= 5) {
          _latestVersion = '${major + 1}.0.0';
        } else {
          _latestVersion = '$major.${minor + 5}.0';
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('App updated to $_currentVersion successfully!'),
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }
}
