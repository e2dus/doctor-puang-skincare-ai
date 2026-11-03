import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobileprogramming_groupproject_2025/features/product/presentation/viewmodels/no_recommend_viewmodel.dart';
import 'package:mobileprogramming_groupproject_2025/screens/product_detail_page.dart';
import 'package:mobileprogramming_groupproject_2025/features/liked_products/data/mappers/cosmetic_item_mapper.dart';

class NoRecommendPage extends ConsumerWidget {
  const NoRecommendPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noRecommendItems = ref.watch(noRecommendProductsProvider);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Not Recommended',
          style: TextStyle(
            fontFamily: 'HelveticaNeue93',
            fontWeight: FontWeight.w900,
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 20,
          ),
        ),
        actions: [
          if (noRecommendItems.isNotEmpty)
            TextButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear All'),
                    content: Text(
                      'Are you sure you want to remove all ${noRecommendItems.length} not recommended products?',
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
                  ref.read(noRecommendProductsProvider.notifier).clearAll();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All not recommended products cleared'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Clear All'),
            ),
        ],
      ),
      body: noRecommendItems.isEmpty
          ? Center(
              child: Text(
                'No products marked as not recommended',
                style: TextStyle(
                  fontSize: 16,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: noRecommendItems.length,
              itemBuilder: (context, index) {
                final item = noRecommendItems[index];
                return Card(
                  color: theme.cardColor,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailPage(
                            item: CosmeticItemMapper.productEntityToModel(item),
                          ),
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
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.orange,
                      ),
                      onPressed: () {
                        ref
                            .read(noRecommendProductsProvider.notifier)
                            .removeNoRecommend(item);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${item.title} removed from not recommended',
                            ),
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
