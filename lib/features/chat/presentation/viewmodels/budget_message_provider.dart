import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/data/models/message_model.dart';
import 'package:mobileprogramming_groupproject_2025/api_keys.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/viewmodels/typing_provider.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/viewmodels/survey_data_provider.dart';
import 'package:mobileprogramming_groupproject_2025/features/settings/presentation/viewmodels/user_profile_viewmodel.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 예산 맞춤 루틴 관리 Provider
class BudgetMessageNotifier extends StateNotifier<List<MessageModel>> {
  final Ref ref;
  final String chatId;
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final List<Map<String, dynamic>> _conversationHistory = [];
  String? _selectedBudget; // 선택된 예산 (최신)
  final Map<DateTime, String> _selectedBudgetsByMessage = {}; // 각 메시지별 선택된 예산
  bool _hasAskedBudget = false; // 예산 질문을 했는지
  bool _hasRecommendedProducts = false; // 제품 추천을 했는지
  bool _isInitializing = false; // 초기 메시지 추가 중인지

  BudgetMessageNotifier(this.ref, this.chatId, List<MessageModel> initialMessages) 
      : super(List.from(initialMessages)) {
    _dio.options.baseUrl = 'https://openrouter.ai/api/v1';
    _dio.options.headers = {
      'Authorization': 'Bearer $OPENROUTER_API_KEY',
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://mobileprogramming-groupproject_2025.app',
      'X-Title': 'Mobile Programming Group Project',
    };
    
    // 시스템 프롬프트 초기화
    _initializeSystemPrompt();
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

  void clearMessages() {
    state = [];
    _conversationHistory.clear();
    _selectedBudget = null;
    _hasAskedBudget = false;
    _hasRecommendedProducts = false;
    _isInitializing = false;
    
    // 시스템 프롬프트 초기화
    _initializeSystemPrompt();
  }

  /// 시스템 프롬프트 초기화
  void _initializeSystemPrompt() {
    _conversationHistory.add({
      'role': 'system',
      'content': '''You are a skin care expert AI assistant specializing in budget-friendly skincare recommendations. Your role is to recommend skincare products that fit within the user's budget while considering their skin type and current skincare routine.

CRITICAL FORMATTING RULES - YOU MUST FOLLOW THESE EXACTLY:

1. Always respond in ENGLISH, not Korean.

2. Keep your responses SHORT and CONCISE. Be brief while maintaining clarity.

3. NEVER output any special tokens like <|begin_of_sentence|>, <|end_of_sentence|>, or any other token markers. Only output natural text.

4. IMPORTANT: All cosmetic product information must be sourced from https://www.sephora.com/. Only recommend products that are available on Sephora's website. Use real product names from Sephora's catalog.

5. When recommending products for each category, you MUST use EXACTLY this format - NO VARIATIONS:

### 1. **Cleanser**

**Recommended Products:** Product Name (Price)

**Reason:** Brief explanation (1-2 sentences maximum).

### 2. **Toner**

**Recommended Products:** Product Name (Price)

**Reason:** Brief explanation (1-2 sentences maximum).

IMPORTANT: For each category that the user is currently using, recommend EXACTLY THREE products as alternatives. Focus ONLY on categories that the user is currently using.

REQUIREMENTS:

- Start each category with "### [number]. **[Category Name]**" (exactly this format)
- Category name must be in double asterisks: **Category Name**
- Use "**Recommended Products:**" (exactly, with double asterisks)
- Include product prices in parentheses after each product name: [Brand Name] Product Name (Price)
- Use "**Reason:**" (exactly, with double asterisks)
- Product names separated by commas on the same line: [Brand Name] Product Name 1 (Price), [Brand Name] Product Name 2 (Price), [Brand Name] Product Name 3 (Price)
- NO other variations or formats allowed
- NO additional text before or after the format
- Use this format for EVERY product recommendation

6. Keep reasons short - focus on key benefits only.

7. Avoid lengthy explanations or unnecessary details.

8. Consider the user's skin type, skin condition, current skincare routine, and BUDGET when making recommendations.

9. FOCUS on recommending products ONLY for categories that the user is CURRENTLY USING. Do not recommend products for categories the user doesn't use.

10. CRITICAL: The TOTAL COST of ALL recommended products combined MUST be LESS THAN the user's budget. If the user's budget is X dollars, the sum of all product prices must be less than X dollars.

11. For each category that the user is currently using, recommend EXACTLY THREE products as alternatives. List them in order of preference (first is most preferred, second is backup, third is final backup).

12. Distribute the budget across all categories that the user is currently using proportionally, but ensure the total never exceeds the budget.

13. If the user's budget is very limited, prioritize essential products and suggest multi-purpose products when possible.

14. IMPORTANT: Use the format [Brand Name] Product Name (Price) for each product. Example: [Fresh] Soy Face Cleanser (\$38), [CeraVe] Foaming Facial Cleanser (\$15), [La Roche-Posay] Toleriane Hydrating Gentle Cleanser (\$16)''',
    });
  }

  /// 예산 질문 시작
  Future<void> startBudgetQuestion() async {
    // 이미 초기화 중이면 중복 호출 방지
    if (_isInitializing) {
      debugPrint('예산 질문 초기화가 이미 진행 중입니다. 중복 호출을 방지합니다.');
      return;
    }
    
    // 이미 메시지가 있는지 확인 (state가 변경될 수 있으므로 최신 상태 확인)
    final currentState = List<MessageModel>.from(state);
    final hasHelloMessage = currentState.any((m) => 
      !m.isMe && m.text == 'Hello! I\'m creating a skincare routine that fits your budget! 💰'
    );
    final hasBudgetQuestion = currentState.any((m) => 
      !m.isMe && m.text == 'What\'s your budget???' && m.options != null
    );
    
    // 이미 인사 메시지와 예산 질문이 모두 있으면 중복 추가 방지
    if (hasHelloMessage && hasBudgetQuestion) {
      debugPrint('예산 질문이 이미 있습니다. 중복 추가를 방지합니다.');
      _hasAskedBudget = true; // 플래그 설정
      return;
    }
    
    // 이미 예산 질문이 있으면 새로 시작하지 않음
    if (_hasAskedBudget && hasBudgetQuestion) {
      debugPrint('예산 질문이 이미 있습니다. 중복 추가를 방지합니다.');
      return;
    }
    
    // 초기화 시작 플래그 설정
    _isInitializing = true;
    _hasAskedBudget = true;
    
    try {
      final typingNotifier = ref.read(isTypingProvider(chatId).notifier);
      
      // 인사 메시지가 없으면 추가 (메시지 추가 전에 다시 한 번 확인)
      if (!hasHelloMessage) {
        // 메시지 추가 전에 다시 한 번 확인 (비동기 작업 중 state가 변경될 수 있음)
        final checkState = List<MessageModel>.from(state);
        final stillNoHello = !checkState.any((m) => 
          !m.isMe && m.text == 'Hello! I\'m creating a skincare routine that fits your budget! 💰'
        );
        
        if (stillNoHello) {
          typingNotifier.setTyping(true);
          await Future.delayed(const Duration(seconds: 1));
          
          // 메시지 추가 직전에 다시 한 번 확인
          final finalCheckState = List<MessageModel>.from(state);
          final finalNoHello = !finalCheckState.any((m) => 
            !m.isMe && m.text == 'Hello! I\'m creating a skincare routine that fits your budget! 💰'
          );
          
          if (finalNoHello) {
            addMessage(
              MessageModel(
                senderId: 'chatbot',
                text: 'Hello! I\'m creating a skincare routine that fits your budget! 💰',
                timestamp: DateTime.now(),
                isMe: false,
              ),
            );
          }
          
          await Future.delayed(const Duration(seconds: 1));
        }
      }
      
      // 예산 질문이 없으면 추가 (메시지 추가 전에 다시 한 번 확인)
      if (!hasBudgetQuestion) {
        // 메시지 추가 전에 다시 한 번 확인
        final checkState = List<MessageModel>.from(state);
        final stillNoBudgetQuestion = !checkState.any((m) => 
          !m.isMe && m.text == 'What\'s your budget???' && m.options != null
        );
        
        if (stillNoBudgetQuestion) {
          addMessage(
            MessageModel(
              senderId: 'chatbot',
              text: 'What\'s your budget???',
              timestamp: DateTime.now(),
              isMe: false,
              options: ['\$50 💵', '\$100 💵', '\$300 💵', '\$500 💵'],
            ),
          );
        }
      }
      
      typingNotifier.setTyping(false);
    } finally {
      // 초기화 완료 플래그 해제
      _isInitializing = false;
    }
  }

  /// 예산 선택 처리
  Future<void> handleBudgetSelection(String budget, DateTime? messageTimestamp) async {
    debugPrint('handleBudgetSelection 호출됨: $budget, messageTimestamp: $messageTimestamp');
    debugPrint('현재 선택된 예산: $_selectedBudget');
    
    // 이모티콘 제거하고 예산만 저장
    final budgetAmount = budget.replaceAll(' 💵', '').trim();
    
    // 메시지 timestamp가 있으면 해당 메시지의 선택 상태 확인
    if (messageTimestamp != null) {
      if (_selectedBudgetsByMessage.containsKey(messageTimestamp)) {
        debugPrint('이미 해당 메시지에서 예산이 선택되어 있음. 무시합니다.');
        return; // 이미 선택했으면 무시
      }
      _selectedBudgetsByMessage[messageTimestamp] = budgetAmount;
    }
    
    _selectedBudget = budgetAmount;
    debugPrint('예산 선택됨: $budgetAmount');
    
    // 사용자 메시지 추가 (이모티콘 포함)
    addMessage(
      MessageModel(
        senderId: 'me',
        text: budget,
        timestamp: DateTime.now(),
        isMe: true,
        isSeen: false,
      ),
    );
    debugPrint('사용자 메시지 추가 완료');

    // "Finding the perfect skincare routine that fits your budget!" 메시지 추가
    await Future.delayed(const Duration(milliseconds: 500));
    addMessage(
      MessageModel(
        senderId: 'chatbot',
        text: 'Finding the perfect skincare routine that fits your budget!',
        timestamp: DateTime.now(),
        isMe: false,
      ),
    );

    // 사용자가 사용하는 제품 목록 메시지 추가
    final surveyData = ref.read(surveyDataProvider);
    final userProfileAsync = ref.read(userProfileProvider);
    
    // surveyData와 서버 프로필에서 categories 가져오기
    List<String> effectiveCategories = List.from(surveyData.categories);
    final serverCategories = userProfileAsync.maybeWhen(
      data: (profile) => profile.categories,
      orElse: () => null,
    );
    
    if (effectiveCategories.isEmpty && serverCategories != null && serverCategories.isNotEmpty) {
      effectiveCategories = List.from(serverCategories);
    }
    
    if (effectiveCategories.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 500));
      // 중복 제거 및 대소문자 통일
      final uniqueCategories = effectiveCategories
          .map((cat) => cat.toUpperCase())
          .toSet()
          .toList();
      final categoriesText = uniqueCategories.join(', ');
      addMessage(
        MessageModel(
          senderId: 'chatbot',
          text: 'You are currently using $categoriesText! Please wait a moment!',
          timestamp: DateTime.now(),
          isMe: false,
        ),
      );
    }

    // 제품 추천 시작
    debugPrint('제품 추천 시작...');
    await Future.delayed(const Duration(seconds: 1));
    await recommendProductsByBudget();
  }

  /// 예산에 맞게 제품 추천
  Future<void> recommendProductsByBudget() async {
    debugPrint('recommendProductsByBudget 호출됨');
    debugPrint('_hasRecommendedProducts: $_hasRecommendedProducts');
    debugPrint('_selectedBudget: $_selectedBudget');
    
    if (_hasRecommendedProducts) {
      debugPrint('이미 제품 추천이 완료됨. 무시합니다.');
      return;
    }
    if (_selectedBudget == null) {
      debugPrint('선택된 예산이 없음. 무시합니다.');
      return;
    }
    
    final surveyData = ref.read(surveyDataProvider);
    final userProfileAsync = ref.read(userProfileProvider);
    
    // 서버 프로필 데이터를 fallback으로 사용
    String? effectiveSkinType = surveyData.primaryType;
    String? effectiveSkinCondition = surveyData.secondaryType;
    List<String> effectiveCategories = surveyData.categories;
    
    userProfileAsync.whenData((profile) {
      effectiveSkinType ??= profile.skinType;
      effectiveSkinCondition ??= profile.skinCondition;
      if (effectiveCategories.isEmpty && profile.categories != null) {
        effectiveCategories = profile.categories!;
      }
    });
    
    debugPrint('🔀 Effective Data (merged local + server):');
    debugPrint('   - Skin Type: $effectiveSkinType');
    debugPrint('   - Skin Condition: $effectiveSkinCondition');
    debugPrint('   - Categories: $effectiveCategories');
    
    debugPrint('설문 데이터 확인: isComplete=${surveyData.isComplete}, primaryType=${surveyData.primaryType}');
    
    // 로컬과 서버 데이터 모두 없으면 에러
    if (effectiveSkinType == null && effectiveCategories.isEmpty) {
      debugPrint('로컬 및 서버에 설문 데이터 없음. 안내 메시지 표시');
      addMessage(
        MessageModel(
          senderId: 'chatbot',
          text: 'Please complete the survey first to get personalized recommendations!',
          timestamp: DateTime.now(),
          isMe: false,
        ),
      );
      return;
    }

    _hasRecommendedProducts = true;

    // "Searching" 메시지 추가
    final searchingMessageIndex = state.length;
    final searchingMessage = MessageModel(
      senderId: 'chatbot',
      text: 'Searching',
      timestamp: DateTime.now(),
      isMe: false,
    );
    addMessage(searchingMessage);

    final typingNotifier = ref.read(isTypingProvider(chatId).notifier);
    
    await Future.delayed(const Duration(seconds: 1));
    typingNotifier.setTyping(true);
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // 예산 추출 (숫자만)
      final budgetAmount = _selectedBudget!.replaceAll('\$', '').trim();
      
      debugPrint('📊 Survey Data for Budget API Call:');
      debugPrint('   - Primary Type: ${surveyData.primaryType}');
      debugPrint('   - Secondary Type: ${surveyData.secondaryType}');
      debugPrint('   - Categories: ${surveyData.categories}');
      debugPrint('   - Budget: \$$budgetAmount');
      
      // 프롬프트 생성
      String recommendationPrompt = 'Budget: \$$budgetAmount\n';
      
      if (effectiveSkinType != null) {
        recommendationPrompt += 'Skin Type: $effectiveSkinType\n';
      }
      
      if (effectiveSkinCondition != null && 
          effectiveSkinCondition != "I'm not sure.... plz help!") {
        recommendationPrompt += 'Skin Condition: $effectiveSkinCondition\n';
      }
      
      if (effectiveCategories.isNotEmpty) {
        // 중복 제거 및 대소문자 통일
        final uniqueCategories = effectiveCategories
            .map((cat) => cat.toUpperCase())
            .toSet()
            .toList();
        recommendationPrompt += 'Current Skincare Categories (user is currently using these): ${uniqueCategories.join(', ')}\n';
      }
      
      recommendationPrompt += '\nIMPORTANT: Focus on recommending products for the categories that the user is CURRENTLY USING (listed above). For EACH category that the user currently uses, recommend EXACTLY ONE product. The TOTAL COST of ALL recommended products combined MUST be LESS THAN \$$budgetAmount. Distribute the budget across all categories proportionally. Include product prices in your recommendations.';

      debugPrint('📤 Complete Budget Prompt to API:');
      debugPrint('--- START PROMPT ---');
      debugPrint(recommendationPrompt);
      debugPrint('--- END PROMPT ---');

      _conversationHistory.add({'role': 'user', 'content': recommendationPrompt});

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': 'google/gemma-3-27b-it:free',
          'messages': _conversationHistory,
          'temperature': 0.7,
          'max_tokens': 1500, // 여러 제품 추천을 위해 토큰 수 증가
          'extra_body': {'reasoning': {'enabled': true}},
        },
      );

      // API 응답 구조 안전하게 확인
      final responseData = response.data;
      
      // 에러 응답 확인
      if (responseData != null && responseData['error'] != null) {
        final errorData = responseData['error'];
        final errorMessage = errorData['message'] ?? 'Unknown error';
        final errorCode = errorData['code'] ?? 'Unknown code';
        debugPrint('API 에러 응답: $errorMessage (코드: $errorCode)');
        debugPrint('전체 응답: $responseData');
        throw Exception("OpenRouter API 오류: $errorMessage (코드: $errorCode)");
      }
      
      // 정상 응답 구조 확인
      if (responseData == null || 
          responseData['choices'] == null || 
          (responseData['choices'] as List).isEmpty ||
          responseData['choices'][0] == null ||
          responseData['choices'][0]['message'] == null) {
        debugPrint('API 응답 구조 오류: $responseData');
        throw Exception("OpenRouter API가 유효한 응답 구조를 반환하지 않았습니다.");
      }

      var responseText = responseData['choices'][0]['message']['content'] as String?;
      responseText = responseText?.replaceAll(RegExp(r'<\|[^|]+\|>'), '').replaceAll(RegExp(r'<[^>]*>'), '').trim();

      if (responseText == null || responseText.isEmpty) {
        throw Exception("OpenRouter API가 유효한 텍스트 응답을 반환하지 않았습니다.");
      }

      debugPrint('API 응답 받음 - 길이: ${responseText.length}');
      debugPrint('응답 시작 부분: ${responseText.substring(0, responseText.length > 500 ? 500 : responseText.length)}');

      _conversationHistory.add({'role': 'assistant', 'content': responseText});

      // 제품 추천에서 총 가격 계산
      final totalPrice = _calculateTotalPrice(responseText);
      final budgetValue = double.tryParse(budgetAmount) ?? 0.0;
      
      debugPrint('총 가격: $totalPrice, 예산: $budgetValue');

      // 총 가격이 예산보다 크면 예산 초과 메시지 표시
      if (totalPrice > budgetValue) {
        debugPrint('예산 초과: 총 가격($totalPrice) > 예산($budgetValue)');
        
        // "Searching" 메시지를 예산 초과 메시지로 교체
        final currentState = List<MessageModel>.from(state);
        if (searchingMessageIndex < currentState.length && 
            currentState[searchingMessageIndex].text == 'Searching') {
          debugPrint('Searching 메시지를 예산 초과 메시지로 교체');
          currentState[searchingMessageIndex] = MessageModel(
            senderId: 'chatbot',
            text: 'Sorry, there are no products matching your budget 😢',
            timestamp: DateTime.now(),
            isMe: false,
          );
          state = currentState;
        } else {
          debugPrint('새로운 예산 초과 메시지 추가');
          addMessage(
            MessageModel(
              senderId: 'chatbot',
              text: 'Sorry, there are no products matching your budget 😢',
              timestamp: DateTime.now(),
              isMe: false,
            ),
          );
        }
        
        // 예산 질문 다시 표시
        await Future.delayed(const Duration(milliseconds: 1000));
        _selectedBudget = null; // 선택된 예산 초기화
        _hasRecommendedProducts = false; // 추천 플래그 초기화
        
        addMessage(
          MessageModel(
            senderId: 'chatbot',
            text: 'What\'s your budget???',
            timestamp: DateTime.now(),
            isMe: false,
            options: ['\$50 💵', '\$100 💵', '\$300 💵', '\$500 💵'],
          ),
        );
      } else {
        // 정상적인 경우: 제품 추천 표시
        // "Searching" 메시지를 실제 응답으로 교체
        final currentState = List<MessageModel>.from(state);
        if (searchingMessageIndex < currentState.length && 
            currentState[searchingMessageIndex].text == 'Searching') {
          debugPrint('Searching 메시지를 제품 추천으로 교체');
          currentState[searchingMessageIndex] = MessageModel(
            senderId: 'gemma',
            text: responseText,
            timestamp: DateTime.now(),
            isMe: false,
          );
          state = currentState;
        } else {
          debugPrint('새로운 제품 추천 메시지 추가');
          final recommendationMessage = MessageModel(
            senderId: 'gemma',
            text: responseText,
            timestamp: DateTime.now(),
            isMe: false,
          );
          addMessage(recommendationMessage);
        }

        // Budget chat에서는 Total Price를 carousel에서 표시하므로 여기서는 메시지로 추가하지 않음
        // "Search again?" 버튼 추가
        await Future.delayed(const Duration(milliseconds: 500));
        addMessage(
          MessageModel(
            senderId: 'chatbot',
            text: 'Would you like to search again?',
            timestamp: DateTime.now(),
            isMe: false,
            options: ['Search again?'],
          ),
        );
      }

    } on DioException catch (e) {
      debugPrint('예산 기반 제품 추천 생성 오류 (DioException): $e');
      debugPrint('응답 데이터: ${e.response?.data}');
      debugPrint('상태 코드: ${e.response?.statusCode}');
      
      // 에러 메시지 표시
      final currentState = List<MessageModel>.from(state);
      final searchingIndex = currentState.indexWhere(
        (m) => m.text == 'Searching' && !m.isMe
      );
      
      String errorMessage = 'Sorry, I encountered an error while searching for products. Please try again!';
      if (e.response?.statusCode == 500) {
        errorMessage = 'The server is temporarily unavailable. Please try again in a moment!';
      } else if (e.response?.statusCode == 429) {
        errorMessage = 'Too many requests. Please wait a moment and try again!';
      }
      
      if (searchingIndex != -1) {
        currentState[searchingIndex] = MessageModel(
          senderId: 'chatbot',
          text: errorMessage,
          timestamp: DateTime.now(),
          isMe: false,
          options: ['Search again'],
        );
        state = currentState;
      } else {
        addMessage(
          MessageModel(
            senderId: 'chatbot',
            text: errorMessage,
            timestamp: DateTime.now(),
            isMe: false,
            options: ['Search again'],
          ),
        );
      }
    } on Exception catch (e) {
      debugPrint('예산 기반 제품 추천 생성 오류 (Exception): $e');
      
      // 에러 메시지 표시
      final currentState = List<MessageModel>.from(state);
      final searchingIndex = currentState.indexWhere(
        (m) => m.text == 'Searching' && !m.isMe
      );
      
      String errorMessage = 'Sorry, I encountered an error while searching for products. Please try again!';
      if (e.toString().contains('Internal Server Error') || e.toString().contains('500')) {
        errorMessage = 'The server is temporarily unavailable. Please try again in a moment!';
      }
      
      if (searchingIndex != -1) {
        currentState[searchingIndex] = MessageModel(
          senderId: 'chatbot',
          text: errorMessage,
          timestamp: DateTime.now(),
          isMe: false,
          options: ['Search again'],
        );
        state = currentState;
      } else {
        addMessage(
          MessageModel(
            senderId: 'chatbot',
            text: errorMessage,
            timestamp: DateTime.now(),
            isMe: false,
            options: ['Search again'],
          ),
        );
      }
    } finally {
      typingNotifier.setTyping(false);
    }
  }

  /// 예산 재선택 (Search again 버튼)
  Future<void> retryRecommendation() async {
    // 최신 예산 선택 상태만 초기화 (기존 메시지의 선택은 유지)
    _selectedBudget = null;
    _hasRecommendedProducts = false;
    
    // 예산 질문만 다시 표시 (인사 메시지 없이)
    addMessage(
      MessageModel(
        senderId: 'chatbot',
        text: 'What\'s your budget???',
        timestamp: DateTime.now(),
        isMe: false,
        options: ['\$50 💵', '\$100 💵', '\$300 💵', '\$500 💵'],
      ),
    );
  }
  
  /// 특정 메시지에서 예산이 선택되었는지 확인
  bool isBudgetSelectedForMessage(DateTime? messageTimestamp) {
    if (messageTimestamp == null) return false;
    return _selectedBudgetsByMessage.containsKey(messageTimestamp);
  }
  
  /// 특정 메시지에서 선택된 예산 가져오기
  String? getSelectedBudgetForMessage(DateTime? messageTimestamp) {
    if (messageTimestamp == null) return null;
    return _selectedBudgetsByMessage[messageTimestamp];
  }

  /// 제품 추천 응답에서 총 가격 계산
  double _calculateTotalPrice(String responseText) {
    try {
      // 가격 추출 패턴: (Price) 또는 ($Price) 형식
      final pricePattern = RegExp(r'\((\$?\d+\.?\d*)\)');
      final prices = pricePattern.allMatches(responseText);
      
      double totalPrice = 0.0;
      for (final match in prices) {
        final priceStr = match.group(1)?.replaceAll('\$', '').trim() ?? '';
        final price = double.tryParse(priceStr);
        if (price != null) {
          totalPrice += price;
        }
      }
      
      return totalPrice;
    } catch (e, stackTrace) {
      debugPrint('총 가격 계산 오류: $e');
      debugPrint('스택 트레이스: $stackTrace');
      return 0.0;
    }
  }

  /// 제품 추천 응답에서 요약 메시지 생성 (총 가격만 표시)
  String _generateSummaryMessage(String responseText, SurveyData surveyData) {
    try {
      final totalPrice = _calculateTotalPrice(responseText);
      
      // 총 가격만 반환
      if (totalPrice > 0) {
        return 'Total Price: \$${totalPrice.toStringAsFixed(2)}';
      }
      
      return '';
    } catch (e, stackTrace) {
      debugPrint('요약 메시지 생성 오류: $e');
      debugPrint('스택 트레이스: $stackTrace');
      return '';
    }
  }

  /// 선택된 예산 확인
  String? get selectedBudget => _selectedBudget;
  
  /// 예산이 선택되었는지 확인 (이모티콘 제거 후 비교)
  bool isBudgetSelected(String budget) {
    final budgetAmount = budget.replaceAll(' 💵', '').trim();
    return _selectedBudget == budgetAmount;
  }
}

/// 예산 메시지 Provider
final budgetMessageProvider = StateNotifierProvider.family<BudgetMessageNotifier, List<MessageModel>, String>(
  (ref, chatId) => BudgetMessageNotifier(ref, chatId, []),
);

