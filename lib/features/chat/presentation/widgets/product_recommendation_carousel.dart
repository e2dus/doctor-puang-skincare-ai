import 'package:flutter/material.dart';
import 'package:mobileprogramming_groupproject_2025/core/theme/app_colors.dart';
import 'package:mobileprogramming_groupproject_2025/core/constants/api_constants.dart';
import 'package:mobileprogramming_groupproject_2025/models/cosmetic_item.dart';
import 'package:mobileprogramming_groupproject_2025/screens/product_detail_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// 제품 추천 정보 모델
class ProductRecommendation {
  final String name; // 간략화된 제품명 (검색용)
  final String fullName; // 전체 제품명 (표시용)
  final String category;
  final String description;
  final String? imageUrl;
  final String? price; // 가격 추가
  final String? brandName; // 브랜드명 추가
  final String? productId; // 제품 ID (상세페이지 이동용)
  final String? skuId; // SKU ID (상세페이지 이동용)

  ProductRecommendation({
    required this.name,
    required this.fullName,
    required this.category,
    required this.description,
    this.imageUrl,
    this.price,
    this.brandName,
    this.productId,
    this.skuId,
  });

  ProductRecommendation copyWith({
    String? imageUrl,
    String? price,
    String? brandName,
    String? productId,
    String? skuId,
    String? fullName,
    String? description,
  }) {
    return ProductRecommendation(
      name: name,
      fullName: fullName ?? this.fullName,
      category: category,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      brandName: brandName ?? this.brandName,
      productId: productId ?? this.productId,
      skuId: skuId ?? this.skuId,
    );
  }

  /// 검색 쿼리 생성: 브랜드명과 제품명을 포함하여 검색 정확도 향상
  String get searchQuery {
    // 브랜드명이 있으면 브랜드명 + 제품명으로 검색, 없으면 제품명만 사용
    if (brandName != null && brandName!.isNotEmpty) {
      return '$brandName $fullName';
    }
    return fullName;
  }
}

/// AI 응답 텍스트에서 제품 추천 정보를 파싱하는 함수
/// [chatId]를 받아서 Budget chat인지 확인하여 파싱 로직 결정
List<ProductRecommendation> parseProductRecommendations(
  String text, {
  String? chatId,
}) {
  final List<ProductRecommendation> products = [];

  // 디버깅: 텍스트 확인
  if (text.contains('Recommended Products') || text.contains('###')) {
    debugPrint('파싱 시도 - 텍스트 길이: ${text.length}');
    debugPrint(
      '텍스트 시작 부분: ${text.substring(0, text.length > 500 ? 500 : text.length)}',
    );
  }

  // 더 간단하고 직접적인 방법: "### 숫자." 로 시작하는 모든 섹션 찾기
  final sectionPattern = RegExp(
    r'###\s*\d+\.\s*(.*?)(?=###\s*\d+\.|$)',
    dotAll: true,
  );

  final sections = sectionPattern.allMatches(text);
  // 섹션이 있을 때만 디버그 출력
  if (sections.isNotEmpty) {
    debugPrint('섹션 개수: ${sections.length}');
  }

  for (final sectionMatch in sections) {
    final sectionText = sectionMatch.group(1) ?? '';
    if (sectionText.isEmpty) continue;

    // 카테고리 추출: 첫 줄 또는 **로 감싸진 부분
    String category = '';
    final categoryMatch1 = RegExp(r'^\*\*([^*]+)\*\*').firstMatch(sectionText);
    if (categoryMatch1 != null) {
      category = categoryMatch1.group(1)?.trim() ?? '';
    } else {
      // 별표 없이 첫 줄이 카테고리일 수 있음
      final firstLine = sectionText.split('\n').first.trim();
      if (firstLine.isNotEmpty && !firstLine.contains('Recommended Products')) {
        category = firstLine;
      }
    }

    // 카테고리에서 별표 제거
    category = category.replaceAll(RegExp(r'\*\*?'), '').trim();

    if (category.isEmpty) continue;

    debugPrint('카테고리 발견: $category');

    // 카테고리에서 괄호 안의 영어 제거
    final cleanCategory = category
        .replaceAll(RegExp(r'\s*\([^)]+\)\s*'), '')
        .trim();

    // "**Recommended Products:**" 또는 "Recommended Products:" 찾기
    String? productNames;
    final productPattern1 = RegExp(
      r'\*\*Recommended Products:\*\*\s*(.*?)(?=\*\*Reason:|\*\*이유:|$)',
      dotAll: true,
    );
    final productMatch1 = productPattern1.firstMatch(sectionText);
    if (productMatch1 != null) {
      productNames = productMatch1.group(1)?.trim();
    } else {
      // 별표 없이 시도
      final productPattern2 = RegExp(
        r'Recommended Products:\s*(.*?)(?=Reason:|이유:|$)',
        dotAll: true,
        caseSensitive: false,
      );
      final productMatch2 = productPattern2.firstMatch(sectionText);
      productNames = productMatch2?.group(1)?.trim();
    }

    if (productNames == null || productNames.isEmpty) {
      debugPrint('제품명을 찾을 수 없음 - 카테고리: $cleanCategory');
      continue;
    }

    debugPrint('제품명 텍스트: $productNames');

    // "**Reason:**" 또는 "Reason:" 찾기
    String description = '';
    final reasonPattern1 = RegExp(
      r'\*\*Reason:\*\*\s*(.*?)(?=###|$)',
      dotAll: true,
    );
    final reasonMatch1 = reasonPattern1.firstMatch(sectionText);
    if (reasonMatch1 != null) {
      description = reasonMatch1.group(1)?.trim() ?? '';
    } else {
      final reasonPattern2 = RegExp(
        r'Reason:\s*(.*?)(?=###|$)',
        dotAll: true,
        caseSensitive: false,
      );
      final reasonMatch2 = reasonPattern2.firstMatch(sectionText);
      description = reasonMatch2?.group(1)?.trim() ?? '';
    }

    // 여러 제품이 있을 수 있으므로 쉼표로 분리
    final productList = productNames
        .split(',')
        .map((p) => p.trim())
        .where(
          (p) => p.isNotEmpty && !p.startsWith('**') && !p.startsWith('###'),
        )
        .toList();

    debugPrint('파싱된 제품 개수: ${productList.length}');

    // Budget chat의 경우 각 카테고리당 최대 7개 제품 파싱 (대체 제품용)
    // 다른 chat의 경우 첫 번째 제품만 사용
    final isBudgetChat = chatId == 'chatbot_budget_routine';
    final maxProducts = isBudgetChat ? 7 : 1;
    final productsToProcess = productList.take(maxProducts).toList();

    debugPrint(
      '처리할 제품 개수: ${productsToProcess.length} (Budget chat: $isBudgetChat)',
    );

    // 브랜드명 추출하고 제품명 정리, 가격 추출
    for (var productText in productsToProcess) {
      String originalText = productText;

      // 1. 가격 추출: ($Price) 또는 (Price) 형식
      String? price;
      final priceMatch = RegExp(r'\((\$?\d+\.?\d*)\)').firstMatch(productText);
      if (priceMatch != null) {
        price = priceMatch.group(1);
        // 가격 부분 제거
        productText = productText
            .replaceAll(RegExp(r'\s*\([^)]+\)\s*'), '')
            .trim();
      }

      // 2. 브랜드명 추출: [브랜드명] 형식 (반드시 대괄호로 감싸져 있어야 함)
      String? brandName;
      String productName;

      final brandMatch = RegExp(r'\[([^\]]+)\]').firstMatch(productText);
      if (brandMatch != null) {
        brandName = brandMatch.group(1)?.trim();
        // 브랜드명 부분 제거
        productName = productText.replaceAll(RegExp(r'\[.*?\]\s*'), '').trim();
      } else {
        // [브랜드명] 형식이 없으면, 일반적인 브랜드명 패턴 시도
        // 예: "Fresh Soy Face Cleanser" -> "Fresh"가 브랜드명일 수 있음
        // 하지만 이는 추정이므로, 가능하면 [브랜드명] 형식을 사용하도록 프롬프트에서 요청
        productName = productText.trim();

        // 일반적인 브랜드명 패턴: 첫 단어가 짧고(10자 이하), 제품명이 여러 단어인 경우
        final words = productName.split(' ');
        if (words.length >= 3 && words[0].length <= 10) {
          // 첫 단어를 브랜드명으로 추정
          brandName = words[0];
          productName = words.sublist(1).join(' ');
        }
      }

      // 제품명 정리: 여러 공백을 하나로
      final fullProductName = productName
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      // 브랜드명이 없으면 경고
      if (brandName == null || brandName.isEmpty) {
        debugPrint('⚠️ 브랜드명을 찾을 수 없음: $originalText');
      }

      // 제품명 간략화: 한 두 단어로 (검색용, 첫 번째와 두 번째 단어만 사용)
      final words = fullProductName.split(' ');
      String simplifiedName = fullProductName;
      if (words.length > 2) {
        // 첫 두 단어만 사용
        simplifiedName = words.take(2).join(' ');
      }

      if (fullProductName.isNotEmpty && fullProductName.length > 2) {
        products.add(
          ProductRecommendation(
            name: simplifiedName, // 검색용 간략화된 이름
            fullName:
                fullProductName, // 브랜드명 제외한 전체 제품명 (예: "Mini Pure Skin Face Cleanser")
            category: cleanCategory,
            description: description,
            price: price,
            brandName: brandName,
          ),
        );
        debugPrint(
          '✅ 제품 추가: 브랜드=$brandName, fullName=$fullProductName (간략화: $simplifiedName, 카테고리: $cleanCategory, 가격: $price)',
        );
      }
    }
  }

  // 기존 형식도 지원: "### **추천 화장품**" 섹션
  if (products.isEmpty) {
    final recommendationSection = RegExp(
      r'###\s*\*\*추천 화장품\*\*.*?(?=###|$)',
      dotAll: true,
    ).firstMatch(text);

    if (recommendationSection != null) {
      final sectionText = recommendationSection.group(0) ?? '';

      // 각 제품 정보 추출 (숫자. **카테고리** 형식)
      final productPattern = RegExp(
        r'\d+\.\s*\*\*([^*]+)\*\*\s*\n\s*\*\*제품명:\*\*\s*(?:\[([^\]]+)\]\s*)?([^\n]+)\s*\n\s*\*\*이유:\*\*\s*([^\n]+)',
        dotAll: true,
      );

      final matches = productPattern.allMatches(sectionText);

      for (final match in matches) {
        final category = match.group(1)?.trim() ?? '';
        final brand = match.group(2)?.trim();
        var productName = match.group(3)?.trim() ?? '';
        final description = match.group(4)?.trim() ?? '';

        if (category.isNotEmpty && productName.isNotEmpty) {
          final cleanCategory = category
              .replaceAll(RegExp(r'\s*\([^)]+\)\s*'), '')
              .trim();

          // 제품명 간략화: 한 두 단어로 (첫 번째와 두 번째 단어만 사용)
          final words = productName.split(' ');
          String simplifiedName = productName;
          if (words.length > 2) {
            // 첫 두 단어만 사용
            simplifiedName = words.take(2).join(' ');
          }

          products.add(
            ProductRecommendation(
              name: simplifiedName, // 검색용 간략화된 이름
              fullName: productName, // 표시용 전체 이름
              category: cleanCategory,
              description: description.isNotEmpty
                  ? description
                  : (brand != null ? '$brand 제품' : ''),
              brandName: brand,
            ),
          );
        }
      }
    }
  }

  return products;
}

Future<String?> fetchProductImageUrlFromServer(String query) async {
  final dio = Dio();
  dio.options.baseUrl = 'http://43.203.250.50:8080';
  dio.options.headers = {'Content-Type': 'application/json'};

  try {
    debugPrint('🔍 제품 이미지 검색 시작: query="$query"');

    // ranking 엔드포인트에서 제품 찾기
    final response = await dio.get(
      '/products/ranking',
      queryParameters: {'top_n': 1000}, // 더 많은 제품 가져오기
    );

    if (response.statusCode == 200) {
      final data = response.data;
      final List<dynamic> ranking = data['ranking'] ?? [];

      debugPrint('📦 서버에서 ${ranking.length}개 제품 가져옴');

      // 쿼리를 소문자로 변환하고 단어로 분리
      final queryLower = query.toLowerCase().trim();
      final queryWords = queryLower
          .split(' ')
          .where((w) => w.isNotEmpty)
          .toList();

      debugPrint('🔎 검색 단어: $queryWords');

      // 브랜드명 추출 (첫 번째 단어가 보통 브랜드명)
      String? targetBrand;
      if (queryWords.isNotEmpty) {
        targetBrand = queryWords.first;
      }

      // Fallback용: 같은 브랜드의 다른 제품 이미지 저장
      String? fallbackImageUrl;

      // 제품명이나 브랜드명에 쿼리가 포함된 제품 찾기
      for (var item in ranking) {
        final productName = (item['product_name'] ?? '')
            .toString()
            .toLowerCase();
        final brandName = (item['brand_name'] ?? '').toString().toLowerCase();
        final imageUrl = item['image_url'];

        // 이미지 URL이 없으면 건너뛰기
        if (imageUrl == null || imageUrl.toString().isEmpty) {
          continue;
        }

        // Fallback: 같은 브랜드의 제품 이미지 저장
        if (targetBrand != null &&
            brandName.contains(targetBrand) &&
            fallbackImageUrl == null) {
          fallbackImageUrl = imageUrl as String;
          debugPrint(
            '💾 Fallback 이미지 저장: ${item['product_name']} (${item['brand_name']})',
          );
        }

        // 1. 정확한 쿼리 매칭 (제품명 또는 브랜드명에 전체 쿼리가 포함)
        if (productName.contains(queryLower) ||
            brandName.contains(queryLower)) {
          debugPrint(
            '✅ 매칭 성공 (전체 쿼리): ${item['product_name']} (${item['brand_name']})',
          );
          return imageUrl as String;
        }

        // 2. 쿼리의 모든 단어가 제품명에 포함되는지 확인
        bool allWordsMatch = queryWords.isNotEmpty;
        for (var word in queryWords) {
          if (!productName.contains(word) && !brandName.contains(word)) {
            allWordsMatch = false;
            break;
          }
        }

        if (allWordsMatch) {
          debugPrint(
            '✅ 매칭 성공 (단어 매칭): ${item['product_name']} (${item['brand_name']})',
          );
          return imageUrl as String;
        }

        // 3. 브랜드명이 정확히 일치하고 제품명의 첫 단어가 일치하는지 확인
        if (queryWords.length >= 2) {
          final firstWord = queryWords.first;
          final secondWord = queryWords[1];

          if (brandName.contains(firstWord) &&
              productName.contains(secondWord)) {
            debugPrint(
              '✅ 매칭 성공 (브랜드+제품명): ${item['product_name']} (${item['brand_name']})',
            );
            return imageUrl as String;
          }
        }
      }

      // 정확한 매칭을 찾지 못했지만 같은 브랜드의 제품이 있으면 그것을 반환
      if (fallbackImageUrl != null) {
        debugPrint('⚠️ 정확한 매칭 실패, 같은 브랜드 제품 이미지 사용: query="$query"');
        return fallbackImageUrl;
      }

      debugPrint('❌ 매칭되는 제품을 찾지 못함: query="$query"');
    } else {
      debugPrint('❌ 서버 응답 오류: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('❌ 제품 이미지 가져오기 실패: $e');
  }

  // 끝까지 찾았는데 이미지가 없으면 null
  return null;
}

/// 제품 이름으로 검색하여 product_id 가져오기
/// targetCategory가 제공되면 카테고리 매칭을 우선시 (Budget chat용)
/// targetBrandName이 제공되면 브랜드명 매칭을 우선시 (일반 chat용)
Future<Map<String, String>?> searchProductId(
  String query, {
  String? targetCategory,
  String? targetBrandName,
}) async {
  final dio = Dio();
  dio.options.baseUrl = ApiConstants.baseUrl;
  dio.options.headers = {'Content-Type': 'application/json'};

  try {
    debugPrint(
      '🔍 제품 ID 검색 시작: query="$query"${targetCategory != null ? ', targetCategory="$targetCategory"' : ''}${targetBrandName != null ? ', targetBrand="$targetBrandName"' : ''}',
    );

    final response = await dio.get(
      ApiConstants.productsSearchEndpoint,
      queryParameters: {
        'query': query,
        'top_n': 10, // Budget chat을 위해 더 많은 결과 확인
      },
    );

    if (response.statusCode == 200) {
      final data = response.data;
      final List<dynamic> results = data['results'] ?? [];

      if (results.isNotEmpty) {
        // 타겟 카테고리가 있으면 카테고리가 일치하는 제품을 우선 선택 (Budget chat용)
        if (targetCategory != null && targetCategory.isNotEmpty) {
          final targetCategoryLower = targetCategory.toLowerCase().trim();

          // 먼저 카테고리가 일치하는 제품 찾기
          for (var product in results) {
            final category = (product['primary_category']?.toString() ?? '')
                .toLowerCase()
                .trim();
            if (category == targetCategoryLower ||
                category.contains(targetCategoryLower) ||
                targetCategoryLower.contains(category)) {
              final productId = product['product_id']?.toString();
              final productName = product['product_name']?.toString() ?? '';
              final brandName = product['brand_name']?.toString() ?? '';
              final imageUrl = product['image_url']?.toString();

              debugPrint(
                '✅ 제품 ID 검색 성공 (카테고리 매칭): productId=$productId, productName=$productName, category=$category',
              );

              return {
                'productId': productId ?? '',
                'productName': productName,
                'brandName': brandName,
                'imageUrl': imageUrl ?? '',
                'category': category,
              };
            }
          }
        }

        // 타겟 브랜드명이 있으면 브랜드명이 일치하는 제품을 우선 선택 (일반 chat용)
        if (targetBrandName != null && targetBrandName.isNotEmpty) {
          final targetBrandLower = targetBrandName.toLowerCase().trim();

          // 먼저 브랜드명이 정확히 일치하는 제품 찾기
          for (var product in results) {
            final brandName = (product['brand_name']?.toString() ?? '')
                .toLowerCase()
                .trim();
            if (brandName == targetBrandLower ||
                brandName.contains(targetBrandLower) ||
                targetBrandLower.contains(brandName)) {
              final productId = product['product_id']?.toString();
              final productName = product['product_name']?.toString() ?? '';
              final imageUrl = product['image_url']?.toString();

              debugPrint(
                '✅ 제품 ID 검색 성공 (브랜드 매칭): productId=$productId, productName=$productName, brandName=$brandName',
              );

              return {
                'productId': productId ?? '',
                'productName': productName,
                'brandName': brandName,
                'imageUrl': imageUrl ?? '',
              };
            }
          }
        }

        // 카테고리/브랜드명 매칭 실패 또는 타겟이 없으면 첫 번째 결과 사용
        final product = results.first;
        final productId = product['product_id']?.toString();
        final productName = product['product_name']?.toString() ?? '';
        final brandName = product['brand_name']?.toString() ?? '';
        final imageUrl = product['image_url']?.toString();
        final category = product['primary_category']?.toString() ?? '';

        debugPrint(
          '✅ 제품 ID 검색 성공: productId=$productId, productName=$productName, brandName=$brandName, category=$category',
        );

        return {
          'productId': productId ?? '',
          'productName': productName,
          'brandName': brandName,
          'imageUrl': imageUrl ?? '',
          'category': category,
        };
      }
    }
  } catch (e) {
    debugPrint('❌ 제품 ID 검색 실패: $e');
  }

  return null;
}

/// 제품명이 유사한지 확인하는 헬퍼 함수
bool areProductNamesSimilar(String name1, String name2) {
  // 단어 단위로 비교
  final words1 = name1.split(' ').where((w) => w.length > 2).toSet();
  final words2 = name2.split(' ').where((w) => w.length > 2).toSet();

  // 공통 단어가 50% 이상이면 유사하다고 판단
  final intersection = words1.intersection(words2);
  final union = words1.union(words2);

  if (union.isEmpty) return false;
  return intersection.length / union.length >= 0.5;
}

/// 제품 상세 정보 가져오기 (product_id만으로 - /products/detail 사용)
Future<Map<String, dynamic>?> fetchProductDetailById(String productId) async {
  final dio = Dio();
  dio.options.baseUrl = ApiConstants.baseUrl;
  dio.options.headers = {'Content-Type': 'application/json'};

  try {
    debugPrint('📦 제품 상세 정보 가져오기 (by product_id): productId=$productId');

    // /products/detail 엔드포인트 사용 (preferredSku는 더미 데이터)
    final queryParams = <String, dynamic>{
      'productId': productId,
      'preferredSku': '0', // 더미 데이터
    };

    final response = await dio.get(
      ApiConstants.productsDetailEndpoint,
      queryParameters: queryParams,
    );

    if (response.statusCode == 200) {
      final data = response.data;
      final product = data['product'];

      if (product != null) {
        debugPrint('✅ 제품 상세 정보 가져오기 성공');
        return product as Map<String, dynamic>;
      }
    }
  } catch (e) {
    debugPrint('❌ 제품 상세 정보 가져오기 실패: $e');
  }

  return null;
}

/// 제품 상세 정보 가져오기 (productId와 skuId로 - 파싱 API)
Future<Map<String, dynamic>?> fetchProductDetail(
  String productId,
  String? skuId,
) async {
  final dio = Dio();
  dio.options.baseUrl = ApiConstants.baseUrl;
  dio.options.headers = {'Content-Type': 'application/json'};

  try {
    debugPrint('📦 제품 상세 정보 가져오기 (파싱 API): productId=$productId, skuId=$skuId');

    final queryParams = <String, dynamic>{'productId': productId};
    if (skuId != null && skuId.isNotEmpty) {
      queryParams['preferredSku'] = skuId;
    }

    final response = await dio.get(
      ApiConstants.productsDetailEndpoint,
      queryParameters: queryParams,
    );

    if (response.statusCode == 200) {
      final data = response.data;
      final product = data['product'];

      if (product != null) {
        debugPrint('✅ 제품 상세 정보 가져오기 성공');
        return product as Map<String, dynamic>;
      }
    }
  } catch (e) {
    debugPrint('❌ 제품 상세 정보 가져오기 실패: $e');
  }

  return null;
}

/// 제품 추천 목록에 productId와 skuId 추가 (enrich)
Future<List<ProductRecommendation>> enrichProductRecommendations(
  List<ProductRecommendation> products,
) async {
  final enrichedProducts = <ProductRecommendation>[];

  for (var product in products) {
    // 이미 productId, skuId, imageUrl이 모두 있으면 그대로 사용 (재검색 방지)
    if (product.productId != null &&
        product.productId!.isNotEmpty &&
        product.skuId != null &&
        product.skuId!.isNotEmpty &&
        product.imageUrl != null &&
        product.imageUrl!.isNotEmpty) {
      enrichedProducts.add(product);
      debugPrint(
        '✅ 제품 정보 이미 완료 (재검색 스킵): ${product.fullName} -> productId=${product.productId}, imageUrl=${product.imageUrl}',
      );
      continue;
    }

    // productId는 있지만 skuId가 없는 경우, /products/detail로 상세 정보를 가져와서 skuId를 찾음
    if (product.productId != null && product.productId!.isNotEmpty) {
      try {
        final detailResult = await fetchProductDetailById(product.productId!);
        String? skuId = product.skuId;
        String? imageUrl = product.imageUrl;
        String? detailProductName;
        String? detailBrandName;
        String? detailDescription;

        if (detailResult != null) {
          // skuId 추출: product.skus 배열의 첫 번째 항목에서 skuId 가져오기
          final skus = detailResult['skus'];
          if (skus != null && skus is List && skus.isNotEmpty) {
            final firstSku = skus[0];
            if (firstSku is Map) {
              skuId = firstSku['skuId']?.toString();
            }
          }

          // 상세 정보에서 제품명, 브랜드명, 이미지, 설명 가져오기
          detailProductName = detailResult['product_name']?.toString();
          detailBrandName = detailResult['brand_name']?.toString();
          final detailImageUrl = detailResult['main_image']?.toString();
          detailDescription =
              detailResult['short_description']?.toString() ??
              detailResult['long_description']?.toString();

          if (detailImageUrl != null && detailImageUrl.isNotEmpty) {
            imageUrl = detailImageUrl;
          }

          // AI 추천 제품명(쿼리)과 상세 정보의 제품명이 다른지 확인
          final recommendedNameLower = product.fullName.toLowerCase().trim();
          final detailNameLower = (detailProductName ?? '')
              .toLowerCase()
              .trim();

          // 제품명이 다르면 아예 표시하지 않음
          bool isNameMatch = false;
          if (detailProductName != null && detailProductName.isNotEmpty) {
            // 정확히 일치하거나 포함 관계이거나 유사한 경우만 일치로 판단
            isNameMatch =
                detailNameLower == recommendedNameLower ||
                detailNameLower.contains(recommendedNameLower) ||
                recommendedNameLower.contains(detailNameLower) ||
                areProductNamesSimilar(recommendedNameLower, detailNameLower);
          }

          if (!isNameMatch) {
            debugPrint(
              '❌ 제품명이 다름: 쿼리="${product.fullName}" vs 상세 정보="$detailProductName"',
            );
            debugPrint('   제품 표시 안 함');
            // enrichedProducts에 추가하지 않음 (화면에 표시되지 않음)
          } else {
            // 제품명이 일치하면 상세 정보로 업데이트하여 표시
            enrichedProducts.add(
              product.copyWith(
                skuId: skuId,
                imageUrl: imageUrl,
                fullName: detailProductName ?? product.fullName,
                brandName: detailBrandName ?? product.brandName,
                description: detailDescription ?? product.description,
              ),
            );
            debugPrint(
              '✅ 제품 정보 enrich 완료: $detailProductName -> productId=${product.productId}, skuId=$skuId',
            );
          }
        } else {
          // 상세 정보를 가져오지 못한 경우 제품을 표시하지 않음 (스킵)
          debugPrint('⚠️ 상세 정보를 가져오지 못함, 제품 표시 안 함: ${product.fullName}');
          // enrichedProducts에 추가하지 않음 (화면에 표시되지 않음)
        }

        await Future.delayed(const Duration(milliseconds: 200));
        continue;
      } catch (e) {
        debugPrint('❌ 제품 정보 enrich 오류 (${product.fullName}): $e');
        // 에러 발생 시 제품을 표시하지 않음 (스킵)
        // enrichedProducts에 추가하지 않음 (화면에 표시되지 않음)
        await Future.delayed(const Duration(milliseconds: 200));
        continue;
      }
    }

    try {
      // 1. 제품 이름으로 검색하여 productId 가져오기 (브랜드명 포함)
      final searchResult = await searchProductId(
        product.searchQuery,
        targetBrandName: product.brandName,
      );

      if (searchResult != null &&
          searchResult['productId']?.isNotEmpty == true) {
        final productId = searchResult['productId']!;
        final foundProductName = searchResult['productName'] ?? '';
        final foundBrandName = searchResult['brandName'] ?? '';
        final imageUrl = searchResult['imageUrl'];

        // 브랜드명 매칭 확인 (우선순위 높음)
        bool isBrandMatch = true;
        if (product.brandName != null && product.brandName!.isNotEmpty) {
          final recommendedBrandLower = product.brandName!.toLowerCase().trim();
          final foundBrandLower = foundBrandName.toLowerCase().trim();
          isBrandMatch =
              foundBrandLower.contains(recommendedBrandLower) ||
              recommendedBrandLower.contains(foundBrandLower) ||
              foundBrandLower == recommendedBrandLower;
        }

        // 제품명 매칭 확인
        final recommendedNameLower = product.fullName.toLowerCase().trim();
        final foundNameLower = foundProductName.toLowerCase().trim();

        final isNameMatch =
            foundNameLower.contains(recommendedNameLower) ||
            recommendedNameLower.contains(foundNameLower) ||
            areProductNamesSimilar(recommendedNameLower, foundNameLower);

        // 브랜드명이 일치하면 제품명 유사도 검사를 완화
        if (!isNameMatch && !isBrandMatch) {
          debugPrint(
            '⚠️ 검색 결과가 추천 제품과 일치하지 않음: ${product.fullName} vs $foundProductName',
          );
          debugPrint('   브랜드: ${product.brandName} vs $foundBrandName');
          debugPrint('❌ 브랜드명과 제품명 모두 일치하지 않음, 제품 표시 안 함');
          // enrichedProducts에 추가하지 않음 (화면에 표시되지 않음)
          await Future.delayed(const Duration(milliseconds: 200));
          continue;
        }

        // 브랜드명이 일치하지만 제품명이 다를 경우 경고만 출력하고 계속 진행
        if (!isNameMatch && isBrandMatch) {
          debugPrint(
            '⚠️ 브랜드명은 일치하지만 제품명이 다름: ${product.fullName} vs $foundProductName',
          );
          debugPrint('   브랜드 매칭으로 제품 표시 계속 진행');
        }

        // 2. /products/detail로 상세 정보 가져오기
        final detailResult = await fetchProductDetailById(productId);

        String? skuId;
        String? finalImageUrl = imageUrl;
        String? detailProductName;
        String? detailBrandName;
        String? detailDescription;

        if (detailResult != null) {
          // skuId 추출: product.skus 배열의 첫 번째 항목에서 skuId 가져오기
          final skus = detailResult['skus'];
          if (skus != null && skus is List && skus.isNotEmpty) {
            final firstSku = skus[0];
            if (firstSku is Map) {
              skuId = firstSku['skuId']?.toString();
            }
          }

          // 상세 정보에서 제품명, 브랜드명, 이미지, 설명 가져오기
          detailProductName = detailResult['product_name']?.toString();
          detailBrandName = detailResult['brand_name']?.toString();
          detailDescription =
              detailResult['short_description']?.toString() ??
              detailResult['long_description']?.toString();

          // 이미지 URL이 없으면 상세 정보에서 가져오기
          if ((finalImageUrl == null || finalImageUrl.isEmpty) &&
              detailResult['main_image'] != null) {
            finalImageUrl = detailResult['main_image']?.toString();
          }

          // 쿼리(검색한 제품명)와 상세 정보의 제품명이 다른지 확인
          final queryNameLower = product.fullName.toLowerCase().trim();
          final detailNameLower = (detailProductName ?? '')
              .toLowerCase()
              .trim();

          // 제품명이 다르면 아예 표시하지 않음
          bool isNameMatch = false;
          if (detailProductName != null && detailProductName.isNotEmpty) {
            // 정확히 일치하거나 포함 관계이거나 유사한 경우만 일치로 판단
            isNameMatch =
                detailNameLower == queryNameLower ||
                detailNameLower.contains(queryNameLower) ||
                queryNameLower.contains(detailNameLower) ||
                areProductNamesSimilar(queryNameLower, detailNameLower);
          }

          if (!isNameMatch) {
            debugPrint(
              '❌ 제품명이 다름: 쿼리="${product.fullName}" vs 상세 정보="$detailProductName"',
            );
            debugPrint('   제품 표시 안 함');
            // enrichedProducts에 추가하지 않음 (화면에 표시되지 않음)
          } else {
            // 제품명이 일치하면 상세 정보로 업데이트하여 표시
            enrichedProducts.add(
              product.copyWith(
                productId: productId,
                skuId: skuId,
                imageUrl: finalImageUrl?.isNotEmpty == true
                    ? finalImageUrl
                    : product.imageUrl,
                fullName: detailProductName ?? product.fullName,
                brandName: detailBrandName ?? product.brandName,
                description: detailDescription ?? product.description,
              ),
            );
            debugPrint(
              '✅ 제품 정보 enrich 완료: $detailProductName -> productId=$productId, skuId=$skuId',
            );
          }
        } else {
          // 상세 정보를 가져오지 못한 경우 제품을 표시하지 않음 (스킵)
          debugPrint('⚠️ 상세 정보를 가져오지 못함, 제품 표시 안 함: ${product.fullName}');
          // enrichedProducts에 추가하지 않음 (화면에 표시되지 않음)
        }

        debugPrint(
          '✅ 제품 정보 enrich 완료: ${product.fullName} -> productId=$productId, skuId=$skuId',
        );
      } else {
        // 검색 실패 시 제품을 표시하지 않음 (스킵)
        debugPrint('⚠️ 제품 ID 검색 실패, 제품 표시 안 함: ${product.fullName}');
        // enrichedProducts에 추가하지 않음 (화면에 표시되지 않음)
      }
    } catch (e) {
      debugPrint('❌ 제품 정보 enrich 오류 (${product.fullName}): $e');
      // 에러 발생 시 제품을 표시하지 않음 (스킵)
      // enrichedProducts에 추가하지 않음 (화면에 표시되지 않음)
    }

    // API 호출 간 딜레이 (서버 부하 감소)
    await Future.delayed(const Duration(milliseconds: 200));
  }

  return enrichedProducts;
}

/// 제품 추천 캐러셀 위젯
class ProductRecommendationCarousel extends StatefulWidget {
  final List<ProductRecommendation> products;
  final String? chatId;

  const ProductRecommendationCarousel({
    super.key,
    required this.products,
    this.chatId,
  });

  @override
  State<ProductRecommendationCarousel> createState() =>
      _ProductRecommendationCarouselState();
}

class _ProductRecommendationCarouselState
    extends State<ProductRecommendationCarousel>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  int _currentIndex = 0;
  final double _itemWidth = 288.0; // 아이템 너비 (이미지 280 + 패딩 8)
  List<ProductRecommendation> _enrichedProducts = [];
  bool _isNavigating = false; // 네비게이션 중복 클릭 방지 플래그
  bool _isLoading = true; // 제품 정보 로딩 중인지 확인

  @override
  bool get wantKeepAlive => true; // 위젯 상태 유지

  @override
  void initState() {
    super.initState();
    // 초기 상태: widget.products를 그대로 사용해서 캐러셀을 바로 표시
    _enrichedProducts = List.from(widget.products);
    _isLoading = true; // 초기 로딩 상태

    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final index = (_scrollController.offset / _itemWidth).round();
        if (index >= 0 &&
            index < _enrichedProducts.length &&
            index != _currentIndex) {
          // setState를 즉시 호출하지 않고 다음 프레임에 실행 (성능 최적화)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && index != _currentIndex) {
              setState(() {
                _currentIndex = index;
              });
            }
          });
        }
      }
    });
    // 제품 정보 enrich (productId, skuId 가져오기) 및 이미지 로딩
    _enrichAndLoadProducts();
  }

  /// 제품 정보 enrich 및 이미지 로딩 (각 제품이 완료되는 대로 하나씩 표시)
  Future<void> _enrichAndLoadProducts() async {
    // 로딩 시작
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    // 이미 enrich된 제품이 있고, 모든 제품에 imageUrl이 있으면 다시 enrich하지 않음
    if (_enrichedProducts.isNotEmpty &&
        _enrichedProducts.length == widget.products.length &&
        _enrichedProducts.every(
          (p) => p.imageUrl != null && p.imageUrl!.isNotEmpty,
        )) {
      debugPrint('✅ 이미 enrich된 제품이 있고 모든 이미지가 있음. 재검색 스킵');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    // 초기 상태: 빈 리스트로 시작
    if (mounted) {
      setState(() {
        _enrichedProducts = [];
      });
    }

    // Budget chat인지 확인
    final isBudgetChat = widget.chatId == 'chatbot_budget_routine';

    if (isBudgetChat) {
      // Budget chat: 카테고리별로 그룹화하고, 각 카테고리당 하나씩만 표시 (첫 번째가 실패하면 다음 시도)
      final Map<String, List<ProductRecommendation>> productsByCategory = {};

      // 제품들을 카테고리별로 그룹화
      for (var product in widget.products) {
        final category = product.category;
        if (!productsByCategory.containsKey(category)) {
          productsByCategory[category] = [];
        }
        productsByCategory[category]!.add(product);
      }

      // 각 카테고리별로 제품 처리
      for (var category in productsByCategory.keys) {
        final categoryProducts = productsByCategory[category]!;
        bool productAdded = false;

        // 같은 카테고리의 제품들을 순서대로 시도 (첫 번째가 실패하면 다음 시도)
        for (var product in categoryProducts) {
          // 이미 productId, skuId, imageUrl이 모두 있으면 그대로 사용
          if (product.productId != null &&
              product.productId!.isNotEmpty &&
              product.skuId != null &&
              product.skuId!.isNotEmpty &&
              product.imageUrl != null &&
              product.imageUrl!.isNotEmpty) {
            if (mounted) {
              setState(() {
                _enrichedProducts.add(product);
              });
            }
            debugPrint('✅ 제품 정보 이미 완료 (재검색 스킵): ${product.fullName}');
            productAdded = true;
            break; // 이 카테고리는 완료
          }

          // 제품 정보 enrich 시도
          final enrichedProduct = await _enrichSingleProduct(product);

          // enrich된 제품이 있으면 추가하고 다음 카테고리로 이동
          if (enrichedProduct != null && mounted) {
            setState(() {
              _enrichedProducts.add(enrichedProduct);
            });
            debugPrint(
              '✅ 카테고리 "$category"에 제품 추가: ${enrichedProduct.fullName}',
            );
            productAdded = true;
            break; // 이 카테고리는 완료, 다음 카테고리로
          } else {
            debugPrint(
              '⚠️ 카테고리 "$category"의 제품 "${product.fullName}" 실패, 다음 제품 시도',
            );
          }

          // 다음 제품 시도 전 딜레이
          await Future.delayed(const Duration(milliseconds: 100));
        }

        if (!productAdded) {
          debugPrint('❌ 카테고리 "$category"의 모든 제품 실패');
        }
      }
    } else {
      // 일반 chat: 기존 로직 유지
      for (var product in widget.products) {
        // 이미 productId, skuId, imageUrl이 모두 있으면 그대로 사용
        if (product.productId != null &&
            product.productId!.isNotEmpty &&
            product.skuId != null &&
            product.skuId!.isNotEmpty &&
            product.imageUrl != null &&
            product.imageUrl!.isNotEmpty) {
          if (mounted) {
            setState(() {
              _enrichedProducts.add(product);
            });
          }
          debugPrint('✅ 제품 정보 이미 완료 (재검색 스킵): ${product.fullName}');
          continue;
        }

        // 제품 정보 enrich (하나씩 처리)
        final enrichedProduct = await _enrichSingleProduct(product);

        // enrich된 제품이 있으면 추가 (제품명이 일치하는 경우만)
        if (enrichedProduct != null && mounted) {
          setState(() {
            _enrichedProducts.add(enrichedProduct);
          });
        }

        // 다음 제품 처리 전 짧은 딜레이
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    // 로딩 완료
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 단일 제품 정보 enrich
  Future<ProductRecommendation?> _enrichSingleProduct(
    ProductRecommendation product,
  ) async {
    // productId는 있지만 skuId가 없는 경우, /products/detail로 상세 정보를 가져와서 skuId를 찾음
    if (product.productId != null && product.productId!.isNotEmpty) {
      try {
        final detailResult = await fetchProductDetailById(product.productId!);
        String? skuId = product.skuId;
        String? imageUrl = product.imageUrl;
        String? detailProductName;
        String? detailBrandName;
        String? detailDescription;

        if (detailResult != null) {
          // skuId 추출: product.skus 배열의 첫 번째 항목에서 skuId 가져오기
          final skus = detailResult['skus'];
          if (skus != null && skus is List && skus.isNotEmpty) {
            final firstSku = skus[0];
            if (firstSku is Map) {
              skuId = firstSku['skuId']?.toString();
            }
          }

          // 상세 정보에서 제품명, 브랜드명, 이미지, 설명 가져오기
          detailProductName = detailResult['product_name']?.toString();
          detailBrandName = detailResult['brand_name']?.toString();
          final detailImageUrl = detailResult['main_image']?.toString();
          detailDescription =
              detailResult['short_description']?.toString() ??
              detailResult['long_description']?.toString();

          if (detailImageUrl != null && detailImageUrl.isNotEmpty) {
            imageUrl = detailImageUrl;
          }

          // Budget chat인지 확인
          final isBudgetChat = widget.chatId == 'chatbot_budget_routine';

          // AI 추천 제품명(쿼리)과 상세 정보의 제품명이 다른지 확인
          final recommendedNameLower = product.fullName.toLowerCase().trim();
          final detailNameLower = (detailProductName ?? '')
              .toLowerCase()
              .trim();

          // 제품명이 다르면 아예 표시하지 않음 (Budget chat 제외)
          bool isNameMatch = false;
          if (detailProductName != null && detailProductName.isNotEmpty) {
            // 정확히 일치하거나 포함 관계이거나 유사한 경우만 일치로 판단
            isNameMatch =
                detailNameLower == recommendedNameLower ||
                detailNameLower.contains(recommendedNameLower) ||
                recommendedNameLower.contains(detailNameLower) ||
                areProductNamesSimilar(recommendedNameLower, detailNameLower);
          }

          // Budget chat이면 제품명이 달라도 상세 정보의 제품을 표시 (카테고리가 일치하는 경우)
          if (!isNameMatch && !isBudgetChat) {
            debugPrint(
              '❌ 제품명이 다름: 쿼리="${product.fullName}" vs 상세 정보="$detailProductName"',
            );
            debugPrint('   제품 표시 안 함');
            return null; // 제품 표시 안 함
          } else {
            // 제품명이 일치하거나 Budget chat이면 상세 정보로 업데이트하여 표시
            if (!isNameMatch && isBudgetChat) {
              debugPrint('⚠️ Budget chat: 제품명이 다르지만 카테고리 매칭으로 상세 정보 제품 표시');
              debugPrint(
                '   쿼리="${product.fullName}" vs 상세 정보="$detailProductName"',
              );
            }
            debugPrint(
              '✅ 제품 정보 enrich 완료: $detailProductName -> productId=${product.productId}, skuId=$skuId',
            );
            return product.copyWith(
              skuId: skuId,
              imageUrl: imageUrl,
              fullName: detailProductName ?? product.fullName, // 상세 정보의 제품명 우선
              brandName: detailBrandName ?? product.brandName, // 상세 정보의 브랜드명 우선
              description:
                  detailDescription ?? product.description, // 상세 정보의 설명 우선
            );
          }
        } else {
          // 상세 정보를 가져오지 못한 경우 제품을 표시하지 않음 (스킵)
          debugPrint('⚠️ 상세 정보를 가져오지 못함, 제품 표시 안 함: ${product.fullName}');
          return null;
        }
      } catch (e) {
        debugPrint('❌ 제품 정보 enrich 오류 (${product.fullName}): $e');
        return null; // 에러 발생 시 제품 표시 안 함
      }
    }

    try {
      // Budget chat인지 확인
      final isBudgetChat = widget.chatId == 'chatbot_budget_routine';

      // 1. 제품 이름으로 검색하여 productId 가져오기
      // Budget chat: 카테고리 매칭 우선, 일반 chat: 브랜드명 매칭 우선
      final searchResult = await searchProductId(
        product.searchQuery,
        targetCategory: isBudgetChat ? product.category : null,
        targetBrandName: isBudgetChat ? null : product.brandName,
      );

      if (searchResult != null &&
          searchResult['productId']?.isNotEmpty == true) {
        final productId = searchResult['productId']!;
        final foundProductName = searchResult['productName'] ?? '';
        final foundBrandName = searchResult['brandName'] ?? '';
        final foundCategory = searchResult['category'] ?? '';
        final imageUrl = searchResult['imageUrl'];

        if (isBudgetChat) {
          // Budget chat: 카테고리 매칭 확인 (우선순위 높음)
          bool isCategoryMatch = true;
          if (product.category.isNotEmpty) {
            final recommendedCategoryLower = product.category
                .toLowerCase()
                .trim();
            final foundCategoryLower = foundCategory.toLowerCase().trim();
            isCategoryMatch =
                foundCategoryLower.contains(recommendedCategoryLower) ||
                recommendedCategoryLower.contains(foundCategoryLower) ||
                foundCategoryLower == recommendedCategoryLower;
          }

          // 제품명 매칭 확인
          final recommendedNameLower = product.fullName.toLowerCase().trim();
          final foundNameLower = foundProductName.toLowerCase().trim();

          final isNameMatch =
              foundNameLower.contains(recommendedNameLower) ||
              recommendedNameLower.contains(foundNameLower) ||
              areProductNamesSimilar(recommendedNameLower, foundNameLower);

          // 카테고리가 일치하면 제품명 유사도 검사를 완화
          if (!isNameMatch && !isCategoryMatch) {
            debugPrint(
              '⚠️ 검색 결과가 추천 제품과 일치하지 않음: ${product.fullName} vs $foundProductName',
            );
            debugPrint('   카테고리: ${product.category} vs $foundCategory');
            debugPrint('❌ 카테고리와 제품명 모두 일치하지 않음, 제품 표시 안 함');
            return null;
          }

          // 카테고리가 일치하지만 제품명이 다를 경우 경고만 출력하고 계속 진행
          if (!isNameMatch && isCategoryMatch) {
            debugPrint(
              '⚠️ 카테고리는 일치하지만 제품명이 다름: ${product.fullName} vs $foundProductName',
            );
            debugPrint('   카테고리 매칭으로 제품 표시 계속 진행');
          }
        } else {
          // 일반 chat: 브랜드명 매칭 확인 (우선순위 높음)
          bool isBrandMatch = true;
          if (product.brandName != null && product.brandName!.isNotEmpty) {
            final recommendedBrandLower = product.brandName!
                .toLowerCase()
                .trim();
            final foundBrandLower = foundBrandName.toLowerCase().trim();
            isBrandMatch =
                foundBrandLower.contains(recommendedBrandLower) ||
                recommendedBrandLower.contains(foundBrandLower) ||
                foundBrandLower == recommendedBrandLower;
          }

          // 제품명 매칭 확인
          final recommendedNameLower = product.fullName.toLowerCase().trim();
          final foundNameLower = foundProductName.toLowerCase().trim();

          final isNameMatch =
              foundNameLower.contains(recommendedNameLower) ||
              recommendedNameLower.contains(foundNameLower) ||
              areProductNamesSimilar(recommendedNameLower, foundNameLower);

          // 브랜드명이 일치하면 제품명 유사도 검사를 완화
          if (!isNameMatch && !isBrandMatch) {
            debugPrint(
              '⚠️ 검색 결과가 추천 제품과 일치하지 않음: ${product.fullName} vs $foundProductName',
            );
            debugPrint('   브랜드: ${product.brandName} vs $foundBrandName');
            debugPrint('❌ 브랜드명과 제품명 모두 일치하지 않음, 제품 표시 안 함');
            return null;
          }

          // 브랜드명이 일치하지만 제품명이 다를 경우 경고만 출력하고 계속 진행
          if (!isNameMatch && isBrandMatch) {
            debugPrint(
              '⚠️ 브랜드명은 일치하지만 제품명이 다름: ${product.fullName} vs $foundProductName',
            );
            debugPrint('   브랜드 매칭으로 제품 표시 계속 진행');
          }
        }

        // 2. /products/detail로 상세 정보 가져오기
        final detailResult = await fetchProductDetailById(productId);

        String? skuId;
        String? finalImageUrl = imageUrl;
        String? detailProductName;
        String? detailBrandName;
        String? detailDescription;

        if (detailResult != null) {
          // skuId 추출: product.skus 배열의 첫 번째 항목에서 skuId 가져오기
          final skus = detailResult['skus'];
          if (skus != null && skus is List && skus.isNotEmpty) {
            final firstSku = skus[0];
            if (firstSku is Map) {
              skuId = firstSku['skuId']?.toString();
            }
          }

          // 상세 정보에서 제품명, 브랜드명, 이미지, 설명 가져오기
          detailProductName = detailResult['product_name']?.toString();
          detailBrandName = detailResult['brand_name']?.toString();
          detailDescription =
              detailResult['short_description']?.toString() ??
              detailResult['long_description']?.toString();

          // 이미지 URL이 없으면 상세 정보에서 가져오기
          if ((finalImageUrl == null || finalImageUrl.isEmpty) &&
              detailResult['main_image'] != null) {
            finalImageUrl = detailResult['main_image']?.toString();
          }

          // 쿼리(검색한 제품명)와 상세 정보의 제품명이 다른지 확인
          final queryNameLower = product.fullName.toLowerCase().trim();
          final detailNameLower = (detailProductName ?? '')
              .toLowerCase()
              .trim();

          // 제품명이 다르면 아예 표시하지 않음 (Budget chat 제외)
          bool isNameMatch = false;
          if (detailProductName != null && detailProductName.isNotEmpty) {
            // 정확히 일치하거나 포함 관계이거나 유사한 경우만 일치로 판단
            isNameMatch =
                detailNameLower == queryNameLower ||
                detailNameLower.contains(queryNameLower) ||
                queryNameLower.contains(detailNameLower) ||
                areProductNamesSimilar(queryNameLower, detailNameLower);
          }

          // Budget chat이면 카테고리가 일치했으므로 제품명이 달라도 상세 정보의 제품을 표시
          if (!isNameMatch && !isBudgetChat) {
            debugPrint(
              '❌ 제품명이 다름: 쿼리="${product.fullName}" vs 상세 정보="$detailProductName"',
            );
            debugPrint('   제품 표시 안 함');
            return null;
          } else {
            // 제품명이 일치하거나 Budget chat이면 상세 정보로 업데이트하여 반환
            if (!isNameMatch && isBudgetChat) {
              debugPrint('⚠️ Budget chat: 제품명이 다르지만 카테고리 매칭으로 상세 정보 제품 표시');
              debugPrint(
                '   쿼리="${product.fullName}" vs 상세 정보="$detailProductName"',
              );
            }
            debugPrint(
              '✅ 제품 정보 enrich 완료: $detailProductName -> productId=$productId, skuId=$skuId',
            );
            return product.copyWith(
              productId: productId,
              skuId: skuId,
              imageUrl: finalImageUrl?.isNotEmpty == true
                  ? finalImageUrl
                  : product.imageUrl,
              fullName: detailProductName ?? product.fullName, // 상세 정보의 제품명 우선
              brandName: detailBrandName ?? product.brandName, // 상세 정보의 브랜드명 우선
              description:
                  detailDescription ?? product.description, // 상세 정보의 설명 우선
            );
          }
        } else {
          // 상세 정보를 가져오지 못한 경우 제품을 표시하지 않음 (스킵)
          debugPrint('⚠️ 상세 정보를 가져오지 못함, 제품 표시 안 함: ${product.fullName}');
          return null;
        }
      } else {
        // 검색 실패 시 제품을 표시하지 않음 (스킵)
        debugPrint('⚠️ 제품 ID 검색 실패, 제품 표시 안 함: ${product.fullName}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ 제품 정보 enrich 오류 (${product.fullName}): $e');
      return null;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin을 위해 필요
    if (widget.products.isEmpty) {
      return const SizedBox.shrink();
    }

    // 모든 제품이 표시되지 않았을 때 메시지 표시
    if (_enrichedProducts.isEmpty && _isLoading == false) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey[700], size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'I\'m sorry, but the server has insufficient data.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[900],
                    fontFamily: 'HelveticaNeue',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Budget chat인지 확인
    final isBudgetChat = widget.chatId == 'chatbot_budget_routine';

    // Total price 계산 (budget chat일 때만)
    double? totalPrice;
    if (isBudgetChat) {
      totalPrice = _enrichedProducts.fold<double>(0.0, (sum, product) {
        if (product.price != null && product.price!.isNotEmpty) {
          // 가격에서 숫자만 추출 (예: "$38" -> 38, "$50-60" -> 50)
          final priceStr = product.price!.replaceAll('\$', '').trim();
          final priceMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(priceStr);
          if (priceMatch != null) {
            final priceValue = double.tryParse(priceMatch.group(1) ?? '0');
            if (priceValue != null) {
              return sum + priceValue;
            }
          }
        }
        return sum;
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 스크롤 가능하다는 힌트 (제품이 2개 이상일 때만)
        if (_enrichedProducts.length > 1)
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Row(
              children: [
                Icon(Icons.swipe, size: 18, color: Colors.grey[700]),
                const SizedBox(width: 4),
                Text(
                  'Swipe or use arrows to see more products',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                    fontFamily: 'HelveticaNeue',
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          height: 500, // 이미지 높이(280) + 간격(16) + 텍스트 영역 높이(약 200) + 여유 공간
          child: Stack(
            children: [
              ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: _enrichedProducts.length,
                padding: const EdgeInsets.only(left: 0, right: 0),
                clipBehavior: Clip.none,
                physics: const BouncingScrollPhysics(), // 스와이프 가능하게 활성화
                itemBuilder: (context, index) {
                  final product = _enrichedProducts[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 0 : 8,
                      right: index == _enrichedProducts.length - 1 ? 0 : 8,
                    ),
                    child: _ProductCard(
                      isNavigating: _isNavigating,
                      onNavigatingChanged: (value) {
                        setState(() {
                          _isNavigating = value;
                        });
                      },
                      product: product,
                      chatId: widget.chatId,
                      onProductUpdated: (updatedProduct) {
                        if (mounted && index < _enrichedProducts.length) {
                          setState(() {
                            _enrichedProducts[index] = updatedProduct;
                          });
                        }
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        // Total price 표시 (budget chat일 때만)
        if (isBudgetChat && totalPrice != null && totalPrice > 0)
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total Price: ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                      fontFamily: 'Helvetica',
                    ),
                  ),
                  Text(
                    '\$${totalPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                      fontFamily: 'Helvetica',
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// 제품 카드 위젯
class _ProductCard extends StatelessWidget {
  final ProductRecommendation product;
  final Function(ProductRecommendation)? onProductUpdated;
  final bool isNavigating; // 네비게이션 중복 클릭 방지
  final Function(bool) onNavigatingChanged; // 네비게이션 상태 변경 콜백
  final String? chatId; // Budget chat인지 확인용

  const _ProductCard({
    required this.product,
    this.onProductUpdated,
    required this.isNavigating,
    required this.onNavigatingChanged,
    this.chatId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // 상세페이지로 이동 (productId가 없으면 검색해서 찾음)
        await _navigateToProductDetail(context);
      },
      child: Container(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 (모서리가 둥근 직사각형) - 하늘색 배경
            GestureDetector(
              onTap: () async {
                // 이미지 클릭 시 상세페이지로 이동
                await _navigateToProductDetail(context);
              },
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.secondary, // 하늘색 배경
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child:
                      product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                                color: Colors.white,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('이미지 로드 실패: ${product.imageUrl}');
                            return _buildPlaceholder();
                          },
                        )
                      : _buildPlaceholder(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 텍스트 영역 - 노란색 배경
            Container(
              width: 280,
              constraints: const BoxConstraints(maxHeight: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.primary, // 노란색 배경
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 브랜드명 (맨 위, Bold)
                  if (product.brandName != null &&
                      product.brandName!.isNotEmpty)
                    Text(
                      product.brandName!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontFamily: 'Helvetica',
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                  if (product.brandName != null &&
                      product.brandName!.isNotEmpty)
                    const SizedBox(height: 4),
                  // 제품 이름 (Helvetica 930 - Light)
                  Text(
                    product.fullName,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontFamily: 'Helvetica',
                      fontWeight: FontWeight.w300, // Helvetica 930 (Light)
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.price != null) ...[
                    const SizedBox(height: 4),
                    // 가격 표시
                    Text(
                      product.price!.startsWith('\$')
                          ? product.price!
                          : '\$${product.price}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontFamily: 'Helvetica',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  // 제품 설명
                  Expanded(
                    child: Text(
                      product.description,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        fontFamily: 'HelveticaNeue',
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.secondary, // 하늘색 배경 유지
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image,
              size: 64,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                product.fullName,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontFamily: 'HelveticaNeue',
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Convert ProductRecommendation to CosmeticItem for ProductDetailPage
  CosmeticItem _convertToCosmeticItem(ProductRecommendation product) {
    return CosmeticItem(
      title: product.fullName,
      rating: 0.0, // 기본값
      category: product.category,
      priceRange: product.price ?? 'Not specified',
      supportingText: product.brandName ?? product.description,
      productId: product.productId,
      skuId: product.skuId,
    );
  }

  /// 상세페이지로 이동
  Future<void> _navigateToProductDetail(BuildContext context) async {
    // 이미 네비게이션 중이면 무시 (중복 클릭 방지)
    if (isNavigating) {
      debugPrint('⚠️ 네비게이션 진행 중, 클릭 무시');
      return;
    }

    // 네비게이션 시작
    onNavigatingChanged(true);

    try {
      // productId가 있으면 바로 이동 (홈 페이지와 동일)
      if (product.productId != null && product.productId!.isNotEmpty) {
        String? finalProductId = product.productId;
        String? finalSkuId = product.skuId;

        // skuId가 없으면 /products/detail로 상세 정보를 가져와서 skuId 추출
        if (finalSkuId == null || finalSkuId.isEmpty) {
          debugPrint('⚠️ skuId가 없어서 /products/detail로 상세 정보를 가져옵니다.');
          try {
            final detailResult = await fetchProductDetailById(finalProductId!);
            if (detailResult != null) {
              // skuId 추출: product.skus 배열의 첫 번째 항목에서 skuId 가져오기
              final skus = detailResult['skus'];
              if (skus != null && skus is List && skus.isNotEmpty) {
                final firstSku = skus[0];
                if (firstSku is Map) {
                  finalSkuId = firstSku['skuId']?.toString();
                }
              }

              // 이미지 URL도 가져오기 (상세 페이지와 동일한 이미지 사용)
              String? imageUrl = detailResult['main_image']?.toString();

              if (finalSkuId != null && finalSkuId.isNotEmpty) {
                debugPrint('✅ SKU 찾음: $finalSkuId');
                // 상태 업데이트: 찾은 skuId와 imageUrl을 제품에 저장
                onProductUpdated?.call(
                  product.copyWith(skuId: finalSkuId, imageUrl: imageUrl),
                );
              } else if (imageUrl != null && imageUrl.isNotEmpty) {
                // skuId는 없지만 imageUrl은 있으면 이미지만 업데이트
                onProductUpdated?.call(product.copyWith(imageUrl: imageUrl));
              }
            }
          } catch (e) {
            debugPrint('❌ 제품 상세 정보 가져오기 실패: $e');
          }
        }

        final cosmeticItem = _convertToCosmeticItem(product);
        // skuId가 찾아졌으면 업데이트
        if (finalSkuId != null && finalSkuId.isNotEmpty) {
          final cosmeticItemWithSku = CosmeticItem(
            title: cosmeticItem.title,
            rating: cosmeticItem.rating,
            category: cosmeticItem.category,
            priceRange: cosmeticItem.priceRange,
            supportingText: cosmeticItem.supportingText,
            productId: cosmeticItem.productId,
            skuId: finalSkuId,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProductDetailPage(item: cosmeticItemWithSku),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(item: cosmeticItem),
            ),
          );
        }
        return;
      }

      // productId가 없으면 제품 이름으로 검색해서 productId를 가져옴
      debugPrint('⚠️ productId가 없어서 제품 이름으로 검색합니다: ${product.searchQuery}');
      // Budget chat인지 확인
      final isBudgetChat = chatId == 'chatbot_budget_routine';

      final searchResult = await searchProductId(
        product.searchQuery,
        targetCategory: isBudgetChat ? product.category : null,
        targetBrandName: isBudgetChat ? null : product.brandName,
      );
      if (searchResult != null &&
          searchResult['productId']?.isNotEmpty == true) {
        final productId = searchResult['productId']!;
        final foundProductName = searchResult['productName'] ?? '';
        final foundBrandName = searchResult['brandName'] ?? '';
        final foundCategory = searchResult['category'] ?? '';

        debugPrint('✅ 제품 ID 검색 성공: productId=$productId');
        debugPrint('  찾은 제품명: $foundProductName');
        debugPrint('  찾은 브랜드명: $foundBrandName');
        debugPrint('  찾은 카테고리: $foundCategory');
        debugPrint('  추천 제품명: ${product.fullName}');
        debugPrint('  추천 브랜드명: ${product.brandName}');
        debugPrint('  추천 카테고리: ${product.category}');

        bool isMatch = false;
        if (isBudgetChat) {
          // Budget chat: 카테고리 매칭 확인 (우선순위 높음)
          bool isCategoryMatch = true;
          if (product.category.isNotEmpty) {
            final recommendedCategoryLower = product.category
                .toLowerCase()
                .trim();
            final foundCategoryLower = foundCategory.toLowerCase().trim();
            isCategoryMatch =
                foundCategoryLower.contains(recommendedCategoryLower) ||
                recommendedCategoryLower.contains(foundCategoryLower) ||
                foundCategoryLower == recommendedCategoryLower;
          }

          // 제품명 매칭 확인
          final recommendedNameLower = product.fullName.toLowerCase().trim();
          final foundNameLower = foundProductName.toLowerCase().trim();

          final isNameMatch =
              foundNameLower == recommendedNameLower ||
              foundNameLower.contains(recommendedNameLower) ||
              recommendedNameLower.contains(foundNameLower) ||
              areProductNamesSimilar(recommendedNameLower, foundNameLower);

          isMatch = isNameMatch || isCategoryMatch;

          if (!isMatch) {
            debugPrint('❌ 검색 결과가 추천 제품과 일치하지 않습니다.');
            debugPrint('  추천 제품: ${product.category} ${product.fullName}');
            debugPrint('  찾은 제품: $foundCategory $foundProductName');
            debugPrint('  제품명 일치: $isNameMatch, 카테고리 일치: $isCategoryMatch');
          }
        } else {
          // 일반 chat: 브랜드명 매칭 확인 (우선순위 높음)
          bool isBrandMatch = true;
          if (product.brandName != null && product.brandName!.isNotEmpty) {
            final recommendedBrandLower = product.brandName!
                .toLowerCase()
                .trim();
            final foundBrandLower = foundBrandName.toLowerCase().trim();
            isBrandMatch =
                foundBrandLower.contains(recommendedBrandLower) ||
                recommendedBrandLower.contains(foundBrandLower) ||
                foundBrandLower == recommendedBrandLower;
          }

          // 제품명 매칭 확인
          final recommendedNameLower = product.fullName.toLowerCase().trim();
          final foundNameLower = foundProductName.toLowerCase().trim();

          final isNameMatch =
              foundNameLower == recommendedNameLower ||
              foundNameLower.contains(recommendedNameLower) ||
              recommendedNameLower.contains(foundNameLower) ||
              areProductNamesSimilar(recommendedNameLower, foundNameLower);

          isMatch = isNameMatch || isBrandMatch;

          if (!isMatch) {
            debugPrint('❌ 검색 결과가 추천 제품과 일치하지 않습니다.');
            debugPrint(
              '  추천 제품: ${product.brandName ?? ''} ${product.fullName}',
            );
            debugPrint('  찾은 제품: $foundBrandName $foundProductName');
            debugPrint('  제품명 일치: $isNameMatch, 브랜드명 일치: $isBrandMatch');
          }
        }

        if (!isMatch) {
          // 일치하지 않으면 비슷한 제품을 추천한다는 메시지 표시
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'No exact match found. Showing a similar product instead!',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }

          // 검색 결과 제품의 상세 페이지로 이동 (검색 결과의 제품명과 브랜드명 사용)
          // /products/detail로 상세 정보 가져와서 skuId 추출
          String? skuId;
          String? imageUrl = searchResult['imageUrl'];
          final detailResult = await fetchProductDetailById(productId);
          if (detailResult != null) {
            // skuId 추출: product.skus 배열의 첫 번째 항목에서 skuId 가져오기
            final skus = detailResult['skus'];
            if (skus != null && skus is List && skus.isNotEmpty) {
              final firstSku = skus[0];
              if (firstSku is Map) {
                skuId = firstSku['skuId']?.toString();
              }
            }
            // 이미지 URL이 없으면 상세 정보에서 가져오기
            if ((imageUrl == null || imageUrl.isEmpty) &&
                detailResult['main_image'] != null) {
              imageUrl = detailResult['main_image']?.toString();
            }
            debugPrint('✅ SKU 찾음: $skuId');
          }

          // 상태 업데이트: 찾은 productId, skuId, imageUrl을 제품에 저장
          final updatedProduct = product.copyWith(
            productId: productId,
            skuId: skuId,
            imageUrl: imageUrl,
          );
          onProductUpdated?.call(updatedProduct);

          // 검색 결과의 제품명과 브랜드명을 사용하여 상세 페이지로 이동
          final cosmeticItem = CosmeticItem(
            title: foundProductName, // 검색 결과 제품명 사용
            rating: 0.0,
            category: product.category,
            priceRange: product.price ?? 'Not specified',
            supportingText: foundBrandName.isNotEmpty
                ? foundBrandName
                : product.description, // 검색 결과 브랜드명 사용
            productId: productId,
            skuId: skuId,
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(item: cosmeticItem),
            ),
          );
          return;
        }

        // /products/detail로 상세 정보 가져와서 skuId 추출
        String? skuId;
        String? imageUrl = searchResult['imageUrl'];
        final detailResult = await fetchProductDetailById(productId);
        if (detailResult != null) {
          skuId =
              detailResult['skuld']?.toString() ??
              detailResult['skuId']?.toString() ??
              detailResult['sku_id']?.toString();
          // 이미지 URL이 없으면 상세 정보에서 가져오기
          if ((imageUrl == null || imageUrl.isEmpty) &&
              detailResult['image_url'] != null) {
            imageUrl = detailResult['image_url']?.toString();
          }
          debugPrint('✅ SKU 찾음: $skuId');
        }

        // 상태 업데이트: 찾은 productId, skuId, imageUrl을 제품에 저장
        final updatedProduct = product.copyWith(
          productId: productId,
          skuId: skuId,
          imageUrl: imageUrl,
        );
        onProductUpdated?.call(updatedProduct);

        // AI가 추천한 제품명과 브랜드명을 그대로 사용 (검색 결과가 아닌)
        final cosmeticItem = CosmeticItem(
          title: product.fullName, // AI 추천 제품명 사용
          rating: 0.0,
          category: product.category,
          priceRange: product.price ?? 'Not specified',
          supportingText:
              product.brandName ?? product.description, // AI 추천 브랜드명 사용
          productId: productId,
          skuId: skuId,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(item: cosmeticItem),
          ),
        );
      } else {
        debugPrint('❌ 제품 ID 검색 실패: ${product.fullName}');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('제품 정보를 찾을 수 없습니다: ${product.fullName}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ 제품 ID 검색 오류: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('제품 정보를 가져오는 중 오류가 발생했습니다.'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      // 네비게이션 완료 후 플래그 해제 (성공/실패 관계없이)
      onNavigatingChanged(false);
    }
  }
}
