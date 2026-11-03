import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/data/models/message_model.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/viewmodels/recommend_message_provider.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/viewmodels/survey_data_provider.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/viewmodels/typing_provider.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/widgets/message_bubble.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/widgets/typing_indicator.dart';
import '../../../settings/presentation/viewmodels/user_profile_viewmodel.dart';

class ChatFindSkincarePage extends ConsumerStatefulWidget {
  const ChatFindSkincarePage({super.key});

  @override
  ConsumerState<ChatFindSkincarePage> createState() => _ChatFindSkincarePageState();
}

class _ChatFindSkincarePageState extends ConsumerState<ChatFindSkincarePage> {
  final ScrollController _scrollController = ScrollController();
  final String chatId = 'chatbot_find_skincare'; // 제품 추천 전용 챗 ID
  bool _hasStartedRecommendation = false;

  @override
  void initState() {
    super.initState();
    // 설문 데이터 리로드 확인
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 설문 데이터가 로드되었는지 확인
      final surveyNotifier = ref.read(surveyDataProvider.notifier);
      await surveyNotifier.reload();
      final surveyData = ref.read(surveyDataProvider);
      debugPrint('🔄 Find Skincare - Survey Data Loaded:');
      debugPrint('   - Primary Type: ${surveyData.primaryType}');
      debugPrint('   - Secondary Type: ${surveyData.secondaryType}');
      debugPrint('   - Categories: ${surveyData.categories}');
      debugPrint('   - isComplete: ${surveyData.isComplete}');
      
      if (mounted && !_hasStartedRecommendation) {
        try {
          final aiMessages = ref.read(aiMessageProvider(chatId));
          // 메시지가 비어있을 때만 자동으로 시작 (처음 진입한 경우)
          if (aiMessages.isEmpty) {
            _hasStartedRecommendation = true;
            _startProductRecommendation();
          } else {
            // 이미 메시지가 있으면 (다시 들어온 경우) 상태 확인
            _hasStartedRecommendation = true;
            debugPrint('이미 메시지가 있습니다. 기존 상태를 유지합니다.');
            
            // 메시지가 있으면 recommendProducts()가 자동으로 처리함
            // 여기서는 아무것도 하지 않음 (중복 방지)
          }
        } catch (e) {
          debugPrint('메시지 로드 오류: $e');
          // 오류가 발생해도 제품 추천 시작
          if (!_hasStartedRecommendation) {
            _hasStartedRecommendation = true;
            _startProductRecommendation();
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 제품 추천 시작 (처음 진입 시에만 자동 호출)
  void _startProductRecommendation() {
    debugPrint('제품 추천 시작 (자동)');
    
    // 설문 데이터 확인
    final surveyData = ref.read(surveyDataProvider);
    debugPrint('설문 데이터 확인: primaryType=${surveyData.primaryType}, categories=${surveyData.categories.length}, questionAnswers=${surveyData.questionAnswers.length}');
    debugPrint('로컬 설문 완료 여부: ${surveyData.isComplete}');
    
    // 서버 프로필도 확인
    final userProfileAsync = ref.read(userProfileProvider);
    final hasServerData = userProfileAsync.maybeWhen(
      data: (profile) => (profile.skinType != null && profile.skinType!.isNotEmpty) ||
                         (profile.categories != null && profile.categories!.isNotEmpty),
      orElse: () => false,
    );
    
    final isSurveyComplete = surveyData.isComplete || hasServerData;
    debugPrint('서버 프로필: hasServerData=$hasServerData');
    debugPrint('✅ 최종 판단 (local OR server): isSurveyComplete=$isSurveyComplete');
    
    if (!isSurveyComplete) {
      // 설문이 완료되지 않았으면 안내 메시지만 표시 (페이지는 유지)
      debugPrint('설문이 완료되지 않음 - 안내 메시지 표시');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please complete the survey first! Go back and click "go!" to start the survey.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // 제품 추천 시작
    ref.read(aiMessageProvider(chatId).notifier).recommendProducts();
  }

  void _scrollToBottom() {
    if (mounted && _scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 메시지 로드 시 오류 방지
    List<MessageModel> aiMessages = [];
    try {
      aiMessages = ref.watch(aiMessageProvider(chatId));
    } catch (e) {
      debugPrint('메시지 로드 오류: $e');
      // 오류가 발생해도 빈 리스트로 처리
    }
    
    final isTyping = ref.watch(isTypingProvider(chatId));
    final surveyData = ref.watch(surveyDataProvider);

    // 메시지가 변경될 때만 스크롤 (ref.listen 사용)
    ref.listen(
      aiMessageProvider(chatId),
      (previous, next) {
        try {
          if (previous != null && next.length > previous.length && mounted) {
            // intro 메시지가 추가된 경우에는 스크롤하지 않음 (맨 위에 보이도록)
            final newMessage = next.last;
            final isIntroMessage = newMessage.text == "I'd like to recommend these products right now! 👍";
            
            if (!isIntroMessage) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _scrollController.hasClients) {
                  _scrollToBottom();
                }
              });
            }
          }
        } catch (e) {
          debugPrint('스크롤 오류: $e');
        }
      },
    );
    
    // 마지막 메시지가 "Searching"인지 확인
    final isSearching = aiMessages.isNotEmpty &&
        aiMessages.last.text == 'Searching' &&
        !aiMessages.last.isMe;
    
    // "Searching" 메시지가 이미 있으면 바깥쪽 TypingIndicator는 숨김
    final shouldShowTyping = isTyping && !isSearching;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? Theme.of(context).scaffoldBackgroundColor
          : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDarkMode
            ? Theme.of(context).appBarTheme.backgroundColor
            : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () {
            // 메시지는 유지하고 그냥 뒤로가기만
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Find Your Perfect Skincare',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontFamily: 'HelveticaNeue93',
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: surveyData.isComplete && aiMessages.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                // 메시지 리스트
                Expanded(
                  child: aiMessages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Please complete the survey first!',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                  fontFamily: 'Helvetica',
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Go back and click "go!" to start the survey.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontFamily: 'HelveticaNeue',
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: aiMessages.length + (shouldShowTyping ? 1 : 0),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemBuilder: (context, index) {
                            if (index == aiMessages.length && shouldShowTyping) {
                              return const TypingIndicator();
                            }
                            return MessageBubble(
                              message: aiMessages[index],
                              chatId: chatId,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

