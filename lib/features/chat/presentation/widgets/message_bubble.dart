import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/data/models/message_model.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/viewmodels/survey_message_provider.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/viewmodels/recommend_message_provider.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/viewmodels/budget_message_provider.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/viewmodels/compare_message_provider.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/viewmodels/skin_types_data.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/widgets/product_recommendation_carousel.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/widgets/typing_indicator.dart';
import 'dart:async';

class MessageBubble extends ConsumerStatefulWidget {
  final MessageModel message;
  final String chatId;

  const MessageBubble({super.key, required this.message, required this.chatId});

  @override
  ConsumerState<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends ConsumerState<MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // 한국어 피부 타입/세부 타입을 영어로 변환
  String _getEnglishText(String text) {
    // 피부 타입 변환
    final skinTypeMap = {
      '지성': 'OILY',
      '건성': 'DRY',
      '복합성': 'COMBINATION',
      '민감성': 'SENSITIVE',
    };

    if (skinTypeMap.containsKey(text)) {
      return skinTypeMap[text]!;
    }

    // 세부 타입 변환
    final details = skinSubTypeDetails[text];
    if (details != null && details['english'] != null) {
      return details['english']!;
    }

    return text; // 변환할 수 없으면 원본 반환
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.message.isMe;

    // "Searching" 메시지인지 확인
    final isSearching = !isMe && widget.message.text == 'Searching';

    // 제품 추천 메시지인지 확인 (gemma 메시지도 포함)
    final productRecommendations = !isMe
        ? parseProductRecommendations(
            widget.message.text,
            chatId: widget.chatId,
          )
        : <ProductRecommendation>[];
    final hasProductRecommendations = productRecommendations.isNotEmpty;

    // 디버깅: 파싱 결과 확인
    if (!isMe) {
      if (widget.message.senderId == 'gemma' ||
          widget.message.text.contains('###')) {
        debugPrint(
          '제품 추천 파싱 시도 - senderId: ${widget.message.senderId}, 파싱된 제품 수: ${productRecommendations.length}',
        );
        if (productRecommendations.isEmpty &&
            widget.message.text.contains('###')) {
          debugPrint(
            '제품 추천 파싱 실패 - 메시지 시작 부분: ${widget.message.text.substring(0, widget.message.text.length > 500 ? 500 : widget.message.text.length)}',
          );
        } else if (productRecommendations.isNotEmpty) {
          debugPrint('제품 추천 파싱 성공 - 제품 수: ${productRecommendations.length}');
          for (var product in productRecommendations) {
            debugPrint('  - ${product.name} (${product.category})');
          }
        }
      }
    }

    // 사용자 메시지인 경우 한국어를 영어로 변환
    final displayText = isMe
        ? _getEnglishText(widget.message.text)
        : widget.message.text;

    // 표 형식인지 확인 (비교 메시지)
    final isComparisonTable = !isMe && _isComparisonTable(displayText);
    final parsedTable = isComparisonTable
        ? _parseComparisonTable(displayText)
        : null;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              // 제품 추천이 있으면 캐러셀만 표시, 없으면 일반 메시지 표시
              if (hasProductRecommendations)
                Padding(
                  padding: const EdgeInsets.only(left: 0, right: 48),
                  child: ProductRecommendationCarousel(
                    key: ValueKey(
                      'product_carousel_${widget.message.text.hashCode}_${widget.message.timestamp.millisecondsSinceEpoch}',
                    ),
                    products: productRecommendations,
                    chatId: widget.chatId,
                  ),
                )
              else if (isSearching)
                // "Searching" 메시지는 TypingIndicator 애니메이션으로 표시
                const TypingIndicator()
              else if (isComparisonTable && parsedTable != null)
                // 표 형식 메시지는 Table 위젯으로 렌더링
                Padding(
                  padding: const EdgeInsets.only(left: 0, right: 48),
                  child: _ComparisonTableWidget(
                    tableData: parsedTable['data'] as Map<String, List<String>>,
                    product1Name: parsedTable['product1Name'] as String,
                    product2Name: parsedTable['product2Name'] as String,
                    summary: _extractSummary(displayText),
                  ),
                )
              else
                Row(
                  mainAxisAlignment: isMe
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Theme.of(context)
                                    .colorScheme
                                    .primary // Primary 색상 (크림색) - 내 메시지
                              : Theme.of(context)
                                    .colorScheme
                                    .secondary, // Secondary 색상 (파란색) - AI 메시지
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          displayText,
                          style: TextStyle(
                            color: isMe
                                ? Colors.black
                                : Colors.white, // 내 메시지는 검정, AI 메시지는 흰색
                            fontSize: isMe ? 14 : 16, // AI 메시지는 더 큰 폰트
                            fontFamily: 'HelveticaNeue',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              // 선택 옵션 버튼들
              if (widget.message.options != null &&
                  widget.message.options!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(
                    top: 16,
                    bottom: 16,
                    left: 0, // 채팅 버블 왼쪽과 맞춤
                    right: 0, // 오른쪽 패딩 제거하여 오른쪽으로 붙임
                  ),
                  child: Align(
                    alignment: _isSkinTypeOptions(widget.message.options!)
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: _isSearchAgainOption(widget.message.options!)
                        ? _SearchAgainButton(
                            chatId: widget.chatId,
                            options: widget.message.options!,
                            message: widget.message,
                          )
                        : _isSkinTypeOptions(widget.message.options!)
                        ? _SkinTypeSelector(
                            options: widget.message.options!,
                            chatId: widget.chatId,
                          )
                        : _isCosmeticTypeOptions(widget.message.options!)
                        ? _CosmeticTypeSelector(
                            options: widget.message.options!,
                            chatId: widget.chatId,
                          )
                        : _isBudgetOptions(widget.message.options!)
                        ? _BudgetSelector(
                            options: widget.message.options!,
                            chatId: widget.chatId,
                            questionText: widget.message.text,
                            messageTimestamp: widget.message.timestamp,
                          )
                        : _isFollowUpQuestionOptions(widget.message.options!)
                        ? _FollowUpQuestionSelector(
                            options: widget.message.options!,
                            chatId: widget.chatId,
                            questionText: widget.message.text,
                          )
                        : _SubTypeSelector(
                            options: widget.message.options!,
                            chatId: widget.chatId,
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 피부 타입 옵션인지 확인 (영어: OILY, DRY, COMBINATION, SENSITIVE)
  bool _isSkinTypeOptions(List<String> options) {
    const skinTypes = ['OILY', 'DRY', 'COMBINATION', 'SENSITIVE'];
    return options.any((option) => skinTypes.contains(option));
  }

  // 화장품 타입 옵션인지 확인
  bool _isCosmeticTypeOptions(List<String> options) {
    return options.any((option) => cosmeticTypes.contains(option));
  }

  // 예산 옵션인지 확인 ($50, $100, $300, $500 - 이모티콘 포함 가능)
  bool _isBudgetOptions(List<String> options) {
    const budgetOptions = ['\$50', '\$100', '\$300', '\$500'];
    return options.any((option) {
      // 이모티콘 제거 후 비교
      final cleanOption = option.replaceAll(' 💵', '').trim();
      return budgetOptions.contains(cleanOption);
    });
  }

  // 추가 질문 옵션인지 확인 (피부 타입, 세부 타입, 화장품 타입이 아닌 경우)
  bool _isFollowUpQuestionOptions(List<String> options) {
    const skinTypes = ['OILY', 'DRY', 'COMBINATION', 'SENSITIVE'];

    // 피부 타입이나 화장품 타입이 아니고, 세부 타입도 아닌 경우
    final isNotSkinType = !options.any((option) => skinTypes.contains(option));
    final isNotCosmeticType = !options.any(
      (option) => cosmeticTypes.contains(option),
    );

    // 세부 타입인지 확인 (skinSubTypeDetails에 있는지)
    final isNotSubType = !options.any(
      (option) => skinSubTypeDetails.containsKey(option),
    );

    return isNotSkinType && isNotCosmeticType && isNotSubType;
  }

  // "Search again" 옵션인지 확인
  bool _isSearchAgainOption(List<String> options) {
    return options.contains('Search again') ||
        options.contains('Search again?');
  }

  // 비교 표 형식인지 확인
  bool _isComparisonTable(String text) {
    // 표 형식 마커 확인
    if (text.contains('COMPARISON_TABLE_START') ||
        text.contains('COMPARISON_TABLE_END')) {
      return true;
    }
    // 마크다운 표 형식 확인 (| Feature | Product 1 | Product 2 |)
    final tablePattern = RegExp(
      r'^\s*\|.*Feature.*\|.*Product\s+[12].*\|',
      multiLine: true,
    );
    return tablePattern.hasMatch(text);
  }

  // 비교 표 파싱
  Map<String, dynamic>? _parseComparisonTable(String text) {
    try {
      // COMPARISON_TABLE_START와 COMPARISON_TABLE_END 사이의 내용 추출
      final startMatch = RegExp(
        r'COMPARISON_TABLE_START',
        caseSensitive: false,
      ).firstMatch(text);
      final endMatch = RegExp(
        r'COMPARISON_TABLE_END',
        caseSensitive: false,
      ).firstMatch(text);

      String tableContent = text;
      if (startMatch != null &&
          endMatch != null &&
          endMatch.start > startMatch.end) {
        tableContent = text.substring(startMatch.end, endMatch.start).trim();
      }

      final lines = tableContent
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();
      if (lines.isEmpty) return null;

      final tableData = <String, List<String>>{};
      String product1Name = 'Product 1';
      String product2Name = 'Product 2';

      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty || line.contains('|---')) continue;

        if (!line.startsWith('|') || !line.endsWith('|')) continue;

        // 파이프로 분리
        final cells = line
            .split('|')
            .map((c) => c.trim())
            .where((c) => c.isNotEmpty)
            .toList();

        if (cells.isEmpty) continue;

        // 헤더 확인
        if (cells[0].toLowerCase() == 'feature' && cells.length >= 3) {
          // 제품명 추출
          if (cells[1].contains('Product 1:')) {
            product1Name = cells[1].replaceAll('Product 1:', '').trim();
          }
          if (cells[2].contains('Product 2:')) {
            product2Name = cells[2].replaceAll('Product 2:', '').trim();
          }
          continue;
        }

        // 데이터 행
        if (cells.length >= 3) {
          final feature = cells[0];
          final product1Value = cells.length > 1 ? cells[1] : '';
          final product2Value = cells.length > 2 ? cells[2] : '';

          tableData[feature] = [product1Value, product2Value];
        }
      }

      if (tableData.isEmpty) return null;

      return {
        'data': tableData,
        'product1Name': product1Name,
        'product2Name': product2Name,
      };
    } catch (e) {
      debugPrint('표 파싱 오류: $e');
      return null;
    }
  }

  // Summary 추출
  String _extractSummary(String text) {
    try {
      final endMatch = RegExp(
        r'COMPARISON_TABLE_END',
        caseSensitive: false,
      ).firstMatch(text);
      if (endMatch != null && endMatch.end < text.length) {
        return text.substring(endMatch.end).trim();
      }

      // 표 다음 줄부터 summary로 간주
      final lines = text.split('\n');
      bool foundTableEnd = false;
      final summaryLines = <String>[];

      for (var line in lines) {
        if (line.contains('|---') ||
            (line.contains('|') && line.toLowerCase().contains('ai score'))) {
          foundTableEnd = true;
          continue;
        }

        if (foundTableEnd && line.trim().isNotEmpty && !line.startsWith('|')) {
          summaryLines.add(line);
        }
      }

      return summaryLines.join('\n').trim();
    } catch (e) {
      return '';
    }
  }
}

// 비교 표 위젯
class _ComparisonTableWidget extends StatelessWidget {
  final Map<String, List<String>> tableData;
  final String product1Name;
  final String product2Name;
  final String summary;

  const _ComparisonTableWidget({
    required this.tableData,
    required this.product1Name,
    required this.product2Name,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final rows = tableData.entries.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 표
          Table(
            border: TableBorder.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
            columnWidths: const {
              0: FlexColumnWidth(1.5),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(2),
            },
            children: [
              // 헤더
              TableRow(
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1)),
                children: [
                  _TableCell('Feature', isHeader: true),
                  _TableCell(product1Name, isHeader: true),
                  _TableCell(product2Name, isHeader: true),
                ],
              ),
              // 데이터 행
              ...rows.map((row) {
                return TableRow(
                  children: [
                    _TableCell(row.key),
                    _TableCell(row.value.isNotEmpty ? row.value[0] : ''),
                    _TableCell(row.value.length > 1 ? row.value[1] : ''),
                  ],
                );
              }),
            ],
          ),
          // Summary
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              summary,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'HelveticaNeue',
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// 표 셀 위젯
class _TableCell extends StatelessWidget {
  final String text;
  final bool isHeader;

  const _TableCell(this.text, {this.isHeader = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'HelveticaNeue',
          fontSize: isHeader ? 14 : 13,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }
}

// "Search again" 버튼 위젯
class _SearchAgainButton extends ConsumerStatefulWidget {
  final String chatId;
  final List<String> options;
  final MessageModel message; // 메시지 참조 추가

  const _SearchAgainButton({
    required this.chatId,
    required this.options,
    required this.message,
  });

  @override
  ConsumerState<_SearchAgainButton> createState() => _SearchAgainButtonState();
}

class _SearchAgainButtonState extends ConsumerState<_SearchAgainButton> {
  bool _isDisabled = false; // 버튼 비활성화 상태

  @override
  Widget build(BuildContext context) {
    // chatId에 따라 적절한 provider 사용
    final isBudgetChat = widget.chatId == 'chatbot_budget_routine';

    // 버튼 텍스트 결정 (옵션에서 첫 번째 사용)
    final buttonText = widget.options.first;

    return ElevatedButton(
      onPressed: _isDisabled
          ? null
          : () {
              // 버튼을 즉시 비활성화 (회색으로 변경)
              setState(() {
                _isDisabled = true;
              });

              // 추천 시작
              if (isBudgetChat) {
                final notifier = ref.read(
                  budgetMessageProvider(widget.chatId).notifier,
                );
                notifier.retryRecommendation();
              } else if (widget.chatId == 'chatbot_find_skincare') {
                final notifier = ref.read(
                  aiMessageProvider(widget.chatId).notifier,
                );
                notifier.recommendProducts(isRetry: true);
              } else if (widget.chatId == 'chatbot_compare') {
                final notifier = ref.read(
                  compareMessageProvider(widget.chatId).notifier,
                );
                notifier.retryComparison();
              }
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: _isDisabled
            ? Colors.grey[300] // 비활성화 시 회색
            : Theme.of(context).colorScheme.primary,
        foregroundColor: _isDisabled
            ? Colors.grey[700] // 비활성화 시 회색 텍스트 (밝게)
            : Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(
        buttonText,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'Helvetica',
          color: _isDisabled ? Colors.grey[700] : Colors.black,
        ),
      ),
    );
  }
}

// 피부 타입 선택 위젯 (화살표 포함)
class _SkinTypeSelector extends ConsumerStatefulWidget {
  final List<String> options;
  final String chatId;

  const _SkinTypeSelector({required this.options, required this.chatId});

  @override
  ConsumerState<_SkinTypeSelector> createState() => _SkinTypeSelectorState();
}

class _SkinTypeSelectorState extends ConsumerState<_SkinTypeSelector> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  final double _itemWidth = 276.0; // 260 (이미지) + 16 (padding)
  Timer? _autoScrollTimer;
  bool _isUserScrolling = false;
  final Map<String, bool> _pressedStates = {}; // 각 옵션의 눌림 상태

  @override
  void initState() {
    super.initState();
    // 스크롤 위치 변경 감지
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final page = (_scrollController.offset / _itemWidth).round();
        if (page >= 0 && page != _currentPage) {
          setState(() {
            _currentPage = page;
          });
        }
      }
    });
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 1500), (
      timer,
    ) {
      // 주기를 더 빠르게 (1.5초)
      if (!_isUserScrolling && _scrollController.hasClients) {
        // 메시지 프로바이더에서 선택 상태 확인
        final messageNotifier = ref.read(
          surveyMessageProvider(widget.chatId).notifier,
        );
        final hasSelection = messageNotifier.selectedSkinType != null;

        // 선택이 있으면 자동 스크롤 중지
        if (hasSelection) {
          timer.cancel();
          return;
        }

        // 다음 페이지로 이동 (무한 루프)
        _currentPage++;
        final targetOffset = _currentPage * _itemWidth;

        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 600), // 속도를 느리게 (600ms)
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  String? _getImagePath(String option) {
    // 영어 옵션을 그대로 사용 (이미지 파일명이 영어)
    switch (option) {
      case 'OILY':
        return 'assets/images/OILY.png';
      case 'DRY':
        return 'assets/images/DRY.png';
      case 'COMBINATION':
        return 'assets/images/COMBINATION.png';
      case 'SENSITIVE':
        return 'assets/images/SENSITIVE.png';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 메시지 리스트를 watch하여 상태 변경 시 UI 업데이트
    ref.watch(surveyMessageProvider(widget.chatId));
    final messageNotifier = ref.read(
      surveyMessageProvider(widget.chatId).notifier,
    );
    final hasSelection = messageNotifier.selectedSkinType != null;

    // 선택이 있으면 자동 스크롤 중지, 없으면 시작
    if (hasSelection) {
      _stopAutoScroll();
    } else if (_autoScrollTimer == null || !_autoScrollTimer!.isActive) {
      _startAutoScroll();
    }

    return SizedBox(
      height: 340,
      child: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                _isUserScrolling = true;
              } else if (notification is ScrollEndNotification) {
                // 스크롤이 끝난 후 잠시 대기 후 다시 자동 스크롤 시작
                Future.delayed(const Duration(milliseconds: 1500), () {
                  // 주기를 더 빠르게 (1.5초)
                  if (mounted) {
                    _isUserScrolling = false;
                  }
                });
              }
              return false;
            },
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: 1000, // 무한 스크롤을 위한 큰 숫자
              clipBehavior: Clip.none,
              physics: const BouncingScrollPhysics(), // 스와이프 가능하게 활성화
              itemBuilder: (context, index) {
                final actualIndex = index % widget.options.length;
                final option = widget.options[actualIndex];
                final imagePath = _getImagePath(option);
                final isSelected = messageNotifier.isSkinTypeSelected(option);
                // 선택된 항목도 다시 선택 가능 (sendUserMessage에서 중복 처리)
                final isHelpOption = option == "I'm not sure.... plz help!";

                // 불투명도: 선택된 항목은 1.0, 선택이 있으면 선택 안 한 항목은 0.5, 선택이 없으면 모두 1.0
                final opacity = isSelected ? 1.0 : (hasSelection ? 0.5 : 1.0);

                // "I'm not sure.... plz help!" 옵션은 버튼만 표시
                if (isHelpOption) {
                  return Padding(
                    padding: EdgeInsets.only(
                      left: actualIndex == 0 && index == 0 ? 0 : 8,
                      right: 8,
                    ),
                    child: Opacity(
                      opacity: opacity,
                      child: ElevatedButton(
                        onPressed: () {
                          messageNotifier.sendUserMessage(option);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Text(
                          option,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'HelveticaNeue',
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: EdgeInsets.only(
                    left: actualIndex == 0 && index == 0 ? 0 : 8,
                    right: 8,
                  ),
                  child: Opacity(
                    opacity: opacity,
                    child: Column(
                      children: [
                        // 원형 이미지
                        AbsorbPointer(
                          absorbing:
                              hasSelection &&
                              !isSelected, // 이미 선택이 있으면 선택되지 않은 항목은 클릭 불가
                          child: GestureDetector(
                            onTapDown: (_) {
                              setState(() {
                                _pressedStates[option] = true;
                              });
                            },
                            onTapUp: (_) {
                              setState(() {
                                _pressedStates[option] = false;
                              });
                              messageNotifier.sendUserMessage(option);
                            },
                            onTapCancel: () {
                              setState(() {
                                _pressedStates[option] = false;
                              });
                            },
                            child: AnimatedScale(
                              scale: _pressedStates[option] == true
                                  ? 0.95
                                  : 1.0,
                              duration: const Duration(milliseconds: 100),
                              curve: Curves.easeInOut,
                              child: Container(
                                width: 260,
                                height: 260,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(context)
                                              .colorScheme
                                              .primary // Primary 색상 (크림색) - 선택됨
                                        : Theme.of(context)
                                              .colorScheme
                                              .secondary, // Secondary 색상 (파란색)
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: imagePath != null
                                      ? Image.asset(
                                          imagePath,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                debugPrint(
                                                  '이미지 로드 실패: $imagePath',
                                                );
                                                debugPrint('에러: $error');
                                                return Container(
                                                  color: Colors.grey[200],
                                                  child: Icon(
                                                    Icons.image,
                                                    size: 40,
                                                    color: Colors.grey[400],
                                                  ),
                                                );
                                              },
                                        )
                                      : Container(
                                          color: Colors.grey[200],
                                          child: Icon(
                                            Icons.image,
                                            size: 40,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 버튼
                        GestureDetector(
                          onTapDown: hasSelection && !isSelected
                              ? null
                              : (_) {
                                  setState(() {
                                    _pressedStates['${option}_button'] = true;
                                  });
                                },
                          onTapUp: hasSelection && !isSelected
                              ? null
                              : (_) {
                                  setState(() {
                                    _pressedStates['${option}_button'] = false;
                                  });
                                  messageNotifier.sendUserMessage(option);
                                },
                          onTapCancel: hasSelection && !isSelected
                              ? null
                              : () {
                                  setState(() {
                                    _pressedStates['${option}_button'] = false;
                                  });
                                },
                          child: AnimatedScale(
                            scale: _pressedStates['${option}_button'] == true
                                ? 0.95
                                : 1.0,
                            duration: const Duration(milliseconds: 100),
                            curve: Curves.easeInOut,
                            child: ElevatedButton(
                              onPressed: hasSelection && !isSelected
                                  ? null // 이미 선택이 있으면 선택되지 않은 항목은 클릭 불가
                                  : () {
                                      messageNotifier.sendUserMessage(option);
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(color: Colors.grey[300]!),
                                ),
                              ),
                              child: Text(
                                option, // 이미 영어로 표시됨
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'HelveticaNeue',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 추가 질문 옵션 선택 위젯 (간단한 버튼들)
class _FollowUpQuestionSelector extends ConsumerWidget {
  final List<String> options;
  final String chatId;
  final String questionText; // 질문 텍스트

  const _FollowUpQuestionSelector({
    required this.options,
    required this.chatId,
    required this.questionText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // chatId에 따라 적절한 provider 사용
    final isFindSkincareChat = chatId == 'chatbot_find_skincare';

    // 메시지 리스트를 watch하여 상태 변경 시 UI 업데이트
    if (isFindSkincareChat) {
      ref.watch(aiMessageProvider(chatId));
    } else {
      ref.watch(surveyMessageProvider(chatId));
    }

    // 현재 질문에 대한 선택된 답변 확인
    final messages = isFindSkincareChat
        ? ref.read(aiMessageProvider(chatId))
        : ref.read(surveyMessageProvider(chatId));

    String? selectedAnswer;
    for (var i = 0; i < messages.length - 1; i++) {
      if (!messages[i].isMe &&
          messages[i].text == questionText &&
          messages[i + 1].isMe) {
        selectedAnswer = messages[i + 1].text;
        break;
      }
    }
    final hasSelection = selectedAnswer != null;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: options.map((option) {
        // 선택이 있으면 모든 항목을 회색으로 비활성화 (선택된 항목 포함)

        return ElevatedButton(
          onPressed: hasSelection
              ? null
              : () {
                  if (isFindSkincareChat) {
                    ref
                        .read(aiMessageProvider(chatId).notifier)
                        .handleAnswer(option);
                  } else {
                    ref
                        .read(surveyMessageProvider(chatId).notifier)
                        .handleAnswer(option);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: hasSelection ? Colors.grey[300] : Colors.white,
            foregroundColor: hasSelection ? Colors.grey[600] : Colors.black,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Text(
            option,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'HelveticaNeue',
              color: hasSelection ? Colors.grey[600] : Colors.black,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// 예산 선택 위젯
class _BudgetSelector extends ConsumerWidget {
  final List<String> options;
  final String chatId;
  final String questionText;
  final DateTime messageTimestamp;

  const _BudgetSelector({
    required this.options,
    required this.chatId,
    required this.questionText,
    required this.messageTimestamp,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint(
      '_BudgetSelector build 호출됨 - options: $options, chatId: $chatId, timestamp: $messageTimestamp',
    );

    // budget_message_provider를 watch하여 상태 변경 시 UI 업데이트
    ref.watch(budgetMessageProvider(chatId));
    final budgetNotifier = ref.read(budgetMessageProvider(chatId).notifier);

    // 해당 메시지에서 선택된 예산 확인
    final hasSelection = budgetNotifier.isBudgetSelectedForMessage(
      messageTimestamp,
    );
    final selectedBudgetForMessage = budgetNotifier.getSelectedBudgetForMessage(
      messageTimestamp,
    );

    debugPrint(
      '예산 선택 상태 - hasSelection: $hasSelection, selectedBudgetForMessage: $selectedBudgetForMessage',
    );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: options.map((option) {
        // 이모티콘 제거 후 비교
        final optionAmount = option.replaceAll(' 💵', '').trim();
        final isSelected = selectedBudgetForMessage == optionAmount;

        debugPrint(
          '예산 버튼 생성: $option (isSelected: $isSelected, hasSelection: $hasSelection)',
        );

        return ElevatedButton(
          onPressed: hasSelection
              ? null
              : () {
                  debugPrint('예산 버튼 클릭됨: $option');
                  debugPrint('메시지 timestamp: $messageTimestamp');
                  debugPrint('chatId: $chatId');
                  budgetNotifier.handleBudgetSelection(
                    option,
                    messageTimestamp,
                  );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: hasSelection ? Colors.grey[300] : Colors.white,
            foregroundColor: hasSelection ? Colors.grey[600] : Colors.black,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Text(
            option,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'HelveticaNeue',
              color: hasSelection ? Colors.grey[600] : Colors.black,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// 세부 타입 선택 위젯 (이모지 + 영어 단어 버튼)
class _SubTypeSelector extends ConsumerWidget {
  final List<String> options;
  final String chatId;

  const _SubTypeSelector({required this.options, required this.chatId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 메시지 리스트를 watch하여 상태 변경 시 UI 업데이트
    ref.watch(surveyMessageProvider(chatId));
    final messageNotifier = ref.read(surveyMessageProvider(chatId).notifier);
    final hasSelectedSubType = messageNotifier.selectedSubType != null;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: options.map((option) {
        final isHelpOption = option == "I'm not sure.... plz help!";
        final isSelected = messageNotifier.isSubTypeSelected(option);
        // 선택된 항목도 다시 선택 가능 (sendUserMessage에서 중복 처리)

        // "I'm not sure.... plz help!" 옵션은 텍스트만 표시
        if (isHelpOption) {
          return Opacity(
            opacity: isSelected ? 1.0 : (hasSelectedSubType ? 0.3 : 1.0),
            child: ElevatedButton(
              onPressed: hasSelectedSubType && !isSelected
                  ? null
                  : () {
                      messageNotifier.sendUserMessage(option);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Text(
                option,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'HelveticaNeue',
                ),
              ),
            ),
          );
        }

        final details = skinSubTypeDetails[option];
        final emoji = details?['emoji'] ?? '❓';
        final english = details?['english'] ?? 'UNKNOWN';

        return Opacity(
          opacity: isSelected ? 1.0 : (hasSelectedSubType ? 0.3 : 1.0),
          child: ElevatedButton(
            onPressed: hasSelectedSubType && !isSelected
                ? null
                : () {
                    messageNotifier.sendUserMessage(option);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  english,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'HelveticaNeue',
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// 화장품 타입 선택 위젯 (이모지 + 영어 단어 버튼, 다중 선택)
class _CosmeticTypeSelector extends ConsumerStatefulWidget {
  final List<String> options;
  final String chatId;

  const _CosmeticTypeSelector({required this.options, required this.chatId});

  @override
  ConsumerState<_CosmeticTypeSelector> createState() =>
      _CosmeticTypeSelectorState();
}

class _CosmeticTypeSelectorState extends ConsumerState<_CosmeticTypeSelector> {
  // 화장품 타입별 이모지와 영어 단어 맵
  final Map<String, Map<String, String>> cosmeticDetails = {
    'TONER': {'emoji': '💧', 'english': 'TONER'},
    'ESSENCE': {'emoji': ' 🧪', 'english': 'ESSENCE'},
    'AMPOULE': {'emoji': '💉', 'english': 'AMPOULE'},
    'SERUM': {'emoji': '✨', 'english': 'SERUM'},
    'LOTION': {'emoji': '🧴', 'english': 'LOTION'},
    'CREAM': {'emoji': '🧈', 'english': 'CREAM'},
    'EYE CREAM': {'emoji': '👁️', 'english': 'EYE CREAM'},
    'MIST': {'emoji': '🌫️', 'english': 'MIST'},
    'SUNSCREEN': {'emoji': '☀️', 'english': 'SUNSCREEN'},
    'CLEANSER': {'emoji': '🧼', 'english': 'CLEANSER'},
    'MASK PACK': {'emoji': '🎭', 'english': 'MASK PACK'},
  };

  @override
  Widget build(BuildContext context) {
    // 메시지 리스트를 watch하여 상태 변경 시 UI 업데이트
    ref.watch(surveyMessageProvider(widget.chatId));
    final messageNotifier = ref.read(
      surveyMessageProvider(widget.chatId).notifier,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: widget.options.map((option) {
            final details = cosmeticDetails[option];
            final emoji = details?['emoji'] ?? '❓';
            final english = details?['english'] ?? option;
            final isSelected = messageNotifier.isCosmeticSelected(option);
            final isLocked = messageNotifier.isCosmeticsSelectionLocked;
            // 선택되지 않은 화장품만 반투명하게, 선택된 화장품은 다시 클릭 불가
            final isDisabled = isSelected || isLocked;
            // Done을 누른 후(isLocked)에만 선택되지 않은 화장품을 반투명하게 표시
            final opacity = isSelected ? 1.0 : (isLocked ? 0.5 : 1.0);

            return Opacity(
              opacity: opacity,
              child: GestureDetector(
                onTap: isDisabled
                    ? null
                    : () {
                        messageNotifier.toggleCosmeticSelection(option);
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context)
                              .colorScheme
                              .primary // 노란색(크림색) - 선택됨
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context)
                                .colorScheme
                                .primary // 노란색(크림색) - 선택됨
                          : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        english,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.black : Colors.black,
                          fontFamily: 'HelveticaNeue',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // Done 버튼 (색깔 유지, 클릭만 불가)
        ElevatedButton(
          onPressed: messageNotifier.isCosmeticsSelectionLocked
              ? null
              : () async {
                  // 먼저 설문 완료 처리 (질문 생성 중단 플래그 설정)
                  final surveyNotifier = ref.read(
                    surveyMessageProvider(widget.chatId).notifier,
                  );
                  // 화장품 선택 완료 처리
                  await messageNotifier.sendSelectedCosmetics();
                  // 설문 완료 처리 (감사 메시지 표시 및 초기 화면으로 복귀)
                  await surveyNotifier.completeSurvey();
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary, // Primary 색상 (크림색)
            foregroundColor: Colors.black87,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            'Done',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              fontFamily: 'HelveticaNeue',
            ),
          ),
        ),
      ],
    );
  }
}
