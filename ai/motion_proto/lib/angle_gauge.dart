import 'package:flutter/material.dart';

/// แถบวัดมุม 0-180° แสดงมุมปัจจุบันเทียบกับโซนเป้าหมาย
/// ซ้าย = โซน "งอ/ลง" (ต่ำกว่าเกณฑ์ลง) ขวา = โซน "เหยียด/ขึ้น" (สูงกว่าเกณฑ์ขึ้น)
/// ต้องเดินทางจากโซนหนึ่งไปอีกโซนหนึ่งจึงนับ 1 ครั้ง
class AngleGauge extends StatelessWidget {
  const AngleGauge({
    super.key,
    required this.angle,
    required this.downBelow,
    required this.upAbove,
    required this.bendLabel,
    required this.straightLabel,
    this.minSeen,
    this.maxSeen,
  });

  final double? angle;
  final double downBelow;
  final double upAbove;
  final String bendLabel;
  final String straightLabel;
  final double? minSeen;
  final double? maxSeen;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      width: double.infinity,
      child: CustomPaint(
        painter: _GaugePainter(
          angle: angle,
          downBelow: downBelow,
          upAbove: upAbove,
          bendLabel: bendLabel,
          straightLabel: straightLabel,
          minSeen: minSeen,
          maxSeen: maxSeen,
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.angle,
    required this.downBelow,
    required this.upAbove,
    required this.bendLabel,
    required this.straightLabel,
    required this.minSeen,
    required this.maxSeen,
  });

  final double? angle;
  final double downBelow;
  final double upAbove;
  final String bendLabel;
  final String straightLabel;
  final double? minSeen;
  final double? maxSeen;

  static const _teal = Color(0xFF2BB3A3);
  static const _orange = Color(0xFFFF5A1F);

  void _text(
    Canvas canvas,
    String text, {
    required double x,
    required double y,
    required double maxWidth,
    required TextAlign align,
    Color color = Colors.white70,
    double size = 12,
    FontWeight weight = FontWeight.w500,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: size, fontWeight: weight),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    final dx = align == TextAlign.right
        ? x - tp.width
        : align == TextAlign.center
            ? x - tp.width / 2
            : x;
    tp.paint(canvas, Offset(dx, y));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 12.0;
    final w = size.width - pad * 2;
    double xOf(double deg) => pad + (deg.clamp(0, 180) / 180) * w;

    const trackTop = 24.0;
    const trackH = 12.0;
    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(pad, trackTop, w, trackH),
      const Radius.circular(6),
    );
    canvas.drawRRect(track, Paint()..color = Colors.white12);

    // โซนเป้าหมาย
    final zone = Paint()..color = _teal.withValues(alpha: 0.55);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(pad, trackTop, xOf(downBelow), trackTop + trackH),
        const Radius.circular(6),
      ),
      zone,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(xOf(upAbove), trackTop, pad + w, trackTop + trackH),
        const Radius.circular(6),
      ),
      zone,
    );

    // ชื่อโซน (ซ้าย = งอ, ขวา = เหยียด)
    final half = w / 2;
    _text(canvas, bendLabel,
        x: pad, y: 4, maxWidth: half, align: TextAlign.left, color: _teal, weight: FontWeight.w600);
    _text(canvas, straightLabel,
        x: pad + w, y: 4, maxWidth: half, align: TextAlign.right, color: _teal, weight: FontWeight.w600);

    // ค่าเกณฑ์ใต้แถบ
    _text(canvas, '${downBelow.round()}°',
        x: xOf(downBelow), y: trackTop + trackH + 4, maxWidth: 60, align: TextAlign.center, size: 11);
    _text(canvas, '${upAbove.round()}°',
        x: xOf(upAbove), y: trackTop + trackH + 4, maxWidth: 60, align: TextAlign.center, size: 11);

    // ช่วงมุมที่เคยวัดได้ในรอบนี้
    final lo = minSeen;
    final hi = maxSeen;
    if (lo != null && hi != null) {
      canvas.drawLine(
        Offset(xOf(lo), trackTop + trackH + 26),
        Offset(xOf(hi), trackTop + trackH + 26),
        Paint()
          ..color = Colors.white38
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }

    // ตัวชี้มุมปัจจุบัน
    final a = angle;
    if (a != null) {
      final inZone = a <= downBelow || a >= upAbove;
      final c = Offset(xOf(a), trackTop + trackH / 2);
      canvas.drawCircle(c, 10, Paint()..color = inZone ? _teal : _orange);
      canvas.drawCircle(
        c,
        10,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.angle != angle ||
      old.downBelow != downBelow ||
      old.upAbove != upAbove ||
      old.minSeen != minSeen ||
      old.maxSeen != maxSeen ||
      old.bendLabel != bendLabel;
}
