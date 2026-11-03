import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/data/models/message_model.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/viewmodels/compare_message_provider.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/viewmodels/typing_provider.dart';
import 'package:mobileprogramming_groupproject_2025/features/liked_products/presentation/providers/liked_products_provider.dart';
import 'package:mobileprogramming_groupproject_2025/features/liked_products/domain/entities/cosmetic_item_entity.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/widgets/message_bubble.dart';
import 'package:mobileprogramming_groupproject_2025/features/chat/presentation/widgets/typing_indicator.dart';

class ChatComparePage extends ConsumerStatefulWidget {
  const ChatComparePage({super.key});

  @override
  ConsumerState<ChatComparePage> createState() => _ChatComparePageState();
}

class _ChatComparePageState extends ConsumerState<ChatComparePage> {
  final ScrollController _scrollController = ScrollController();
  final String chatId = 'chatbot_compare'; // 제품 비교 전용 챗 ID
  CosmeticItemEntity? _selectedProduct1;
  CosmeticItemEntity? _selectedProduct2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializePage();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 페이지 초기화
  void _initializePage() {
    final compareMessages = ref.read(compareMessageProvider(chatId));

    // 메시지가 없으면 초기 안내 메시지 추가
    if (compareMessages.isEmpty) {
      ref
          .read(compareMessageProvider(chatId).notifier)
          .addMessage(
            MessageModel(
              senderId: 'assistant',
              text: 'Select two products from your liked list to compare them!',
              timestamp: DateTime.now(),
              isMe: false,
            ),
          );
    }
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

  /// 제품 선택 처리
  void _handleProductSelection(CosmeticItemEntity product) {
    final notifier = ref.read(compareMessageProvider(chatId).notifier);

    if (_selectedProduct1 == null) {
      setState(() {
        _selectedProduct1 = product;
      });
      notifier.selectProduct(product, isFirst: true);
    } else if (_selectedProduct2 == null && _selectedProduct1 != product) {
      setState(() {
        _selectedProduct2 = product;
      });
      notifier.selectProduct(product, isFirst: false);
    } else if (_selectedProduct1 == product) {
      // 첫 번째 제품 선택 해제
      setState(() {
        _selectedProduct1 = null;
      });
      notifier.deselectProduct(isFirst: true);
    } else if (_selectedProduct2 == product) {
      // 두 번째 제품 선택 해제
      setState(() {
        _selectedProduct2 = null;
      });
      notifier.deselectProduct(isFirst: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final compareMessages = ref.watch(compareMessageProvider(chatId));
    final isTyping = ref.watch(isTypingProvider(chatId));
    final likedState = ref.watch(likedProductsNotifierProvider);
    final likedProducts = likedState.products;

    // 메시지가 변경될 때만 스크롤
    ref.listen(compareMessageProvider(chatId), (previous, next) {
      if (previous != null && next.length > previous.length && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scrollController.hasClients) {
            _scrollToBottom();
          }
        });
      }
      // "Search again" 메시지가 제거되면 선택 상태 초기화
      if (previous != null && next.length < previous.length) {
        final hasSearchAgain = previous.any(
          (m) =>
              m.text.contains('Would you like to compare other products?') ||
              m.options?.contains('Search again?') == true,
        );
        final stillHasSearchAgain = next.any(
          (m) =>
              m.text.contains('Would you like to compare other products?') ||
              m.options?.contains('Search again?') == true,
        );
        if (hasSearchAgain && !stillHasSearchAgain) {
          // Search again 메시지가 제거되었으므로 선택 상태 초기화
          setState(() {
            _selectedProduct1 = null;
            _selectedProduct2 = null;
          });
        }
      }
    });

    final shouldShowTyping = isTyping;
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
          'Compare Products',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontFamily: 'HelveticaNeue93',
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Column(
        children: [
          // 제품 선택 영역
          if (likedProducts.length < 2)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Center(
                child: Text(
                  'Please like at least 2 products to compare!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    fontFamily: 'Helvetica',
                  ),
                ),
              ),
            )
          else if (likedProducts.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Two Products to Compare',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Helvetica',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: likedProducts.length,
                      itemBuilder: (context, index) {
                        final product = likedProducts[index];
                        final isSelected1 =
                            _selectedProduct1?.title == product.title;
                        final isSelected2 =
                            _selectedProduct2?.title == product.title;
                        final isSelected = isSelected1 || isSelected2;
                        final isFirst = isSelected1;

                        // 비교가 이미 시작되었는지 확인 (비교 중/완료 후에는 선택/해제 불가)
                        final compareNotifier = ref.read(
                          compareMessageProvider(chatId).notifier,
                        );
                        final isComparisonStarted =
                            compareNotifier.isComparisonStarted;

                        return GestureDetector(
                          onTap: isComparisonStarted
                              ? null
                              : () => _handleProductSelection(product),
                          child: Container(
                            width: 200,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isFirst
                                        ? Colors.blue[50]
                                        : Colors.green[50])
                                  : Colors.grey[100],
                              border: Border.all(
                                color: isSelected
                                    ? (isFirst ? Colors.blue : Colors.green)
                                    : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (isSelected)
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: isFirst
                                              ? Colors.blue
                                              : Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            isFirst ? '1' : '2',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (isSelected) const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        product.title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.black
                                              : Colors.grey[700],
                                          fontFamily: 'Helvetica',
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  product.category,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontFamily: 'HelveticaNeue',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  product.priceRange,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                    fontFamily: 'Helvetica',
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
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: const Center(
                child: Text(
                  'No liked products to compare. Please like some products first!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontFamily: 'Helvetica',
                  ),
                ),
              ),
            ),

          // 메시지 리스트
          Expanded(
            child: compareMessages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.compare_arrows,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Select two products to compare',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontFamily: 'Helvetica',
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount:
                        compareMessages.length + (shouldShowTyping ? 1 : 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemBuilder: (context, index) {
                      if (index == compareMessages.length && shouldShowTyping) {
                        return const TypingIndicator();
                      }
                      return MessageBubble(
                        message: compareMessages[index],
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
