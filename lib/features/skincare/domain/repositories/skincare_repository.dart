import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/skincare_routine_entity.dart';

/// Abstract repository for skincare operations
abstract class SkincareRepository {
  /// Get routine for a specific date
  Future<Either<Failure, SkincareRoutineEntity?>> getRoutineForDate(DateTime date);

  /// Save routine for a specific date
  Future<Either<Failure, void>> saveRoutine(SkincareRoutineEntity routine);

  /// Toggle item in checklist
  Future<Either<Failure, void>> toggleItem(DateTime date, String item);

  /// Add custom item to checklist
  Future<Either<Failure, void>> addCustomItem(DateTime date, String item);

  /// Remove item from checklist
  Future<Either<Failure, void>> removeItem(DateTime date, String item);
}

