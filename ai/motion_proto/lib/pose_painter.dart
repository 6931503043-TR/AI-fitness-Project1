import 'dart:io' show Platform;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'pose_stability.dart';

/// แปลงพิกัด x จากภาพดิบของกล้อง ไปเป็นพิกัดบน canvas ที่วางทับ preview
/// (ตามตัวอย่างทางการของ google_mlkit_flutter ต้องล็อกจอแนวตั้งให้ canvas ตรงกับ preview)
double translateX(
  double x,
  Size canvas,
  Size image,
  InputImageRotation rotation,
  CameraLensDirection lens,
) {
  switch (rotation) {
    case InputImageRotation.rotation90deg:
      return x * canvas.width / (Platform.isIOS ? image.width : image.height);
    case InputImageRotation.rotation270deg:
      return canvas.width -
          x * canvas.width / (Platform.isIOS ? image.width : image.height);
    case InputImageRotation.rotation0deg:
    case InputImageRotation.rotation180deg:
      return lens == CameraLensDirection.back
          ? x * canvas.width / image.width
          : canvas.width - x * canvas.width / image.width;
  }
}

double translateY(
  double y,
  Size canvas,
  Size image,
  InputImageRotation rotation,
  CameraLensDirection lens,
) {
  switch (rotation) {
    case InputImageRotation.rotation90deg:
    case InputImageRotation.rotation270deg:
      return y * canvas.height / (Platform.isIOS ? image.height : image.width);
    case InputImageRotation.rotation0deg:
    case InputImageRotation.rotation180deg:
      return y * canvas.height / image.height;
  }
}

const _bones = <List<PoseLandmarkType>>[
  [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
  [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
  [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
  [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
  [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
  [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
  [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
  [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
  [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
  [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
  [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
  [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
];

/// ความหนาเส้นเป็นหน่วยพิกเซลบนจอจริง (dp) ไม่ขึ้นกับความละเอียดกล้อง
/// ค่าตั้งให้ใกล้กับที่เห็นตอนใช้ความละเอียดสูงบนจอกว้างราว 411 dp (ประมาณจากการคำนวณ ปรับได้)
const _faintStrokeDp = 1.1;
const _faintDotDp = 1.6;
const _hotStrokeDp = 3.8;
const _hotDotDp = 4.2;
const _labelFontDp = 13.0;

/// วาดจุดเฉพาะข้อต่อลำตัว (ไม่วาดใบหน้า/นิ้ว/ปลายเท้า ซึ่งซ้อนทับกันมากและไม่ได้ใช้นับท่า)
final Set<PoseLandmarkType> _jointTypes = {
  for (final b in _bones) ...b,
};

class PosePainter extends CustomPainter {
  PosePainter({
    required this.points,
    required this.imageSize,
    required this.rotation,
    required this.lens,
    required this.focusSides,
    required this.focusColor,
    this.angleText,
    this.lineScale = 1.0,
  });

  /// จุดที่ผ่านการกรองแล้ว (มีเฉพาะจุดที่มั่นใจพอหรือกำลังค้างค่าเดิมสั้นๆ)
  final Map<PoseLandmarkType, LmPoint> points;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection lens;

  /// ข้อต่อ 3 จุดของข้างที่ระบบใช้วัดมุมอยู่จริง (วาดสีเด่น) ข้างที่ไม่ได้ใช้วาดจางๆ
  final List<List<PoseLandmarkType>> focusSides;

  /// สีของข้างที่ใช้วัด: เขียวอมฟ้า = อยู่ในโซนเป้าหมาย, ส้ม = ระหว่างทาง
  final Color focusColor;

  /// ตัวเลขมุมที่แสดงข้างจุดหมุน
  final String? angleText;

  /// หน่วย canvas ต่อ 1 dp บนจอ (= 1 / อัตราที่ FittedBox ขยาย canvas)
  /// ใช้คูณความหนาเส้น/ขนาดจุด/ตัวอักษร ให้ดูเท่ากันทุกความละเอียดกล้อง
  final double lineScale;

  Offset? _point(PoseLandmarkType t, Size size) {
    final l = points[t];
    if (l == null) return null;
    return Offset(
      translateX(l.x, size, imageSize, rotation, lens),
      translateY(l.y, size, imageSize, rotation, lens),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final k = lineScale;
    final faint = Paint()
      ..color = Colors.white38
      ..strokeWidth = _faintStrokeDp * k
      ..style = PaintingStyle.stroke;
    final faintDot = Paint()..color = Colors.white54;
    final hot = Paint()
      ..color = focusColor
      ..strokeWidth = _hotStrokeDp * k
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final hotDot = Paint()..color = focusColor;

    // โครงร่างทั้งตัว (จาง)
    for (final b in _bones) {
      final p1 = _point(b[0], size);
      final p2 = _point(b[1], size);
      if (p1 == null || p2 == null) continue;
      canvas.drawLine(p1, p2, faint);
    }
    for (final t in _jointTypes) {
      final p = _point(t, size);
      if (p != null) canvas.drawCircle(p, _faintDotDp * k, faintDot);
    }

    // ข้างที่ใช้วัดมุม (เด่น)
    for (final side in focusSides) {
      final p0 = _point(side[0], size);
      final p1 = _point(side[1], size);
      final p2 = _point(side[2], size);
      if (p0 != null && p1 != null) canvas.drawLine(p0, p1, hot);
      if (p1 != null && p2 != null) canvas.drawLine(p1, p2, hot);
      for (final p in [p0, p1, p2]) {
        if (p != null) canvas.drawCircle(p, _hotDotDp * k, hotDot);
      }
    }

    final text = angleText;
    if (text != null && focusSides.isNotEmpty) {
      final pivot = _point(focusSides.first[1], size);
      if (pivot != null) _label(canvas, pivot, text, k);
    }
  }

  void _label(Canvas canvas, Offset at, String text, double k) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: _labelFontDp * k,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final rect = Rect.fromLTWH(
      at.dx + 8 * k,
      at.dy - tp.height - 6 * k,
      tp.width + 10 * k,
      tp.height + 4 * k,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(6 * k)),
      Paint()..color = Colors.black87,
    );
    tp.paint(canvas, Offset(rect.left + 5 * k, rect.top + 2 * k));
  }

  @override
  bool shouldRepaint(covariant PosePainter old) =>
      old.points != points ||
      old.focusColor != focusColor ||
      old.angleText != angleText ||
      old.lineScale != lineScale;
}
