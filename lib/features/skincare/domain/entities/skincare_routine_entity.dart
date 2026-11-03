import 'package:equatable/equatable.dart';

/// Skincare routine entity
class SkincareRoutineEntity extends Equatable {
  final DateTime date;
  final Map<String, bool> checklist;
  final String? memo;
  final Map<String, String>? categoryOverrides; // Maps item name to custom category

  const SkincareRoutineEntity({
    required this.date,
    required this.checklist,
    this.memo,
    this.categoryOverrides,
  });

  SkincareRoutineEntity copyWith({
    DateTime? date,
    Map<String, bool>? checklist,
    String? memo,
    Map<String, String>? categoryOverrides,
  }) {
    return SkincareRoutineEntity(
      date: date ?? this.date,
      checklist: checklist ?? this.checklist,
      memo: memo ?? this.memo,
      categoryOverrides: categoryOverrides ?? this.categoryOverrides,
    );
  }

  @override
  List<Object?> get props => [date, checklist, memo, categoryOverrides];
}

