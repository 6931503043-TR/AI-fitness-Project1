import 'dart:math' as math;

/// จุดบนภาพ 2 มิติ (แยกจาก ML Kit เพื่อให้ตรรกะนี้เทสต์ได้โดยไม่ต้องมีกล้อง)
class Pt {
  const Pt(this.x, this.y);
  final double x;
  final double y;
}

/// มุมที่จุด [b] ระหว่างเส้น b→a กับ b→c หน่วยองศา (0-180)
/// คืน NaN ถ้าสองจุดทับกัน (คำนวณมุมไม่ได้)
double angleDeg(Pt a, Pt b, Pt c) {
  final v1x = a.x - b.x, v1y = a.y - b.y;
  final v2x = c.x - b.x, v2y = c.y - b.y;
  final m1 = math.sqrt(v1x * v1x + v1y * v1y);
  final m2 = math.sqrt(v2x * v2x + v2y * v2y);
  if (m1 == 0 || m2 == 0) return double.nan;
  final cos = ((v1x * v2x + v1y * v2y) / (m1 * m2)).clamp(-1.0, 1.0).toDouble();
  return math.acos(cos) * 180 / math.pi;
}

enum TrackedMove { squat, pushUp, curl }

class MoveSpec {
  const MoveSpec({
    required this.label,
    required this.exerciseId,
    required this.downBelow,
    required this.upAbove,
    required this.hint,
    this.bestSideOnly = false,
  });

  final String label;

  /// id ของท่าในคลังท่า (seed) ที่จะบันทึกเซตลงไป
  final String exerciseId;

  /// มุมข้อต่อต่ำกว่านี้ = อยู่ในช่วง "ลง/งอ"
  final double downBelow;

  /// มุมข้อต่อสูงกว่านี้ = กลับมา "ขึ้น/เหยียด" ครบ 1 ครั้ง
  final double upAbove;
  final String hint;

  /// true = ใช้มุมของข้างที่เห็นชัดกว่าเพียงข้างเดียว (เหมาะกับท่าที่ถ่ายด้านข้าง
  /// ซึ่งอีกข้างถูกลำตัวบัง จึงมักถูกเดาตำแหน่งและทำให้ค่าเฉลี่ยเพี้ยน)
  /// false = เฉลี่ยทั้งสองข้างที่เห็นชัดพอ
  final bool bestSideOnly;
}

/// ค่าเกณฑ์มุมเป็นค่าเริ่มต้นที่ประมาณขึ้นเอง ยังไม่ได้ปรับจากการทดสอบจริง
/// คาดว่าต้องจูนหลังลองกับกล้องจริง (มุมกล้อง ระยะ ความลึกของท่า มีผลมาก)
const Map<TrackedMove, MoveSpec> moveSpecs = {
  TrackedMove.squat: MoveSpec(
    label: 'สควอท',
    exerciseId: 'seed-squat',
    downBelow: 100,
    upAbove: 160,
    hint: 'วางมือถือไว้ด้านข้าง เห็นตัวเต็ม ตั้งแต่สะโพกถึงข้อเท้า',
  ),
  TrackedMove.pushUp: MoveSpec(
    label: 'วิดพื้น',
    exerciseId: 'seed-push-up',
    downBelow: 90,
    upAbove: 155,
    hint: 'วางมือถือไว้ด้านข้างระดับพื้น เห็นไหล่ ศอก และข้อมือ',
    bestSideOnly: true,
  ),
  TrackedMove.curl: MoveSpec(
    label: 'เคิร์ล',
    exerciseId: 'seed-db-curl',
    downBelow: 50,
    upAbove: 150,
    hint: 'ยืนหันหน้าหรือหันข้าง เห็นแขนทั้งท่อน',
  ),
};

/// นับครั้งด้วย hysteresis: ต้องงอต่ำกว่า downBelow แล้วเหยียดเกิน upAbove จึงนับ 1 ครั้ง
/// มุมที่แกว่งอยู่ระหว่างสองเกณฑ์ไม่ถูกนับ และต้อง "เหยียด" ก่อนอย่างน้อยหนึ่งครั้งถึงเริ่มนับ
/// (กันนับเกินถ้าผู้ใช้เริ่มกดเริ่มในท่าที่งออยู่แล้ว)
class RepCounter {
  RepCounter(this.spec, {this.smoothing = 0.4})
      : downBelow = spec.downBelow,
        upAbove = spec.upAbove;

  final MoveSpec spec;

  /// เกณฑ์ปัจจุบัน เริ่มจากค่าของ spec และปรับได้ระหว่างใช้งาน (ใช้จูนในโปรโตไทป์)
  double downBelow;
  double upAbove;

  /// 0-1: ยิ่งน้อยยิ่งเรียบ (ลดอาการมุมกระตุกจากการตรวจจับ)
  double smoothing;

  int reps = 0;
  double? smoothedAngle;
  bool _armed = false;
  bool _isDown = false;

  bool get isDown => _isDown;

  /// true เมื่อเคยเหยียดถึงเกณฑ์ "ขึ้น" แล้วอย่างน้อยหนึ่งครั้ง (พร้อมเริ่มนับ)
  bool get armed => _armed;

  /// ป้อนมุมใหม่ คืน true ถ้าการอัปเดตนี้ทำให้นับเพิ่ม 1 ครั้ง
  bool update(double angle) {
    if (angle.isNaN) return false;
    final prev = smoothedAngle;
    final s = prev == null ? angle : prev + smoothing * (angle - prev);
    smoothedAngle = s;

    if (!_armed) {
      if (s > upAbove) _armed = true;
      return false;
    }
    if (!_isDown && s < downBelow) {
      _isDown = true;
      return false;
    }
    if (_isDown && s > upAbove) {
      _isDown = false;
      reps++;
      return true;
    }
    return false;
  }

  void reset() {
    reps = 0;
    smoothedAngle = null;
    _armed = false;
    _isDown = false;
  }
}
