import 'package:flutter_test/flutter_test.dart';
import 'package:motion_proto/start_gate.dart';

void main() {
  test('ยังไม่เริ่มจับเวลา ไม่ถือว่ากำลังรอ', () {
    final g = StartGate(countdownSec: 5);
    expect(g.isWaiting(100), isFalse);
    expect(g.secondsLeft(100), 0);
  });

  test('นับถอยหลัง 5 วินาที: รอจนครบแล้วถึงนับได้', () {
    final g = StartGate(countdownSec: 5)..begin(10);
    expect(g.isWaiting(10), isTrue);
    expect(g.secondsLeft(10), 5);
    expect(g.secondsLeft(12.1), 3);
    expect(g.secondsLeft(14.9), 1);
    expect(g.isWaiting(14.9), isTrue);
    expect(g.isWaiting(15), isFalse);
    expect(g.secondsLeft(15), 0);
    expect(g.isWaiting(20), isFalse);
  });

  test('countdownSec = 0 เริ่มนับทันที (พฤติกรรมเดิม)', () {
    final g = StartGate(countdownSec: 0)..begin(10);
    expect(g.isWaiting(10), isFalse);
    expect(g.secondsLeft(10), 0);
  });

  test('ปรับเวลาได้ระหว่างใช้งาน และ reset ยกเลิกการรอ', () {
    final g = StartGate(countdownSec: 5)..begin(0);
    g.countdownSec = 3;
    expect(g.secondsLeft(1), 2);
    g.reset();
    expect(g.isWaiting(1), isFalse);
  });

  test('begin ใหม่เริ่มนับถอยหลังรอบใหม่', () {
    final g = StartGate(countdownSec: 5)..begin(0);
    expect(g.isWaiting(6), isFalse);
    g.begin(6);
    expect(g.isWaiting(6), isTrue);
    expect(g.secondsLeft(8), 3);
  });
}
