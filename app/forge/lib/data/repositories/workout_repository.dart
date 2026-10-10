import 'package:drift/drift.dart';

import '../../domain/enums.dart';
import '../db/app_database.dart';

class WorkoutRepository {
  WorkoutRepository(this._db);
  final AppDatabase _db;

  // ---------- เริ่ม/จบการซ้อม ----------

  Future<String> start({String? routineId}) async {
    final id = newId();
    await _db.into(_db.workouts).insert(
          WorkoutsCompanion.insert(id: Value(id), routineId: Value(routineId)),
        );
    return id;
  }

  Future<void> finish(String workoutId, {String? note}) {
    final now = DateTime.now();
    return (_db.update(_db.workouts)..where((w) => w.id.equals(workoutId)))
        .write(
      WorkoutsCompanion(
        endedAt: Value(now),
        note: Value(note),
        updatedAt: Value(now),
      ),
    );
  }

  // ---------- บันทึกเซต ----------

  /// บันทึกเซตใหม่ ระบบกำหนด setNo ให้ต่อจากเซตล่าสุดของท่านั้นในการซ้อมนี้
  Future<String> logSet({
    required String workoutId,
    required String exerciseId,
    int? reps,
    double? weightKg,
    int? durationSec,
    double? distanceM,
  }) async {
    final existing = await (_db.select(_db.workoutSets)
          ..where((s) =>
              s.workoutId.equals(workoutId) & s.exerciseId.equals(exerciseId)))
        .get();
    final nextNo =
        existing.fold<int>(0, (m, s) => s.setNo > m ? s.setNo : m) + 1;

    final id = newId();
    await _db.into(_db.workoutSets).insert(
          WorkoutSetsCompanion.insert(
            id: Value(id),
            workoutId: workoutId,
            exerciseId: exerciseId,
            setNo: nextNo,
            reps: Value(reps),
            weightKg: Value(weightKg),
            durationSec: Value(durationSec),
            distanceM: Value(distanceM),
          ),
        );
    return id;
  }

  Future<void> updateSet(
    String setId, {
    int? reps,
    double? weightKg,
    int? durationSec,
    double? distanceM,
  }) {
    return (_db.update(_db.workoutSets)..where((s) => s.id.equals(setId)))
        .write(
      WorkoutSetsCompanion(
        reps: Value(reps),
        weightKg: Value(weightKg),
        durationSec: Value(durationSec),
        distanceM: Value(distanceM),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteSet(String setId) {
    return (_db.delete(_db.workoutSets)..where((s) => s.id.equals(setId))).go();
  }

  Stream<List<WorkoutSet>> watchSets(String workoutId) {
    return (_db.select(_db.workoutSets)
          ..where((s) => s.workoutId.equals(workoutId))
          ..orderBy([
            (s) => OrderingTerm.asc(s.doneAt),
            (s) => OrderingTerm.asc(s.setNo),
          ]))
        .watch();
  }

  /// เซตของท่านี้ในการซ้อมครั้งล่าสุดก่อนหน้า (ใช้เติมน้ำหนัก/ครั้งจากครั้งที่แล้วให้อัตโนมัติ)
  Future<List<WorkoutSet>> lastPerformance(
    String exerciseId, {
    String? excludeWorkoutId,
  }) async {
    final exclude = excludeWorkoutId;
    final latest = await (_db.select(_db.workoutSets)
          ..where((s) {
            final base = s.exerciseId.equals(exerciseId);
            return exclude == null
                ? base
                : base & s.workoutId.equals(exclude).not();
          })
          ..orderBy([(s) => OrderingTerm.desc(s.doneAt)])
          ..limit(1))
        .getSingleOrNull();
    if (latest == null) return const [];

    return (_db.select(_db.workoutSets)
          ..where((s) =>
              s.workoutId.equals(latest.workoutId) &
              s.exerciseId.equals(exerciseId))
          ..orderBy([(s) => OrderingTerm.asc(s.setNo)]))
        .get();
  }

  // ---------- ข้อมูลสำหรับหน้า Body / streak ----------

  /// วันที่ (ตัดเวลาออก) ที่มีการซ้อมที่จบแล้ว
  Stream<Set<DateTime>> watchWorkoutDays() {
    return (_db.select(_db.workouts)..where((w) => w.endedAt.isNotNull()))
        .watch()
        .map(
          (rows) => rows
              .map((w) => DateTime(
                  w.startedAt.year, w.startedAt.month, w.startedAt.day))
              .toSet(),
        );
  }

  JoinedSelectStatement<HasResultSet, dynamic> _recentStrengthSets() {
    final since = DateTime.now().subtract(const Duration(days: 30));
    return _db.select(_db.workoutSets).join([
      innerJoin(
        _db.exercises,
        _db.exercises.id.equalsExp(_db.workoutSets.exerciseId),
      ),
    ])
      ..where(
        _db.workoutSets.doneAt.isBiggerOrEqualValue(since) &
            _db.exercises.type.equalsValue(ExerciseType.strength),
      );
  }

  Map<MuscleGroup, DateTime> _lastTrained(List<TypedResult> rows) {
    final result = <MuscleGroup, DateTime>{};
    for (final r in rows) {
      final muscle = r.readTable(_db.exercises).primaryMuscle;
      final at = r.readTable(_db.workoutSets).doneAt;
      final current = result[muscle];
      if (current == null || at.isAfter(current)) result[muscle] = at;
    }
    return result;
  }

  /// เวลาที่ฝึกล่าสุดของแต่ละกล้ามเนื้อ (นับจากท่า strength และกล้ามเนื้อหลักเท่านั้น
  /// ย้อนหลัง 30 วัน — กล้ามเนื้อที่ไม่อยู่ในผลลัพธ์ถือว่าพักครบแล้ว)
  Future<Map<MuscleGroup, DateTime>> lastTrainedByMuscle() async {
    final rows = await _recentStrengthSets().get();
    return _lastTrained(rows);
  }

  Stream<Map<MuscleGroup, DateTime>> watchLastTrainedByMuscle() {
    return _recentStrengthSets().watch().map(_lastTrained);
  }
}
