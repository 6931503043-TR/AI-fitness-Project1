DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// นับจำนวนวัน "ติดต่อกัน" ที่มีการซ้อม
/// ถ้าวันนี้ยังไม่ได้ซ้อม แต่เมื่อวานซ้อม จะยังนับสตรีคต่อ (สตรีคขาดเมื่อพลาดครบทั้งวัน)
int computeStreak(Iterable<DateTime> workoutDays, DateTime now) {
  final days = workoutDays.map(_dayOnly).toSet();
  var cursor = _dayOnly(now);
  if (!days.contains(cursor)) {
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }
  var count = 0;
  while (days.contains(cursor)) {
    count++;
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }
  return count;
}
