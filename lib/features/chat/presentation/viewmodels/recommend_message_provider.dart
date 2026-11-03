import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/data/models/message_model.dart';
import 'package:mobileprogramming_groupproject_2025/api_keys.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/viewmodels/typing_provider.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/viewmodels/survey_data_provider.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/viewmodels/survey_message_provider.dart';
import 'package:mobileprogramming_groupproject_2025/features/settings/presentation/viewmodels/user_profile_viewmodel.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// AI 기반 제품 추천 및 추가 질문 관리 Provider
class AIMessageNotifier extends StateNotifier<List<MessageModel>> {
  final Ref ref;
  final String chatId;
  final Dio _dio = Dio();
  final Dio _serverDio = Dio(); // 서버 통신용 Dio 인스턴스
  final Random _random = Random();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final List<Map<String, dynamic>> _conversationHistory = [];
  int _currentQuestionIndex = 0; // 현재 질문 인덱스 (추가 질문용, 0-2, 총 3개)
  final List<Map<String, String>> _questionAnswers = []; // 질문과 답변 저장 (추가 질문용)
  bool _dataSentToServer = false; // 서버로 데이터를 보냈는지 추적
  Future<void>? _currentApiCall; // 현재 진행 중인 API 호출 추적
  bool _hasStartedRecommendation = false; // 제품 추천이 시작되었는지 추적

  AIMessageNotifier(this.ref, this.chatId, List<MessageModel> initialMessages) 
      : super(List.from(initialMessages)) {
    _dio.options.baseUrl = 'https://openrouter.ai/api/v1';
    _dio.options.headers = {
      'Authorization': 'Bearer $OPENROUTER_API_KEY',
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://mobileprogramming-groupproject_2025.app',
      'X-Title': 'Mobile Programming Group Project',
    };
    
    // 서버 통신용 Dio 설정
    _serverDio.options.baseUrl = 'http://43.203.250.50:8080';
    _serverDio.options.headers = {
      'Content-Type': 'application/json',
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
    _currentQuestionIndex = 0;
    _questionAnswers.clear();
    _dataSentToServer = false;
    _currentApiCall = null;
    _hasStartedRecommendation = false;
    
    // 시스템 프롬프트 초기화
    _initializeSystemPrompt();
  }

  /// 시스템 프롬프트 초기화
  void _initializeSystemPrompt() {
    _conversationHistory.add({
      'role': 'system',
      'content': '''You are a skin care expert AI assistant. Your role is to analyze users' skin conditions and recommend appropriate skincare products.

⚠️⚠️⚠️ CRITICAL FORMATTING RULES - YOU MUST FOLLOW THESE EXACTLY OR YOUR RESPONSE WILL FAIL TO PARSE ⚠️⚠️⚠️

1. Always respond in ENGLISH, not Korean.

2. Keep your responses SHORT and CONCISE. Be brief while maintaining clarity.

3. NEVER output any special tokens like <|begin_of_sentence|>, <|end_of_sentence|>, or any other token markers. Only output natural text.

4. ⚠️ CRITICAL: You MUST recommend ONLY products that EXIST in the Sephora database. Use EXACT product names and brand names as they appear on Sephora.com. 
   - DO NOT make up product names or use generic descriptions
   - DO NOT abbreviate or modify product names
   - Use the COMPLETE, EXACT product name as it appears on Sephora.com
   - Examples of REAL Sephora products:
     * Cleansers: [Fresh] Soy Face Cleanser, [Youth To The People] Superfood Antioxidant Cleanser, [La Roche-Posay] Toleriane Hydrating Gentle Cleanser
     * Toners: [The Ordinary] Glycolic Acid 7% Toning Solution, [Paula's Choice] Skin Perfecting 2% BHA Liquid Exfoliant, [Thayers] Witch Hazel Facial Toner
     * Serums: [The Ordinary] Niacinamide 10% + Zinc 1%, [SkinCeuticals] C E Ferulic, [Drunk Elephant] C-Firma Vitamin C Day Serum
     * Moisturizers: [Kiehl's] Ultra Facial Cream, [Tatcha] The Water Cream, [La Mer] Crème de la Mer
   - If you are unsure about a product name, use well-known, popular products from major brands like The Ordinary, Paula's Choice, Fresh, Youth To The People, La Roche-Posay, etc.

5. ⚠️ MANDATORY FORMAT - YOU MUST USE THIS EXACT FORMAT WITH NO DEVIATIONS:

### 1. **Cleanser**

**Recommended Products:** [Brand Name] Product Name 1 (\$Price), [Brand Name] Product Name 2 (\$Price)

**Reason:** Brief explanation (1-2 sentences maximum).

### 2. **Toner**

**Recommended Products:** [Brand Name] Product Name 1 (\$Price), [Brand Name] Product Name 2 (\$Price)

**Reason:** Brief explanation (1-2 sentences maximum).

### 3. **Serum**

**Recommended Products:** [Brand Name] Product Name 1 (\$Price), [Brand Name] Product Name 2 (\$Price)

**Reason:** Brief explanation (1-2 sentences maximum).

⚠️ ABSOLUTE REQUIREMENTS - DO NOT DEVIATE FROM THESE:

1. Category header format: EXACTLY "### [number]. **[Category Name]**"
   - MUST start with "### "
   - MUST have a number followed by ". "
   - Category name MUST be wrapped in double asterisks: **Category Name**
   - Example: ### 1. **Cleanser**
   - Example: ### 2. **Toner**
   - Example: ### 3. **Serum**

2. Recommended Products line: EXACTLY "**Recommended Products:**"
   - MUST use double asterisks before and after "Recommended Products"
   - MUST have a colon after "Products"
   - MUST be on its own line
   - Example: **Recommended Products:**

3. Product format: EXACTLY "[Brand Name] Product Name (\$Price)"
   - Brand name MUST be in square brackets [Brand Name]
   - Product name comes AFTER the brand name (outside brackets)
   - Price MUST be in parentheses with dollar sign: (\$XX)
   - Multiple products separated by comma and space: ", "
   - Example: [Fresh] Soy Face Cleanser (\$38), [Youth To The People] Superfood Antioxidant Cleanser (\$36)
   - Example: [The Ordinary] Niacinamide 10% + Zinc 1% (\$6), [Paula's Choice] 2% BHA Liquid Exfoliant (\$30)

4. Reason line: EXACTLY "**Reason:**"
   - MUST use double asterisks before and after "Reason"
   - MUST have a colon after "Reason"
   - MUST be on its own line
   - Example: **Reason:**

5. Category names: Use standard skincare categories
   - Cleanser, Toner, Serum, Moisturizer, Sunscreen, Eye Cream, Mask, Exfoliant, etc.
   - Category name MUST be in double asterisks: **Category Name**

6. Price format: MUST be (\$XX) or (\$XX.XX)
   - Always include dollar sign and parentheses
   - Example: (\$38), (\$6.50), (\$145.00)

7. NO DEVIATIONS ALLOWED:
   - NO other text before the first "###"
   - NO other text after the last "**Reason:**" section
   - NO variations in spacing, punctuation, or formatting
   - NO missing brackets, asterisks, or colons
   - NO alternative formats like "Products:" or "Recommended:" without asterisks
   - NO product names without brand names in brackets
   - NO prices without dollar signs or parentheses

8. COMPLETE EXAMPLE OF CORRECT FORMAT:

### 1. **Cleanser**

**Recommended Products:** [Fresh] Soy Face Cleanser (\$38), [Youth To The People] Superfood Antioxidant Cleanser (\$36)

**Reason:** These gentle cleansers are perfect for your skin type and won't strip natural oils.

### 2. **Toner**

**Recommended Products:** [The Ordinary] Glycolic Acid 7% Toning Solution (\$8), [Paula's Choice] Skin Perfecting 2% BHA Liquid Exfoliant (\$30)

**Reason:** These toners help balance pH and provide gentle exfoliation.

### 3. **Serum**

**Recommended Products:** [The Ordinary] Niacinamide 10% + Zinc 1% (\$6), [SkinCeuticals] C E Ferulic (\$166)

**Reason:** These serums target specific skin concerns and provide targeted benefits.

⚠️ IF YOU DO NOT FOLLOW THIS EXACT FORMAT, THE RESPONSE WILL FAIL TO PARSE AND NO PRODUCTS WILL BE DISPLAYED ⚠️

6. Keep reasons short - focus on key benefits only (1-2 sentences maximum).

7. Avoid lengthy explanations or unnecessary details.

8. Consider the user's skin type, skin condition, and current skincare routine when making recommendations.

9. ⚠️ CRITICAL PRODUCT SELECTION RULES:
   - ONLY recommend products that you are CERTAIN exist on Sephora.com
   - Use EXACT product names - do not modify, abbreviate, or create variations
   - Prefer well-known, popular products from major brands
   - If uncertain, choose from these reliable brands: The Ordinary, Paula's Choice, Fresh, Youth To The People, La Roche-Posay, Kiehl's, Tatcha, Drunk Elephant, SkinCeuticals, CeraVe, Neutrogena
   - The product name MUST match exactly as it appears on Sephora.com - check your knowledge base for exact names
   - DO NOT recommend products you are not 100% certain exist on Sephora.com''',
    });
  }

  /// 서버로 사용자 정보 전송
  Future<void> _sendUserDataToServer() async {
    if (_dataSentToServer) return;
    
    try {
      final surveyData = ref.read(surveyDataProvider);
      final accessToken = await _storage.read(key: 'access_token');
      
      final Map<String, dynamic> userData = {
        'primaryType': surveyData.primaryType,
        'secondaryType': surveyData.secondaryType != "I'm not sure.... plz help!" 
            ? surveyData.secondaryType 
            : null,
        'categories': surveyData.categories,
        'preset': null,
        'min': null,
        'max': null,
      };
      
      if (accessToken != null) {
        _serverDio.options.headers['Authorization'] = 'Bearer $accessToken';
      }
      
      final response = await _serverDio.post(
        '/users/skin-info',
        data: userData,
      );
      
      debugPrint('서버로 사용자 정보 전송 성공: ${response.statusCode}');
      debugPrint('전송된 데이터: $userData');
      
      _dataSentToServer = true;
    } catch (e) {
      debugPrint('서버로 사용자 정보 전송 실패: $e');
    }
  }

  /// 저장된 설문 데이터로 제품 추천 시작
  Future<void> recommendProducts({bool isRetry = false}) async {
    // "Search again?" 버튼을 눌렀을 때는 기존 메시지를 유지하고 새로 추천 시작
    if (isRetry) {
      debugPrint('Search again 버튼 클릭: 새 제품 추천 시작');
      // "Search again" 메시지만 제거 (기존 제품 추천 메시지는 유지)
      final newState = state.where((m) => 
        m.text != 'Search again' &&
        m.text != 'Search again?'
      ).toList();
      state = newState;
      
      // 상태 초기화
      _hasStartedRecommendation = false;
      _currentApiCall = null;
      
      // 새로 추천 시작 (아래 로직 계속 진행)
    } else {
    // 이미 제품 추천이 시작되었는지 확인 (budget routine처럼)
    if (_hasStartedRecommendation) {
      debugPrint('제품 추천이 이미 시작되었습니다. 중복 호출을 방지합니다.');
      return;
    }
    
    // 이미 제품 추천이 완료되었는지 확인
    final hasProductRecommendation = state.any((m) => 
      m.senderId == 'gemma' && 
      (m.text.contains('###') || m.text.contains('Recommended Products'))
    );
    
    // 이미 제품 추천이 완료되었으면 새로 시작하지 않음
    if (hasProductRecommendation) {
      debugPrint('제품 추천이 이미 완료되었습니다.');
      _hasStartedRecommendation = true; // 시작된 것으로 표시
      return;
      }
    }
    
    // 인트로 메시지가 이미 있는지 확인
    final hasIntroMessage = state.any((m) => 
      !m.isMe && m.text == "Based on your survey, I'd like to recommend these products for you! 👍"
    );
    
    // "Searching" 메시지가 있지만 API 호출이 진행 중이면 기다림 (백그라운드에서 계속 진행)
    final hasSearchingMessage = state.any((m) => m.text == 'Searching' && !m.isMe);
    if (hasSearchingMessage && _currentApiCall != null) {
      debugPrint('API 호출이 이미 진행 중입니다. 백그라운드에서 계속 진행됩니다.');
      // typing indicator는 _performApiCall에서 관리하므로 여기서는 설정하지 않음
      _hasStartedRecommendation = true; // 시작된 것으로 표시
      return;
    }
    
    // "Searching" 메시지가 있지만 API 호출이 null이면 재개 필요
    if (hasSearchingMessage && _currentApiCall == null) {
      debugPrint('Searching 메시지는 있지만 API 호출이 없습니다. 재개합니다.');
      // Searching 메시지의 인덱스 찾기
      final searchingIndex = state.indexWhere((m) => m.text == 'Searching' && !m.isMe);
      if (searchingIndex != -1) {
        final typingNotifier = ref.read(isTypingProvider(chatId).notifier);
        // typing indicator는 _performApiCall에서 설정하므로 여기서는 설정하지 않음
        // API 호출 재개
        _currentApiCall = _performApiCall(searchingIndex, typingNotifier);
        _currentApiCall!.then((_) {
          _currentApiCall = null;
          debugPrint('API 호출 완료됨 (백그라운드)');
        }).catchError((e) {
          _currentApiCall = null;
          debugPrint('API 호출 오류 (백그라운드): $e');
        });
        _hasStartedRecommendation = true;
        return;
      }
    }
    
    // 인트로 메시지는 있지만 Searching이 없으면 API 호출을 재개해야 함
    if (hasIntroMessage) {
      debugPrint('인트로 메시지는 있지만 Searching이 없습니다. API 호출을 재개합니다.');
      
      final surveyData = ref.read(surveyDataProvider);
      
      // "Searching" 메시지 추가
      final searchingMessageIndex = state.length;
      final searchingMessage = MessageModel(
        senderId: 'chatbot',
        text: 'Searching',
        timestamp: DateTime.now(),
        isMe: false,
      );
      addMessage(searchingMessage);
      
      // 프롬프트 구성 (이미 대화 기록에 있을 수 있으므로 확인)
      String recommendationPrompt = '';
      
      if (surveyData.primaryType != null) {
        recommendationPrompt += 'Skin Type: ${surveyData.primaryType}\n';
      }
      
      if (surveyData.secondaryType != null && surveyData.secondaryType != "I'm not sure.... plz help!") {
        recommendationPrompt += 'Skin Condition: ${surveyData.secondaryType}\n';
      }
      
      if (surveyData.categories.isNotEmpty) {
        final cosmeticsText = surveyData.categories.join(', ');
        recommendationPrompt += 'Current Skincare Products: $cosmeticsText\n';
      }
      
      if (surveyData.questionAnswers.isNotEmpty) {
        recommendationPrompt += '\nQuestions and Answers:\n';
        for (var qa in surveyData.questionAnswers) {
          recommendationPrompt += 'Q: ${qa['question']}\nA: ${qa['answer']}\n\n';
        }
      }
      
      recommendationPrompt += '''Based on the above information, please recommend skincare products that match my skin type and condition.

⚠️ CRITICAL REQUIREMENTS:
1. You MUST use the EXACT format specified in the system prompt
2. You MUST recommend ONLY products that EXIST on Sephora.com - use EXACT product names
3. Use well-known, popular products from major brands (The Ordinary, Paula's Choice, Fresh, Youth To The People, La Roche-Posay, etc.)
4. DO NOT make up or modify product names - use the COMPLETE, EXACT name as it appears on Sephora.com
5. Format: ### [number]. **[Category Name]**
   **Recommended Products:** [Brand Name] EXACT Product Name (\$Price)
   **Reason:** Brief explanation''';
      
      // 대화 기록에 없으면 추가
      final hasPromptInHistory = _conversationHistory.any((msg) => 
        msg['role'] == 'user' && msg['content'].contains('Skin Type:')
      );
      if (!hasPromptInHistory) {
        _conversationHistory.add({
          'role': 'user',
          'content': recommendationPrompt,
        });
      }
      
      // API 호출 재개
      final typingNotifier = ref.read(isTypingProvider(chatId).notifier);
      
      final readDelayMs = 1000 + _random.nextInt(3000);
      await Future.delayed(Duration(milliseconds: readDelayMs));
      
      final thinkDelayMs = 1000 + _random.nextInt(2000);
      await Future.delayed(Duration(milliseconds: thinkDelayMs));
      
      // typing indicator 설정 (API 호출 직전에 한 번만)
      final isCurrentlyTyping = ref.read(isTypingProvider(chatId));
      if (!isCurrentlyTyping) {
        typingNotifier.setTyping(true);
      }
      await Future.delayed(const Duration(milliseconds: 500));
      
      _currentApiCall = _performApiCall(searchingMessageIndex, typingNotifier);
      _currentApiCall!.then((_) {
        _currentApiCall = null;
        debugPrint('API 호출 완료됨 (백그라운드)');
      }).catchError((e) {
        _currentApiCall = null;
        debugPrint('API 호출 오류 (백그라운드): $e');
      });
      
      _hasStartedRecommendation = true;
      return;
    }
    
    // 제품 추천 시작
    _hasStartedRecommendation = true;
    
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
    
    // 서버로 사용자 정보 전송
    await _sendUserDataToServer();

    // "Based on your survey, I'd like to recommend these products for you! 👍" 메시지가 없으면 추가
    final hasIntroMessageAlready = state.any((m) => 
      !m.isMe && m.text == "Based on your survey, I'd like to recommend these products for you! 👍"
    );
    
    if (!hasIntroMessageAlready) {
    final introMessage = MessageModel(
      senderId: 'chatbot',
      text: "I'd like to recommend these products right now! 👍",
      timestamp: DateTime.now(),
      isMe: false,
    );
    addMessage(introMessage);

    // 2초 대기
    await Future.delayed(const Duration(seconds: 2));
    } else {
      // 이미 인트로 메시지가 있으면 짧게 대기
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // "Searching" 메시지 추가
    final searchingMessageIndex = state.length;
    final searchingMessage = MessageModel(
      senderId: 'chatbot',
      text: 'Searching',
      timestamp: DateTime.now(),
      isMe: false,
    );
    addMessage(searchingMessage);

    // 피부 타입, 서브타입, 선택한 화장품, 질문 답변을 조합해서 AI에게 질문 구성
    debugPrint('📊 Survey Data for API Call:');
    debugPrint('   - Primary Type: ${surveyData.primaryType}');
    debugPrint('   - Secondary Type: ${surveyData.secondaryType}');
    debugPrint('   - Categories: ${surveyData.categories}');
    debugPrint('   - Question Answers: ${surveyData.questionAnswers.length}');
    
    String recommendationPrompt = '';
    
    if (effectiveSkinType != null) {
      recommendationPrompt += 'Skin Type: $effectiveSkinType\n';
    }
    
    if (effectiveSkinCondition != null && effectiveSkinCondition != "I'm not sure.... plz help!") {
      recommendationPrompt += 'Skin Condition: $effectiveSkinCondition\n';
    }
    
    if (effectiveCategories.isNotEmpty) {
      final cosmeticsText = effectiveCategories.join(', ');
      recommendationPrompt += 'Current Skincare Products: $cosmeticsText\n';
    }
    
    if (surveyData.questionAnswers.isNotEmpty) {
      recommendationPrompt += '\nQuestions and Answers:\n';
      for (var qa in surveyData.questionAnswers) {
        recommendationPrompt += 'Q: ${qa['question']}\nA: ${qa['answer']}\n\n';
      }
    }
    
    recommendationPrompt += '''Based on the above information, please recommend skincare products that match my skin type and condition.

⚠️ CRITICAL: You MUST use the EXACT format specified in the system prompt:
- Start each category with: ### [number]. **[Category Name]**
- Use: **Recommended Products:** [Brand Name] Product Name (\$Price), [Brand Name] Product Name (\$Price)
- Use: **Reason:** Brief explanation
- Follow the format EXACTLY or the response will fail to parse.''';

    debugPrint('📤 Complete Prompt to API:');
    debugPrint('--- START PROMPT ---');
    debugPrint(recommendationPrompt);
    debugPrint('--- END PROMPT ---');

    // 질문을 대화 기록에만 추가 (UI에는 표시하지 않음)
    _conversationHistory.add({
      'role': 'user',
      'content': recommendationPrompt,
    });

    // AI 응답 받기
    final typingNotifier = ref.read(isTypingProvider(chatId).notifier);
    
    final readDelayMs = 1000 + _random.nextInt(3000);
    await Future.delayed(Duration(milliseconds: readDelayMs));

    final thinkDelayMs = 1000 + _random.nextInt(2000);
    await Future.delayed(Duration(milliseconds: thinkDelayMs));

    // typing indicator 설정 (API 호출 직전에 한 번만)
    final isCurrentlyTyping = ref.read(isTypingProvider(chatId));
    if (!isCurrentlyTyping) {
    typingNotifier.setTyping(true);
    }
    await Future.delayed(const Duration(milliseconds: 500));

    // API 호출을 Future로 저장하여 백그라운드에서 계속 진행되도록 함
    // await하지 않아서 페이지를 나가도 백그라운드에서 계속 진행됨
    _currentApiCall = _performApiCall(searchingMessageIndex, typingNotifier);
    _currentApiCall!.then((_) {
      _currentApiCall = null;
      debugPrint('API 호출 완료됨 (백그라운드)');
    }).catchError((e) {
      _currentApiCall = null;
      debugPrint('API 호출 오류 (백그라운드): $e');
    });
  }

  /// 실제 API 호출 수행 (백그라운드에서 계속 진행)
  Future<void> _performApiCall(int searchingMessageIndex, TypingNotifier typingNotifier) async {
    try {
      // API 호출 중에는 typing indicator 유지
      // recommendProducts()에서 이미 설정했으므로 여기서는 다시 설정하지 않음
      // (중복 방지)
      
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': 'google/gemma-3-27b-it:free',
          'messages': _conversationHistory,
          'temperature': 0.7,
          'max_tokens': 500,
          'extra_body': {
            'reasoning': {'enabled': true}
          },
        },
      );

      var responseText = response.data['choices'][0]['message']['content'] as String?;

      if (responseText == null || responseText.isEmpty) {
        throw Exception("OpenRouter API가 유효한 텍스트 응답을 반환하지 않았습니다.");
      }

      // 특수 토큰 제거
      responseText = responseText
          .replaceAll(RegExp(r'<\|[^|]+\|>'), '')
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .trim();

      _conversationHistory.add({
        'role': 'assistant',
        'content': responseText,
      });

      // "Searching" 메시지를 제거하고 실제 응답으로 교체
      final currentState = List<MessageModel>.from(state);
      if (searchingMessageIndex < currentState.length && 
          currentState[searchingMessageIndex].text == 'Searching') {
        currentState[searchingMessageIndex] = MessageModel(
          senderId: 'gemma',
          text: responseText,
          timestamp: DateTime.now(),
          isMe: false,
        );
        state = currentState;
      } else {
        final deepseekResponse = MessageModel(
          senderId: 'gemma',
          text: responseText,
          timestamp: DateTime.now(),
          isMe: false,
        );
        addMessage(deepseekResponse);
      }

      // 제품 추천이 있는지 확인
      final hasProducts = responseText.contains('###') && 
                         (responseText.contains('**Recommended Products:**') || 
                          responseText.contains('Recommended Products'));

      // 제품 추천 후에는 질문 3개를 연속으로 생성
      if (hasProducts) {
        // 제품 추천 후 안내 메시지 추가
        await Future.delayed(const Duration(seconds: 1));
        final guideMessage = MessageModel(
          senderId: 'chatbot',
          text: "Would you like more personalized recommendations? Let me ask you a few more questions! 😊",
          timestamp: DateTime.now(),
          isMe: false,
        );
        addMessage(guideMessage);
        
        _currentQuestionIndex = 0;
        _questionAnswers.clear();
        await Future.delayed(const Duration(seconds: 1));
        await _generateThreeQuestions();
      }

    } catch (e) {
      debugPrint('제품 추천 생성 오류: $e');
      // typing indicator 종료
      typingNotifier.setTyping(false);
      
      // 에러 메시지 표시 (영어로)
      final currentState = List<MessageModel>.from(state);
      final searchingIndex = currentState.indexWhere(
        (m) => m.text == 'Searching' && !m.isMe
      );
      if (searchingIndex != -1) {
        currentState[searchingIndex] = MessageModel(
          senderId: 'chatbot',
          text: 'Sorry, I encountered an error while searching for products. Please try again!',
          timestamp: DateTime.now(),
          isMe: false,
          options: ['Search again'],
        );
        state = currentState;
      } else {
        // Searching 메시지가 없으면 새로 추가
        addMessage(
          MessageModel(
            senderId: 'chatbot',
            text: 'Sorry, I encountered an error while searching for products. Please try again!',
            timestamp: DateTime.now(),
            isMe: false,
            options: ['Search again'],
          ),
        );
      }
    }
  }

  /// 질문 3개를 연속으로 생성 (제품 추천 후 추가 질문)
  Future<void> _generateThreeQuestions() async {
    _currentQuestionIndex = 0;
    _questionAnswers.clear();
    await generateNextQuestion();
  }

  /// 다음 질문 생성 (3개 중 하나) - ai_message_provider에서 호출
  Future<void> generateNextQuestion() async {
    debugPrint('generateNextQuestion 호출됨 (ai_message_provider)');
    
    final typingNotifier = ref.read(isTypingProvider(chatId).notifier);
    
    // ai_message_provider의 메시지에서 질문 답변 가져오기
    final questionAnswers = <Map<String, String>>[];
    for (var i = 0; i < state.length - 1; i++) {
      final msg = state[i];
      if (!msg.isMe && msg.options != null && msg.options!.isNotEmpty) {
        // 다음 사용자 메시지 찾기
        if (i + 1 < state.length && state[i + 1].isMe) {
          questionAnswers.add({
            'question': msg.text,
            'answer': state[i + 1].text,
          });
        }
      }
    }
    
    // 2-3초 대기 (rate limit 방지)
    await Future.delayed(Duration(seconds: 2 + _random.nextInt(2)));
    
    typingNotifier.setTyping(true);
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // 이전 질문과 답변을 컨텍스트로 포함
      String contextPrompt = '';
      if (questionAnswers.isNotEmpty) {
        contextPrompt = 'Previous questions and answers:\n';
        for (var qa in questionAnswers) {
          contextPrompt += 'Q: ${qa['question']}\nA: ${qa['answer']}\n\n';
        }
        contextPrompt += 'Now generate the next question (${questionAnswers.length + 1} of 3):\n';
      } else {
        contextPrompt = 'Generate the first question (1 of 3) based on our conversation:\n';
      }

      // 이전 질문들을 가져와서 중복 방지
      final previousQuestions = questionAnswers.map((qa) => qa['question'] as String).toList();
      final previousQuestionsText = previousQuestions.isNotEmpty 
          ? 'Previous questions asked: ${previousQuestions.join(' | ')}\n\nCRITICAL: You MUST ask a COMPLETELY DIFFERENT question. Do NOT ask about the same topic or use similar wording.\n'
          : '';

      // 질문 주제 다양화를 위한 힌트
      final questionTopics = [
        'daily skincare routine',
        'skin texture and feel',
        'environmental factors',
        'product preferences',
        'skin concerns timing',
        'lifestyle habits',
        'skin reaction patterns',
        'skincare goals',
      ];
      final topicHint = questionAnswers.length < questionTopics.length
          ? 'Consider asking about: ${questionTopics[questionAnswers.length]}\n'
          : 'Ask about a NEW aspect of skincare we haven\'t covered yet.\n';

      final questionPrompt = '''$contextPrompt
$previousQuestionsText
$topicHint
Generate ONE short follow-up question related to skincare. The question must be COMPLETELY DIFFERENT from previous questions - ask about a different aspect, topic, or concern.

Question guidelines:
- Ask about DIFFERENT topics: routine, texture, environment, products, timing, lifestyle, reactions, goals
- Use DIFFERENT wording and phrasing
- Focus on a NEW aspect we haven't discussed
- The question should be concise and have 3-4 multiple choice options

Format your response EXACTLY like this:
QUESTION: [Your question here]
OPTIONS: option1, option2, option3, option4

Examples of DIFFERENT questions:
QUESTION: How often do you change your skincare routine?
OPTIONS: weekly, monthly, rarely, never
QUESTION: What time of day is your skin most problematic?
OPTIONS: morning, afternoon, evening, night
QUESTION: How does your skin react to new products?
OPTIONS: immediately, after days, rarely, never

Keep the question and options SHORT (1-3 words each). Make it COMPLETELY DIFFERENT from previous questions.''';

      // 대화 기록 가져오기 (survey_data_provider에서)
      final surveyData = ref.read(surveyDataProvider);
      final conversationHistory = [
        if (surveyData.primaryType != null)
          {'role': 'user', 'content': surveyData.primaryType!},
        if (surveyData.secondaryType != null)
          {'role': 'user', 'content': surveyData.secondaryType!},
      ];

      final tempHistory = List<Map<String, dynamic>>.from(conversationHistory);
      tempHistory.add({
        'role': 'user',
        'content': questionPrompt,
      });

      Response response;
      try {
        response = await _dio.post(
          '/chat/completions',
          data: {
            'model': 'google/gemma-3-27b-it:free',
            'messages': tempHistory,
            'temperature': 0.7,
            'max_tokens': 150,
          },
        );
      } on DioException catch (dioError) {
        if (dioError.response?.statusCode == 429) {
          int retryAfterSeconds = 5;
          final retryAfterHeader = dioError.response?.headers.value('retry-after');
          if (retryAfterHeader != null) {
            final retryAfterValue = int.tryParse(retryAfterHeader);
            if (retryAfterValue != null && retryAfterValue > 0) {
              retryAfterSeconds = retryAfterValue;
            }
          }
          
          await Future.delayed(Duration(seconds: retryAfterSeconds));
          
          try {
            response = await _dio.post(
              '/chat/completions',
              data: {
                'model': 'google/gemma-3-27b-it:free',
                'messages': tempHistory,
                'temperature': 0.7,
                'max_tokens': 150,
              },
            );
          } catch (retryError) {
            debugPrint('질문 생성 재시도 실패: $retryError');
            final errorMessage = MessageModel(
              senderId: 'chatbot',
              text: 'I had trouble generating a question. Please try again later.',
              timestamp: DateTime.now(),
              isMe: false,
            );
            addMessage(errorMessage);
            typingNotifier.setTyping(false);
            return;
          }
        } else {
          final errorMessage = MessageModel(
            senderId: 'chatbot',
            text: 'I had trouble generating a question. Please try again later.',
            timestamp: DateTime.now(),
            isMe: false,
          );
          addMessage(errorMessage);
          typingNotifier.setTyping(false);
          return;
        }
      }

      dynamic messageData = response.data['choices'][0]['message'];
      var responseText = messageData['content'] as String?;

      if (responseText == null || responseText.isEmpty) {
        final errorMessage = MessageModel(
          senderId: 'chatbot',
          text: 'I had trouble generating a question. Please try again later.',
          timestamp: DateTime.now(),
          isMe: false,
        );
        addMessage(errorMessage);
        typingNotifier.setTyping(false);
        return;
      }

      // 특수 토큰 제거
      responseText = responseText
          .replaceAll(RegExp(r'<\|[^|]+\|>'), '')
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .trim();

      // 질문과 옵션 파싱
      var questionMatch = RegExp(r'QUESTION:\s*(.+?)(?=OPTIONS:|$)', dotAll: true, caseSensitive: false).firstMatch(responseText);
      var optionsMatch = RegExp(r'OPTIONS:\s*(.+?)$', dotAll: true, caseSensitive: false).firstMatch(responseText);
      
      if (questionMatch == null || optionsMatch == null) {
        questionMatch = RegExp(r'(?:QUESTION|Question|Q):\s*(.+?)(?=OPTIONS|Options|$)', dotAll: true, caseSensitive: false).firstMatch(responseText);
        optionsMatch = RegExp(r'(?:OPTIONS|Options|O):\s*(.+?)$', dotAll: true, caseSensitive: false).firstMatch(responseText);
      }

      String? question;
      List<String>? options;

      if (questionMatch != null && optionsMatch != null) {
        final parsedQuestion = questionMatch.group(1)?.trim() ?? '';
        final optionsText = optionsMatch.group(1)?.trim() ?? '';
        
        final parsedOptions = optionsText
            .split(',')
            .map((o) => o.trim())
            .where((o) => o.isNotEmpty)
            .toList();

        if (parsedQuestion.isNotEmpty && parsedOptions.isNotEmpty) {
          // ai_message_provider에서 사용된 질문 확인
          final usedQuestions = questionAnswers.map((qa) => qa['question'] as String).toList();
          final existingQuestions = state
              .where((m) => !m.isMe && m.options != null && m.options!.isNotEmpty)
              .map((m) => m.text)
              .toList();
          final allUsedQuestions = [...usedQuestions, ...existingQuestions];
          
          if (!allUsedQuestions.contains(parsedQuestion)) {
            question = parsedQuestion;
            options = parsedOptions;
          }
        }
      }

      // 파싱 실패 시 에러 메시지
      if (question == null || options == null || question.isEmpty || options.isEmpty) {
        final errorMessage = MessageModel(
          senderId: 'chatbot',
          text: 'I had trouble generating a question. Please try again later.',
          timestamp: DateTime.now(),
          isMe: false,
        );
        addMessage(errorMessage);
        typingNotifier.setTyping(false);
        return;
      }

      // 질문 메시지를 ai_message_provider에 추가
      if (question.isNotEmpty && options.isNotEmpty) {
        final questionMessage = MessageModel(
          senderId: 'chatbot',
          text: question,
          timestamp: DateTime.now(),
          isMe: false,
          options: options,
        );
        addMessage(questionMessage);
      }

    } catch (e, stackTrace) {
      debugPrint('질문 생성 오류: $e');
      debugPrint('스택 트레이스: $stackTrace');
      
      final errorMessage = MessageModel(
        senderId: 'chatbot',
        text: 'I had trouble generating a question. Please try again later.',
        timestamp: DateTime.now(),
        isMe: false,
      );
      ref.read(surveyMessageProvider(chatId).notifier).addMessage(errorMessage);
    } finally {
      typingNotifier.setTyping(false);
    }
  }

  /// 사용자 답변 처리 (추가 질문에 대한 답변)
  Future<void> handleAnswer(String answer) async {
    // 최근 질문 찾기
    String? recentQuestion;
    for (int i = state.length - 1; i >= 0; i--) {
      if (!state[i].isMe && state[i].options != null && state[i].options!.isNotEmpty) {
        recentQuestion = state[i].text;
        break;
      }
    }

    if (recentQuestion != null) {
      // 이미 이 질문에 대한 답변이 있는지 확인
      final existingAnswer = _questionAnswers.firstWhere(
        (qa) => qa['question'] == recentQuestion,
        orElse: () => {},
      );
      
      // 이미 답변이 있고, 같은 답변이면 무시
      if (existingAnswer.isNotEmpty && existingAnswer['answer'] == answer) {
        debugPrint('이미 같은 답변이 있습니다. 무시합니다.');
        return;
      }
      
      // 기존 답변이 있으면 업데이트, 없으면 추가
      if (existingAnswer.isNotEmpty) {
        final index = _questionAnswers.indexWhere((qa) => qa['question'] == recentQuestion);
        if (index != -1) {
          _questionAnswers[index] = {
            'question': recentQuestion,
            'answer': answer,
          };
        }
      } else {
        // 사용자 메시지 추가 (새로운 답변인 경우만)
      final userMessage = MessageModel(
        senderId: 'me',
        text: answer,
        timestamp: DateTime.now(),
        isMe: true,
        isSeen: false,
      );
      addMessage(userMessage);

      // 현재 질문 세트의 답변 저장
      _questionAnswers.add({
        'question': recentQuestion,
        'answer': answer,
      });
      }
      
      debugPrint('현재 답변 개수: ${_questionAnswers.length}');
      debugPrint('답변 목록: ${_questionAnswers.map((qa) => '${qa['question']}: ${qa['answer']}').join(', ')}');
      
      // 3개 질문이 완료되었는지 확인 (_questionAnswers 크기로 확인)
      if (_questionAnswers.length >= 3) {
        debugPrint('3개 질문 완료, 제품 추천 생성 시작');
        debugPrint('답변 개수: ${_questionAnswers.length}');
        await _generateProductRecommendationFromThreeQuestions();
      } else {
        debugPrint('아직 질문이 ${_questionAnswers.length}개만 완료됨. 다음 질문 생성');
        // 다음 질문 생성
        _currentQuestionIndex++;
        await generateNextQuestion();
      }
    }
  }

  /// 3개 질문의 답변을 기반으로 제품 추천 생성
  Future<void> _generateProductRecommendationFromThreeQuestions() async {
    debugPrint('_generateProductRecommendationFromThreeQuestions 호출됨');
    debugPrint('현재 답변 개수: ${_questionAnswers.length}');
    
    // 추가 질문 3개에 답변했으므로 새로운 제품 추천을 시작해야 함
    // 기존 제품 추천이 있어도 새로운 추천을 시작 (추가 질문 기반)
    
    final hasSearchingMessage = state.any((m) => m.text == 'Searching' && !m.isMe);
    
    debugPrint('hasSearchingMessage: $hasSearchingMessage');
    debugPrint('_currentApiCall: $_currentApiCall');
    
    // API 호출이 이미 진행 중이면 기다림
    if (hasSearchingMessage && _currentApiCall != null) {
      debugPrint('API 호출이 이미 진행 중입니다. 기존 호출을 취소하고 새로 시작합니다.');
      // 기존 API 호출은 백그라운드에서 계속 진행되도록 두고, 새로운 추천 시작
    }
    
    debugPrint('추가 질문 기반 제품 추천 시작 진행...');
    
    final typingNotifier = ref.read(isTypingProvider(chatId).notifier);
    
    // 기존 "Searching" 메시지가 있으면 제거
    final currentState = List<MessageModel>.from(state);
    final existingSearchingIndex = currentState.indexWhere(
      (m) => m.text == 'Searching' && !m.isMe
    );
    if (existingSearchingIndex != -1) {
      currentState.removeAt(existingSearchingIndex);
      state = currentState;
    }
    
    // 기존 "Based on your survey, I'd like to recommend..." 메시지가 있는지 확인
    final hasIntroMessage = state.any((m) => 
      !m.isMe && m.text == "Based on your survey, I'd like to recommend these products for you! 👍"
    );
    
    // 인트로 메시지가 없으면 추가
    if (!hasIntroMessage) {
    final introMessage = MessageModel(
      senderId: 'chatbot',
      text: "Based on your survey, I'd like to recommend these products for you! 👍",
      timestamp: DateTime.now(),
      isMe: false,
    );
    addMessage(introMessage);
    await Future.delayed(const Duration(seconds: 2));
    } else {
      // 이미 있으면 짧게 대기
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    // "Searching" 메시지 추가
    final searchingMessageIndex = state.length;
    final searchingMessage = MessageModel(
      senderId: 'chatbot',
      text: 'Searching',
      timestamp: DateTime.now(),
      isMe: false,
    );
    addMessage(searchingMessage);
    
    typingNotifier.setTyping(true);
    await Future.delayed(const Duration(milliseconds: 500));

    // API 호출을 Future로 저장하여 백그라운드에서 계속 진행되도록 함
    _currentApiCall = _performApiCallFromQuestions(searchingMessageIndex, typingNotifier);
    _currentApiCall!.then((_) {
      _currentApiCall = null;
      debugPrint('API 호출 완료됨 (3개 질문 기반, 백그라운드)');
    }).catchError((e) {
      _currentApiCall = null;
      debugPrint('API 호출 오류 (3개 질문 기반, 백그라운드): $e');
    });
  }

  /// 3개 질문 기반 API 호출 수행 (백그라운드에서 계속 진행)
  Future<void> _performApiCallFromQuestions(int searchingMessageIndex, TypingNotifier typingNotifier) async {
    try {
      final surveyData = ref.read(surveyDataProvider);
      
      // 제품 추천 프롬프트 생성
      String recommendationPrompt = '';
      
      if (surveyData.primaryType != null) {
        recommendationPrompt += 'Skin Type: ${surveyData.primaryType}\n';
      }
      
      if (surveyData.secondaryType != null && surveyData.secondaryType != "I'm not sure.... plz help!") {
        recommendationPrompt += 'Skin Condition: ${surveyData.secondaryType}\n';
      }
      
      recommendationPrompt += '\nQuestions and Answers:\n';
      for (var qa in _questionAnswers) {
        recommendationPrompt += 'Q: ${qa['question']}\nA: ${qa['answer']}\n\n';
      }
      
      recommendationPrompt += '''Based on the above information, especially the three questions and answers, please recommend skincare products that match the user's needs.

⚠️ CRITICAL REQUIREMENTS:
1. You MUST use the EXACT format specified in the system prompt
2. You MUST recommend ONLY products that EXIST on Sephora.com - use EXACT product names
3. Use well-known, popular products from major brands (The Ordinary, Paula's Choice, Fresh, Youth To The People, La Roche-Posay, etc.)
4. DO NOT make up or modify product names - use the COMPLETE, EXACT name as it appears on Sephora.com
5. Format: ### [number]. **[Category Name]**
   **Recommended Products:** [Brand Name] EXACT Product Name (\$Price)
   **Reason:** Brief explanation''';

      final tempHistory = List<Map<String, dynamic>>.from(_conversationHistory);
      tempHistory.add({
        'role': 'user',
        'content': recommendationPrompt,
      });

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': 'google/gemma-3-27b-it:free',
          'messages': tempHistory,
          'temperature': 0.7,
          'max_tokens': 500,
          'extra_body': {
            'reasoning': {'enabled': true}
          },
        },
      );

      var responseText = response.data['choices'][0]['message']['content'] as String?;

      if (responseText == null || responseText.isEmpty) {
        throw Exception("OpenRouter API가 유효한 텍스트 응답을 반환하지 않았습니다.");
      }

      // 특수 토큰 제거
      responseText = responseText
          .replaceAll(RegExp(r'<\|[^|]+\|>'), '')
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .trim();

      _conversationHistory.add({
        'role': 'assistant',
        'content': responseText,
      });

      // "Searching" 메시지를 제거하고 실제 응답으로 교체
      final currentState = List<MessageModel>.from(state);
      if (searchingMessageIndex < currentState.length && 
          currentState[searchingMessageIndex].text == 'Searching') {
        currentState[searchingMessageIndex] = MessageModel(
          senderId: 'gemma',
          text: responseText,
          timestamp: DateTime.now(),
          isMe: false,
        );
        state = currentState;
      } else {
        final recommendationMessage = MessageModel(
          senderId: 'gemma',
          text: responseText,
          timestamp: DateTime.now(),
          isMe: false,
        );
        addMessage(recommendationMessage);
      }

      // 제품 추천이 있는지 확인
      final hasProducts = responseText.contains('###') && 
                         (responseText.contains('**Recommended Products:**') || 
                          responseText.contains('Recommended Products'));

      // 제품 추천 후 다시 3개 질문 생성
      if (hasProducts) {
        await Future.delayed(const Duration(seconds: 1));
        final guideMessage = MessageModel(
          senderId: 'chatbot',
          text: "Would you like more personalized recommendations? Let me ask you a few more questions! 😊",
          timestamp: DateTime.now(),
          isMe: false,
        );
        addMessage(guideMessage);
        
        _currentQuestionIndex = 0;
        _questionAnswers.clear();
        await Future.delayed(const Duration(seconds: 1));
        await _generateThreeQuestions();
      }

    } catch (e) {
      debugPrint('3개 질문 기반 제품 추천 생성 오류: $e');
      // 에러 메시지 표시 (영어로) + Search again 버튼
      final currentState = List<MessageModel>.from(state);
      final searchingIndex = currentState.indexWhere(
        (m) => m.text == 'Searching' && !m.isMe
      );
      if (searchingIndex != -1) {
        currentState[searchingIndex] = MessageModel(
          senderId: 'chatbot',
          text: 'Sorry, I encountered an error while searching for products. Please try again!',
          timestamp: DateTime.now(),
          isMe: false,
          options: ['Search again'],
        );
        state = currentState;
      } else {
        // Searching 메시지가 없으면 새로 추가
        addMessage(
          MessageModel(
            senderId: 'chatbot',
            text: 'Sorry, I encountered an error while searching for products. Please try again!',
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
}

/// AI 메시지 Provider
final aiMessageProvider = StateNotifierProvider.family<AIMessageNotifier, List<MessageModel>, String>(
  (ref, chatId) => AIMessageNotifier(ref, chatId, []),
);

