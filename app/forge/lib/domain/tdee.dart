import 'dart:math' as math;

import 'enums.dart';

/// สูตร Mifflin-St Jeor (เหมือนกับที่ใช้ในไฟล์ HTML เดิม)
double bmrMifflinStJeor({
  required Gender gender,
  required double weightKg,
  required double heightCm,
  required int age,
}) {
  final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
  final bmr = base + (gender == Gender.male ? 5 : -161);
  return math.max(0, bmr);
}

double calcTdee(double bmr, ActivityLevel activity) => bmr * activity.factor;
