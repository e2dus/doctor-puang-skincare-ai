import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/viewmodels/survey_message_provider.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/viewmodels/survey_data_provider.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/viewmodels/skin_types_data.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/viewmodels/recommend_message_provider.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/viewmodels/budget_message_provider.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/widgets/rive_logo_animation.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/widgets/rive_coin_animation.dart';
import 'package:mobileprogramming_groupproject_2025/core/theme/app_colors.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/pages/chat_survey_page.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/pages/chat_find_skincare_page.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/pages/chat_budget_routine_page.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/pages/chat_compare_page.dart';
import '../../../settings/presentation/viewmodels/user_profile_viewmodel.dart';

class ChatBotPage extends ConsumerStatefulWidget {
  const ChatBotPage({super.key});

  @override
  ConsumerState<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends ConsumerState<ChatBotPage> {
  // 각 카드의 눌림 상태 추적
  bool _isProductCardPressed = false;
  bool _isCompareCardPressed = false;
  bool _isBudgetCardPressed = false;

  @override
  void initState() {
    super.initState();
    // 페이지가 처음 로드될 때 모든 챗봇 메시지 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChatbotMessages();
    });
  }

  /// 챗봇 메시지 초기화
  void _initializeChatbotMessages() {
    try {
      // 모든 챗봇 메시지 초기화
      ref
          .read(surveyMessageProvider('chatbot_survey').notifier)
          .clearMessages();
      ref
          .read(aiMessageProvider('chatbot_find_skincare').notifier)
          .clearMessages();
      ref
          .read(budgetMessageProvider('chatbot_budget_routine').notifier)
          .clearMessages();
      print('✅ ChatBotPage: All chatbot messages initialized');
    } catch (e) {
      print('⚠️ ChatBotPage: Error initializing chatbot messages: $e');
    }
  }

  /// 설문 조사 시작 (go! 버튼 클릭 시) - chat_survey_page로 이동
  void _startSurvey() {
    // 설문 데이터와 메시지 모두 초기화 (처음부터 다시 시작)
    ref.read(surveyDataProvider.notifier).clear();
    ref.read(surveyMessageProvider('chatbot_survey').notifier).clearMessages();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatSurveyPage()),
    );
  }

  /// Find Your Perfect Skincare 카드 클릭 시 - chat_find_skincare_page로 이동
  void _startProductRecommendation() {
    debugPrint('Find Your Perfect Skincare 카드 클릭됨');
    debugPrint('Navigator.push 호출 전');
    try {
      Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChatFindSkincarePage(),
            ),
          )
          .then((_) {
            debugPrint('ChatFindSkincarePage에서 돌아옴');
          })
          .catchError((error) {
            debugPrint('Navigator.push 오류: $error');
          });
      debugPrint('Navigator.push 호출 후');
    } catch (e, stackTrace) {
      debugPrint('_startProductRecommendation 오류: $e');
      debugPrint('스택 트레이스: $stackTrace');
    }
  }

  /// 예산 맞춤 루틴 카드 클릭 시 - chat_budget_routine_page로 이동
  void _startBudgetRoutine() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatBudgetRoutinePage()),
    );
  }

  /// 제품 비교 카드 클릭 시 - chat_compare_page로 이동
  void _startCompareProducts() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatComparePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      child: _buildSuggestionsView(),
    );
  }

  /// Suggestions 화면 빌드
  Widget _buildSuggestionsView() {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 애니메이션과 피부 타입 컨테이너 (나란히 배치)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 왼쪽: 피부 타입 컨테이너
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final surveyData = ref.watch(surveyDataProvider);
                        final userProfileAsync = ref.watch(userProfileProvider);

                        // 사용자 이름 추출
                        final username = userProfileAsync.maybeWhen(
                          data: (profile) => profile.username ?? 'there',
                          orElse: () => 'there',
                        );

                        // survey_data 또는 서버 프로필에 피부 정보가 있는지 확인
                        final hasLocalData =
                            surveyData.isComplete &&
                            surveyData.primaryType != null;
                        final hasServerData = userProfileAsync.maybeWhen(
                          data: (profile) =>
                              (profile.skinType != null &&
                              profile.skinType!.isNotEmpty),
                          orElse: () => false,
                        );
                        final isSurveyComplete = hasLocalData || hasServerData;

                        // 설문이 완료되었는지 확인
                        if (isSurveyComplete) {
                          // 설문 완료 후 메시지 - 높이를 늘려서 공간 채우기
                          // 한국어 피부 타입을 영어로 변환
                          final englishSkinTypeMap = {
                            '지성': 'OILY',
                            '건성': 'DRY',
                            '복합성': 'COMBINATION',
                            '민감성': 'SENSITIVE',
                          };

                          // 스킨 타입: surveyData 우선, 없으면 서버 프로필에서 가져오기
                          String? primaryType = surveyData.primaryType;
                          String? secondaryType = surveyData.secondaryType;

                          // surveyData에 없으면 서버 프로필에서 가져오기
                          if (primaryType == null || primaryType.isEmpty) {
                            primaryType = userProfileAsync.maybeWhen(
                              data: (profile) => profile.skinType,
                              orElse: () => null,
                            );
                          }

                          if ((secondaryType == null ||
                                  secondaryType.isEmpty ||
                                  secondaryType ==
                                      "I'm not sure.... plz help!") &&
                              hasServerData) {
                            secondaryType = userProfileAsync.maybeWhen(
                              data: (profile) => profile.skinCondition,
                              orElse: () => null,
                            );
                          }

                          String skinTypeText =
                              englishSkinTypeMap[primaryType] ??
                              primaryType ??
                              '';
                          String subTypeText = '';

                          if (secondaryType != null &&
                              secondaryType.isNotEmpty &&
                              secondaryType != "I'm not sure.... plz help!") {
                            // 세부 타입도 영어로 변환
                            final subTypeDetails =
                                skinSubTypeDetails[secondaryType];
                            final englishSubType =
                                subTypeDetails?['english'] ?? secondaryType;
                            subTypeText = ' and $englishSubType';
                          }

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[800]
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: RichText(
                              textAlign: TextAlign.left,
                              textHeightBehavior: const TextHeightBehavior(
                                applyHeightToFirstAscent: false,
                                applyHeightToLastDescent: false,
                              ),
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 18,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black87,
                                  fontFamily: 'Helvetica',
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Hi ',
                                    style: TextStyle(height: 1.0),
                                  ),
                                  TextSpan(
                                    text: username,
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors
                                                .black, // 다크모드: 흰색, 라이트모드: 검정색
                                      fontFamily: 'HelveticaNeue93',
                                      fontWeight: FontWeight.w900,
                                      height: 0.1,
                                      fontSize: 18,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        '! You have $skinTypeText$subTypeText skin type! Let me help you! 😊',
                                    style: TextStyle(height: 1.2),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // 설문 전 메시지 - 서버에 스킨 타입 정보가 있는지 확인
                        final hasServerSkinType = userProfileAsync.maybeWhen(
                          data: (profile) =>
                              (profile.skinType != null &&
                              profile.skinType!.isNotEmpty),
                          orElse: () => false,
                        );

                        String? serverSkinTypeText;
                        if (hasServerSkinType) {
                          final userProfile = userProfileAsync.maybeWhen(
                            data: (profile) => profile,
                            orElse: () => null,
                          );
                          if (userProfile != null &&
                              userProfile.skinType != null) {
                            // 한국어 피부 타입을 영어로 변환
                            final englishSkinTypeMap = {
                              '지성': 'OILY',
                              '건성': 'DRY',
                              '복합성': 'COMBINATION',
                              '민감성': 'SENSITIVE',
                            };
                            serverSkinTypeText =
                                englishSkinTypeMap[userProfile.skinType] ??
                                userProfile.skinType;
                          }
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[800]
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: RichText(
                                textAlign: TextAlign.left,
                                textHeightBehavior: const TextHeightBehavior(
                                  applyHeightToFirstAscent: false,
                                  applyHeightToLastDescent: false,
                                ),
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 18,
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black87,
                                    fontFamily: 'Helvetica',
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Hi ',
                                      style: TextStyle(height: 1.0),
                                    ),
                                    TextSpan(
                                      text: username,
                                      style: TextStyle(
                                        color:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors
                                                  .black, // 다크모드: 흰색, 라이트모드: 검정색
                                        fontFamily: 'HelveticaNeue93',
                                        fontWeight: FontWeight.w900,
                                        height: 0.1,
                                        fontSize: 18,
                                      ),
                                    ),
                                    if (serverSkinTypeText != null)
                                      TextSpan(
                                        text:
                                            '! You have $serverSkinTypeText skin type! 👋',
                                        style: TextStyle(height: 1.2),
                                      )
                                    else
                                      TextSpan(
                                        text: ' 👋! Tell us your\nskin type',
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 12),
                            // Go! 버튼 컨테이너 (이모티콘)
                            GestureDetector(
                              onTap: _startSurvey,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(
                                    255,
                                    28,
                                    107,
                                    211,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  '👉',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 오른쪽: Rive 애니메이션
                  RiveLogoAnimation(
                    assetPath: 'assets/animations/logo-interaction.riv',
                    height: 150,
                    width: 150,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Suggestions 섹션
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Suggestions 헤더
                  Text(
                    'Suggestions',
                    style: TextStyle(
                      fontSize: 20,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                      fontFamily: 'HelveticaNeue93',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Suggestions 카드들 (2개 나란히) - Stack으로 오버레이 추가
                  Builder(
                    builder: (context) {
                      final surveyData = ref.watch(surveyDataProvider);
                      final userProfileAsync = ref.watch(userProfileProvider);

                      // survey_data 또는 서버 프로필에 피부 정보가 있는지 확인
                      final hasLocalData = surveyData.isComplete;
                      final hasServerData = userProfileAsync.maybeWhen(
                        data: (profile) =>
                            (profile.skinType != null &&
                                profile.skinType!.isNotEmpty) ||
                            (profile.categories != null &&
                                profile.categories!.isNotEmpty),
                        orElse: () => false,
                      );
                      final isSurveyComplete = hasLocalData || hasServerData;

                      return SizedBox(
                        height: 424, // 200 + 16 + 200 + 8
                        child: Stack(
                          children: [
                            // Suggestions 카드들
                            Column(
                              children: [
                                // 첫 번째 줄: 2개 카드
                                Row(
                                  children: [
                                    // 첫 번째 카드: Find Your Perfect Skincare
                                    Expanded(
                                      child: GestureDetector(
                                        onTapDown: isSurveyComplete
                                            ? (_) {
                                                setState(() {
                                                  _isProductCardPressed = true;
                                                });
                                              }
                                            : null,
                                        onTapUp: isSurveyComplete
                                            ? (_) {
                                                setState(() {
                                                  _isProductCardPressed = false;
                                                });
                                                _startProductRecommendation();
                                              }
                                            : null,
                                        onTapCancel: isSurveyComplete
                                            ? () {
                                                setState(() {
                                                  _isProductCardPressed = false;
                                                });
                                              }
                                            : null,
                                        child: AnimatedScale(
                                          scale: _isProductCardPressed
                                              ? 0.95
                                              : 1.0,
                                          duration: const Duration(
                                            milliseconds: 100,
                                          ),
                                          curve: Curves.easeInOut,
                                          child: Opacity(
                                            opacity: isSurveyComplete
                                                ? 1.0
                                                : 0.5,
                                            child: Container(
                                              height: 200,
                                              padding: const EdgeInsets.all(20),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    AppColors.primary, // 노란색
                                                    AppColors.primary
                                                        .withValues(alpha: 0.8),
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.1),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  // 제목 (Helvetica Bold) - 두 줄로 나뉨
                                                  const Text(
                                                    'Find Your Perfect\nSkincare',
                                                    style: TextStyle(
                                                      fontSize: 22,
                                                      color: Colors.white,
                                                      fontFamily: 'Helvetica',
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      height: 1.2,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  // 내용
                                                  const Text(
                                                    'AI recommends personalized\nskincare products',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.white,
                                                      fontFamily:
                                                          'HelveticaNeue',
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      height: 1.4,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // 두 번째 카드: Compare Cosmetics
                                    Expanded(
                                      child: GestureDetector(
                                        onTapDown: isSurveyComplete
                                            ? (_) {
                                                setState(() {
                                                  _isCompareCardPressed = true;
                                                });
                                              }
                                            : null,
                                        onTapUp: isSurveyComplete
                                            ? (_) {
                                                setState(() {
                                                  _isCompareCardPressed = false;
                                                });
                                                _startCompareProducts();
                                              }
                                            : null,
                                        onTapCancel: isSurveyComplete
                                            ? () {
                                                setState(() {
                                                  _isCompareCardPressed = false;
                                                });
                                              }
                                            : null,
                                        child: AnimatedScale(
                                          scale: _isCompareCardPressed
                                              ? 0.95
                                              : 1.0,
                                          duration: const Duration(
                                            milliseconds: 100,
                                          ),
                                          curve: Curves.easeInOut,
                                          child: Opacity(
                                            opacity: isSurveyComplete
                                                ? 1.0
                                                : 0.5,
                                            child: Container(
                                              height: 200,
                                              padding: const EdgeInsets.all(20),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Colors
                                                        .green
                                                        .shade400, // 초록색 계열
                                                    Colors.green.shade600,
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.1),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  // 제목 (Helvetica Bold) - 두 줄로 나뉨
                                                  const Text(
                                                    'Compare\nCosmetics',
                                                    style: TextStyle(
                                                      fontSize: 22,
                                                      color: Colors.white,
                                                      fontFamily: 'Helvetica',
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      height: 1.2,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  // 내용
                                                  const Text(
                                                    'AI compares cosmetics for\nyou',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.white70,
                                                      fontFamily:
                                                          'HelveticaNeue',
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      height: 1.4,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // 두 번째 줄: 예산 맞춤 루틴 카드
                                GestureDetector(
                                  onTapDown: isSurveyComplete
                                      ? (_) {
                                          setState(() {
                                            _isBudgetCardPressed = true;
                                          });
                                        }
                                      : null,
                                  onTapUp: isSurveyComplete
                                      ? (_) {
                                          setState(() {
                                            _isBudgetCardPressed = false;
                                          });
                                          _startBudgetRoutine();
                                        }
                                      : null,
                                  onTapCancel: isSurveyComplete
                                      ? () {
                                          setState(() {
                                            _isBudgetCardPressed = false;
                                          });
                                        }
                                      : null,
                                  child: AnimatedScale(
                                    scale: _isBudgetCardPressed ? 0.95 : 1.0,
                                    duration: const Duration(milliseconds: 100),
                                    curve: Curves.easeInOut,
                                    child: Opacity(
                                      opacity: isSurveyComplete ? 1.0 : 0.5,
                                      child: Container(
                                        height: 200,
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.purple.shade300,
                                              Colors.purple.shade400,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.1,
                                              ),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            // 제목 (Helvetica Bold)
                                            const Text(
                                              'What\'s your budget???',
                                              style: TextStyle(
                                                fontSize: 22,
                                                color: Colors.white,
                                                fontFamily: 'Helvetica',
                                                fontWeight: FontWeight.bold,
                                                height: 1.2,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            // 내용
                                            const Text(
                                              'Create a skincare routine that fits your budget!',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.white70,
                                                fontFamily: 'HelveticaNeue',
                                                fontWeight: FontWeight.w500,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // 동전 애니메이션을 오버레이 아래에 표시 (보라색 컨테이너 위, 텍스트 오른쪽)
                            Positioned(
                              right:
                                  24, // 외부 패딩 24 + 컨테이너 패딩 20 = 44, 하지만 동전 너비 고려
                              top:
                                  230, // 첫 번째 줄(200) + 간격(16) + 두 번째 줄 중앙(100) - 동전 높이 절반(90) = 230
                              child: IgnorePointer(
                                child: RiveCoinAnimation(
                                  assetPath:
                                      'assets/animations/coin-fall-trigger.riv',
                                  height: 180,
                                  width: 180,
                                  fit: BoxFit.contain,
                                  alignment: Alignment.center,
                                ),
                              ),
                            ),
                            // 설문 미완료 시 오버레이 (동전 위에 표시되도록 마지막에 배치)
                            if (!isSurveyComplete)
                              Positioned.fill(
                                child: IgnorePointer(
                                  ignoring: false,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color:
                                          (Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.grey[900]
                                                  : Colors.grey[50])!
                                              .withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.lock_outline,
                                            size: 48,
                                            color:
                                                Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Complete the survey to unlock',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color:
                                                  Theme.of(
                                                        context,
                                                      ).brightness ==
                                                      Brightness.dark
                                                  ? Colors.grey[300]
                                                  : Colors.grey[700],
                                              fontFamily: 'Helvetica',
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
