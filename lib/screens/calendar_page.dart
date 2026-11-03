import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mobileprogramming_groupproject_2025/features/skincare/presentation/viewmodels/skincare_viewmodel.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final TextEditingController _customItemController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  bool _isFabExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  void dispose() {
    _customItemController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final routineNotifier = ref.watch(skincareRoutineProvider.notifier);
    final routinesMap = ref.watch(skincareRoutineProvider);
    final selectedDate = _selectedDay ?? _focusedDay;
    final routine = routinesMap[routineNotifier.dateKey(selectedDate)];

    // Initialize routine if needed (delayed to avoid build-time modification)
    if (routine == null) {
      Future.microtask(() => routineNotifier.ensureRoutineExists(selectedDate));
    }

    return Scaffold(
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              // Initialize routine for the newly selected day
              Future.microtask(
                () => ref
                    .read(skincareRoutineProvider.notifier)
                    .ensureRoutineExists(selectedDay),
              );
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            calendarFormat: CalendarFormat.week,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                final completed = routineNotifier.getCompletedCount(date);
                final total = routineNotifier.getTotalCount(date);

                if (completed > 0) {
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: completed == total
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMMM d, yyyy').format(selectedDate),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(
                      '${routineNotifier.getCompletedCount(selectedDate)}/${routineNotifier.getTotalCount(selectedDate)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: routineNotifier.getTotalCount(selectedDate) > 0
                        ? routineNotifier.getCompletedCount(selectedDate) /
                              routineNotifier.getTotalCount(selectedDate)
                        : 0,
                    minHeight: 8,
                    backgroundColor: theme.brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: routine == null || (routine.checklist.isEmpty && routine.memo == null)
                ? Center(
                    child: Text(
                      'Your checklist is empty',
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Checklist items
                        ...() {
                          final groups = _buildChecklistGroups(
                            routine.checklist,
                            routineNotifier,
                            selectedDate,
                          );
                          return groups.map((group) {
                            if (group['type'] == 'category') {
                              final categoryTitle = group['title'] as String;
                              return Container(
                                padding: const EdgeInsets.only(top: 16, bottom: 8),
                                child: Text(
                                  categoryTitle,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              );
                            } else {
                              final item = group['item'] as String;
                              final isChecked = group['isChecked'] as bool;
                              final category = group['category'] as String?;

                              return GestureDetector(
                                onLongPress: () {
                                  // Show category selection dialog
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Move "$item"'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: categorizedItems.keys.map((cat) {
                                          return ListTile(
                                            title: Text(cat),
                                            leading: Radio<String>(
                                              value: cat,
                                              groupValue: category,
                                              onChanged: (value) {
                                                Navigator.pop(context);
                                                if (value != null && value != category) {
                                                  routineNotifier.moveItemToCategory(
                                                    selectedDate,
                                                    item,
                                                    value,
                                                  );
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('"$item" moved to $value'),
                                                      duration: const Duration(seconds: 1),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: _buildChecklistItem(
                                  context,
                                  theme,
                                  item,
                                  isChecked,
                                  selectedDate,
                                  routineNotifier,
                                ),
                              );
                            }
                          }).toList();
                        }(),
                        // Memo section at the bottom
                        if (routine.memo != null && routine.memo!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 24, bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.note,
                                      size: 16,
                                      color: theme.colorScheme.secondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Memo',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.secondary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.colorScheme.secondary.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          routine.memo!,
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: theme.textTheme.bodyLarge?.color,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        iconSize: 20,
                                        color: Colors.red.withOpacity(0.7),
                                        onPressed: () {
                                          routineNotifier.clearMemo(selectedDate);
                                        },
                                        padding: const EdgeInsets.all(8),
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (_isFabExpanded) ...[
              // Add Item Button
              FloatingActionButton(
                heroTag: 'add_item',
                mini: true,
                backgroundColor: theme.colorScheme.secondary,
                onPressed: () {
                  setState(() => _isFabExpanded = false);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('항목 추가'),
                      content: SingleChildScrollView(
                        child: TextField(
                          controller: _customItemController,
                          decoration: const InputDecoration(
                            hintText: '스킨케어 항목을 입력하세요',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _customItemController.clear();
                          },
                          child: const Text('취소'),
                        ),
                        FilledButton(
                          onPressed: () {
                            if (_customItemController.text.trim().isNotEmpty) {
                              routineNotifier.addCustomItem(
                                selectedDate,
                                _customItemController.text.trim(),
                              );
                              Navigator.pop(context);
                              _customItemController.clear();
                            }
                          },
                          child: const Text('추가'),
                        ),
                      ],
                    ),
                  );
                },
                tooltip: '항목 추가',
                child: const Icon(Icons.playlist_add, size: 20, color: Colors.white),
              ),
              const SizedBox(height: 10),
              // Add Memo Button
              FloatingActionButton(
                heroTag: 'add_memo',
                mini: true,
                backgroundColor: theme.colorScheme.tertiary,
                onPressed: () {
                  setState(() => _isFabExpanded = false);
                  final currentMemo = routineNotifier.getMemo(selectedDate);
                  _memoController.text = currentMemo ?? '';
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('메모'),
                      content: TextField(
                        controller: _memoController,
                        decoration: const InputDecoration(
                          hintText: '오늘의 피부 상태나 메모를 입력하세요',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 5,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _memoController.clear();
                          },
                          child: const Text('취소'),
                        ),
                        FilledButton(
                          onPressed: () {
                            if (_memoController.text.trim().isNotEmpty) {
                              routineNotifier.setMemo(
                                selectedDate,
                                _memoController.text.trim(),
                              );
                            } else {
                              routineNotifier.clearMemo(selectedDate);
                            }
                            Navigator.pop(context);
                            _memoController.clear();
                          },
                          child: const Text('저장'),
                        ),
                      ],
                    ),
                  );
                },
                tooltip: '메모 추가',
                child: const Icon(Icons.note_add, size: 20, color: Colors.white),
              ),
              const SizedBox(height: 10),
            ],
            // Main FAB
            FloatingActionButton(
              heroTag: 'main',
              backgroundColor: theme.colorScheme.primary,
              onPressed: () {
                print('🔵 Main FAB pressed! Current state: $_isFabExpanded');
                setState(() => _isFabExpanded = !_isFabExpanded);
                print('🔵 New state: $_isFabExpanded');
              },
              child: AnimatedRotation(
                duration: const Duration(milliseconds: 200),
                turns: _isFabExpanded ? 0.125 : 0,
                child: Icon(
                  _isFabExpanded ? Icons.close : Icons.add,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(
    BuildContext context,
    ThemeData theme,
    String item,
    bool isChecked,
    DateTime selectedDate,
    SkincareRoutineNotifier routineNotifier,
  ) {
    return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isChecked
              ? theme.colorScheme.primary.withOpacity(0.1)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isChecked
                ? theme.colorScheme.primary.withOpacity(0.3)
                : (theme.brightness == Brightness.dark
                      ? Colors.grey[700]!
                      : Colors.grey[300]!),
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              routineNotifier.toggleItem(selectedDate, item);
            },
            onLongPress: () {
              print('🟡 Long press detected on: $item');
              // Show category selection dialog
              String? selectedCategory;
              final currentCategory = routineNotifier.getItemCategory(item, selectedDate) ?? 'Others';
              selectedCategory = currentCategory;

              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return StatefulBuilder(
                    builder: (context, setDialogState) {
                      return AlertDialog(
                        title: Text('"$item" 카테고리 변경'),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: categorizedItems.keys.map((category) {
                              return RadioListTile<String>(
                                title: Text(category),
                                value: category,
                                groupValue: selectedCategory,
                                onChanged: (value) {
                                  setDialogState(() {
                                    selectedCategory = value;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('취소'),
                          ),
                          FilledButton(
                            onPressed: () {
                              if (selectedCategory != null && selectedCategory != currentCategory) {
                                routineNotifier.moveItemToCategory(
                                  selectedDate,
                                  item,
                                  selectedCategory!,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('"$item"을(를) $selectedCategory(으)로 이동했습니다'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                              Navigator.pop(context);
                            },
                            child: const Text('이동'),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isChecked
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: isChecked
                          ? theme.colorScheme.primary
                          : (theme.brightness == Brightness.dark
                                ? Colors.grey[600]!
                                : Colors.grey[400]!),
                      width: 2,
                    ),
                  ),
                  child: isChecked
                      ? const Icon(
                          Icons.check,
                          size: 18,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isChecked
                          ? theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.6)
                          : theme.textTheme.bodyLarge?.color,
                      decoration: isChecked
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  iconSize: 20,
                  color: Colors.red.withOpacity(0.7),
                  onPressed: () {
                    routineNotifier.removeItem(selectedDate, item);
                  },
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _buildChecklistGroups(
    Map<String, bool> checklist,
    SkincareRoutineNotifier routineNotifier,
    DateTime selectedDate,
  ) {
    final List<Map<String, dynamic>> result = [];
    final routine = routineNotifier.getRoutineForDate(selectedDate);
    final categoryOverrides = routine?.categoryOverrides ?? {};

    // Build a map of category -> items considering overrides
    final Map<String, List<String>> effectiveCategories = {};
    
    for (final item in checklist.keys) {
      String? category;
      
      // Check if there's a custom override
      if (categoryOverrides.containsKey(item)) {
        category = categoryOverrides[item];
      } else {
        // Find the default category
        category = routineNotifier.getItemCategory(item, selectedDate);
      }
      
      category ??= 'Others';
      effectiveCategories.putIfAbsent(category, () => []);
      effectiveCategories[category]!.add(item);
    }

    // Build result with proper ordering (predefined categories first)
    for (final categoryEntry in categorizedItems.entries) {
      final category = categoryEntry.key;
      final items = effectiveCategories[category];
      
      if (items != null && items.isNotEmpty) {
        result.add({'type': 'category', 'title': category});
        
        for (final item in items) {
          result.add({
            'type': 'item',
            'item': item,
            'isChecked': checklist[item] ?? false,
            'category': category,
          });
        }
      }
    }

    // Add 'Others' category if it exists
    final othersItems = effectiveCategories['Others'];
    if (othersItems != null && othersItems.isNotEmpty) {
      result.add({'type': 'category', 'title': 'Others'});
      for (final item in othersItems) {
        result.add({
          'type': 'item',
          'item': item,
          'isChecked': checklist[item] ?? false,
          'category': 'Others',
        });
      }
    }

    return result;
  }
}
