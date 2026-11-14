import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/enums.dart';

const _uuid = Uuid();

/// สร้างคีย์ UUID (ใช้ text เป็น primary key เพื่อรองรับ sync ในอนาคต)
String newId() => _uuid.v4();

/// เก็บ List<MuscleGroup> เป็นข้อความคั่นด้วยคอมมา เช่น "arms,shoulders"
class MuscleListConverter extends TypeConverter<List<MuscleGroup>, String> {
  const MuscleListConverter();

  @override
  List<MuscleGroup> fromSql(String fromDb) {
    if (fromDb.isEmpty) return const [];
    return fromDb.split(',').map((e) => MuscleGroup.values.byName(e)).toList();
  }

  @override
  String toSql(List<MuscleGroup> value) => value.map((e) => e.name).join(',');
}

/// คอลัมน์เวลาที่ทุกตารางข้อมูลผู้ใช้ควรมี
/// หมายเหตุ: updatedAt ต้องถูกตั้งค่าใหม่เองทุกครั้งที่แก้ข้อมูล (ทำใน repository)
mixin Timestamps on Table {
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now())();
}

/// คลังท่าออกกำลังกาย
class Exercises extends Table with Timestamps {
  TextColumn get id => text().clientDefault(newId)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get type => textEnum<ExerciseType>()();
  TextColumn get primaryMuscle => textEnum<MuscleGroup>()();
  TextColumn get secondaryMuscles => text()
      .map(const MuscleListConverter())
      .withDefault(const Constant(''))();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();

  /// ไม่ลบท่าจริง เพราะอาจมีประวัติการซ้อมอ้างอิงอยู่ ให้ซ่อนแทน
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// แผนการซ้อม (แม่แบบ) เช่น Push / Pull / Legs
class Routines extends Table with Timestamps {
  TextColumn get id => text().clientDefault(newId)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get type => textEnum<ExerciseType>()();

  /// 1 = จันทร์ ... 7 = อาทิตย์ (ไม่บังคับ)
  IntColumn get weekday => integer().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_routine_items_routine', columns: {#routineId})
class RoutineItems extends Table with Timestamps {
  TextColumn get id => text().clientDefault(newId)();
  TextColumn get routineId =>
      text().references(Routines, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  IntColumn get targetSets => integer().withDefault(const Constant(3))();
  IntColumn get targetReps => integer().nullable()();
  RealColumn get targetWeightKg => real().nullable()(); // เก็บเป็น กก. เสมอ
  IntColumn get targetDurationSec => integer().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// การซ้อมที่เกิดขึ้นจริงหนึ่งครั้ง
class Workouts extends Table with Timestamps {
  TextColumn get id => text().clientDefault(newId)();
  TextColumn get routineId => text()
      .nullable()
      .references(Routines, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get startedAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// เซตที่ทำจริง
@TableIndex(name: 'idx_workout_sets_exercise_done', columns: {#exerciseId, #doneAt})
class WorkoutSets extends Table with Timestamps {
  TextColumn get id => text().clientDefault(newId)();
  TextColumn get workoutId =>
      text().references(Workouts, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  IntColumn get setNo => integer()();
  IntColumn get reps => integer().nullable()();
  RealColumn get weightKg => real().nullable()(); // เก็บเป็น กก. เสมอ
  IntColumn get durationSec => integer().nullable()();
  RealColumn get distanceM => real().nullable()();
  DateTimeColumn get doneAt => dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};
}

class BodyMetrics extends Table with Timestamps {
  TextColumn get id => text().clientDefault(newId)();
  DateTimeColumn get measuredOn => dateTime()();
  RealColumn get weightKg => real()();
  RealColumn get bodyFatPct => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// โปรไฟล์ผู้ใช้ (ใช้แถวเดียว)
class UserProfiles extends Table with Timestamps {
  TextColumn get id => text().clientDefault(newId)();
  TextColumn get gender => textEnum<Gender>()();
  IntColumn get birthYear => integer()();
  RealColumn get heightCm => real()();
  TextColumn get activityLevel => textEnum<ActivityLevel>()();

  @override
  Set<Column> get primaryKey => {id};
}

/// การตั้งค่าแอปแบบ key-value เช่น หน่วยน้ำหนัก ภาษา เวลาพักกล้ามเนื้อ
class AppSettings extends Table {
  TextColumn get settingKey => text()();
  TextColumn get settingValue => text()();

  @override
  Set<Column> get primaryKey => {settingKey};
}
