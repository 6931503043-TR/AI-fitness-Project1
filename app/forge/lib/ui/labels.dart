import '../data/db/app_database.dart';
import '../domain/enums.dart';

extension ExerciseTypeLabel on ExerciseType {
  String get label => switch (this) {
        ExerciseType.strength => 'ยิม',
        ExerciseType.cardio => 'คาร์ดิโอ',
        ExerciseType.yoga => 'โยคะ',
      };
}

extension MuscleGroupLabel on MuscleGroup {
  String get label => switch (this) {
        MuscleGroup.chest => 'อก',
        MuscleGroup.back => 'หลัง',
        MuscleGroup.legs => 'ขา',
        MuscleGroup.shoulders => 'ไหล่',
        MuscleGroup.arms => 'แขน',
        MuscleGroup.core => 'หน้าท้อง',
        MuscleGroup.fullBody => 'ทั้งตัว',
      };
}

/// 60.0 -> "60", 62.5 -> "62.5"
String formatNumber(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

String formatDuration(int sec) {
  if (sec < 60) return '$sec วิ';
  final m = sec ~/ 60;
  final s = sec % 60;
  return s == 0 ? '$m นาที' : '$m นาที $s วิ';
}

/// ข้อความสรุปเป้าหมายของท่าในแผน เช่น "4 เซต · 8 ครั้ง · 60 กก."
String describeItem(RoutineItem item) {
  final parts = <String>[
    '${item.targetSets} เซต',
    if (item.targetReps != null) '${item.targetReps} ครั้ง',
    if (item.targetDurationSec != null) formatDuration(item.targetDurationSec!),
    if (item.targetWeightKg != null && item.targetWeightKg! > 0)
      '${formatNumber(item.targetWeightKg!)} กก.',
  ];
  return parts.join(' · ');
}
