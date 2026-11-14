import 'package:drift/drift.dart';

import '../../domain/enums.dart';
import '../db/app_database.dart';

class ExerciseRepository {
  ExerciseRepository(this._db);
  final AppDatabase _db;

  /// ท่าที่ยังไม่ถูกซ่อน เรียงตามชื่อ (กรองตามประเภทได้)
  Stream<List<Exercise>> watchAll({ExerciseType? type}) {
    final query = _db.select(_db.exercises)
      ..where((e) => e.isArchived.equals(false))
      ..orderBy([(e) => OrderingTerm.asc(e.name)]);
    final t = type;
    if (t != null) {
      query.where((e) => e.type.equalsValue(t));
    }
    return query.watch();
  }

  /// สร้างท่าใหม่ของผู้ใช้ คืนค่า id
  Future<String> create({
    required String name,
    required ExerciseType type,
    required MuscleGroup primaryMuscle,
    List<MuscleGroup> secondaryMuscles = const [],
  }) async {
    final id = newId();
    await _db.into(_db.exercises).insert(
          ExercisesCompanion.insert(
            id: Value(id),
            name: name.trim(),
            type: type,
            primaryMuscle: primaryMuscle,
            secondaryMuscles: Value(secondaryMuscles),
            isCustom: const Value(true),
          ),
        );
    return id;
  }

  Future<void> rename(String id, String name) {
    return (_db.update(_db.exercises)..where((e) => e.id.equals(id))).write(
      ExercisesCompanion(
        name: Value(name.trim()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// ซ่อนท่าจากรายการ (ไม่ลบจริง เพื่อไม่ให้ประวัติการซ้อมพัง)
  Future<void> archive(String id) {
    return (_db.update(_db.exercises)..where((e) => e.id.equals(id))).write(
      ExercisesCompanion(
        isArchived: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
