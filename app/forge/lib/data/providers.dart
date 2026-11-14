import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/enums.dart';
import '../domain/streak.dart';
import 'db/app_database.dart';
import 'repositories/body_metrics_repository.dart';
import 'repositories/exercise_repository.dart';
import 'repositories/profile_repository.dart';
import 'repositories/routine_repository.dart';
import 'repositories/workout_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final exerciseRepositoryProvider =
    Provider((ref) => ExerciseRepository(ref.watch(databaseProvider)));

final routineRepositoryProvider =
    Provider((ref) => RoutineRepository(ref.watch(databaseProvider)));

final workoutRepositoryProvider =
    Provider((ref) => WorkoutRepository(ref.watch(databaseProvider)));

final profileRepositoryProvider =
    Provider((ref) => ProfileRepository(ref.watch(databaseProvider)));

final bodyMetricsRepositoryProvider =
    Provider((ref) => BodyMetricsRepository(ref.watch(databaseProvider)));

final exercisesByTypeProvider =
    StreamProvider.family<List<Exercise>, ExerciseType>((ref, type) {
  return ref.watch(exerciseRepositoryProvider).watchAll(type: type);
});

final routinesByTypeProvider =
    StreamProvider.family<List<Routine>, ExerciseType>((ref, type) {
  return ref.watch(routineRepositoryProvider).watchByType(type);
});

final routineItemsProvider =
    StreamProvider.family<List<RoutineItemWithExercise>, String>((ref, id) {
  return ref.watch(routineRepositoryProvider).watchItems(id);
});

/// สตรีค = จำนวนวันติดต่อกันที่มีการซ้อม
final streakProvider = StreamProvider<int>((ref) {
  return ref
      .watch(workoutRepositoryProvider)
      .watchWorkoutDays()
      .map((days) => computeStreak(days, DateTime.now()));
});

/// เวลาปัจจุบัน อัปเดตทุกนาที ใช้ขับเคลื่อนแถบพักฟื้นกล้ามเนื้อให้ขยับเอง
final nowProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now());
});

final lastTrainedByMuscleProvider =
    StreamProvider<Map<MuscleGroup, DateTime>>((ref) {
  return ref.watch(workoutRepositoryProvider).watchLastTrainedByMuscle();
});

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  return ref.watch(profileRepositoryProvider).watch();
});

final recentBodyMetricsProvider = StreamProvider<List<BodyMetric>>((ref) {
  return ref.watch(bodyMetricsRepositoryProvider).watchRecent();
});
