import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/viewmodels/budget_message_provider.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/viewmodels/survey_data_provider.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/viewmodels/typing_provider.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/widgets/message_bubble.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/widgets/typing_indicator.dart';
import '../../../settings/presentation/viewmodels/user_profile_viewmodel.dart';

class ChatBudgetRoutinePage extends ConsumerStatefulWidget {
  const ChatBudgetRoutinePage({super.key});

  @override
  ConsumerState<ChatBudgetRoutinePage> createState() => _ChatBudgetRoutinePageState();
}

class _ChatBudgetRoutinePageState extends ConsumerState<ChatBudgetRoutinePage> {
  final ScrollController _scrollController = ScrollController();
  final String chatId = 'chatbot_budget_routine'; // 예산 맞춤 루틴 전용 챗 ID
  bool _hasStartedQuestion = false;
  bool _isInitializing = false; // 초기화 진행 중인지

  @override
  void initState() {
    super.initState();
    // 설문 데이터 리로드 확인
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 이미 초기화 중이면 중복 호출 방지
      if (_isInitializing) {
        debugPrint('이미 초기화가 진행 중입니다. 중복 호출을 방지합니다.');
        return;
      }
      
      // 설문 데이터가 로드되었는지 확인
      final surveyNotifier = ref.read(surveyDataProvider.notifier);
      await surveyNotifier.reload();
      final surveyData = ref.read(surveyDataProvider);
      debugPrint('🔄 Budget Routine - Survey Data Loaded:');
      debugPrint('   - Primary Type: ${surveyData.primaryType}');
      debugPrint('   - Secondary Type: ${surveyData.secondaryType}');
      debugPrint('   - Categories: ${surveyData.categories}');
      debugPrint('   - isComplete: ${surveyData.isComplete}');
      
      // 메시지가 이미 있는지 확인 (최신 상태 확인)
      final budgetMessages = ref.read(budgetMessageProvider(chatId));
      final hasHelloMessage = budgetMessages.any((m) => 
        !m.isMe && m.text == 'Hello! I\'m creating a skincare routine that fits your budget! 💰'
      );
      final hasBudgetQuestion = budgetMessages.any((m) => 
        !m.isMe && m.text == 'What\'s your budget???' && m.options != null
      );
      
      // 이미 인사 메시지와 예산 질문이 모두 있으면 초기화 건너뛰기
      if (hasHelloMessage && hasBudgetQuestion) {
        debugPrint('예산 질문이 이미 있습니다. 초기화를 건너뜁니다.');
        _hasStartedQuestion = true;
        return;
      }
      
      if (mounted && !_hasStartedQuestion && !hasBudgetQuestion) {
        _hasStartedQuestion = true;
        _isInitializing = true;
        try {
          await _startBudgetQuestion();
        } finally {
          _isInitializing = false;
        }
      } else if (hasBudgetQuestion) {
        debugPrint('예산 질문이 이미 있습니다. 초기화를 건너뜁니다.');
        _hasStartedQuestion = true;
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 예산 질문 시작
  Future<void> _startBudgetQuestion() async {
    debugPrint('_startBudgetQuestion 호출됨');
    
    // 설문 데이터 확인
    final surveyData = ref.read(surveyDataProvider);
    debugPrint('설문 데이터 확인: primaryType=${surveyData.primaryType}, categories=${surveyData.categories.length}');
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
      // 설문이 완료되지 않았으면 안내 메시지만 표시
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

    debugPrint('예산 질문 시작');
    
    // 기존 메시지 확인 (이중 체크) - 최신 상태 확인
    final budgetMessages = ref.read(budgetMessageProvider(chatId));
    final hasHelloMessage = budgetMessages.any((m) => 
      !m.isMe && m.text == 'Hello! I\'m creating a skincare routine that fits your budget! 💰'
    );
    final hasBudgetQuestion = budgetMessages.any((m) => 
      !m.isMe && m.text == 'What\'s your budget???' && m.options != null
    );
    
    // 이미 인사 메시지와 예산 질문이 모두 있으면 새로 시작하지 않음
    if (hasHelloMessage && hasBudgetQuestion) {
      debugPrint('예산 질문이 이미 있습니다. 기존 질문을 표시합니다.');
      return;
    }
    
    // Provider 레벨에서도 중복 체크를 하므로 안전하게 호출
    await ref.read(budgetMessageProvider(chatId).notifier).startBudgetQuestion();
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
    final budgetMessages = ref.watch(budgetMessageProvider(chatId));
    final isTyping = ref.watch(isTypingProvider(chatId));
    final surveyData = ref.watch(surveyDataProvider);

    // 메시지가 변경될 때만 스크롤 (ref.listen 사용)
    ref.listen(
      budgetMessageProvider(chatId),
      (previous, next) {
        if (previous != null && next.length > previous.length && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _scrollController.hasClients) {
              _scrollToBottom();
            }
          });
        }
      },
    );

    // 마지막 메시지가 "Searching"인지 확인
    final isSearching = budgetMessages.isNotEmpty && 
                       budgetMessages.last.text == 'Searching' && 
                       !budgetMessages.last.isMe;

    // "Searching" 메시지가 있으면 typing indicator를 표시하지 않음
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
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Budget Routine',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontFamily: 'HelveticaNeue93',
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: surveyData.isComplete && budgetMessages.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                // 메시지 리스트
                Expanded(
                  child: budgetMessages.isEmpty
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
                          itemCount: budgetMessages.length + (shouldShowTyping ? 1 : 0),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemBuilder: (context, index) {
                            if (index == budgetMessages.length && shouldShowTyping) {
                              return const TypingIndicator();
                            }
                            return MessageBubble(
                              message: budgetMessages[index],
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

