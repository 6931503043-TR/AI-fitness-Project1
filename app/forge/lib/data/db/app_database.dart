import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../domain/enums.dart';
import 'seed.dart';
import 'tables.dart';

export 'tables.dart' show newId;

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Exercises,
    Routines,
    RoutineItems,
    Workouts,
    WorkoutSets,
    BodyMetrics,
    UserProfiles,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// ในแอปจริงไม่ต้องส่งอะไร (ใช้ไฟล์ SQLite บนเครื่อง)
  /// ในเทสต์ส่ง `NativeDatabase.memory()` เพื่อใช้ฐานข้อมูลในหน่วยความจำ
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'forge'));

  /// เพิ่มเลขนี้ทุกครั้งที่แก้โครงสร้างตาราง และเขียนขั้นตอนใน onUpgrade
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await seedInitialData(this);
        },
        onUpgrade: (m, from, to) async {
          // เวอร์ชัน 1 ยังไม่มีอะไรต้องอัปเกรด
          // เวอร์ชันถัดไปแนะนำให้ใช้ stepByStep(...) ของ drift
          // ร่วมกับ `dart run drift_dev schema dump` เพื่อทดสอบ migration ได้
        },
        beforeOpen: (details) async {
          // ต้องเปิดเองทุกครั้ง ไม่งั้น ON DELETE CASCADE / SET NULL ไม่ทำงาน
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
