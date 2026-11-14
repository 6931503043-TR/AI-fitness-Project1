import 'enums.dart';

/// เวลาพักเริ่มต้นต่อกลุ่มกล้ามเนื้อ (ชั่วโมง)
/// หมายเหตุ: เป็นค่าประมาณเพื่อใช้เป็นจุดเริ่มต้นเท่านั้น ไม่ใช่ค่าตายตัวทางวิทยาศาสตร์
/// ตั้งใจให้ผู้ใช้ปรับเองได้ในหน้า Setting (เฟส 3)
const Map<MuscleGroup, int> defaultRestHours = {
  MuscleGroup.chest: 48,
  MuscleGroup.back: 48,
  MuscleGroup.legs: 72,
  MuscleGroup.shoulders: 48,
  MuscleGroup.arms: 36,
  MuscleGroup.core: 24,
  MuscleGroup.fullBody: 48,
};

class MuscleRecovery {
  const MuscleRecovery({
    required this.muscle,
    required this.progress,
    required this.hoursLeft,
  });

  final MuscleGroup muscle;

  /// 0.0 = เพิ่งฝึก, 1.0 = พักครบแล้ว
  final double progress;
  final double hoursLeft;

  bool get isRecovered => progress >= 1;
}

/// ลำดับกลุ่มกล้ามเนื้อที่แสดงในหน้า Body (ตรงกับ UI เดิม)
/// ไม่รวม core/fullBody เพราะยังไม่มีท่าหลักที่ใช้กลุ่มนี้เป็นกล้ามเนื้อหลักในคลังท่าเริ่มต้น
const List<MuscleGroup> bodyScreenMuscleOrder = [
  MuscleGroup.chest,
  MuscleGroup.back,
  MuscleGroup.legs,
  MuscleGroup.shoulders,
  MuscleGroup.arms,
];

MuscleRecovery recoveryOf({
  required MuscleGroup muscle,
  required DateTime? lastTrained,
  required DateTime now,
  Map<MuscleGroup, int>? restHours,
}) {
  final rest = (restHours ?? defaultRestHours)[muscle] ??
      defaultRestHours[muscle] ??
      48;

  // ไม่เคยฝึก (หรือไม่มีข้อมูล) ถือว่าพร้อมฝึก
  if (lastTrained == null) {
    return MuscleRecovery(muscle: muscle, progress: 1, hoursLeft: 0);
  }

  final hoursSince = now.difference(lastTrained).inMinutes / 60.0;
  final progress = (hoursSince / rest).clamp(0.0, 1.0).toDouble();
  final hoursLeft = (rest - hoursSince).clamp(0.0, rest.toDouble()).toDouble();
  return MuscleRecovery(muscle: muscle, progress: progress, hoursLeft: hoursLeft);
}
