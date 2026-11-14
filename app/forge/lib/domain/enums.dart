/// ค่า enum ถูกเก็บในฐานข้อมูลเป็น "ชื่อ" (เช่น 'strength')
/// ห้ามเปลี่ยนชื่อ enum ที่ปล่อยใช้งานแล้ว ไม่งั้นข้อมูลเก่าจะอ่านไม่ได้
/// (ถ้าจำเป็นต้องเปลี่ยน ให้เขียน migration แปลงข้อมูลควบคู่กัน)

enum ExerciseType { strength, cardio, yoga }

enum MuscleGroup { chest, back, legs, shoulders, arms, core, fullBody }

enum Gender { male, female }

enum ActivityLevel {
  sedentary(1.2),
  light(1.375),
  moderate(1.55),
  active(1.725),
  athlete(1.9);

  const ActivityLevel(this.factor);
  final double factor;
}
