import 'package:flutter_test/flutter_test.dart';
import 'package:motion_proto/pose_stability.dart';

void main() {
  const dt = 1 / 30;

  group('OneEuroFilter', () {
    test('จุดนิ่งที่มี noise ±2 แกว่งน้อยลงมาก', () {
      final f = OneEuroFilter();
      final out = <double>[];
      for (var i = 0; i < 90; i++) {
        out.add(f.filter(100 + (i.isEven ? 2 : -2), dt,
            minCutoff: 1.5, beta: 0));
      }
      final dev = out.skip(60).map((v) => (v - 100).abs()).reduce(
          (a, b) => a > b ? a : b);
      expect(dev, lessThan(0.5));
    });

    test('beta สูงทำให้ตามการขยับเร็วได้ทันกว่า beta = 0', () {
      double lag(double beta) {
        final f = OneEuroFilter();
        var y = 0.0;
        for (var i = 0; i < 120; i++) {
          y = f.filter(10.0 * i, dt, minCutoff: 1.5, beta: beta);
        }
        return 10.0 * 119 - y;
      }

      final noBeta = lag(0);
      final withBeta = lag(0.1);
      expect(withBeta, lessThan(noBeta));
      expect(withBeta, lessThan(5));
    });

    test('ค่าแรกคืนค่าเดิม ไม่หน่วง', () {
      final f = OneEuroFilter();
      expect(f.filter(42, dt, minCutoff: 1, beta: 0), 42);
    });
  });

  group('LandmarkSmoother', () {
    LandmarkSmoother<String> make() => LandmarkSmoother<String>();

    test('จุดที่ likelihood ต่ำถูกตัดทิ้ง', () {
      final s = make();
      final out = s.update({'a': const LmPoint(10, 10, 0.2)}, dt, scale: 100);
      expect(out, isEmpty);
    });

    test('จุดหลุดชั่วคราวค้างไว้ได้ holdFrames แล้วหายไป', () {
      final s = make();
      s.update({'a': const LmPoint(10, 10, 0.9)}, dt, scale: 100);
      for (var i = 0; i < 3; i++) {
        final out = s.update({'a': const LmPoint(0, 0, 0.1)}, dt, scale: 100);
        expect(out.containsKey('a'), isTrue, reason: 'เฟรมที่ ${i + 1}');
      }
      final out = s.update({'a': const LmPoint(0, 0, 0.1)}, dt, scale: 100);
      expect(out.containsKey('a'), isFalse);
    });

    test('smooth = false คืนค่าดิบตามเดิม (เฉพาะจุดที่ผ่านเกณฑ์)', () {
      final s = make();
      final out = s.update(
        {
          'a': const LmPoint(10, 20, 0.9),
          'b': const LmPoint(1, 1, 0.3),
        },
        dt,
        scale: 100,
        smooth: false,
      );
      expect(out.keys, ['a']);
      expect(out['a']!.x, 10);
      expect(out['a']!.y, 20);
    });

    test('ช่องว่างเวลานานเกิน maxGapSec ล้างสถานะ (ไม่ไหลจากตำแหน่งเก่า)', () {
      final s = make();
      s.update({'a': const LmPoint(10, 10, 0.9)}, dt, scale: 100);
      final out = s.update({'a': const LmPoint(90, 90, 0.9)}, 2.0, scale: 100);
      expect(out['a']!.x, closeTo(90, 1e-9));
    });
  });

  group('StickyPicker', () {
    test('เลือกข้างที่ชัดสุดตอนเริ่ม', () {
      final p = StickyPicker();
      expect(p.pick([0.9, 0.8]), 0);
    });

    test('ข้างอื่นชัดกว่าไม่ถึง margin ไม่สลับ', () {
      final p = StickyPicker();
      p.pick([0.9, 0.8]);
      for (var i = 0; i < 20; i++) {
        expect(p.pick([0.8, 0.85]), 0);
      }
    });

    test('ข้างอื่นชัดกว่าเกิน margin ต่อเนื่อง 5 เฟรมถึงสลับ', () {
      final p = StickyPicker();
      p.pick([0.9, 0.8]);
      for (var i = 0; i < 4; i++) {
        expect(p.pick([0.5, 0.9]), 0);
      }
      expect(p.pick([0.5, 0.9]), 1);
    });

    test('กลับมาไม่ชัดกว่าระหว่างนับ ตัวนับเริ่มใหม่', () {
      final p = StickyPicker();
      p.pick([0.9, 0.8]);
      for (var i = 0; i < 4; i++) {
        p.pick([0.5, 0.9]);
      }
      p.pick([0.9, 0.8]);
      expect(p.pick([0.5, 0.9]), 0);
    });

    test('ข้างปัจจุบันใช้ไม่ได้ สลับไปข้างที่เหลือทันที', () {
      final p = StickyPicker();
      p.pick([0.9, 0.8]);
      expect(p.pick([null, 0.7]), 1);
    });

    test('ไม่มีข้างใดใช้ได้คืน null', () {
      final p = StickyPicker();
      expect(p.pick([null, null]), isNull);
    });
  });
}
