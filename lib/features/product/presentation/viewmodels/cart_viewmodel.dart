/// ============================================================================
/// CART VIEWMODEL
/// ============================================================================
///
/// Manages the shopping cart state.
/// This is a single-responsibility ViewModel for cart operations only.
///
/// ## Usage
/// ```dart
/// // Get cart items
/// final cartItems = ref.watch(cartProvider);
///
/// // Add item to cart
/// ref.read(cartProvider.notifier).addItem(product);
///
/// // Remove item from cart
/// ref.read(cartProvider.notifier).removeItem(productTitle);
/// ```
/// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/product_entity.dart';

/// Notifier for cart state management
class CartNotifier extends Notifier<List<ProductEntity>> {
  static const String _storageKey = 'cart_items';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isInitialized = false;
  Future<void>? _initializationFuture;

  @override
  List<ProductEntity> build() {
    // 초기화 시 저장된 cart 로드
    _initializationFuture = _loadCart();
    return [];
  }

  /// 저장된 cart 로드
  Future<void> _loadCart() async {
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
      _isInitialized = true;
    } catch (e) {
      print('❌ Failed to load cart: $e');
      _isInitialized = true; // 에러가 발생해도 초기화 완료로 표시
    }
  }

  /// 현재 cart를 저장소에 저장
  Future<void> _saveCart() async {
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
      print('❌ Failed to save cart: $e');
    }
  }

  /// Add item to cart
  Future<void> addItem(ProductEntity item) async {
    // 초기화가 완료될 때까지 기다림
    if (!_isInitialized && _initializationFuture != null) {
      await _initializationFuture;
    }
    
    // 중복 체크: 이미 장바구니에 있는지 확인
    if (state.any((i) => i.title == item.title)) {
      print('⚠️ Item already in cart: ${item.title}');
      return;
    }
    
    state = [...state, item];
    await _saveCart();
  }

  /// Remove item from cart by title
  Future<void> removeItem(String title) async {
    // 초기화가 완료될 때까지 기다림
    if (!_isInitialized && _initializationFuture != null) {
      await _initializationFuture;
    }
    
    state = state.where((item) => item.title != title).toList();
    await _saveCart();
  }

  /// Clear all items from cart
  Future<void> clearCart() async {
    // 초기화가 완료될 때까지 기다림
    if (!_isInitialized && _initializationFuture != null) {
      await _initializationFuture;
    }
    
    state = [];
    await _saveCart();
  }

  /// Check if product is in cart
  bool isInCart(ProductEntity item) {
    return state.any((i) => i.title == item.title);
  }

  /// Get total number of items in cart
  int get itemCount => state.length;
}

/// Provider for cart state
final cartProvider = NotifierProvider<CartNotifier, List<ProductEntity>>(() {
  return CartNotifier();
});
