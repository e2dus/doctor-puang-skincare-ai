import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../viewmodels/skincare_viewmodel.dart';

/// Calendar page for skincare routine tracking
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final TextEditingController _memoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  void dispose() {
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
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              // Prevent selecting future dates
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final selected = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
              
              if (selected.isAfter(today)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cannot select future dates. Please select today or a past date.'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              Future.microtask(
                  () => ref.read(skincareRoutineProvider.notifier).ensureRoutineExists(selectedDay));
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
              markerDecoration: const BoxDecoration(
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
                final routine = routineNotifier.getRoutineForDate(date);
                if (routine == null) return null;
                
                // Count checked items (체크된 항목 수)
                final checkedCount = routine.checklist.values.where((v) => v == true).length;

                if (checkedCount > 0) {
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _hasCheckedItems(routine)
                ? _buildChecklist(routine, selectedDate, theme, routineNotifier)
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_circle_outline,
                            size: 64,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Add your skincare routine today',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Track your daily skincare habits',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        FloatingActionButton.extended(
                          onPressed: () => _showSkincareSelectionDialog(context, routineNotifier, selectedDate),
                          backgroundColor: theme.colorScheme.primary,
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text(
                            'Get Started',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: _hasCheckedItems(routine)
          ? FloatingActionButton(
              onPressed: () => _showSkincareSelectionDialog(context, routineNotifier, selectedDate),
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  bool _hasCheckedItems(dynamic routine) {
    if (routine == null) return false;
    return routine.checklist.values.any((checked) => checked == true);
  }

  Widget _buildChecklist(
    dynamic routine,
    DateTime selectedDate,
    ThemeData theme,
    SkincareRoutineNotifier routineNotifier,
  ) {
    // Filter to show only checked items
    final checkedItems = routine.checklist.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: checkedItems.length,
            itemBuilder: (context, index) {
              final item = checkedItems[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.brightness == Brightness.dark
                        ? Colors.grey[700]!
                        : Colors.grey[300]!,
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _buildChecklistGroupsFromMap(
    Map<String, bool> checklist,
    dynamic routine,
    DateTime selectedDate,
    SkincareRoutineNotifier routineNotifier,
  ) {
    final List<Map<String, dynamic>> result = [];
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
        for (final entry in categorizedItems.entries) {
          if (entry.value.contains(item)) {
            category = entry.key;
            break;
          }
        }
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
        });
      }
    }

    return result;
  }

  void _showSkincareSelectionDialog(
    BuildContext context,
    SkincareRoutineNotifier routineNotifier,
    DateTime selectedDate,
  ) {
    // Ensure routine exists
    routineNotifier.ensureRoutineExists(selectedDate);
    final routine = routineNotifier.getRoutineForDate(selectedDate)!;
    final theme = Theme.of(context);

    // Create a temporary copy of the checklist for dialog state
    final Map<String, bool> tempChecklist = Map.from(routine.checklist);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final groups = _buildChecklistGroupsFromMap(tempChecklist, routine, selectedDate, routineNotifier);
          
          return AlertDialog(
            title: Text('Select Skincare Items for ${DateFormat('MMM d').format(selectedDate)}'),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];

                  if (group['type'] == 'category') {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Text(
                        group['title'] as String,
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
                            setDialogState(() {
                              tempChecklist[item] = !(tempChecklist[item] ?? false);
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isChecked ? theme.colorScheme.primary : Colors.transparent,
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
                                      ? const Icon(Icons.check, size: 18, color: Colors.white)
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
                                          ? theme.textTheme.bodyMedium?.color?.withOpacity(0.6)
                                          : theme.textTheme.bodyLarge?.color,
                                      decoration: isChecked ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              FilledButton(
                onPressed: () {
                  // Save the temp checklist to the actual routine
                  routineNotifier.updateChecklist(selectedDate, tempChecklist);
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
  }

}
