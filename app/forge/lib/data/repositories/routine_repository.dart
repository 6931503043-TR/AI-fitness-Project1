import 'package:drift/drift.dart';

import '../../domain/enums.dart';
import '../db/app_database.dart';

/// รายการในแผน พร้อมข้อมูลท่าที่อ้างอิง (สำหรับแสดงผล)
class RoutineItemWithExercise {
  const RoutineItemWithExercise(this.item, this.exercise);
  final RoutineItem item;
  final Exercise exercise;
}

class RoutineRepository {
  RoutineRepository(this._db);
  final AppDatabase _db;

  // ---------- แผน ----------

  Stream<List<Routine>> watchByType(ExerciseType type) {
    return (_db.select(_db.routines)
          ..where((r) => r.type.equalsValue(type))
          ..orderBy([
            (r) => OrderingTerm.asc(r.sortOrder),
            (r) => OrderingTerm.asc(r.createdAt),
          ]))
        .watch();
  }

  Future<String> create({
    required String name,
    required ExerciseType type,
  }) async {
    final existing = await (_db.select(_db.routines)
          ..where((r) => r.type.equalsValue(type)))
        .get();
    final next = existing.fold<int>(-1, (m, r) => r.sortOrder > m ? r.sortOrder : m) + 1;

    final id = newId();
    await _db.into(_db.routines).insert(
          RoutinesCompanion.insert(
            id: Value(id),
            name: name.trim(),
            type: type,
            sortOrder: Value(next),
          ),
        );
    return id;
  }

  Future<void> rename(String id, String name) {
    return (_db.update(_db.routines)..where((r) => r.id.equals(id))).write(
      RoutinesCompanion(
        name: Value(name.trim()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// ลบแผน: รายการในแผนถูกลบตามอัตโนมัติ (cascade)
  /// ส่วนประวัติการซ้อมที่เคยทำจากแผนนี้ยังอยู่ (routineId ถูกตั้งเป็น null)
  Future<void> delete(String id) {
    return (_db.delete(_db.routines)..where((r) => r.id.equals(id))).go();
  }

  // ---------- รายการท่าในแผน ----------

  Stream<List<RoutineItemWithExercise>> watchItems(String routineId) {
    final query = _db.select(_db.routineItems).join([
      innerJoin(
        _db.exercises,
        _db.exercises.id.equalsExp(_db.routineItems.exerciseId),
      ),
    ])
      ..where(_db.routineItems.routineId.equals(routineId))
      ..orderBy([OrderingTerm.asc(_db.routineItems.sortOrder)]);

    return query.watch().map(
          (rows) => rows
              .map((r) => RoutineItemWithExercise(
                    r.readTable(_db.routineItems),
                    r.readTable(_db.exercises),
                  ))
              .toList(),
        );
  }

  Future<String> addItem({
    required String routineId,
    required String exerciseId,
    int sets = 3,
    int? reps,
    double? weightKg,
    int? durationSec,
  }) async {
    final maxOrder = _db.routineItems.sortOrder.max();
    final row = await (_db.selectOnly(_db.routineItems)
          ..addColumns([maxOrder])
          ..where(_db.routineItems.routineId.equals(routineId)))
        .getSingle();
    final next = (row.read(maxOrder) ?? -1) + 1;

    final id = newId();
    await _db.into(_db.routineItems).insert(
          RoutineItemsCompanion.insert(
            id: Value(id),
            routineId: routineId,
            exerciseId: exerciseId,
            targetSets: Value(sets),
            targetReps: Value(reps),
            targetWeightKg: Value(weightKg),
            targetDurationSec: Value(durationSec),
            sortOrder: Value(next),
          ),
        );
    return id;
  }

  Future<void> updateItem(
    String itemId, {
    required int sets,
    int? reps,
    double? weightKg,
    int? durationSec,
  }) {
    return (_db.update(_db.routineItems)..where((i) => i.id.equals(itemId)))
        .write(
      RoutineItemsCompanion(
        targetSets: Value(sets),
        targetReps: Value(reps),
        targetWeightKg: Value(weightKg),
        targetDurationSec: Value(durationSec),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> removeItem(String itemId) {
    return (_db.delete(_db.routineItems)..where((i) => i.id.equals(itemId)))
        .go();
  }
}
