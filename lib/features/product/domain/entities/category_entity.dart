import 'package:equatable/equatable.dart';

/// Category entity representing product category information
class CategoryEntity extends Equatable {
  final String name;
  final int count;

  const CategoryEntity({required this.name, required this.count});

  @override
  List<Object?> get props => [name, count];
}
