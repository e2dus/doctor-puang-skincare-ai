import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/product_entity.dart';
import '../../../../core/theme/app_colors.dart';
import '../viewmodels/liked_products_viewmodel.dart';

/// Grid item widget for displaying a product
class ProductGridItem extends ConsumerWidget {
  final ProductEntity item;
  final int index;
  final int totalCount;
  final VoidCallback? onTap;

  const ProductGridItem({
    super.key,
    required this.item,
    required this.index,
    required this.totalCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final likedItems = ref.watch(likedProductsProvider);
    final isLiked = likedItems.any((p) => p.title == item.title);

    Widget content = Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode
              ? Colors.grey[700]!.withOpacity(0.5) // 다크모드: 더 명확한 테두리
              : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.5) // 다크모드: 더 강한 그림자
                : Colors.black.withOpacity(0.06),
            blurRadius: isDarkMode ? 12 : 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          // 메인 콘텐츠
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이미지 영역
                Expanded(
                  flex: 12,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.white, // 항상 흰색 배경
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Center(
                        // 이미지를 중앙에 정렬
                        child: (item.imageUrl?.isNotEmpty ?? false)
                            ? Image.network(
                                item.imageUrl!,
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
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
                                          strokeWidth: 2,
                                          color: isDarkMode
                                              ? Colors.grey[600]
                                              : AppColors.primary,
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
                  ),
                ),
                const SizedBox(height: 8),
                // 브랜드명
                Text(
                  item.brandName,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                // 제품명
                Expanded(
                  flex: 2,
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                // 평점 및 리뷰
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 15, color: Colors.amber),
                    const SizedBox(width: 3),
                    Text(
                      item.rating.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${item.reviews})',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 순위 배지 (왼쪽 위)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: index < 3
                      ? [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)]
                      : [const Color(0xFF4A90E2), const Color(0xFF6BA3E8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          // 좋아요 버튼 (오른쪽 위)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                ref.read(likedProductsProvider.notifier).toggleLike(item);
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.grey[800]!.withOpacity(0.95)
                      : Colors.white.withOpacity(0.95),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked
                      ? Colors.red[500]
                      : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                  size: 18,
                ),
              ),
            ),
          ),
          // 순위 카운터 (오른쪽 아래)
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.grey[800]!.withOpacity(0.9)
                    : Colors.black.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${index + 1}/$totalCount',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // onTap이 있으면 GestureDetector로 감싸기
    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }

    return content;
  }
}
