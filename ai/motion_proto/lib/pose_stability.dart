import 'dart:math' as math;

/// ตรรกะล้วน (ไม่แตะ ML Kit / กล้อง) สำหรับลดอาการจุดข้อต่อสั่นและสลับข้าง
/// แยกไฟล์เพื่อให้เทสต์ได้โดยไม่ต้องมีมือถือ

/// จุดหนึ่งจุดบนภาพ พร้อมความมั่นใจจากโมเดล (ใช้ทั้งเป็น input และ output)
class LmPoint {
  const LmPoint(this.x, this.y, this.likelihood);
  final double x;
  final double y;
  final double likelihood;
}

/// One Euro filter: ช้า/นิ่งเมื่อจุดแทบไม่ขยับ แต่ตามทันเมื่อขยับเร็ว
/// minCutoff (Hz) ต่ำ = นิ่งขึ้นแต่หน่วงขึ้น, beta สูง = ตามการขยับเร็วได้ดีขึ้น
class OneEuroFilter {
  double? _xHat;
  double? _dxHat;
  double? _prevRaw;

  double filter(
    double x,
    double dt, {
    required double minCutoff,
    required double beta,
    double dCutoff = 1.0,
  }) {
    final prevRaw = _prevRaw;
    final prevX = _xHat;
    if (prevRaw == null || prevX == null || dt <= 0) {
      _prevRaw = x;
      _xHat = x;
      _dxHat = 0;
      return x;
    }
    final dx = (x - prevRaw) / dt;
    _prevRaw = x;
    final prevD = _dxHat ?? 0;
    final dxHat = prevD + _alpha(dCutoff, dt) * (dx - prevD);
    _dxHat = dxHat;
    final cutoff = minCutoff + beta * dxHat.abs();
    final xHat = prevX + _alpha(cutoff, dt) * (x - prevX);
    _xHat = xHat;
    return xHat;
  }

  static double _alpha(double cutoff, double dt) {
    final tau = 1 / (2 * math.pi * cutoff);
    return 1 / (1 + tau / dt);
  }
}

class _Track {
  final fx = OneEuroFilter();
  final fy = OneEuroFilter();
  LmPoint? last;
  int missing = 0;
}

/// กรองตำแหน่งของแต่ละจุดข้อต่อ และ "ค้างค่าเดิมไว้" สั้นๆ เมื่อจุดหลุดชั่วคราว
/// (กันเส้นกระพริบหาย/โผล่) คืนเฉพาะจุดที่ผ่านเกณฑ์ minLikelihood หรือกำลังค้างอยู่
class LandmarkSmoother<K> {
  LandmarkSmoother({
    this.minCutoff = 1.5,
    this.beta = 8.0,
    this.minLikelihood = 0.5,
    this.holdFrames = 3,
    this.maxGapSec = 0.5,
  });

  double minCutoff;
  double beta;
  final double minLikelihood;
  final int holdFrames;
  final double maxGapSec;

  final Map<K, _Track> _tracks = {};

  /// [scale] ใช้ทำให้พิกัดเป็นหน่วยเทียบขนาดภาพ (เช่น ด้านที่ยาวที่สุดของภาพ)
  /// ทำให้ beta ไม่ขึ้นกับความละเอียดกล้อง
  /// [smooth] = false: ไม่กรอง แค่คัดจุดที่ likelihood พอ (ไว้เทียบก่อน/หลัง)
  Map<K, LmPoint> update(
    Map<K, LmPoint> raw,
    double dtSec, {
    required double scale,
    bool smooth = true,
  }) {
    if (!smooth) {
      _tracks.clear();
      return {
        for (final e in raw.entries)
          if (e.value.likelihood >= minLikelihood) e.key: e.value,
      };
    }
    if (dtSec > maxGapSec) _tracks.clear();

    final out = <K, LmPoint>{};
    final seen = <K>{};
    for (final e in raw.entries) {
      final p = e.value;
      if (p.likelihood < minLikelihood) continue;
      seen.add(e.key);
      final t = _tracks.putIfAbsent(e.key, _Track.new);
      t.missing = 0;
      final x = t.fx.filter(p.x / scale, dtSec,
              minCutoff: minCutoff, beta: beta) *
          scale;
      final y = t.fy.filter(p.y / scale, dtSec,
              minCutoff: minCutoff, beta: beta) *
          scale;
      final pt = LmPoint(x, y, p.likelihood);
      t.last = pt;
      out[e.key] = pt;
    }

    final stale = <K>[];
    _tracks.forEach((k, t) {
      if (seen.contains(k)) return;
      t.missing++;
      final last = t.last;
      if (last != null && t.missing <= holdFrames) {
        out[k] = last;
      } else {
        stale.add(k);
      }
    });
    for (final k in stale) {
      _tracks.remove(k);
    }
    return out;
  }

  void reset() => _tracks.clear();
}

/// เลือก "ข้าง" (ดัชนี) ที่ชัดที่สุด แต่ไม่สลับไปมาทุกเฟรม:
/// ต้องชัดกว่าข้างปัจจุบันอย่างน้อย [margin] ติดต่อกัน [confirmFrames] เฟรมถึงจะสลับ
class StickyPicker {
  StickyPicker({this.margin = 0.15, this.confirmFrames = 5});

  final double margin;
  final int confirmFrames;
  int? _current;
  int _streak = 0;

  /// [scores] ต่อข้าง (null = ข้างนั้นใช้ไม่ได้) คืนดัชนีที่เลือก หรือ null ถ้าไม่มีข้างใดใช้ได้
  int? pick(List<double?> scores) {
    int? best;
    for (var i = 0; i < scores.length; i++) {
      final s = scores[i];
      if (s == null) continue;
      if (best == null || s > scores[best]!) best = i;
    }
    if (best == null) {
      reset();
      return null;
    }
    final cur = _current;
    if (cur == null || cur >= scores.length || scores[cur] == null) {
      _current = best;
      _streak = 0;
      return best;
    }
    if (best != cur && scores[best]! - scores[cur]! >= margin) {
      _streak++;
      if (_streak >= confirmFrames) {
        _current = best;
        _streak = 0;
      }
    } else {
      _streak = 0;
    }
    return _current;
  }

  void reset() {
    _current = null;
    _streak = 0;
  }
}
