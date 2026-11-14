import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge/data/db/app_database.dart';
import 'package:forge/data/repositories/body_metrics_repository.dart';
import 'package:forge/data/repositories/profile_repository.dart';
import 'package:forge/data/repositories/workout_repository.dart';
import 'package:forge/domain/enums.dart';
import 'package:forge/domain/recovery.dart';

void main() {
  late AppDatabase db;
  late ProfileRepository profile;
  late BodyMetricsRepository metrics;
  late WorkoutRepository workouts;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    profile = ProfileRepository(db);
    metrics = BodyMetricsRepository(db);
    workouts = WorkoutRepository(db);
  });

  tearDown(() async => db.close());

  group('ProfileRepository', () {
    test('ยังไม่มีโปรไฟล์ตอนแรก', () async {
      expect(await profile.get(), isNull);
    });

    test('save ครั้งแรกสร้างแถวใหม่ เรียกซ้ำแก้ไขแถวเดิม (ไม่สร้างซ้ำ)', () async {
      await profile.save(
        gender: Gender.male,
        birthYear: 1998,
        heightCm: 172,
        activityLevel: ActivityLevel.moderate,
      );
      await profile.save(
        gender: Gender.male,
        birthYear: 1998,
        heightCm: 175,
        activityLevel: ActivityLevel.active,
      );

      final p = await profile.get();
      expect(p!.heightCm, 175);
      expect(p.activityLevel, ActivityLevel.active);

      final all = await db.select(db.userProfiles).get();
      expect(all, hasLength(1));
    });
  });

  group('BodyMetricsRepository', () {
    test('บันทึกน้ำหนักวันเดียวกันซ้ำ = อัปเดตแถวเดิมแทนการเพิ่มแถวใหม่', () async {
      final today = DateTime.now();
      await metrics.logWeight(weightKg: 68, on: today);
      await metrics.logWeight(weightKg: 68.5, on: today);

      final all = await metrics.watchRecent().first;
      expect(all, hasLength(1));
      expect(all.first.weightKg, 68.5);
    });

    test('latest คืนค่าของวันล่าสุด', () async {
      await metrics.logWeight(weightKg: 70, on: DateTime(2026, 9, 1));
      await metrics.logWeight(weightKg: 69, on: DateTime(2026, 9, 10));

      final latest = await metrics.latest();
      expect(latest!.weightKg, 69);
    });

    test('ลบรายการแล้วหายจากรายการ', () async {
      await metrics.logWeight(weightKg: 68, on: DateTime(2026, 9, 1));
      final row = await metrics.latest();
      await metrics.delete(row!.id);
      expect(await metrics.latest(), isNull);
    });
  });

  group('การพักฟื้นอิงจากข้อมูลจริงผ่าน workouts + recovery', () {
    test('กล้ามเนื้อที่ยังไม่เคยฝึกเลยถือว่าพร้อมฝึก', () async {
      final map = await workouts.lastTrainedByMuscle();
      final now = DateTime.now();
      for (final m in bodyScreenMuscleOrder) {
        final r = recoveryOf(muscle: m, lastTrained: map[m], now: now);
        expect(r.isRecovered, isTrue);
      }
    });

    test('ฝึกอกไปแล้ว ยังไม่พักครบ progress ต้องน้อยกว่า 1', () async {
      final w = await workouts.start();
      await workouts.logSet(
          workoutId: w, exerciseId: 'seed-bench-press', reps: 8, weightKg: 60);

      final map = await workouts.lastTrainedByMuscle();
      final r = recoveryOf(
        muscle: MuscleGroup.chest,
        lastTrained: map[MuscleGroup.chest],
        now: DateTime.now(),
      );
      expect(r.isRecovered, isFalse);
      expect(r.progress, lessThan(0.1));
    });
  });
}
