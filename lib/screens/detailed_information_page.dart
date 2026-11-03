import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobileprogramming_groupproject_2025/features/product/presentation/viewmodels/liked_products_viewmodel.dart';
import 'package:mobileprogramming_groupproject_2025/features/product/presentation/viewmodels/cart_viewmodel.dart';
import 'package:mobileprogramming_groupproject_2025/models/cosmetic_item.dart';

//void main() => runApp(const MyApp());

final _currency = NumberFormat.currency(
  locale: 'ko_KR',
  symbol: '₩',
  decimalDigits: 0,
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skincare',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.purple,
        appBarTheme: const AppBarTheme(centerTitle: false),
      ),
      home: const HomePage(),
    );
  }
}

/* ----------------------------- MODEL LAYER ----------------------------- */

@immutable
class Cosmetic {
  final String id;
  final String name;
  final String category;
  final String brand;
  final int price; // KRW
  final String size;
  final double rating; // 0..5
  final int reviewCount;
  final List<String> skinTypes;
  final List<String> keyIngredients;
  final List<String> warnings;
  final String description;
  final String howToUse;
  final String imageUrl;

  const Cosmetic({
    required this.id,
    required this.name,
    required this.category,
    required this.brand,
    required this.price,
    required this.size,
    required this.rating,
    required this.reviewCount,
    required this.skinTypes,
    required this.keyIngredients,
    required this.warnings,
    required this.description,
    required this.howToUse,
    required this.imageUrl,
  }) : assert(rating >= 0 && rating <= 5, 'rating must be 0..5'),
       assert(price >= 0, 'price must be >= 0');

  bool matchesBudget(int max) => price <= max;

  Cosmetic copyWith({
    String? id,
    String? name,
    String? category,
    String? brand,
    int? price,
    String? size,
    double? rating,
    int? reviewCount,
    List<String>? skinTypes,
    List<String>? keyIngredients,
    List<String>? warnings,
    String? description,
    String? howToUse,
    String? imageUrl,
  }) {
    return Cosmetic(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      size: size ?? this.size,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      skinTypes: skinTypes ?? this.skinTypes,
      keyIngredients: keyIngredients ?? this.keyIngredients,
      warnings: warnings ?? this.warnings,
      description: description ?? this.description,
      howToUse: howToUse ?? this.howToUse,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory Cosmetic.fromJson(Map<String, dynamic> json) => Cosmetic(
    id: json['id'] as String,
    name: json['name'] as String,
    category: json['category'] as String? ?? 'Unknown',
    brand: json['brand'] as String? ?? 'Unknown',
    price: (json['price'] as num).toInt(),
    size: json['size'] as String? ?? '',
    rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
    skinTypes: (json['skinTypes'] as List<dynamic>? ?? const []).cast<String>(),
    keyIngredients: (json['keyIngredients'] as List<dynamic>? ?? const [])
        .cast<String>(),
    warnings: (json['warnings'] as List<dynamic>? ?? const []).cast<String>(),
    description: json['description'] as String? ?? '',
    howToUse: json['howToUse'] as String? ?? '',
    imageUrl: json['imageUrl'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'brand': brand,
    'price': price,
    'size': size,
    'rating': rating,
    'reviewCount': reviewCount,
    'skinTypes': skinTypes,
    'keyIngredients': keyIngredients,
    'warnings': warnings,
    'description': description,
    'howToUse': howToUse,
    'imageUrl': imageUrl,
  };
}

/* ------------------------------ UI: HOME ------------------------------- */

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static final List<Cosmetic> items = [
    const Cosmetic(
      id: 'c1',
      name: 'cosmetics 1',
      category: 'Lotion',
      brand: 'Brand A',
      price: 30000,
      size: '150ml',
      rating: 4.5,
      reviewCount: 128,
      skinTypes: ['dry', 'normal'],
      keyIngredients: ['Hyaluronic Acid', 'Ceramide'],
      warnings: ['Fragrance'],
      description: '수분 보충에 초점을 둔 라이트 로션으로 데일리 사용에 적합합니다.',
      howToUse: '토너 후 펌프 1~2회, 얼굴과 목에 부드럽게 흡수시킵니다.',
      imageUrl: 'https://picsum.photos/seed/c1/600/400',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Home Page',
          style: TextStyle(
            fontFamily: 'HelveticaNeue93',
            fontWeight: FontWeight.w900,
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 20,
          ),
        ),
        actions: const [_CartAction()],
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            return _CosmeticTile(
              item: item,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => DetailPage(item: item)),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: _BottomBar(
        currentIndex: 1,
        onTap: (i) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('탭 선택: $i')));
        },
      ),
    );
  }
}

class _CartAction extends StatelessWidget {
  const _CartAction();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {},
      icon: const Icon(Icons.shopping_cart_outlined),
      tooltip: '장바구니',
    );
  }
}

class _CosmeticTile extends StatelessWidget {
  final Cosmetic item;
  final VoidCallback onTap;
  const _CosmeticTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              AspectRatio(aspectRatio: 1, child: _NetImage(url: item.imageUrl)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text('${item.category} · ${item.brand}'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber.shade600,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text('${item.rating} (${item.reviewCount})'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(_currency.format(item.price)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.favorite_border),
                tooltip: '위시리스트',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------------------------- UI: DETAIL PAGE -------------------------- */

class DetailPage extends ConsumerStatefulWidget {
  final Cosmetic item;
  const DetailPage({super.key, required this.item});

  @override
  ConsumerState<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends ConsumerState<DetailPage> {
  bool _isLiked() {
    final c = widget.item;
    final likedItems = ref.watch(likedProductsProvider);
    return likedItems.any((item) => item.title == c.name);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.item;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Description',
          style: TextStyle(
            fontFamily: 'HelveticaNeue93',
            fontWeight: FontWeight.w900,
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 20,
          ),
        ),
        actions: const [_CartAction()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _NetImage(url: c.imageUrl),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 6),
                        Text('${c.brand} · ${c.category} · ${c.size}'),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text('${c.rating}  •  ${c.reviewCount} reviews'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        _currency.format(c.price),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: Icon(
                          _isLiked() ? Icons.favorite : Icons.favorite_border,
                          color: _isLiked() ? Colors.red : null,
                        ),
                        onPressed: () {
                          final cosmeticItem = CosmeticItem(
                            title: c.name,
                            rating: c.rating,
                            category: c.category,
                            priceRange: _currency.format(c.price),
                            supportingText: c.description,
                          );
                          ref
                              .read(likedProductsProvider.notifier)
                              .toggleLike(cosmeticItem.toProductEntity());
                          setState(() {}); // Trigger rebuild
                        },
                        tooltip: '좋아요',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Section(
                title: '주요 성분',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: c.keyIngredients
                      .map((e) => Chip(label: Text(e)))
                      .toList(),
                ),
              ),
              _Section(
                title: '권장 피부 타입',
                child: Wrap(
                  spacing: 8,
                  children: c.skinTypes
                      .map((e) => Chip(label: Text(e)))
                      .toList(),
                ),
              ),
              if (c.warnings.isNotEmpty)
                _Section(
                  title: '주의 성분',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: c.warnings.map((w) => Text('• $w')).toList(),
                  ),
                ),
              _Section(title: '제품 설명', child: Text(c.description)),
              _Section(title: '사용 방법', child: Text(c.howToUse)),
              _Section(
                title: '유사 제품 추천',
                child: SizedBox(
                  height: 140,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 5,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => _RecoCard(
                      index: i,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DetailPage(
                              item: c.copyWith(
                                id: 'reco$i',
                                name: '추천 ${i + 1}',
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  final cosmeticItem = CosmeticItem(
                    title: c.name,
                    rating: c.rating,
                    category: c.category,
                    priceRange: _currency.format(c.price),
                    supportingText: c.description,
                  );
                  await ref
                      .read(cartProvider.notifier)
                      .addItem(cosmeticItem.toProductEntity());
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${c.name}이(가) 장바구니에 추가되었습니다'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('장바구니 담기'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ------------------------------ REUSABLE UI ---------------------------- */

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _RecoCard extends StatelessWidget {
  final int index;
  final VoidCallback? onTap;
  const _RecoCard({required this.index, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _NetImage(
                  url: 'https://picsum.photos/seed/reco$index/300/200',
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '추천 ${index + 1}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _NetImage extends StatelessWidget {
  final String url;
  const _NetImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return ColoredBox(
          color: Theme.of(
            context,
          ).colorScheme.surfaceVariant.withValues(alpha: 0.3),
          child: const Center(child: CircularProgressIndicator()),
        );
      },
      errorBuilder: (context, error, stack) {
        return ColoredBox(
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: const Center(child: Icon(Icons.broken_image_outlined)),
        );
      },
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  const _BottomBar({this.currentIndex = 0, this.onTap});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline),
          label: 'ChatBot',
        ),
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.history), label: 'History'),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          label: 'Setting',
        ),
      ],
    );
  }
}
