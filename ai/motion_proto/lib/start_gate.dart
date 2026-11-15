/// ตรรกะล้วน: นับถอยหลังหลังกด "เริ่ม" เพื่อให้เวลาผู้ใช้เข้าท่า
/// (ช่วงนี้ตรวจจับร่างกายผิดพลาดได้ง่าย เพราะกำลังขยับตัวหรือปรับกล้อง จึงยังไม่นับครั้ง)
/// ไม่แตะกล้อง/ML Kit เพื่อเทสต์ได้โดยไม่ต้องมีมือถือ
class StartGate {
  StartGate({this.countdownSec = 5});

  /// 0 = ไม่รอ เริ่มนับทันที
  double countdownSec;

  double? _beganAt;

  /// เริ่มจับเวลา ([nowSec] เป็นวินาทีจากนาฬิกาเดียวกับที่ใช้เรียกเมธอดอื่น)
  void begin(double nowSec) => _beganAt = nowSec;

  /// ยกเลิก (เช่นตอนกดหยุด) หลังเรียกแล้ว [isWaiting] เป็น false
  void reset() => _beganAt = null;

  double _remaining(double nowSec) {
    final b = _beganAt;
    if (b == null) return 0;
    final r = countdownSec - (nowSec - b);
    return r > 0 ? r : 0;
  }

  /// true = ยังอยู่ในช่วงนับถอยหลัง (ห้ามนับครั้ง)
  bool isWaiting(double nowSec) => _remaining(nowSec) > 0;

  /// วินาทีที่เหลือ ปัดขึ้น (0 = พ้นช่วงนับถอยหลังแล้ว)
  int secondsLeft(double nowSec) => _remaining(nowSec).ceil();
}
