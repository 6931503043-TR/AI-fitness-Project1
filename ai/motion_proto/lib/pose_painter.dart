import 'dart:io' show Platform;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

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

class PosePainter extends CustomPainter {
  PosePainter({
    required this.pose,
    required this.imageSize,
    required this.rotation,
    required this.lens,
    required this.focusSides,
    required this.focusColor,
    this.angleText,
  });

  final Pose pose;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection lens;

  /// ข้อต่อ 3 จุดของข้างที่ระบบใช้วัดมุมอยู่จริง (วาดสีเด่น) ข้างที่ไม่ได้ใช้วาดจางๆ
  final List<List<PoseLandmarkType>> focusSides;

  /// สีของข้างที่ใช้วัด: เขียวอมฟ้า = อยู่ในโซนเป้าหมาย, ส้ม = ระหว่างทาง
  final Color focusColor;

  /// ตัวเลขมุมที่แสดงข้างจุดหมุน
  final String? angleText;

  static const _minLikelihood = 0.5;

  Offset? _point(PoseLandmarkType t, Size size) {
    final l = pose.landmarks[t];
    if (l == null || l.likelihood < _minLikelihood) return null;
    return Offset(
      translateX(l.x, size, imageSize, rotation, lens),
      translateY(l.y, size, imageSize, rotation, lens),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final faint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final faintDot = Paint()..color = Colors.white54;
    final hot = Paint()
      ..color = focusColor
      ..strokeWidth = 7
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
    for (final t in PoseLandmarkType.values) {
      final p = _point(t, size);
      if (p != null) canvas.drawCircle(p, 3, faintDot);
    }

    // ข้างที่ใช้วัดมุม (เด่น)
    for (final side in focusSides) {
      final p0 = _point(side[0], size);
      final p1 = _point(side[1], size);
      final p2 = _point(side[2], size);
      if (p0 != null && p1 != null) canvas.drawLine(p0, p1, hot);
      if (p1 != null && p2 != null) canvas.drawLine(p1, p2, hot);
      for (final p in [p0, p1, p2]) {
        if (p != null) canvas.drawCircle(p, 8, hotDot);
      }
    }

    final text = angleText;
    if (text != null && focusSides.isNotEmpty) {
      final pivot = _point(focusSides.first[1], size);
      if (pivot != null) _label(canvas, pivot, text);
    }
  }

  void _label(Canvas canvas, Offset at, String text) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final rect = Rect.fromLTWH(
      at.dx + 14,
      at.dy - tp.height - 10,
      tp.width + 14,
      tp.height + 6,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..color = Colors.black87,
    );
    tp.paint(canvas, Offset(rect.left + 7, rect.top + 3));
  }

  @override
  bool shouldRepaint(covariant PosePainter old) =>
      old.pose != pose || old.focusColor != focusColor || old.angleText != angleText;
}
