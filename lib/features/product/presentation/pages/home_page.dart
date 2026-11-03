/// ============================================================================
/// HOME PAGE
/// ============================================================================
///
/// Main home screen showing product rankings and promotional content.
///
/// ## Features
/// - Auto-scrolling promotional banner
/// - Hero image section
/// - Product grid with ranking display
/// - Filtering of blocked/no-recommend products
///
/// ## Dependencies
/// - rankingProductsProvider: Fetches product rankings
/// - blockedProductsProvider: Gets blocked products to filter
/// - noRecommendProductsProvider: Gets no-recommend products to filter
/// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/product_entity.dart';
import '../viewmodels/ranking_viewmodel.dart';
import '../viewmodels/category_viewmodel.dart';
import '../viewmodels/blocked_products_viewmodel.dart';
import '../viewmodels/no_recommend_viewmodel.dart';
import '../widgets/product_grid_item.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/cosmetic_item.dart';
import '../../../../screens/product_detail_page.dart';
import '../../../dashboard/presentation/pages/chat_bot_guide_page.dart';
import '../../../main/presentation/providers/main_page_provider.dart';

/// Home page displaying product rankings
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  // Banner data
  final List<Map<String, String>> _tips = const [
    {'title': 'Enter in calendar!', 'subtitle': 'Record your daily skincare routine in the calendar!'},
    {'title': '100% Chatbot Usage Guide!', 'subtitle': 'Ask Puang about your skin concerns!'},
  ];

  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;
  String? _selectedCategory; // Selected category (null = all)

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % _tips.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blockedItems = ref.watch(blockedProductsProvider);
    final noRecommendItems = ref.watch(noRecommendProductsProvider);
    final rankingAsync = ref.watch(rankingProductsProvider(_selectedCategory));

    // Keep previous data while loading new data
    final products = rankingAsync.value;
    final isLoading = rankingAsync.isLoading;
    final hasError = rankingAsync.hasError;

    // Initial loading state (only when no data)
    if (products == null && isLoading && !hasError) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state (only when no data)
    if (hasError && products == null) {
      return _buildErrorView(rankingAsync.error!);
    }

    // Filter and display data if available
    if (products != null) {
      final filteredItems = products.where((item) {
        final isBlocked = blockedItems.any((b) => b.title == item.title);
        final isNoRecommend = noRecommendItems.any(
          (n) => n.title == item.title,
        );
        return !isBlocked && !isNoRecommend;
      }).toList();

      return Stack(
        children: [
          _buildContent(filteredItems),
          // Show small loading indicator at top when loading new data
          if (isLoading && products.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
        ],
      );
    }

    // Fallback (when no data and no error)
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorView(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Failed to load data.', style: AppTextStyles.bodySecondary),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () =>
                ref.refresh(rankingProductsProvider(_selectedCategory)),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<ProductEntity> products) {
    return CustomScrollView(
      slivers: [
        _buildPromoBanner(),
        _buildHeroSection(),
        _buildCategoryFilter(),
        _buildProductGrid(products),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    final categoriesAsync = ref.watch(categoriesProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return categoriesAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: SizedBox(
          height: 50,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => const SliverToBoxAdapter(child: SizedBox()),
      data: (categories) {
        return SliverToBoxAdapter(
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // "All" option
                _buildCategoryChip(
                  label: 'All',
                  isSelected: _selectedCategory == null,
                  isDarkMode: isDarkMode,
                  onTap: () {
                    setState(() {
                      _selectedCategory = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                // Category chips
                ...categories.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildCategoryChip(
                      label: '${category.name} (${category.count})',
                      isSelected: _selectedCategory == category.name,
                      isDarkMode: isDarkMode,
                      onTap: () {
                        setState(() {
                          _selectedCategory = category.name;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF79B4A9) // Misty Green
              : (isDarkMode
                    ? Colors.grey[800]!.withOpacity(0.5)
                    : Colors.grey[200]!),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF79B4A9)
                : (isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDarkMode ? Colors.grey[300] : Colors.grey[700]),
          ),
        ),
      ),
    );
  }

  Widget _buildPromoBanner() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: SizedBox(
          height: 180,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _tips.length,
                itemBuilder: (context, index) => _buildBannerCard(_tips[index], index),
              ),
              _buildPageIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerCard(Map<String, String> tip, int index) {
    return GestureDetector(
      onTap: () {
        final title = tip['title'] ?? '';
        if (title == 'Enter in calendar!') {
          // MainPage의 Calendar 탭(index 2)으로 변경
          ref.read(mainPageTabIndexProvider.notifier).setTabIndex(2);
        } else if (title == '100% Chatbot Usage Guide!') {
          // ChatBot Guide 페이지로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChatBotGuidePage(),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF6E5BFF), Color(0xFF4B3BE3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tip['title']!,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tip['subtitle']!,
                  style: AppTextStyles.bodySecondary.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const _DeliveryTruckGraphic(),
        ],
      ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Positioned(
      top: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '${_currentPage + 1}/${_tips.length}',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AspectRatio(
            aspectRatio: 16 / 9, // Maintain image aspect ratio
            child: GestureDetector(
              onTap: () async {
                final Uri url = Uri.parse('https://www.sephora.com/');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image
                  Image.asset(
                    'assets/images/Sephora.webp',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                // Bottom gradient overlay (improves text readability)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.7), // Darker gradient
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
                // Text area
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 28, // Increased bottom margin
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // "Hello, Puang" text
                      Text(
                        'Hello, Puang',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // "Thanks to SEPHORA" text
                      Text(
                        'Thanks to SEPHORA',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.6),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid(List<ProductEntity> products) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.3, // Reduced height (0.75 * 2)
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => ProductGridItem(
            item: products[index],
            index: index,
            totalCount: products.length,
            onTap: () {
              final cosmeticItem = _convertToCosmeticItem(products[index]);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailPage(item: cosmeticItem),
                ),
              );
            },
          ),
          childCount: products.length,
        ),
      ),
    );
  }

  /// Convert ProductEntity to CosmeticItem for ProductDetailPage
  CosmeticItem _convertToCosmeticItem(ProductEntity product) {
    return CosmeticItem(
      title: product.title,
      rating: product.rating,
      category: product.category ?? product.brandName,
      priceRange: product.priceRange,
      supportingText: product.brandName,
      productId: product.productId,
      skuId: product.skuId,
    );
  }
}

/// Promotional graphic widget
class _DeliveryTruckGraphic extends StatelessWidget {
  const _DeliveryTruckGraphic();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 88,
          height: 62,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(10),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_shipping, size: 26, color: Color(0xFF4B7BFF)),
              SizedBox(width: 4),
              Icon(
                Icons.inventory_2_rounded,
                size: 22,
                color: Color(0xFF36C1FF),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 0.5,
            ),
          ),
          child: const Text(
            'Free',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
