import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/data/models/message_model.dart';
import 'package:mobileprogramming_groupproject_2025/api_keys.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/viewmodels/survey_data_provider.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/viewmodels/skin_types_data.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/viewmodels/chat_bot_state_provider.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/viewmodels/recommend_message_provider.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/viewmodels/typing_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../settings/presentation/viewmodels/user_profile_viewmodel.dart';

/// 설문 질문 관리 Provider
class SurveyMessageNotifier extends StateNotifier<List<MessageModel>> {
  final Ref ref;
  final String chatId;
  final Dio _dio = Dio();
  final Dio _serverDio = Dio(); // 서버 통신용 Dio 인스턴스
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final List<Map<String, String>> _questionAnswers = []; // 질문과 답변 저장
  bool _isSurveyCompleted = false; // 설문이 완료되었는지 추적 (질문 생성 중단용)
  
  // 피부 타입/세부 타입/화장품 선택 관련
  String? _selectedSkinType; // 선택된 피부 타입 추적
  String? _selectedSubType; // 선택된 세부 타입 추적
  final Set<String> _selectedCosmetics = {}; // 선택된 화장품 목록 추적
  bool _cosmeticsSelectionLocked = false; // 화장품 선택이 완료되었는지 추적
  bool _dataSentToServer = false; // 서버로 데이터를 보냈는지 추적

  SurveyMessageNotifier(this.ref, this.chatId, List<MessageModel> initialMessages) 
      : super(List.from(initialMessages)) {
    _dio.options.baseUrl = 'https://openrouter.ai/api/v1';
    _dio.options.headers = {
      'Authorization': 'Bearer $OPENROUTER_API_KEY',
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://mobileprogramming-groupproject-2025.app',
      'X-Title': 'Mobile Programming Group Project',
    };
    
    // 서버 통신용 Dio 설정
    _serverDio.options.baseUrl = 'http://43.203.250.50:8080';
    _serverDio.options.headers = {
      'Content-Type': 'application/json',
    };
  }

  void addMessage(MessageModel message) {
    state = [...state, message];
  }

  /// 메시지의 options를 제거하여 버튼을 숨김
  void removeMessageOptions(MessageModel targetMessage) {
    final currentState = List<MessageModel>.from(state);
    final messageIndex = currentState.indexWhere((m) => 
      m.text == targetMessage.text && 
      m.timestamp == targetMessage.timestamp &&
      m.senderId == targetMessage.senderId
    );
    if (messageIndex != -1) {
      currentState[messageIndex] = currentState[messageIndex].copyWith(options: null);
      state = currentState;
    }
  }

  // ========== 헬퍼 메서드 ==========
  
  /// 설문이 완료되었는지 확인
  bool _checkIfSurveyCompleted() {
    if (_isSurveyCompleted) {
      debugPrint('설문이 완료되어 질문 생성 중단');
      return true;
    }
    return false;
  }

  /// 사용자 메시지 생성
  MessageModel _createUserMessage(String text) {
    return MessageModel(
      senderId: 'me',
      text: text,
      timestamp: DateTime.now(),
      isMe: true,
      isSeen: false,
    );
  }

  /// 최근 질문 찾기
  String? _findRecentQuestion() {
    for (int i = state.length - 1; i >= 0; i--) {
      if (!state[i].isMe && state[i].options != null && state[i].options!.isNotEmpty) {
        return state[i].text;
      }
    }
    return null;
  }

  /// 화장품 질문 추가
  Future<void> _addCosmeticQuestion() async {
    final hasCosmeticQuestion = state.any(
      (m) => m.text == 'Please choose all the cosmetics that you use on a daily basis'
    );
    
    if (!hasCosmeticQuestion) {
      await Future.delayed(const Duration(seconds: 1));
      addMessage(
        MessageModel(
          senderId: 'chatbot',
          text: 'Please choose all the cosmetics that you use on a daily basis',
          timestamp: DateTime.now(),
          isMe: false,
          options: cosmeticTypes,
        ),
      );
    }
  }

  /// 설문 시작 (go! 버튼 클릭 시)
  Future<void> startSurvey() async {
    clearMessages(); // 기존 메시지 및 데이터 초기화

    final typingNotifier = ref.read(isTypingProvider(chatId).notifier);
    typingNotifier.setTyping(true);
    await Future.delayed(const Duration(seconds: 1));

    addMessage(
      MessageModel(
        senderId: 'chatbot',
        text: "hi! i'm puang, your virtual skin expert. 👋 let's chat about your skin!",
        timestamp: DateTime.now(),
        isMe: false,
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1500));
    addMessage(
      MessageModel(
        senderId: 'chatbot',
        text: 'What is your skin type??',
        timestamp: DateTime.now(),
        isMe: false,
        options: ['OILY', 'DRY', 'COMBINATION', 'SENSITIVE'],
      ),
    );
    typingNotifier.setTyping(false);
  }

  // 피부 타입/세부 타입/화장품 선택 관련 메서드
  String? get selectedSkinType => _selectedSkinType;
  String? get selectedSubType => _selectedSubType;
  bool isSkinTypeSelected(String skinType) => _selectedSkinType == skinType;
  bool isSubTypeSelected(String subType) => _selectedSubType == subType;
  bool isCosmeticSelected(String cosmetic) => _selectedCosmetics.contains(cosmetic);
  bool get isCosmeticsSelectionLocked => _cosmeticsSelectionLocked;

  /// 사용자 메시지 처리 (피부 타입/세부 타입/화장품 선택)
  Future<void> sendUserMessage(String text) async {
    // 피부 타입 선택인지 확인 (영어 옵션)
    final skinTypes = ['OILY', 'DRY', 'COMBINATION', 'SENSITIVE'];
    final isSkinTypeSelection = skinTypes.contains(text.trim());
    
    // 영어를 한국어로 변환 (서버 통신용)
    final koreanSkinTypeMap = {
      'OILY': '지성',
      'DRY': '건성',
      'COMBINATION': '복합성',
      'SENSITIVE': '민감성',
    };

    if (isSkinTypeSelection) {
      final trimmedText = text.trim();
      final koreanText = koreanSkinTypeMap[trimmedText] ?? trimmedText;
      
      // 같은 타입을 다시 선택하면 무시
      if (_selectedSkinType == koreanText) return;
      
      // 사용자 메시지 추가 (영어로 표시)
      final hasUserMessage = state.any((m) => m.isMe && m.text == trimmedText);
      if (!hasUserMessage) {
        addMessage(_createUserMessage(trimmedText));
      }
      
      final isFirstSelection = _selectedSkinType == null;
      _selectedSkinType = koreanText; // 내부적으로는 한국어 저장
      ref.read(surveyDataProvider.notifier).setPrimaryType(koreanText);

      // 세부 타입 질문이 없으면 추가
      final hasSubTypeQuestion = state.any((m) => 
        !m.isMe && m.text == 'You can describe your skin condition like....'
      );
      
      if (isFirstSelection && !hasSubTypeQuestion) {
        await Future.delayed(const Duration(seconds: 1));
        final subTypes = skinSubTypes[koreanText] ?? [];
        final subTypesWithHelp = [...subTypes, "I'm not sure.... plz help!"];
        addMessage(
          MessageModel(
            senderId: 'chatbot',
            text: 'You can describe your skin condition like....',
            timestamp: DateTime.now(),
            isMe: false,
            options: subTypesWithHelp,
          ),
        );
      }
      return;
    }

    // 세부 타입 선택인지 확인
    final allSubTypes = skinSubTypes.values.expand((list) => list).toList();
    final isSubTypeSelection = allSubTypes.contains(text.trim()) || text.trim() == "I'm not sure.... plz help!";

    if (isSubTypeSelection) {
      final trimmedText = text.trim();
      
      // 사용자 메시지 추가 (이미 있으면 추가하지 않음)
      final hasUserMessage = state.any((m) => m.isMe && m.text == trimmedText);
      if (!hasUserMessage) {
        addMessage(_createUserMessage(text));
      }

      // 세부 타입 질문 메시지 찾기 및 options 제거
      final subTypeQuestionIndex = state.indexWhere(
        (m) => !m.isMe && m.text == 'You can describe your skin condition like....',
      );
      if (subTypeQuestionIndex != -1) {
        removeMessageOptions(state[subTypeQuestionIndex]);
      }

      if (trimmedText == "I'm not sure.... plz help!") {
        // 화장품 질문이 없으면 추가
        await _addCosmeticQuestion();
        return;
      }
      
      // 같은 세부 타입을 다시 선택하면 무시
      if (_selectedSubType == trimmedText) return;
      
      final isFirstSelection = _selectedSubType == null;
      _selectedSubType = trimmedText;
      ref.read(surveyDataProvider.notifier).setSecondaryType(trimmedText);

      // 화장품 질문이 없으면 추가
      final hasCosmeticQuestion = state.any((m) => 
        m.text == 'Please choose all the cosmetics that you use on a daily basis'
      );
      
      if (isFirstSelection && !hasCosmeticQuestion) {
        await _addCosmeticQuestion();
      }
      return;
    }

    // 설문 질문 답변인지 확인
    final recentQuestion = _findRecentQuestion();
    if (recentQuestion != null) {
      await handleAnswer(text.trim());
      return;
    }
  }

  /// 화장품 선택/해제 토글
  void toggleCosmeticSelection(String cosmetic) {
    if (_cosmeticsSelectionLocked) return;
    
    // 이미 선택되어 있으면 해제, 없으면 추가
    if (_selectedCosmetics.contains(cosmetic)) {
      _selectedCosmetics.remove(cosmetic);
    } else {
      _selectedCosmetics.add(cosmetic);
    }
    
    ref.read(surveyDataProvider.notifier).setCategories(_selectedCosmetics.toList());
    state = [...state];
  }

  /// 화장품 선택 완료 (Done 버튼 클릭)
  Future<void> sendSelectedCosmetics() async {
    if (_selectedCosmetics.isEmpty) return;
    if (_cosmeticsSelectionLocked) return;
    
    final selectedList = _selectedCosmetics.toList();
    _cosmeticsSelectionLocked = true;
    state = [...state];
    
    ref.read(surveyDataProvider.notifier).setCategories(selectedList);
    await _sendUserDataToServer();
    
    // 3개 질문 생성 로직 제거 - 피부 정보만으로 제품 추천
  }

  /// 서버로 사용자 정보 전송 (PUT /users/user)
  Future<void> _sendUserDataToServer() async {
    if (_dataSentToServer) return;
    
    try {
      debugPrint('📤 챗봇 설문 완료: 서버에 skin_type/condition/categories 저장 시작');
      debugPrint('   skin_type: $_selectedSkinType');
      debugPrint('   skin_condition: $_selectedSubType');
      debugPrint('   categories: $_selectedCosmetics');
      
      final accessToken = await _storage.read(key: 'access_token');
      if (accessToken == null) {
        debugPrint('❌ accessToken이 없어서 서버 저장 실패');
        return;
      }
      
      // 현재 사용자 프로필 가져오기
      final userEmail = await _storage.read(key: 'user_email');
      if (userEmail == null) {
        debugPrint('❌ user_email이 없어서 서버 저장 실패');
        return;
      }
      
      // categories 대문자로 통일
      final normalizedCategories = _selectedCosmetics
          .map((cat) => cat.toUpperCase())
          .toSet()
          .toList();
      
      // UserProfile 업데이트 (PUT /users/user)
      final updatedProfile = UserProfile(
        id: '',
        email: userEmail,
        username: null, // 기존 값 유지 (null이면 서버에서 무시)
        skinType: _selectedSkinType,
        skinCondition: _selectedSubType != "I'm not sure.... plz help!" 
            ? _selectedSubType 
            : null,
        categories: normalizedCategories.isNotEmpty ? normalizedCategories : null,
        age: null,
        gender: null,
      );
      
      // updateUserProfileProvider 사용
      await ref.read(updateUserProfileProvider(updatedProfile).future);
      
      debugPrint('✅ 챗봇 설문: 서버에 skin_type/condition/categories 저장 성공');
      _dataSentToServer = true;
      
      // userProfileProvider 캐시 무효화하여 다음 조회 시 서버에서 최신 데이터 가져오기
      ref.invalidate(userProfileProvider);
      
    } catch (e) {
      debugPrint('❌ 챗봇 설문: 서버 저장 실패: $e');
    }
  }

  /// 질문 답변 저장
  void saveAnswer(String question, String answer) {
    _questionAnswers.add({
      'question': question,
      'answer': answer,
    });
    
    // survey_data_provider에도 저장
    ref.read(surveyDataProvider.notifier).addQuestionAnswer(question, answer);
    
    debugPrint('질문 답변 저장: Q=$question, A=$answer');
    debugPrint('저장된 질문/답변 개수: ${_questionAnswers.length}');
  }

  /// 사용자 답변 처리 (설문 중 질문 답변)
  Future<void> handleAnswer(String answer) async {
    final recentQuestion = _findRecentQuestion();
    if (recentQuestion == null) return;

    if (_checkIfSurveyCompleted()) return;
    
    saveAnswer(recentQuestion, answer);
    addMessage(_createUserMessage(answer));

    // 설문 중에는 질문을 생성하지 않음 (제품 추천 시에만 추가 질문 생성)
    debugPrint('질문 답변 저장 완료: Q=$recentQuestion, A=$answer');
  }

  /// 설문 완료 (Done 버튼 클릭 시)
  Future<void> completeSurvey() async {
    // 질문 생성 중단 플래그 설정 (진행 중인 질문 생성도 중단)
    _isSurveyCompleted = true;
    
    // survey_data_provider에 최종 저장 (질문 답변은 없으므로 빈 배열)
    ref.read(surveyDataProvider.notifier).setQuestionAnswers([]);
    
    final surveyData = ref.read(surveyDataProvider);
    debugPrint('설문 완료, 저장된 피부 정보:');
    debugPrint('  - primaryType: ${surveyData.primaryType}');
    debugPrint('  - secondaryType: ${surveyData.secondaryType}');
    debugPrint('  - categories: ${surveyData.categories}');
    debugPrint('  - questionAnswers: ${surveyData.questionAnswers}');
    
    // 감사 메시지 표시
    final thankYouMessage = MessageModel(
      senderId: 'chatbot',
      text: 'Thank you for your answers!',
      timestamp: DateTime.now(),
      isMe: false,
    );
    addMessage(thankYouMessage);
    
    // 2초 대기 후 초기 화면으로 돌아가기
    await Future.delayed(const Duration(seconds: 2));
    
    // 채팅 상태 초기화
    ref.read(chatBotStateProvider.notifier).setHasStartedChat(false);
    
    // 모든 메시지 초기화
    clearMessages();
    ref.read(aiMessageProvider(chatId).notifier).clearMessages();
    
    // 설문 데이터는 유지 (제품 추천에 사용)
  }

  void clearMessages() {
    state = [];
    _questionAnswers.clear();
    _isSurveyCompleted = false; // 플래그도 초기화
    
    // 내부 상태도 초기화 (go! 버튼을 다시 눌렀을 때 처음부터 시작)
    _selectedSkinType = null;
    _selectedSubType = null;
    _selectedCosmetics.clear();
    _cosmeticsSelectionLocked = false;
    _dataSentToServer = false;
  }

  /// 설문 데이터를 기반으로 내부 상태 복원
  


  Future<void> _restoreNextQuestion() async {
    // 1. 피부 타입이 선택되지 않았으면 피부 타입 질문 표시
    if (_selectedSkinType == null) {
      // 피부 타입 질문이 없으면 추가
      final hasSkinTypeQuestion = state.any((m) => 
        !m.isMe && m.text == 'What is your skin type??'
      );
      if (!hasSkinTypeQuestion) {
        // 인사 메시지가 없으면 추가
        final hasGreeting = state.any((m) => 
          !m.isMe && m.text.contains("hi! i'm puang")
        );
        if (!hasGreeting) {
          addMessage(
            MessageModel(
              senderId: 'chatbot',
              text: "hi! i'm puang, your virtual skin expert. 👋 let's chat about your skin!",
              timestamp: DateTime.now(),
              isMe: false,
            ),
          );
          await Future.delayed(const Duration(milliseconds: 1500));
        }
        addMessage(
          MessageModel(
            senderId: 'chatbot',
            text: 'What is your skin type??',
            timestamp: DateTime.now(),
            isMe: false,
            options: ['OILY', 'DRY', 'COMBINATION', 'SENSITIVE'],
          ),
        );
      }
      return; // 피부 타입 질문을 표시했으므로 종료
    }
    
    // 2. 피부 타입은 선택되었지만 세부 타입 질문이 없으면 추가
    if (_selectedSkinType != null) {
      final hasSubTypeQuestion = state.any((m) => 
        !m.isMe && m.text == 'You can describe your skin condition like....'
      );
      
      if (!hasSubTypeQuestion) {
        // 사용자 메시지가 없으면 추가 (영어로 표시)
        final englishSkinTypeMap = {
          '지성': 'OILY',
          '건성': 'DRY',
          '복합성': 'COMBINATION',
          '민감성': 'SENSITIVE',
        };
        final englishSkinType = englishSkinTypeMap[_selectedSkinType] ?? _selectedSkinType ?? '';
        final hasUserMessage = state.any((m) => m.isMe && (m.text == _selectedSkinType || m.text == englishSkinType));
        if (!hasUserMessage && englishSkinType.isNotEmpty) {
          addMessage(_createUserMessage(englishSkinType));
        }
        
        await Future.delayed(const Duration(seconds: 1));
        final subTypes = skinSubTypes[_selectedSkinType] ?? [];
        final subTypesWithHelp = [...subTypes, "I'm not sure.... plz help!"];
        addMessage(
          MessageModel(
            senderId: 'chatbot',
            text: 'You can describe your skin condition like....',
            timestamp: DateTime.now(),
            isMe: false,
            options: subTypesWithHelp,
          ),
        );
        return; // 세부 타입 질문을 추가했으므로 여기서 종료
      }
    }
    
    // 3. 세부 타입까지 선택되었지만 화장품 질문이 없으면 추가
    if (_selectedSkinType != null) {
      final hasCosmeticQuestion = state.any((m) => 
        m.text == 'Please choose all the cosmetics that you use on a daily basis'
      );
      
      if (!hasCosmeticQuestion) {
        // 세부 타입 사용자 메시지가 없으면 추가
        if (_selectedSubType != null) {
          final hasSubTypeUserMessage = state.any((m) => m.isMe && m.text == _selectedSubType);
          if (!hasSubTypeUserMessage) {
            addMessage(_createUserMessage(_selectedSubType!));
          }
        }
        await _addCosmeticQuestion();
      }
    }
  }
}

/// 설문 메시지 Provider
final surveyMessageProvider = StateNotifierProvider.family<SurveyMessageNotifier, List<MessageModel>, String>(
  (ref, chatId) => SurveyMessageNotifier(ref, chatId, []),
);

