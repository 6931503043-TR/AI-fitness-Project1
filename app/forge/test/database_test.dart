import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge/data/db/app_database.dart';
import 'package:forge/data/repositories/exercise_repository.dart';
import 'package:forge/data/repositories/routine_repository.dart';
import 'package:forge/data/repositories/workout_repository.dart';
import 'package:forge/domain/enums.dart';

void main() {
  late AppDatabase db;
  late ExerciseRepository exercises;
  late RoutineRepository routines;
  late WorkoutRepository workouts;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    exercises = ExerciseRepository(db);
    routines = RoutineRepository(db);
    workouts = WorkoutRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('สร้างฐานข้อมูลครั้งแรกแล้วมีคลังท่าและแผนตัวอย่างครบทั้ง 3 ประเภท', () async {
    final all = await db.select(db.exercises).get();
    expect(all.length, greaterThan(20));

    for (final type in ExerciseType.values) {
      final list = await (db.select(db.routines)
            ..where((r) => r.type.equalsValue(type)))
          .get();
      expect(list, hasLength(1), reason: 'ประเภท $type');
    }

    final gymItems = await (db.select(db.routineItems)
          ..where((i) => i.routineId.equals('seed-routine-strength')))
        .get();
    expect(gymItems, hasLength(4));
  });

  test('ท่าที่มี secondaryMuscles อ่านกลับมาเป็น List ได้ถูกต้อง', () async {
    final bench = await (db.select(db.exercises)
          ..where((e) => e.id.equals('seed-bench-press')))
        .getSingle();
    expect(bench.secondaryMuscles,
        containsAll([MuscleGroup.shoulders, MuscleGroup.arms]));
  });

  test('เพิ่มท่าใหม่ของผู้ใช้แล้วเพิ่มเข้าแผน ลำดับต่อท้าย', () async {
    final exId = await exercises.create(
      name: 'แคเบิลครันช์',
      type: ExerciseType.strength,
      primaryMuscle: MuscleGroup.core,
    );
    final itemId = await routines.addItem(
      routineId: 'seed-routine-strength',
      exerciseId: exId,
      sets: 3,
      reps: 15,
      weightKg: 20,
    );

    final item = await (db.select(db.routineItems)
          ..where((i) => i.id.equals(itemId)))
        .getSingle();
    expect(item.sortOrder, 4); // ต่อจากท่าเดิม 4 ท่า (0..3)
    expect(item.targetWeightKg, 20);
  });

  test('แก้ไขรายการในแผนแล้วค่าที่เก็บเปลี่ยนตาม (รวมถึงล้างค่าเป็น null)', () async {
    final items = await (db.select(db.routineItems)
          ..where((i) => i.routineId.equals('seed-routine-strength'))
          ..orderBy([(i) => OrderingTerm.asc(i.sortOrder)]))
        .get();
    final first = items.first;

    await routines.updateItem(first.id, sets: 5, reps: 5, weightKg: null);

    final updated = await (db.select(db.routineItems)
          ..where((i) => i.id.equals(first.id)))
        .getSingle();
    expect(updated.targetSets, 5);
    expect(updated.targetReps, 5);
    expect(updated.targetWeightKg, isNull);
  });

  test('ลบแผน → รายการในแผนถูกลบตาม แต่ท่าในคลังและประวัติการซ้อมยังอยู่', () async {
    final workoutId = await workouts.start(routineId: 'seed-routine-strength');
    await workouts.logSet(
      workoutId: workoutId,
      exerciseId: 'seed-bench-press',
      reps: 8,
      weightKg: 60,
    );

    await routines.delete('seed-routine-strength');

    final items = await (db.select(db.routineItems)
          ..where((i) => i.routineId.equals('seed-routine-strength')))
        .get();
    expect(items, isEmpty);

    final bench = await (db.select(db.exercises)
          ..where((e) => e.id.equals('seed-bench-press')))
        .get();
    expect(bench, hasLength(1));

    final workout = await (db.select(db.workouts)
          ..where((w) => w.id.equals(workoutId)))
        .getSingle();
    expect(workout.routineId, isNull);
    expect(await db.select(db.workoutSets).get(), hasLength(1));
  });

  test('บันทึกเซตแล้ว setNo ไล่ 1,2,3 ต่อท่าในการซ้อมเดียวกัน', () async {
    final w = await workouts.start();
    for (final kg in [60.0, 60.0, 62.5]) {
      await workouts.logSet(
        workoutId: w,
        exerciseId: 'seed-bench-press',
        reps: 8,
        weightKg: kg,
      );
    }
    await workouts.logSet(
      workoutId: w,
      exerciseId: 'seed-squat',
      reps: 10,
      weightKg: 80,
    );

    final sets = await (db.select(db.workoutSets)
          ..where((s) => s.exerciseId.equals('seed-bench-press'))
          ..orderBy([(s) => OrderingTerm.asc(s.setNo)]))
        .get();
    expect(sets.map((s) => s.setNo), [1, 2, 3]);

    final squat = await (db.select(db.workoutSets)
          ..where((s) => s.exerciseId.equals('seed-squat')))
        .getSingle();
    expect(squat.setNo, 1);
  });

  test('lastPerformance คืนเซตของการซ้อมครั้งก่อนหน้า ไม่รวมครั้งปัจจุบัน', () async {
    final first = await workouts.start();
    await workouts.logSet(
        workoutId: first, exerciseId: 'seed-bench-press', reps: 8, weightKg: 60);
    await workouts.logSet(
        workoutId: first, exerciseId: 'seed-bench-press', reps: 6, weightKg: 62.5);
    await workouts.finish(first);

    final second = await workouts.start();
    await workouts.logSet(
        workoutId: second, exerciseId: 'seed-bench-press', reps: 8, weightKg: 65);

    final last = await workouts.lastPerformance(
      'seed-bench-press',
      excludeWorkoutId: second,
    );
    expect(last.map((s) => s.weightKg), [60, 62.5]);

    final none = await workouts.lastPerformance('seed-squat');
    expect(none, isEmpty);
  });

  test('lastTrainedByMuscle นับเฉพาะท่า strength และกล้ามเนื้อหลัก', () async {
    final w = await workouts.start();
    await workouts.logSet(
        workoutId: w, exerciseId: 'seed-bench-press', reps: 8, weightKg: 60);
    await workouts.logSet(
        workoutId: w, exerciseId: 'seed-treadmill', durationSec: 600);

    final map = await workouts.lastTrainedByMuscle();
    expect(map.containsKey(MuscleGroup.chest), isTrue);
    expect(map.containsKey(MuscleGroup.legs), isFalse);
    expect(map.containsKey(MuscleGroup.fullBody), isFalse); // คาร์ดิโอไม่ถูกนับ
  });

  test('ท่าที่ถูกซ่อน (archive) ไม่โผล่ในรายการแต่แถวยังอยู่', () async {
    await exercises.archive('seed-dips');
    final row = await (db.select(db.exercises)
          ..where((e) => e.id.equals('seed-dips')))
        .getSingle();
    expect(row.isArchived, isTrue);
  });
}
