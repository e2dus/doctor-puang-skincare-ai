import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobileprogramming_groupproject_2025/features/liked_products/domain/entities/cosmetic_item_entity.dart';

/// Local data source for liked products (persistent storage using SharedPreferences)
class LikedProductsLocalDataSource {
  static const String _likedProductsKey = 'liked_products';

  /// Get SharedPreferences instance
  Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  /// Get all liked products
  Future<List<CosmeticItemEntity>> getLikedProducts() async {
    try {
      final prefs = await _prefs;
      final jsonString = prefs.getString(_likedProductsKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => CosmeticItemEntity.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error loading liked products: $e');
      return [];
    }
  }

  /// Save a liked product
  Future<void> saveLikedProduct(CosmeticItemEntity product) async {
    try {
      final products = await getLikedProducts();
      if (!products.any((p) => p.title == product.title)) {
        products.add(product);
        await _saveProducts(products);
      }
    } catch (e) {
      print('❌ Error saving liked product: $e');
    }
  }

  /// Remove a liked product
  Future<void> removeLikedProduct(CosmeticItemEntity product) async {
    try {
      final products = await getLikedProducts();
      products.removeWhere((p) => p.title == product.title);
      await _saveProducts(products);
    } catch (e) {
      print('❌ Error removing liked product: $e');
    }
  }

  /// Check if a product is liked
  Future<bool> isLiked(CosmeticItemEntity product) async {
    try {
      final products = await getLikedProducts();
      return products.any((p) => p.title == product.title);
    } catch (e) {
      print('❌ Error checking if product is liked: $e');
      return false;
    }
  }

  /// Save products list to SharedPreferences
  Future<void> _saveProducts(List<CosmeticItemEntity> products) async {
    final prefs = await _prefs;
    final jsonList = products.map((p) => p.toJson()).toList();
    final jsonString = json.encode(jsonList);
    await prefs.setString(_likedProductsKey, jsonString);
  }
}

