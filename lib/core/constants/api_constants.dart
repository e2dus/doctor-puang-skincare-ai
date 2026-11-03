/// ============================================================================
/// API CONSTANTS
/// ============================================================================
///
/// Central configuration for all API endpoints and URLs.
///
/// ## Usage
/// ```dart
/// import 'api_constants.dart';
///
/// final url = '${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}';
/// ```
///
/// ## Modification
/// When adding new endpoints:
/// 1. Add a new static const field
/// 2. Use consistent naming: {resource}{Action}Endpoint
/// 3. Include leading slash
/// ============================================================================

class ApiConstants {
  // Private constructor prevents instantiation
  ApiConstants._();

  // === Base URLs ===

  /// Main backend server URL
  static const String baseUrl = 'http://43.203.250.50:8080';

  /// OpenRouter AI API URL
  static const String openRouterBaseUrl = 'https://openrouter.ai/api/v1';

  // === Auth Endpoints ===

  /// POST: User login
  static const String loginEndpoint = '/users/login';

  /// POST: User registration
  static const String signUpEndpoint = '/users/register';

  /// POST: Refresh access token
  static const String refreshTokenEndpoint = '/users/refresh';

  // === User Endpoints ===

  /// GET: Get current user profile
  static const String userProfileEndpoint = '/users/user';

  /// PUT: Update user profile
  static const String updateUserProfileEndpoint = '/users/user';

  /// POST: Save user skin info
  static const String skinInfoEndpoint = '/users/skin-info';

  // === Product Endpoints ===

  /// GET: Fetch product categories
  static const String productsCategoriesEndpoint = '/products/categories';

  /// GET: Fetch product rankings
  /// Query params: top_n (int), category (string, optional)
  static const String productsRankingEndpoint = '/products/ranking';

  /// GET: Fetch product detail information
  /// Query params: productId (string), preferredSku (string)
  static const String productsDetailEndpoint = '/products/detail';

  /// GET: Fetch product detail by product_id (MongoDB cache)
  /// Path param: product_id (string)
  static const String productsByIdEndpoint = '/products';

  /// GET: Fetch similar products for a product
  /// Path param: product_id (string)
  static const String productsSimilarEndpoint = '/products';

  /// GET: Search products by name
  /// Query params: query (string), top_n (int, optional, default 1)
  static const String productsSearchEndpoint = '/products/search';
}
