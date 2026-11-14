import 'package:flutter_test/flutter_test.dart';
import 'package:forge/domain/enums.dart';
import 'package:forge/domain/recovery.dart';
import 'package:forge/domain/streak.dart';
import 'package:forge/domain/tdee.dart';

void main() {
  group('TDEE', () {
    test('ชาย 28 ปี 68 กก. 172 ซม. ตรงกับค่าในไฟล์ HTML เดิม', () {
      final bmr = bmrMifflinStJeor(
        gender: Gender.male,
        weightKg: 68,
        heightCm: 172,
        age: 28,
      );
      expect(bmr, 1620);
      expect(calcTdee(bmr, ActivityLevel.moderate).round(), 2511);
    });

    test('สูตรของผู้หญิงใช้ค่าคงที่ -161', () {
      final bmr = bmrMifflinStJeor(
        gender: Gender.female,
        weightKg: 68,
        heightCm: 172,
        age: 28,
      );
      expect(bmr, 1454);
    });

    test('ค่า BMR ไม่ติดลบ', () {
      final bmr = bmrMifflinStJeor(
        gender: Gender.female,
        weightKg: 0,
        heightCm: 0,
        age: 90,
      );
      expect(bmr, 0);
    });
  });

  group('streak', () {
    final now = DateTime(2026, 9, 25, 10);

    test('ซ้อมติดต่อกัน 3 วันรวมวันนี้ = 3', () {
      final days = [
        DateTime(2026, 9, 25, 7),
        DateTime(2026, 9, 24, 18),
        DateTime(2026, 9, 23, 6),
      ];
      expect(computeStreak(days, now), 3);
    });

    test('วันนี้ยังไม่ซ้อมแต่เมื่อวานซ้อม สตรีคยังไม่ขาด', () {
      expect(computeStreak([DateTime(2026, 9, 24)], now), 1);
    });

    test('ขาดไปหนึ่งวันเต็ม สตรีคเป็น 0', () {
      expect(computeStreak([DateTime(2026, 9, 23)], now), 0);
    });

    test('ข้ามวันตรงกลางแล้วนับเฉพาะช่วงล่าสุด', () {
      final days = [DateTime(2026, 9, 25), DateTime(2026, 9, 23)];
      expect(computeStreak(days, now), 1);
    });

    test('ไม่มีข้อมูลเลย = 0', () {
      expect(computeStreak(const [], now), 0);
    });
  });

  group('recovery', () {
    final now = DateTime(2026, 9, 25, 12);

    test('อกฝึกมา 24 ชม. จาก 48 ชม. = ครึ่งทาง เหลืออีก 24 ชม.', () {
      final r = recoveryOf(
        muscle: MuscleGroup.chest,
        lastTrained: now.subtract(const Duration(hours: 24)),
        now: now,
      );
      expect(r.progress, closeTo(0.5, 1e-9));
      expect(r.hoursLeft, closeTo(24, 1e-9));
      expect(r.isRecovered, isFalse);
    });

    test('ขาพัก 80 ชม. เกิน 72 ชม. = พร้อมฝึก', () {
      final r = recoveryOf(
        muscle: MuscleGroup.legs,
        lastTrained: now.subtract(const Duration(hours: 80)),
        now: now,
      );
      expect(r.isRecovered, isTrue);
      expect(r.hoursLeft, 0);
    });

    test('ไม่เคยฝึก = พร้อมฝึก', () {
      final r = recoveryOf(muscle: MuscleGroup.back, lastTrained: null, now: now);
      expect(r.isRecovered, isTrue);
    });

    test('ปรับเวลาพักเองได้', () {
      final r = recoveryOf(
        muscle: MuscleGroup.arms,
        lastTrained: now.subtract(const Duration(hours: 10)),
        now: now,
        restHours: const {MuscleGroup.arms: 20},
      );
      expect(r.progress, closeTo(0.5, 1e-9));
    });
  });
}
