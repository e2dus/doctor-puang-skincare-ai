import 'package:equatable/equatable.dart';

/// User entity representing the core user data
class UserEntity extends Equatable {
  final String? id;
  final String email;
  final String? name;

  const UserEntity({
    this.id,
    required this.email,
    this.name,
  });

  @override
  List<Object?> get props => [id, email, name];
}

