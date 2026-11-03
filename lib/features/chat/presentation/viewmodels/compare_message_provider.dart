import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/data/models/message_model.dart';
import 'package:mobileprogramming_groupproject_2025/api_keys.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/viewmodels/typing_provider.dart';
import 'package:mobileprogramming_groupproject_2025/features/liked_products/domain/entities/cosmetic_item_entity.dart';
import 'package:dio/dio.dart';

/// 제품 비교 관리 Provider
class CompareMessageNotifier extends StateNotifier<List<MessageModel>> {
  final Ref ref;
  final String chatId;
  final Dio _dio = Dio();
  final List<Map<String, dynamic>> _conversationHistory = [];
  CosmeticItemEntity? _selectedProduct1;
  CosmeticItemEntity? _selectedProduct2;
  bool _hasStartedComparison = false;

  CompareMessageNotifier(this.ref, this.chatId, List<MessageModel> initialMessages) 
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
    _selectedProduct1 = null;
    _selectedProduct2 = null;
    _hasStartedComparison = false;
    _initializeSystemPrompt();
  }

  /// 시스템 프롬프트 초기화
  void _initializeSystemPrompt() {
    _conversationHistory.clear();
    _conversationHistory.add({
      'role': 'system',
      'content': '''You are a skincare product comparison expert AI assistant. Your role is to compare two skincare products and provide detailed, helpful comparisons in a structured table format.

CRITICAL FORMATTING RULES - YOU MUST FOLLOW THESE EXACTLY:

1. Always respond in ENGLISH, not Korean.

2. NEVER output any special tokens like <|begin_of_sentence|>, <|end_of_sentence|>, or any other token markers. Only output natural text.

3. You MUST format your response EXACTLY as shown below. The table MUST start with COMPARISON_TABLE_START and end with COMPARISON_TABLE_END:

COMPARISON_TABLE_START
| Feature | Product 1: [EXACT FULL PRODUCT NAME] | Product 2: [EXACT FULL PRODUCT NAME] |
|---------|--------------------------------------|--------------------------------------|
| Price | [EXACT PRICE RANGE FROM USER] | [EXACT PRICE RANGE FROM USER] |
| Performance | [Rating out of 10, e.g., 8.5/10] | [Rating out of 10, e.g., 9.0/10] |
| Rating | [User rating out of 5, e.g., 4.5/5] | [User rating out of 5, e.g., 4.8/5] |
| AI Score | [Your evaluation out of 10, e.g., 8.0/10] | [Your evaluation out of 10, e.g., 8.5/10] |
COMPARISON_TABLE_END

CRITICAL REQUIREMENTS:
- The table header MUST use the EXACT product names provided by the user. Do NOT shorten, abbreviate, or modify them.
- The Price row MUST use the EXACT price ranges provided by the user. Do NOT change or estimate them.
- The table MUST have exactly 4 rows: Price, Performance, Rating, AI Score.
- Each row MUST have exactly 3 columns: Feature, Product 1 value, Product 2 value.
- Use proper markdown table format with pipes (|) and dashes (---).

4. After COMPARISON_TABLE_END, provide a VERY BRIEF summary (1 sentence maximum) explaining the key difference. Keep it concise and to the point.

5. For Performance: Rate based on effectiveness, results, and overall performance (0-10 scale).
6. For Rating: Use the product's user rating if available, or estimate based on typical reviews (0-5 scale).
7. For AI Score: Provide your own comprehensive evaluation considering all factors like ingredients, benefits, value, and suitability (0-10 scale).

8. Be objective and helpful. Focus on ingredients, benefits, skin types, and use cases.

9. If you don't have enough information about a product, use "Not specified" in the table rather than making assumptions.

10. DO NOT add any text before COMPARISON_TABLE_START or after COMPARISON_TABLE_END except for the summary.''',
    });
  }

  /// 제품 선택 (첫 번째 또는 두 번째)
  void selectProduct(CosmeticItemEntity product, {required bool isFirst}) {
    if (isFirst) {
      _selectedProduct1 = product;
    } else {
      _selectedProduct2 = product;
    }

    // 두 제품이 모두 선택되면 비교 시작
    if (_selectedProduct1 != null && _selectedProduct2 != null) {
      _startComparison();
    }
  }

  /// 제품 선택 해제
  void deselectProduct({required bool isFirst}) {
    if (isFirst) {
      _selectedProduct1 = null;
    } else {
      _selectedProduct2 = null;
    }
  }

  /// 선택된 제품 가져오기
  CosmeticItemEntity? getSelectedProduct({required bool isFirst}) {
    return isFirst ? _selectedProduct1 : _selectedProduct2;
  }

  /// 두 제품이 모두 선택되었는지 확인
  bool get areBothProductsSelected => _selectedProduct1 != null && _selectedProduct2 != null;

  /// 비교가 이미 시작되었는지 여부 (비교 중에는 선택 막기용)
  bool get isComparisonStarted => _hasStartedComparison;

  /// 비교 시작
  Future<void> _startComparison() async {
    if (_hasStartedComparison || _selectedProduct1 == null || _selectedProduct2 == null) {
      return;
    }

    _hasStartedComparison = true;

    // 선택된 제품 정보 메시지 추가
    final product1Info = '${_selectedProduct1!.title} (${_selectedProduct1!.category}) - ${_selectedProduct1!.priceRange}';
    final product2Info = '${_selectedProduct2!.title} (${_selectedProduct2!.category}) - ${_selectedProduct2!.priceRange}';

    addMessage(MessageModel(
      senderId: 'user',
      text: 'Please compare these two products:\n1. $product1Info\n2. $product2Info',
      timestamp: DateTime.now(),
      isMe: true,
    ));

    // "Comparing..." 메시지 추가
    final comparingMessage = MessageModel(
      senderId: 'assistant',
      text: 'Comparing...',
      timestamp: DateTime.now(),
      isMe: false,
    );
    addMessage(comparingMessage);
    final comparingMessageIndex = state.length - 1;

    // Typing indicator 설정
    final typingNotifier = ref.read(isTypingProvider(chatId).notifier);
    final isCurrentlyTyping = ref.read(isTypingProvider(chatId));
    if (!isCurrentlyTyping) {
      typingNotifier.setTyping(true);
    }
    await Future.delayed(const Duration(milliseconds: 500));

    // API 호출
    await _performComparison(comparingMessageIndex, typingNotifier);
  }

  /// 실제 비교 API 호출
  Future<void> _performComparison(int comparingMessageIndex, TypingNotifier typingNotifier) async {
    try {
      if (_selectedProduct1 == null || _selectedProduct2 == null) {
        throw Exception('Both products must be selected');
      }

      // 비교 프롬프트 생성 - 제품 이름을 정확하게 지정
      final product1Name = _selectedProduct1!.title.trim();
      final product2Name = _selectedProduct2!.title.trim();
      
      final comparisonPrompt = '''Compare these two skincare products:

Product 1:
- Name: $product1Name
- Category: ${_selectedProduct1!.category}
- Price Range: ${_selectedProduct1!.priceRange}
- Description: ${_selectedProduct1!.supportingText}

Product 2:
- Name: $product2Name
- Category: ${_selectedProduct2!.category}
- Price Range: ${_selectedProduct2!.priceRange}
- Description: ${_selectedProduct2!.supportingText}

REQUIREMENTS:
1. Start your response with COMPARISON_TABLE_START
2. Create a markdown table with EXACTLY this format:
   | Feature | Product 1: $product1Name | Product 2: $product2Name |
   |---------|--------------------------|--------------------------|
   | Price | ${_selectedProduct1!.priceRange} | ${_selectedProduct2!.priceRange} |
   | Performance | [rate out of 10] | [rate out of 10] |
   | Rating | [rate out of 5] | [rate out of 5] |
   | AI Score | [rate out of 10] | [rate out of 10] |
3. End the table with COMPARISON_TABLE_END
4. After the table, add a VERY BRIEF summary (1 sentence maximum). Keep it concise.

CRITICAL: Use the EXACT product names "$product1Name" and "$product2Name" in the table header. Use the EXACT price ranges "${_selectedProduct1!.priceRange}" and "${_selectedProduct2!.priceRange}" in the Price row.''';

      _conversationHistory.add({
        'role': 'user',
        'content': comparisonPrompt,
      });

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': 'google/gemma-3-27b-it:free',
          'messages': _conversationHistory,
          'temperature': 0.7,
          'max_tokens': 800,
          'extra_body': {
            'reasoning': {'enabled': true}
          },
        },
      );

      final responseData = response.data;
      
      // 에러 응답 확인
      if (responseData != null && responseData['error'] != null) {
        final errorData = responseData['error'];
        final errorMessage = errorData['message'] ?? 'Unknown error';
        final errorCode = errorData['code'] ?? 'Unknown code';
        debugPrint('API 에러 응답: $errorMessage (코드: $errorCode)');
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

      _conversationHistory.add({'role': 'assistant', 'content': responseText});

      // 표 형식으로 파싱된 비교 결과 생성
      final parsedComparison = _parseComparisonResponse(responseText);

      // "Comparing..." 메시지를 실제 응답으로 교체
      final currentState = List<MessageModel>.from(state);
      if (comparingMessageIndex < currentState.length && 
          currentState[comparingMessageIndex].text == 'Comparing...') {
        debugPrint('Comparing 메시지를 비교 결과로 교체');
        currentState[comparingMessageIndex] = MessageModel(
          senderId: 'assistant',
          text: parsedComparison,
          timestamp: DateTime.now(),
          isMe: false,
        );
        state = currentState;
      } else {
        // 메시지를 찾을 수 없으면 새로 추가
        addMessage(MessageModel(
          senderId: 'assistant',
          text: parsedComparison,
          timestamp: DateTime.now(),
          isMe: false,
        ));
      }

      // "Search again?" 버튼 추가
      await Future.delayed(const Duration(milliseconds: 500));
      addMessage(
        MessageModel(
          senderId: 'assistant',
          text: 'Would you like to compare other products?',
          timestamp: DateTime.now(),
          isMe: false,
          options: ['Search again?'],
        ),
      );

      typingNotifier.setTyping(false);
    } catch (e) {
      debugPrint('비교 API 호출 오류: $e');
      typingNotifier.setTyping(false);

      // 에러 메시지 추가
      final currentState = List<MessageModel>.from(state);
      if (comparingMessageIndex < currentState.length && 
          currentState[comparingMessageIndex].text == 'Comparing...') {
        currentState[comparingMessageIndex] = MessageModel(
          senderId: 'assistant',
          text: 'Sorry, I encountered an error while comparing the products. Please try again.',
          timestamp: DateTime.now(),
          isMe: false,
        );
        state = currentState;
      } else {
        addMessage(MessageModel(
          senderId: 'assistant',
          text: 'Sorry, I encountered an error while comparing the products. Please try again.',
          timestamp: DateTime.now(),
          isMe: false,
        ));
      }

      // 에러 이후에도 "Search again" 버튼을 표시하여 다시 시도할 수 있게 함
      await Future.delayed(const Duration(milliseconds: 300));
      addMessage(
        MessageModel(
          senderId: 'assistant',
          text: 'Would you like to compare other products?',
          timestamp: DateTime.now(),
          isMe: false,
          options: ['Search again?'],
        ),
      );
    }
  }

  /// 비교 응답을 표 형식으로 파싱
  String _parseComparisonResponse(String responseText) {
    try {
      if (_selectedProduct1 == null || _selectedProduct2 == null) {
        return responseText;
      }

      final product1Name = _selectedProduct1!.title.trim();
      final product2Name = _selectedProduct2!.title.trim();
      final product1Price = _selectedProduct1!.priceRange.trim();
      final product2Price = _selectedProduct2!.priceRange.trim();

      // COMPARISON_TABLE_START와 COMPARISON_TABLE_END 마커 찾기
      final tableStartRegex = RegExp(r'COMPARISON_TABLE_START', caseSensitive: false);
      final tableEndRegex = RegExp(r'COMPARISON_TABLE_END', caseSensitive: false);

      final tableStartMatch = tableStartRegex.firstMatch(responseText);
      final tableEndMatch = tableEndRegex.firstMatch(responseText);

      String tableContent = '';
      String summary = '';

      // 마커가 있는 경우
      if (tableStartMatch != null && tableEndMatch != null && tableEndMatch.start > tableStartMatch.end) {
        tableContent = responseText.substring(tableStartMatch.end, tableEndMatch.start).trim();
        summary = responseText.substring(tableEndMatch.end).trim();
      } else {
        // 마커가 없으면 표 형식 찾기 시도
        tableContent = _extractTableFromText(responseText);
        if (tableContent.isEmpty) {
          return _buildTableManually(product1Name, product2Name, product1Price, product2Price, responseText);
        }
        // 마커 이후 텍스트를 summary로
        if (tableEndMatch != null && tableEndMatch.end < responseText.length) {
          summary = responseText.substring(tableEndMatch.end).trim();
        } else {
          // 표 다음 줄부터 summary로
          final tableEndIndex = responseText.indexOf(tableContent) + tableContent.length;
          if (tableEndIndex < responseText.length) {
            summary = responseText.substring(tableEndIndex).trim();
          }
        }
      }

      // 표 내용 정규화
      final normalizedTable = _normalizeTable(tableContent, product1Name, product2Name, product1Price, product2Price);

      // summary 정리
      summary = summary.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();

      if (summary.isNotEmpty) {
        return '$normalizedTable\n\n$summary';
      }
      return normalizedTable;
    } catch (e, stackTrace) {
      debugPrint('⚠️ 비교 응답 파싱 중 오류 발생: $e');
      debugPrint('STACK: $stackTrace');
      // 에러 발생 시 수동으로 표 생성
      if (_selectedProduct1 != null && _selectedProduct2 != null) {
        return _buildTableManually(
          _selectedProduct1!.title.trim(),
          _selectedProduct2!.title.trim(),
          _selectedProduct1!.priceRange.trim(),
          _selectedProduct2!.priceRange.trim(),
          responseText,
        );
      }
      return responseText;
    }
  }

  /// 텍스트에서 표 추출
  String _extractTableFromText(String text) {
    final lines = text.split('\n');
    final tableLines = <String>[];
    bool foundHeader = false;

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // 헤더 찾기
      if (line.contains('|') && (line.contains('Feature') || line.contains('Product 1') || line.contains('Product 2'))) {
        foundHeader = true;
        tableLines.add(line);
        continue;
      }

      // 구분선
      if (foundHeader && line.contains('|---')) {
        tableLines.add(line);
        continue;
      }

      // 데이터 행 (Price, Performance, Rating, AI Score)
      if (foundHeader && line.contains('|')) {
        final lowerLine = line.toLowerCase();
        if (lowerLine.contains('price') || 
            lowerLine.contains('performance') || 
            lowerLine.contains('rating') || 
            lowerLine.contains('ai score')) {
          tableLines.add(line);
        } else if (tableLines.length >= 2) {
          // 이미 헤더와 구분선이 있으면 추가 행도 포함
          tableLines.add(line);
        }
      } else if (foundHeader && !line.contains('|') && tableLines.length >= 3) {
        // 표가 끝남
        break;
      }
    }

    return tableLines.join('\n');
  }

  /// 표 정규화 (제품명과 가격 교체)
  String _normalizeTable(String tableContent, String product1Name, String product2Name, String product1Price, String product2Price) {
    final lines = tableContent.split('\n');
    final normalizedLines = <String>[];

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // 헤더 라인
      if (line.contains('|') && (line.contains('Feature') || line.contains('Product 1') || line.contains('Product 2'))) {
        normalizedLines.add('| Feature | Product 1: $product1Name | Product 2: $product2Name |');
      }
      // Price 라인
      else if (line.toLowerCase().contains('| price')) {
        normalizedLines.add('| Price | $product1Price | $product2Price |');
      }
      // 구분선
      else if (line.contains('|---')) {
        normalizedLines.add('|---------|--------------------------|--------------------------|');
      }
      // 다른 데이터 행
      else if (line.contains('|')) {
        normalizedLines.add(line);
      }
    }

    // 최소한의 표 구조가 있는지 확인
    if (normalizedLines.isEmpty || normalizedLines.length < 3) {
      return _buildTableManually(product1Name, product2Name, product1Price, product2Price, '');
    }

    return normalizedLines.join('\n');
  }

  /// 수동으로 표 생성 (파싱 실패 시)
  String _buildTableManually(String product1Name, String product2Name, String product1Price, String product2Price, String originalText) {
    return '''| Feature | Product 1: $product1Name | Product 2: $product2Name |
|---------|--------------------------|--------------------------|
| Price | $product1Price | $product2Price |
| Performance | Not specified | Not specified |
| Rating | Not specified | Not specified |
| AI Score | Not specified | Not specified |

${originalText.isNotEmpty ? 'Note: Could not parse AI response. Original response:\n\n$originalText' : 'Please try again for detailed comparison.'}''';
  }


  /// 비교 재시작 (Search again 버튼 클릭 시)
  void retryComparison() {
    // 버튼이 이미 비활성화되어 있으므로 중복 클릭 방지 체크 불필요
    // 선택된 제품 초기화
    _selectedProduct1 = null;
    _selectedProduct2 = null;
    _hasStartedComparison = false;
    
    // "Search again" 메시지만 제거
    final newState = state.where((m) => 
      m.text != 'Search again' &&
      m.text != 'Search again?' &&
      !m.text.contains('Would you like to compare other products?')
    ).toList();
    state = newState;
  }
}

/// Provider for compare messages
final compareMessageProvider = StateNotifierProvider.family<CompareMessageNotifier, List<MessageModel>, String>((ref, chatId) {
  return CompareMessageNotifier(ref, chatId, []);
});

