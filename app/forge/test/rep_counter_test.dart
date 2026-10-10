import 'package:flutter_test/flutter_test.dart';
import 'package:forge/domain/rep_counter.dart';

void main() {
  group('angleDeg', () {
    test('มุมฉาก = 90', () {
      expect(angleDeg(const Pt(0, 1), const Pt(0, 0), const Pt(1, 0)),
          closeTo(90, 1e-9));
    });

    test('เหยียดตรง = 180', () {
      expect(angleDeg(const Pt(-1, 0), const Pt(0, 0), const Pt(1, 0)),
          closeTo(180, 1e-9));
    });

    test('พับทับกัน = 0', () {
      expect(angleDeg(const Pt(1, 0), const Pt(0, 0), const Pt(2, 0)),
          closeTo(0, 1e-9));
    });

    test('จุดทับกันคืน NaN', () {
      expect(angleDeg(const Pt(0, 0), const Pt(0, 0), const Pt(1, 0)).isNaN,
          isTrue);
    });

    test('ไม่ขึ้นกับการหมุนหรือกลับภาพ (ใช้ได้ทั้งกล้องหน้า/หลังและทุกการหมุนจอ)', () {
      final a = angleDeg(const Pt(0, 1), const Pt(0, 0), const Pt(1, 1));
      final mirrored = angleDeg(const Pt(0, 1), const Pt(0, 0), const Pt(-1, 1));
      final rotated = angleDeg(const Pt(1, 0), const Pt(0, 0), const Pt(1, -1));
      expect(mirrored, closeTo(a, 1e-9));
      expect(rotated, closeTo(a, 1e-9));
    });
  });

  group('RepCounter (สควอท: ลง <100, ขึ้น >160)', () {
    final spec = moveSpecs[TrackedMove.squat]!;

    /// ป้อนมุมหลายค่าติดกัน (ใช้ smoothing = 1 เพื่อไม่ให้ค่าเรียบจนเทสต์อ่านยาก)
    int feed(RepCounter c, List<double> angles) {
      for (final a in angles) {
        c.update(a);
      }
      return c.reps;
    }

    test('ลงแล้วขึ้น 3 รอบ = 3 ครั้ง', () {
      final c = RepCounter(spec, smoothing: 1);
      final seq = <double>[170, 130, 90, 130, 170, 120, 80, 120, 170, 100, 70, 110, 170];
      expect(feed(c, seq), 3);
    });

    test('ลงไม่ถึงเกณฑ์ ไม่นับ', () {
      final c = RepCounter(spec, smoothing: 1);
      expect(feed(c, [170, 120, 110, 120, 170]), 0);
    });

    test('ลงแล้วไม่ขึ้นสุด ไม่นับ', () {
      final c = RepCounter(spec, smoothing: 1);
      expect(feed(c, [170, 90, 140, 150, 140]), 0);
    });

    test('มุมสั่นอยู่ระหว่างสองเกณฑ์ ไม่นับเกิน', () {
      final c = RepCounter(spec, smoothing: 1);
      expect(feed(c, [170, 90, 130, 95, 130, 105, 165]), 1);
    });

    test('เริ่มตอนอยู่ในท่างอ ต้องเหยียดก่อนถึงเริ่มนับ (ไม่นับครั้งแรกเกิน)', () {
      final c = RepCounter(spec, smoothing: 1);
      expect(feed(c, [80, 120, 170]), 0);
      expect(feed(c, [90, 170]), 1);
    });

    test('NaN ถูกข้าม ไม่ทำให้พัง', () {
      final c = RepCounter(spec, smoothing: 1);
      c.update(double.nan);
      expect(c.reps, 0);
      expect(c.smoothedAngle, isNull);
    });

    test('reset ล้างค่าทั้งหมด', () {
      final c = RepCounter(spec, smoothing: 1);
      feed(c, [170, 90, 170]);
      expect(c.reps, 1);
      c.reset();
      expect(c.reps, 0);
      expect(c.isDown, isFalse);
    });
  });

  test('วิดพื้นใช้ข้างที่ชัดกว่าข้างเดียว ส่วนท่าอื่นเฉลี่ยสองข้าง', () {
    expect(moveSpecs[TrackedMove.pushUp]!.bestSideOnly, isTrue);
    expect(moveSpecs[TrackedMove.squat]!.bestSideOnly, isFalse);
    expect(moveSpecs[TrackedMove.curl]!.bestSideOnly, isFalse);
  });

  test('armed เป็น true หลังเหยียดถึงเกณฑ์ขึ้นครั้งแรก', () {
    final c = RepCounter(moveSpecs[TrackedMove.squat]!, smoothing: 1);
    expect(c.armed, isFalse);
    c.update(170);
    expect(c.armed, isTrue);
  });

  test('ทุกท่ามีเกณฑ์ที่สมเหตุสมผล (down < up) และอ้าง id ของท่าใน seed', () {
    for (final entry in moveSpecs.entries) {
      expect(entry.value.downBelow, lessThan(entry.value.upAbove),
          reason: '${entry.key}');
      expect(entry.value.exerciseId, startsWith('seed-'));
    }
  });
}
