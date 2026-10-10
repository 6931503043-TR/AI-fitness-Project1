import 'package:drift/drift.dart';

import '../../domain/enums.dart';
import 'app_database.dart';

/// ข้อมูลเริ่มต้น: คลังท่า + แผนตัวอย่าง 3 แผน (เหมือนกับข้อมูลในไฟล์ HTML เดิม)
/// ใช้ id คงที่ ('seed-...') เพื่อให้ท่ามาตรฐานอ้างอิงได้เสถียร
/// ถ้าไม่อยากให้มีแผนตัวอย่าง ให้ลบ _routines กับ _routineItems ออกได้
Future<void> seedInitialData(AppDatabase db) async {
  await db.batch((b) {
    b.insertAll(db.exercises, _exercises);
    b.insertAll(db.routines, _routines);
    b.insertAll(db.routineItems, _routineItems);
  });
}

ExercisesCompanion _ex(
  String id,
  String name,
  ExerciseType type,
  MuscleGroup primary, [
  List<MuscleGroup> secondary = const [],
]) {
  return ExercisesCompanion.insert(
    id: Value('seed-$id'),
    name: name,
    type: type,
    primaryMuscle: primary,
    secondaryMuscles: Value(secondary),
  );
}

const _s = ExerciseType.strength;
const _c = ExerciseType.cardio;
const _y = ExerciseType.yoga;

final List<ExercisesCompanion> _exercises = [
  // อก
  _ex('bench-press', 'เบนช์เพรส', _s, MuscleGroup.chest,
      [MuscleGroup.shoulders, MuscleGroup.arms]),
  _ex('incline-db-press', 'อินคลายน์ดัมเบลเพรส', _s, MuscleGroup.chest,
      [MuscleGroup.shoulders, MuscleGroup.arms]),
  _ex('push-up', 'วิดพื้น', _s, MuscleGroup.chest,
      [MuscleGroup.arms, MuscleGroup.core]),
  _ex('db-fly', 'ดัมเบลฟลาย', _s, MuscleGroup.chest),
  // หลัง
  _ex('pull-up', 'ดึงข้อบาร์', _s, MuscleGroup.back, [MuscleGroup.arms]),
  _ex('lat-pulldown', 'แล็ตพูลดาวน์', _s, MuscleGroup.back, [MuscleGroup.arms]),
  _ex('barbell-row', 'บาร์เบลโรว์', _s, MuscleGroup.back, [MuscleGroup.arms]),
  _ex('deadlift', 'เดดลิฟต์', _s, MuscleGroup.back,
      [MuscleGroup.legs, MuscleGroup.core]),
  // ขา
  _ex('squat', 'สควอท', _s, MuscleGroup.legs, [MuscleGroup.core]),
  _ex('leg-press', 'เลกเพรส', _s, MuscleGroup.legs),
  _ex('lunge', 'ลันจ์', _s, MuscleGroup.legs),
  _ex('rdl', 'โรมาเนียนเดดลิฟต์', _s, MuscleGroup.legs, [MuscleGroup.back]),
  _ex('calf-raise', 'ยืนเขย่งส้นเท้า', _s, MuscleGroup.legs),
  // ไหล่
  _ex('overhead-press', 'โอเวอร์เฮดเพรส', _s, MuscleGroup.shoulders,
      [MuscleGroup.arms]),
  _ex('lateral-raise', 'ดัมเบลยกไหล่ด้านข้าง', _s, MuscleGroup.shoulders),
  // แขน
  _ex('db-curl', 'ดัมเบลเคิร์ล', _s, MuscleGroup.arms),
  _ex('triceps-pushdown', 'ทริเซปส์พุชดาวน์', _s, MuscleGroup.arms),
  _ex('dips', 'ดิป', _s, MuscleGroup.arms, [MuscleGroup.chest]),
  // หน้าท้อง
  _ex('crunch', 'ครันช์', _s, MuscleGroup.core),
  // คาร์ดิโอ
  _ex('treadmill', 'วิ่งบนลู่', _c, MuscleGroup.fullBody),
  _ex('bike', 'ปั่นจักรยาน', _c, MuscleGroup.fullBody),
  _ex('jump-rope', 'กระโดดเชือก', _c, MuscleGroup.fullBody),
  // โยคะ
  _ex('sun-salutation', 'Sun salutation', _y, MuscleGroup.fullBody),
  _ex('warrior-2', 'ท่านักรบ (Warrior II)', _y, MuscleGroup.fullBody),
  _ex('child-pose', 'ท่าเด็ก (Child pose)', _y, MuscleGroup.fullBody),
  _ex('downward-dog', 'ท่าสุนัขก้มหน้า (Downward dog)', _y, MuscleGroup.fullBody),
];

final List<RoutinesCompanion> _routines = [
  RoutinesCompanion.insert(
    id: const Value('seed-routine-strength'),
    name: 'แผนยิม',
    type: ExerciseType.strength,
    sortOrder: const Value(0),
  ),
  RoutinesCompanion.insert(
    id: const Value('seed-routine-cardio'),
    name: 'แผนคาร์ดิโอ',
    type: ExerciseType.cardio,
    sortOrder: const Value(0),
  ),
  RoutinesCompanion.insert(
    id: const Value('seed-routine-yoga'),
    name: 'แผนโยคะ',
    type: ExerciseType.yoga,
    sortOrder: const Value(0),
  ),
];

RoutineItemsCompanion _item(
  String routineKey,
  String exerciseKey,
  int order, {
  int sets = 3,
  int? reps,
  double? weightKg,
  int? seconds,
}) {
  return RoutineItemsCompanion.insert(
    routineId: 'seed-routine-$routineKey',
    exerciseId: 'seed-$exerciseKey',
    sortOrder: Value(order),
    targetSets: Value(sets),
    targetReps: Value(reps),
    targetWeightKg: Value(weightKg),
    targetDurationSec: Value(seconds),
  );
}

final List<RoutineItemsCompanion> _routineItems = [
  _item('strength', 'bench-press', 0, sets: 4, reps: 8, weightKg: 60),
  _item('strength', 'squat', 1, sets: 4, reps: 10, weightKg: 80),
  _item('strength', 'pull-up', 2, sets: 3, reps: 8, weightKg: 0),
  _item('strength', 'db-curl', 3, sets: 3, reps: 12, weightKg: 12),
  _item('cardio', 'treadmill', 0, sets: 1, seconds: 20 * 60),
  _item('cardio', 'bike', 1, sets: 1, seconds: 15 * 60),
  _item('cardio', 'jump-rope', 2, sets: 3, seconds: 2 * 60),
  _item('yoga', 'sun-salutation', 0, sets: 3),
  _item('yoga', 'warrior-2', 1, sets: 2, seconds: 30),
  _item('yoga', 'child-pose', 2, sets: 1, seconds: 60),
];
