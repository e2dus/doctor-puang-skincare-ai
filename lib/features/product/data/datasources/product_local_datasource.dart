import '../models/product_model.dart';

/// Local data source for product operations (in-memory storage)
/// In a production app, this would use SharedPreferences or a local database
abstract class ProductLocalDataSource {
  /// Get liked products
  List<ProductModel> getLikedProducts();

  /// Add to liked products
  void likeProduct(ProductModel product);

  /// Remove from liked products
  void unlikeProduct(ProductModel product);

  /// Check if product is liked
  bool isLiked(ProductModel product);

  /// Get cart products
  List<ProductModel> getCartProducts();

  /// Add to cart
  void addToCart(ProductModel product);

  /// Remove from cart
  void removeFromCart(String title);

  /// Clear cart
  void clearCart();

  /// Get blocked products
  List<ProductModel> getBlockedProducts();

  /// Block product
  void blockProduct(ProductModel product);

  /// Unblock product
  void unblockProduct(ProductModel product);

  /// Check if product is blocked
  bool isBlocked(ProductModel product);

  /// Get no-recommend products
  List<ProductModel> getNoRecommendProducts();

  /// Add to no-recommend
  void addNoRecommend(ProductModel product);

  /// Remove from no-recommend
  void removeNoRecommend(ProductModel product);

  /// Check if product is in no-recommend
  bool isNoRecommend(ProductModel product);
}

/// In-memory implementation of ProductLocalDataSource
class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  final List<ProductModel> _likedProducts = [];
  final List<ProductModel> _cartProducts = [];
  final List<ProductModel> _blockedProducts = [];
  final List<ProductModel> _noRecommendProducts = [];

  @override
  List<ProductModel> getLikedProducts() => List.from(_likedProducts);

  @override
  void likeProduct(ProductModel product) {
    if (!_likedProducts.any((p) => p.title == product.title)) {
      _likedProducts.add(product);
    }
  }

  @override
  void unlikeProduct(ProductModel product) {
    _likedProducts.removeWhere((p) => p.title == product.title);
  }

  @override
  bool isLiked(ProductModel product) {
    return _likedProducts.any((p) => p.title == product.title);
  }

  @override
  List<ProductModel> getCartProducts() => List.from(_cartProducts);

  @override
  void addToCart(ProductModel product) {
    _cartProducts.add(product);
  }

  @override
  void removeFromCart(String title) {
    _cartProducts.removeWhere((p) => p.title == title);
  }

  @override
  void clearCart() {
    _cartProducts.clear();
  }

  @override
  List<ProductModel> getBlockedProducts() => List.from(_blockedProducts);

  @override
  void blockProduct(ProductModel product) {
    if (!_blockedProducts.any((p) => p.title == product.title)) {
      _blockedProducts.add(product);
    }
  }

  @override
  void unblockProduct(ProductModel product) {
    _blockedProducts.removeWhere((p) => p.title == product.title);
  }

  @override
  bool isBlocked(ProductModel product) {
    return _blockedProducts.any((p) => p.title == product.title);
  }

  @override
  List<ProductModel> getNoRecommendProducts() => List.from(_noRecommendProducts);

  @override
  void addNoRecommend(ProductModel product) {
    if (!_noRecommendProducts.any((p) => p.title == product.title)) {
      _noRecommendProducts.add(product);
    }
  }

  @override
  void removeNoRecommend(ProductModel product) {
    _noRecommendProducts.removeWhere((p) => p.title == product.title);
  }

  @override
  bool isNoRecommend(ProductModel product) {
    return _noRecommendProducts.any((p) => p.title == product.title);
  }
}

