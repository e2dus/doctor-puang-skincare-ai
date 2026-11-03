import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobileprogramming_groupproject_2025/models/cosmetic_item.dart';
import 'package:mobileprogramming_groupproject_2025/features/product/presentation/viewmodels/cart_viewmodel.dart';
import 'package:mobileprogramming_groupproject_2025/features/product/presentation/viewmodels/liked_products_viewmodel.dart';
import 'package:mobileprogramming_groupproject_2025/features/product/presentation/viewmodels/product_detail_viewmodel.dart';
import 'package:mobileprogramming_groupproject_2025/features/product/presentation/viewmodels/similar_products_viewmodel.dart';
import 'package:mobileprogramming_groupproject_2025/features/product/presentation/viewmodels/no_recommend_viewmodel.dart';
import 'package:mobileprogramming_groupproject_2025/features/product/presentation/viewmodels/blocked_products_viewmodel.dart';
import 'package:mobileprogramming_groupproject_2025/features/product/domain/entities/product_detail_entity.dart';
import 'package:mobileprogramming_groupproject_2025/features/product/domain/entities/similar_product_entity.dart';
import 'package:mobileprogramming_groupproject_2025/features/liked_products/data/mappers/cosmetic_item_mapper.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  final CosmeticItem item;

  const ProductDetailPage({super.key, required this.item});

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage>
    with SingleTickerProviderStateMixin {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  bool _isFabExpanded = false;
  bool _isIngredientsExpanded = false; // 성분 섹션 접기/펼치기 상태

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() {
      _isFabExpanded = !_isFabExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    var entity = CosmeticItemMapper.fromModel(item);
    final likedItems = ref.watch(likedProductsProvider);
    final isLiked = likedItems.any((p) => p.title == item.title);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    // API 호출 (productId만 있어도 작동하도록 수정)
    final productId = item.productId;
    final skuId = item.skuId;

    print('📱 ProductDetailPage - build:');
    print('  productId: $productId');
    print('  skuId: $skuId');
    print('  productId is null: ${productId == null}');
    print('  skuId is null: ${skuId == null}');
    print('  productId isEmpty: ${productId?.isEmpty ?? true}');
    print('  skuId isEmpty: ${skuId?.isEmpty ?? true}');

    // String 키를 사용하여 캐싱이 제대로 작동하도록 함
    // '|' 구분자를 사용하여 productId나 skuId에 '_'가 포함되어도 안전하게 파싱
    // productId만 있어도 작동하도록 수정 (skuId가 없으면 더미 값 "0" 사용)
    final shouldFetchDetail = productId != null && productId.isNotEmpty;

    print('  shouldFetchDetail: $shouldFetchDetail');

    // skuId가 없으면 더미 값 "0" 사용 (서버에서 첫 번째 skuId를 반환함)
    final finalSkuId = (skuId != null && skuId.isNotEmpty) ? skuId : '0';

    final productDetailAsync = shouldFetchDetail
        ? ref.watch(productDetailProvider('$productId|$finalSkuId'))
        : null;

    print('  productDetailAsync is null: ${productDetailAsync == null}');

    return Scaffold(
      backgroundColor: isDarkMode
          ? theme.scaffoldBackgroundColor
          : Colors.white,
      body: Stack(
        children: [
          productDetailAsync != null
              ? productDetailAsync.when(
                  data: (productDetail) => _buildContentWithApiData(
                    context,
                    item,
                    entity,
                    isLiked,
                    isDarkMode,
                    theme,
                    productDetail,
                    productId ?? '',
                  ),
                  loading: () {
                    print('⏳ ProductDetailPage - Loading state');
                    return _buildLoadingState(context, isDarkMode, theme);
                  },
                  error: (error, stack) {
                    print('❌ ProductDetailPage - Error state:');
                    print('  Error: $error');
                    print('  Stack Trace: $stack');
                    return _buildErrorState(
                      context,
                      item,
                      entity,
                      isLiked,
                      isDarkMode,
                      theme,
                      error,
                    );
                  },
                )
              : _buildContentWithLegacyData(
                  context,
                  item,
                  entity,
                  isLiked,
                  isDarkMode,
                  theme,
                ),
          // 플로팅 뒤로가기 버튼
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (isDarkMode ? Colors.grey[800]! : Colors.white)
                      .withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: isDarkMode ? Colors.white : Colors.black87,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: productDetailAsync != null
          ? productDetailAsync.when(
              data: (productDetail) => _buildExpandableFab(
                context,
                item,
                entity,
                theme,
                isDarkMode,
                productDetail,
              ),
              loading: () => _buildExpandableFab(
                context,
                item,
                entity,
                theme,
                isDarkMode,
                null,
              ),
              error: (error, stack) => _buildExpandableFab(
                context,
                item,
                entity,
                theme,
                isDarkMode,
                null,
              ),
            )
          : _buildExpandableFab(context, item, entity, theme, isDarkMode, null),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildLoadingState(
    BuildContext context,
    bool isDarkMode,
    ThemeData theme,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading product details...',
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    CosmeticItem item,
    dynamic entity,
    bool isLiked,
    bool isDarkMode,
    ThemeData theme,
    Object error,
  ) {
    // 에러 발생 시 레거시 데이터로 표시
    return _buildContentWithLegacyData(
      context,
      item,
      entity,
      isLiked,
      isDarkMode,
      theme,
    );
  }

  Widget _buildContentWithApiData(
    BuildContext context,
    CosmeticItem item,
    dynamic entity,
    bool isLiked,
    bool isDarkMode,
    ThemeData theme,
    ProductDetailEntity productDetail,
    String productId,
  ) {
    // target_url 로그 출력
    print('📦 Product Detail Page - target_url:');
    print('  target_url: ${productDetail.targetUrl}');
    print('  target_url isEmpty: ${productDetail.targetUrl.isEmpty}');
    print('  target_url length: ${productDetail.targetUrl.length}');

    // API에서 받은 이미지 배열 사용
    // mainImage가 있으면 첫 번째로 추가, 그 다음 images 배열 추가
    final List<String> images = [];

    // CosmeticItem에서 imageUrl이 있으면 먼저 추가
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      images.add(item.imageUrl!);
    }

    if (productDetail.mainImage.isNotEmpty) {
      if (!images.contains(productDetail.mainImage)) {
        images.add(productDetail.mainImage);
      }
    }
    // 중복 제거하면서 images 배열 추가
    for (final imageUrl in productDetail.images) {
      if (imageUrl.isNotEmpty && !images.contains(imageUrl)) {
        images.add(imageUrl);
      }
    }
    // 이미지가 없으면 빈 배열 (에러 처리에서 대체 이미지 표시)
    if (images.isEmpty) {
      images.add(''); // 빈 문자열로 표시하여 에러 처리 트리거
    }

    // 이미지 URL 로그 출력
    print('📸 Product Detail Images:');
    print('  Main Image: ${productDetail.mainImage}');
    print('  Images Array (${productDetail.images.length}):');
    for (int i = 0; i < productDetail.images.length; i++) {
      print('    [$i] ${productDetail.images[i]}');
    }
    print('  Final Images List (${images.length}):');
    for (int i = 0; i < images.length; i++) {
      print('    [$i] ${images[i]}');
    }

    // API에서 받은 이미지로 entity의 imageUrl 업데이트
    // (like, cart, block 버튼에서 사용)
    if (images.isNotEmpty) {
      entity = entity.copyWith(imageUrl: images[0]);
    }

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              // 이미지 슬라이더
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.45,
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          final imageUrl = images[index];
                          // 빈 문자열이면 플레이스홀더 표시
                          if (imageUrl.isEmpty) {
                            return Container(
                              color: isDarkMode
                                  ? Colors.grey[900]
                                  : Colors.grey[100],
                              child: Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 100,
                                  color: Colors.grey[400],
                                ),
                              ),
                            );
                          }
                          return Container(
                            color: isDarkMode
                                ? Colors.grey[900]
                                : Colors.grey[100],
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value:
                                            loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                            : null,
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.grey[200],
                                  child: Center(
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      size: 100,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                // 페이지 인디케이터
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      images.length,
                      (index) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentImageIndex == index
                              ? (isDarkMode ? Colors.white : Colors.black)
                              : Colors.grey[300],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // 제품 정보 영역
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 브랜드 이름
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.grey[700]
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.storefront,
                              size: 18,
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            productDetail.brandName,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // 제품명
                      Text(
                        productDetail.productName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode ? Colors.white : Colors.black87,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 평점 및 리뷰
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            productDetail.rating.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${productDetail.reviews})',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Highlights
                      if (productDetail.highlights.isNotEmpty) ...[
                        Text(
                          'Highlights',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: productDetail.highlights.map((highlight) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.grey[800]
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                highlight,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode
                                      ? Colors.grey[300]
                                      : Colors.grey[700],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],
                      // 설명
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        productDetail.shortDescription.isNotEmpty
                            ? productDetail.shortDescription
                            : productDetail.longDescription,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // 성분 섹션
                      if (productDetail.ingredients.isNotEmpty) ...[
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isIngredientsExpanded = !_isIngredientsExpanded;
                            });
                          },
                          child: Row(
                            children: [
                              Text(
                                'Ingredients',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _isIngredientsExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                        if (_isIngredientsExpanded) ...[
                          const SizedBox(height: 16),
                          // 전체 성분 리스트 (INCI list)
                          Text(
                            productDetail.ingredients.join(', '),
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 24),
                      // 가격 정보
                      Text(
                        'Price',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        productDetail.price,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // You May Also Like 섹션
              if (productId.isNotEmpty)
                _buildSimilarProductsSection(context, productId, isDarkMode),
            ],
          ),
        ),
        // 하단 버튼 영역
        Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12,
          ),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final noRecommendItems = ref.watch(noRecommendProductsProvider);
                    final isNoRecommend = noRecommendItems.any((p) => p.title == item.title);
                    final blockedItems = ref.watch(blockedProductsProvider);
                    final isBlocked = blockedItems.any((p) => p.title == item.title);
                    final isDisabled = isNoRecommend || isBlocked;
                    
                    return OutlinedButton(
                      onPressed: isDisabled ? null : () async {
                        await ref
                            .read(cartProvider.notifier)
                            .addItem(entity.toProductEntity());
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item.title} added to cart'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: isDisabled ? Colors.grey : const Color(0xFF2DB4A8),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledForegroundColor: Colors.grey,
                      ),
                      child: Text(
                        'Cart',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDisabled ? Colors.grey : const Color(0xFF2DB4A8),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    print('🛒 Buy Now 버튼 클릭');
                    print('  target_url: ${productDetail.targetUrl}');

                    if (productDetail.targetUrl.isNotEmpty) {
                      try {
                        final uri = Uri.parse(productDetail.targetUrl);
                        print('  Parsed URI: $uri');
                        print('  Full URI: ${uri.toString()}');
                        print('  Scheme: ${uri.scheme}');
                        print('  Host: ${uri.host}');
                        print('  Path: ${uri.path}');

                        // 시스템 기본 브라우저에서 열기
                        // externalApplication: 외부 앱(브라우저)에서 열기
                        final launched = await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                        print('  ✅ Launch result: $launched');

                        if (!launched && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Cannot open URL: ${productDetail.targetUrl}',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e, stackTrace) {
                        print('❌ Error opening URL:');
                        print('  Error: $e');
                        print('  Stack Trace: $stackTrace');
                        // iOS 플러그인 에러 발생 시에도 조용히 처리
                        // 앱이 완전히 재빌드되면 해결될 수 있음
                      }
                    } else {
                      print('  ⚠️ target_url is empty');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Product URL is not available'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF2DB4A8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Buy Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContentWithLegacyData(
    BuildContext context,
    CosmeticItem item,
    dynamic entity,
    bool isLiked,
    bool isDarkMode,
    ThemeData theme,
  ) {
    // 기존 레거시 데이터 표시 로직
    final dummyImages = [
      'https://picsum.photos/seed/cosmetic1/600/600',
      'https://picsum.photos/seed/cosmetic2/600/600',
      'https://picsum.photos/seed/cosmetic3/600/600',
    ];

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.45,
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemCount: dummyImages.length,
                        itemBuilder: (context, index) {
                          return Container(
                            color: isDarkMode
                                ? Colors.grey[900]
                                : Colors.grey[100],
                            child: Image.network(
                              dummyImages[index],
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.grey[200],
                                  child: Icon(
                                    Icons.image_outlined,
                                    size: 100,
                                    color: Colors.grey[400],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 16,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color:
                                (isDarkMode ? Colors.grey[800]! : Colors.white)
                                    .withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            color: isDarkMode ? Colors.white : Colors.black87,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      right: 16,
                      child: Consumer(
                        builder: (context, ref, _) {
                          final likedItems = ref.watch(likedProductsProvider);
                          final currentIsLiked = likedItems.any(
                            (p) => p.title == item.title,
                          );
                          return GestureDetector(
                            onTap: () {
                              ref
                                  .read(likedProductsProvider.notifier)
                                  .toggleLike(entity.toProductEntity());
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color:
                                    (isDarkMode
                                            ? Colors.grey[800]!
                                            : Colors.white)
                                        .withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                currentIsLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: currentIsLiked
                                    ? Colors.red
                                    : (isDarkMode
                                          ? Colors.white
                                          : Colors.grey[600]),
                                size: 22,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      dummyImages.length,
                      (index) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentImageIndex == index
                              ? (isDarkMode ? Colors.white : Colors.black)
                              : Colors.grey[300],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.grey[700]
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.storefront,
                              size: 18,
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            item.category,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode ? Colors.white : Colors.black87,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            item.rating.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.supportingText,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Price Range',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.priceRange,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12,
          ),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final noRecommendItems = ref.watch(noRecommendProductsProvider);
                    final isNoRecommend = noRecommendItems.any((p) => p.title == item.title);
                    final blockedItems = ref.watch(blockedProductsProvider);
                    final isBlocked = blockedItems.any((p) => p.title == item.title);
                    final isDisabled = isNoRecommend || isBlocked;
                    
                    return OutlinedButton(
                      onPressed: isDisabled ? null : () async {
                        await ref
                            .read(cartProvider.notifier)
                            .addItem(item.toProductEntity());
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item.title} added to cart'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: isDisabled ? Colors.grey : const Color(0xFF2DB4A8),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledForegroundColor: Colors.grey,
                      ),
                      child: Text(
                        'Cart',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDisabled ? Colors.grey : const Color(0xFF2DB4A8),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    // 레거시 데이터에는 targetUrl이 없으므로 안내 메시지 표시
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Product URL is not available for this item',
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF2DB4A8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Buy Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimilarProductsSection(
    BuildContext context,
    String productId,
    bool isDarkMode,
  ) {
    final similarProductsAsync = ref.watch(similarProductsProvider(productId));

    return similarProductsAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => const SliverToBoxAdapter(child: SizedBox()),
      data: (similarProducts) {
        if (similarProducts.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox());
        }

        return SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 32, 0, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 섹션 제목
                Text(
                  'You May Also Like',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                // 가로 스크롤 제품 리스트
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: similarProducts.length,
                    itemBuilder: (context, index) {
                      final product = similarProducts[index];
                      return _buildSimilarProductCard(
                        context,
                        product,
                        isDarkMode,
                        index == similarProducts.length - 1,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSimilarProductCard(
    BuildContext context,
    SimilarProductEntity product,
    bool isDarkMode,
    bool isLast,
  ) {
    return Container(
      width: 180,
      margin: EdgeInsets.only(right: isLast ? 20 : 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          // 유사 제품 클릭 시 해당 제품의 상세 페이지로 이동
          final cosmeticItem = CosmeticItem(
            title: product.productName,
            rating: product.rating,
            category: product.brandName,
            priceRange: product.price,
            supportingText: product.brandName,
            productId: product.productId,
            skuId: product.skuId, // image_url 또는 target_url에서 추출된 skuId
            imageUrl: product.imageUrl,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(item: cosmeticItem),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 제품 이미지
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white, // 이미지 배경은 항상 흰색
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                              color: isDarkMode
                                  ? Colors.grey[600]
                                  : Colors.grey[400],
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.white,
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 40,
                              color: isDarkMode
                                  ? Colors.grey[600]
                                  : Colors.grey[400],
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.white,
                        child: Icon(
                          Icons.image_outlined,
                          size: 40,
                          color: isDarkMode
                              ? Colors.grey[600]
                              : Colors.grey[400],
                        ),
                      ),
              ),
            ),
            // 제품 정보 영역 (패딩 추가)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 브랜드명
                  Text(
                    product.brandName,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  // 제품명
                  Text(
                    product.productName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  // 가격 및 평점
                  Row(
                    children: [
                      // 평점
                      Icon(Icons.star_rounded, size: 13, color: Colors.amber),
                      const SizedBox(width: 3),
                      Text(
                        product.rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          '(${_formatReviewCount(product.reviews)})',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDarkMode
                                ? Colors.grey[500]
                                : Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  // 가격
                  Text(
                    product.price,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatReviewCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  Widget _buildExpandableFab(
    BuildContext context,
    CosmeticItem item,
    dynamic entity,
    ThemeData theme,
    bool isDarkMode,
    dynamic productDetail,
  ) {
    if (productDetail != null && productDetail.mainImage != null) {
      entity = entity.copyWith(imageUrl: productDetail.mainImage);
    } else {
      entity = entity.copyWith(imageUrl: item.imageUrl);
    }
    print(entity.imageUrl);

    return Padding(
      padding: EdgeInsets.only(
        bottom: 80.0 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isFabExpanded) ...[
            // Like button
            Consumer(
              builder: (context, ref, _) {
                final likedItems = ref.watch(likedProductsProvider);
                final isLiked = likedItems.any((p) => p.title == item.title);
                final noRecommendItems = ref.watch(noRecommendProductsProvider);
                final isNoRecommend = noRecommendItems.any((p) => p.title == item.title);
                final blockedItems = ref.watch(blockedProductsProvider);
                final isBlocked = blockedItems.any((p) => p.title == item.title);
                
                return FloatingActionButton(
                  heroTag: 'like',
                  mini: true,
                  backgroundColor: isLiked
                      ? Colors.red
                      : (isDarkMode ? Colors.grey[800] : Colors.white),
                  onPressed: () {
                    // 다른 버튼이 눌려있으면 먼저 해제
                    if (isNoRecommend) {
                      ref
                          .read(noRecommendProductsProvider.notifier)
                          .removeNoRecommend(entity.toProductEntity());
                    }
                    if (isBlocked) {
                      ref
                          .read(blockedProductsProvider.notifier)
                          .unblockProduct(entity.toProductEntity());
                    }
                    
                    // Like 토글
                    ref
                        .read(likedProductsProvider.notifier)
                        .toggleLike(entity.toProductEntity());
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isLiked
                              ? '${item.title} removed from likes'
                              : '${item.title} added to likes',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked
                        ? Colors.white
                        : (isDarkMode ? Colors.white : Colors.black87),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            // No Recommend button
            Consumer(
              builder: (context, ref, _) {
                final likedItems = ref.watch(likedProductsProvider);
                final isLiked = likedItems.any((p) => p.title == item.title);
                final noRecommendItems = ref.watch(noRecommendProductsProvider);
                final isNoRecommend = noRecommendItems.any((p) => p.title == item.title);
                final blockedItems = ref.watch(blockedProductsProvider);
                final isBlocked = blockedItems.any((p) => p.title == item.title);
                
                return FloatingActionButton(
                  heroTag: 'no_recommend',
                  mini: true,
                  backgroundColor: isNoRecommend
                      ? Colors.orange
                      : (isDarkMode ? Colors.grey[800] : Colors.white),
                  onPressed: () {
                    // 다른 버튼이 눌려있으면 먼저 해제
                    if (isLiked) {
                      ref
                          .read(likedProductsProvider.notifier)
                          .toggleLike(entity.toProductEntity());
                    }
                    if (isBlocked) {
                      ref
                          .read(blockedProductsProvider.notifier)
                          .unblockProduct(entity.toProductEntity());
                    }
                    
                    // No Recommend 토글
                    if (isNoRecommend) {
                      ref
                          .read(noRecommendProductsProvider.notifier)
                          .removeNoRecommend(entity.toProductEntity());
                    } else {
                      ref
                          .read(noRecommendProductsProvider.notifier)
                          .addNoRecommend(entity.toProductEntity());
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isNoRecommend
                              ? '${item.title} removed from not recommended'
                              : '${item.title} added to not recommended',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Icon(
                    Icons.thumb_down,
                    color: isNoRecommend
                        ? Colors.white
                        : (isDarkMode ? Colors.white : Colors.black87),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            // Block button
            Consumer(
              builder: (context, ref, _) {
                final likedItems = ref.watch(likedProductsProvider);
                final isLiked = likedItems.any((p) => p.title == item.title);
                final noRecommendItems = ref.watch(noRecommendProductsProvider);
                final isNoRecommend = noRecommendItems.any((p) => p.title == item.title);
                final blockedItems = ref.watch(blockedProductsProvider);
                final isBlocked = blockedItems.any((p) => p.title == item.title);
                
                return FloatingActionButton(
                  heroTag: 'block',
                  mini: true,
                  backgroundColor: isBlocked
                      ? Colors.red[700]
                      : (isDarkMode ? Colors.grey[800] : Colors.white),
                  onPressed: () {
                    // 다른 버튼이 눌려있으면 먼저 해제
                    if (isLiked) {
                      ref
                          .read(likedProductsProvider.notifier)
                          .toggleLike(entity.toProductEntity());
                    }
                    if (isNoRecommend) {
                      ref
                          .read(noRecommendProductsProvider.notifier)
                          .removeNoRecommend(entity.toProductEntity());
                    }
                    
                    // Block 토글
                    if (isBlocked) {
                      ref
                          .read(blockedProductsProvider.notifier)
                          .unblockProduct(entity.toProductEntity());
                    } else {
                      ref
                          .read(blockedProductsProvider.notifier)
                          .blockProduct(entity.toProductEntity());
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isBlocked
                              ? '${item.title} unblocked'
                              : '${item.title} blocked',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Icon(
                    Icons.block,
                    color: isBlocked
                        ? Colors.white
                        : (isDarkMode ? Colors.white : Colors.black87),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
          // Main FAB
          FloatingActionButton(
            heroTag: 'main',
            backgroundColor: theme.colorScheme.primary,
            onPressed: _toggleFab,
            child: Icon(
              _isFabExpanded ? Icons.close : Icons.favorite,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
