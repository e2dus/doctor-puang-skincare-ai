import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobileprogramming_groupproject_2025/features/liked_products/presentation/providers/liked_products_provider.dart';
import 'package:mobileprogramming_groupproject_2025/screens/product_detail_page.dart';
import 'package:mobileprogramming_groupproject_2025/features/liked_products/data/mappers/cosmetic_item_mapper.dart';

/// Page displaying all liked products
class LikedProductsPage extends ConsumerStatefulWidget {
  const LikedProductsPage({super.key});

  @override
  ConsumerState<LikedProductsPage> createState() => _LikedProductsPageState();
}

class _LikedProductsPageState extends ConsumerState<LikedProductsPage> {
  @override
  void initState() {
    super.initState();
    // 페이지가 표시될 때마다 liked products 새로 고침
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(likedProductsNotifierProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(likedProductsNotifierProvider);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Likes',
          style: TextStyle(
            fontFamily: 'HelveticaNeue93',
            fontWeight: FontWeight.w900,
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 20,
          ),
        ),
        actions: [
          if (state.products.isNotEmpty)
            TextButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear All'),
                    content: Text(
                      'Are you sure you want to remove all ${state.products.length} liked products?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && context.mounted) {
                  await ref
                      .read(likedProductsNotifierProvider.notifier)
                      .clearAll();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All liked products cleared'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Clear All'),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
          ? Center(
              child: Text(
                'Error: ${state.error}',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            )
          : state.products.isEmpty
          ? Center(
              child: Text(
                'No liked products yet',
                style: TextStyle(
                  fontSize: 16,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.products.length,
              itemBuilder: (context, index) {
                final item = state.products[index];
                return Card(
                  color: theme.cardColor,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () {
                      final cosmeticItem = CosmeticItemMapper.toModel(item);
                      debugPrint(
                        '📱 LikedProductsPage - productId: ${cosmeticItem.productId}, skuId: ${cosmeticItem.skuId}',
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProductDetailPage(item: cosmeticItem),
                        ),
                      );
                    },
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                item.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.palette_outlined,
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.grey[400]
                                        : Colors.grey,
                                  );
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color:
                                                theme.brightness ==
                                                    Brightness.dark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                      );
                                    },
                              ),
                            )
                          : Icon(
                              Icons.palette_outlined,
                              color: theme.brightness == Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey,
                            ),
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    ),
                    subtitle: Text(
                      '${item.category} - ${item.priceRange}',
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.red),
                      onPressed: () {
                        ref
                            .read(likedProductsNotifierProvider.notifier)
                            .unlikeProduct(item);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${item.title} removed from likes'),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
