/// ============================================================================
/// BLOCKED PRODUCTS VIEWMODEL
/// ============================================================================
///
/// Manages the blocked products state.
/// Blocked products are hidden from recommendations.
///
/// ## Usage
/// ```dart
/// // Get blocked items
/// final blockedItems = ref.watch(blockedProductsProvider);
///
/// // Block product
/// ref.read(blockedProductsProvider.notifier).blockProduct(product);
///
/// // Check if blocked
/// final isBlocked = ref.read(blockedProductsProvider.notifier).isBlocked(product);
/// ```
/// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/product_entity.dart';

/// Notifier for blocked products state
class BlockedProductsNotifier extends Notifier<List<ProductEntity>> {
  static const String _storageKey = 'blocked_products';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  List<ProductEntity> build() {
    // 초기화 시 저장된 blocked products 로드
    _loadBlockedProducts();
    return [];
  }

  /// 저장된 blocked products 로드
  Future<void> _loadBlockedProducts() async {
    try {
      final jsonString = await _storage.read(key: _storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final jsonList = jsonDecode(jsonString) as List;
        final items = jsonList
            .map(
              (item) => ProductEntity(
                productId: item['productId'] ?? '',
                title: item['title'] ?? '',
                brandName: item['brandName'] ?? '',
                rating: (item['rating'] ?? 0).toDouble(),
                reviews: item['reviews'] ?? 0,
                category: item['category'],
                priceRange: item['priceRange'] ?? '',
                imageUrl: item['imageUrl'],
                targetUrl: item['targetUrl'],
                skuId: item['skuId'],
                score: item['score'] != null
                    ? (item['score'] as num).toDouble()
                    : null,
              ),
            )
            .toList();
        state = items;
      }
    } catch (e) {
      print('❌ Failed to load blocked products: $e');
    }
  }

  /// 현재 blocked products를 저장소에 저장
  Future<void> _saveBlockedProducts() async {
    try {
      final jsonList = state
          .map(
            (item) => {
              'productId': item.productId,
              'title': item.title,
              'brandName': item.brandName,
              'rating': item.rating,
              'reviews': item.reviews,
              'category': item.category,
              'priceRange': item.priceRange,
              'imageUrl': item.imageUrl,
              'targetUrl': item.targetUrl,
              'skuId': item.skuId,
              'score': item.score,
            },
          )
          .toList();
      await _storage.write(key: _storageKey, value: jsonEncode(jsonList));
    } catch (e) {
      print('❌ Failed to save blocked products: $e');
    }
  }

  /// Block a product
  void blockProduct(ProductEntity item) {
    if (!isBlocked(item)) {
      state = [...state, item];
      _saveBlockedProducts();
    }
  }

  /// Unblock a product
  void unblockProduct(ProductEntity item) {
    state = state.where((blocked) => blocked.title != item.title).toList();
    _saveBlockedProducts();
  }

  /// Check if product is blocked
  bool isBlocked(ProductEntity item) {
    return state.any((blocked) => blocked.title == item.title);
  }

  /// Get count of blocked products
  int get blockedCount => state.length;

  /// Clear all blocked products
  void clearAll() {
    state = [];
  }
}

/// Provider for blocked products
final blockedProductsProvider =
    NotifierProvider<BlockedProductsNotifier, List<ProductEntity>>(() {
      return BlockedProductsNotifier();
    });
