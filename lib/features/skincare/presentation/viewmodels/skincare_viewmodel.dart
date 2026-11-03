import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/skincare_routine_entity.dart';

/// Categorized skincare items
const Map<String, List<String>> categorizedItems = {
  'Cleansing': ['Cleanser'],
  'Basic care': ['Toner/Essence', 'Serum/Ampoule'],
  'Moisturizing': ['Lotion', 'Cream'],
  'Sun protection': ['Sunscreen'],
  'Special care': ['Sheet mask', 'Peeling', 'Ampoule mask', 'Eye cream', 'Double cleansing'],
};

/// Get default skincare items
List<String> get defaultItems {
  return categorizedItems.values.expand((items) => items).toList();
}

/// Skincare routine state notifier
class SkincareRoutineNotifier extends Notifier<Map<String, SkincareRoutineEntity>> {
  @override
  Map<String, SkincareRoutineEntity> build() {
    return {};
  }

  String dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  SkincareRoutineEntity? getRoutineForDate(DateTime date) {
    final key = dateKey(date);
    return state[key];
  }

  void ensureRoutineExists(DateTime date) {
    final key = dateKey(date);
    if (!state.containsKey(key)) {
      final checklist = {for (var item in defaultItems) item: false};
      state = {
        ...state,
        key: SkincareRoutineEntity(date: date, checklist: checklist)
      };
    }
  }

  void toggleItem(DateTime date, String item) {
    ensureRoutineExists(date);
    final key = dateKey(date);
    final routine = state[key]!;
    final updatedChecklist = {...routine.checklist};
    updatedChecklist[item] = !(updatedChecklist[item] ?? false);

    state = {
      ...state,
      key: routine.copyWith(checklist: updatedChecklist),
    };
  }

  void updateChecklist(DateTime date, Map<String, bool> newChecklist) {
    ensureRoutineExists(date);
    final key = dateKey(date);
    final routine = state[key]!;

    state = {
      ...state,
      key: routine.copyWith(checklist: newChecklist),
    };
  }

  void addCustomItem(DateTime date, String item) {
    ensureRoutineExists(date);
    final key = dateKey(date);
    final routine = state[key]!;
    final updatedChecklist = {...routine.checklist, item: false};

    state = {
      ...state,
      key: routine.copyWith(checklist: updatedChecklist),
    };
  }

  void removeItem(DateTime date, String item) {
    ensureRoutineExists(date);
    final key = dateKey(date);
    final routine = state[key]!;
    final updatedChecklist = {...routine.checklist};
    updatedChecklist.remove(item);

    state = {
      ...state,
      key: routine.copyWith(checklist: updatedChecklist),
    };
  }

  /// Move an item to a different category
  void moveItemToCategory(DateTime date, String item, String newCategory) {
    ensureRoutineExists(date);
    final key = dateKey(date);
    final routine = state[key]!;
    final updatedOverrides = {...?routine.categoryOverrides};
    updatedOverrides[item] = newCategory;

    state = {
      ...state,
      key: routine.copyWith(categoryOverrides: updatedOverrides),
    };
  }

  /// Get the category of an item
  String? getItemCategory(String item, [DateTime? date]) {
    // Check for custom override first
    if (date != null) {
      final routine = getRoutineForDate(date);
      if (routine?.categoryOverrides?.containsKey(item) == true) {
        return routine!.categoryOverrides![item];
      }
    }
    
    // Fall back to default categories
    for (final entry in categorizedItems.entries) {
      if (entry.value.contains(item)) {
        return entry.key;
      }
    }
    return null;
  }

  int getCompletedCount(DateTime date) {
    final routine = getRoutineForDate(date);
    if (routine == null) return 0;
    
    // Exclude Special care items from completed count (considering overrides)
    return routine.checklist.entries
        .where((entry) {
          if (!entry.value) return false; // Not checked
          
          // Check actual category (with overrides)
          final actualCategory = getItemCategory(entry.key, date);
          return actualCategory != 'Special care';
        })
        .length;
  }

  int getTotalCount(DateTime date) {
    final routine = getRoutineForDate(date);
    if (routine == null) return 0;
    
    // Exclude Special care items from total count (considering overrides)
    return routine.checklist.keys
        .where((item) {
          // Check actual category (with overrides)
          final actualCategory = getItemCategory(item, date);
          return actualCategory != 'Special care';
        })
        .length;
  }

  /// Get memo for a specific date
  String? getMemo(DateTime date) {
    final routine = getRoutineForDate(date);
    return routine?.memo;
  }

  /// Set memo for a specific date
  void setMemo(DateTime date, String memo) {
    ensureRoutineExists(date);
    final key = dateKey(date);
    final routine = state[key]!;

    state = {
      ...state,
      key: routine.copyWith(memo: memo),
    };
  }

  /// Clear memo for a specific date
  void clearMemo(DateTime date) {
    ensureRoutineExists(date);
    final key = dateKey(date);
    final routine = state[key]!;

    state = {
      ...state,
      key: routine.copyWith(memo: null),
    };
  }
}

/// Provider for skincare routine
final skincareRoutineProvider =
    NotifierProvider<SkincareRoutineNotifier, Map<String, SkincareRoutineEntity>>(() {
  return SkincareRoutineNotifier();
});

