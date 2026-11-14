import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'move_guides.dart';
import 'rep_counter.dart';

/// ท่าจำลองด้วยเส้น 2 มิติ มองจากด้านข้าง (พิกัดหน่วยสมมติ แกน y ชี้ขึ้น)
/// มุมของข้อต่อที่ระบบวัดตรงกับค่า [angle] ที่ส่งเข้ามาพอดี
/// จึงใช้แสดงให้เห็นว่าเกณฑ์ "ลง/ขึ้น" ของท่านั้นหน้าตาเป็นอย่างไร
typedef Joints = Map<String, Offset>;

double _rad(double deg) => deg * math.pi / 180;
Offset _o(double x, double y) => Offset(x, y);

Joints squatJoints(double k) {
  const ls = 0.22, lt = 0.24, ltr = 0.32;
  final a = _rad((180 - k) * 0.25); // ขาท่อนล่างเอียงไปข้างหน้า
  final knee = _o(ls * math.sin(a), ls * math.cos(a));
  final angKA = math.atan2(-math.cos(a), -math.sin(a));
  final angH = angKA - _rad(k);
  final hip = knee + _o(lt * math.cos(angH), lt * math.sin(angH));
  final tr = _rad((180 - k) * 0.3); // ลำตัวโน้มไปข้างหน้า
  final shoulder = hip + _o(ltr * math.sin(tr), ltr * math.cos(tr));
  final head = shoulder + _o(0.09 * math.sin(tr), 0.09 * math.cos(tr));
  final elbow = shoulder + _o(0.17, -0.02);
  final wrist = elbow + _o(0.15, -0.02);
  return {
    'ankle': _o(0, 0),
    'toe': _o(0.09, 0),
    'knee': knee,
    'hip': hip,
    'shoulder': shoulder,
    'head': head,
    'elbow': elbow,
    'wrist': wrist,
  };
}

Joints pushUpJoints(double e) {
  const lu = 0.17, lf = 0.15, body = 0.78, dist = 0.72;
  final d = math.sqrt(lu * lu + lf * lf - 2 * lu * lf * math.cos(_rad(e)));
  final toe = _o(0, 0);
  final wrist = _o(dist, 0);
  // ไหล่ = จุดตัดของวงกลมรัศมี body รอบปลายเท้า กับวงกลมรัศมี d รอบข้อมือ
  final a = (body * body - d * d + dist * dist) / (2 * dist);
  final h = math.sqrt(math.max(0.0, body * body - a * a));
  final shoulder = _o(a, h);
  final gamma = math.atan2(shoulder.dy - wrist.dy, shoulder.dx - wrist.dx);
  final cosAlpha =
      ((lf * lf + d * d - lu * lu) / (2 * lf * d)).clamp(-1.0, 1.0).toDouble();
  final alpha = math.acos(cosAlpha);
  final elbow =
      wrist + _o(lf * math.cos(gamma + alpha), lf * math.sin(gamma + alpha));
  final len = (shoulder - toe).distance;
  final dir = (shoulder - toe) / len;
  return {
    'toe': toe,
    'hip': toe + (shoulder - toe) * 0.58,
    'shoulder': shoulder,
    'head': shoulder + dir * 0.09,
    'elbow': elbow,
    'wrist': wrist,
  };
}

Joints curlJoints(double e) {
  const lu = 0.17, lf = 0.15;
  final shoulder = _o(0, 0.78);
  final elbow = shoulder + _o(0.02, -lu);
  final angES = math.atan2(shoulder.dy - elbow.dy, shoulder.dx - elbow.dx);
  final angEW = angES - _rad(e);
  final wrist = elbow + _o(lf * math.cos(angEW), lf * math.sin(angEW));
  return {
    'ankle': _o(0, 0),
    'toe': _o(0.09, 0),
    'knee': _o(0, 0.22),
    'hip': _o(0, 0.46),
    'shoulder': shoulder,
    'head': _o(0, 0.87),
    'elbow': elbow,
    'wrist': wrist,
  };
}

class _Box {
  const _Box(this.minX, this.minY, this.maxX, this.maxY);
  final double minX, minY, maxX, maxY;
  double get width => maxX - minX;
  double get height => maxY - minY;
}

class _Rig {
  const _Rig({
    required this.joints,
    required this.segments,
    required this.tracked,
    required this.box,
  });
  final Joints Function(double) joints;
  final List<List<String>> segments;

  /// ข้อต่อ 3 จุดที่วัดมุม (จุดที่ 2 คือจุดหมุน)
  final List<String> tracked;
  final _Box box;
}

final Map<TrackedMove, _Rig> _rigs = {
  TrackedMove.squat: const _Rig(
    joints: squatJoints,
    segments: [
      ['ankle', 'knee'],
      ['knee', 'hip'],
      ['hip', 'shoulder'],
      ['shoulder', 'elbow'],
      ['elbow', 'wrist'],
      ['ankle', 'toe'],
    ],
    tracked: ['hip', 'knee', 'ankle'],
    box: _Box(-0.30, -0.05, 0.50, 0.98),
  ),
  TrackedMove.pushUp: const _Rig(
    joints: pushUpJoints,
    segments: [
      ['toe', 'hip'],
      ['hip', 'shoulder'],
      ['shoulder', 'elbow'],
      ['elbow', 'wrist'],
    ],
    tracked: ['shoulder', 'elbow', 'wrist'],
    box: _Box(-0.08, -0.06, 0.95, 0.50),
  ),
  TrackedMove.curl: const _Rig(
    joints: curlJoints,
    segments: [
      ['ankle', 'knee'],
      ['knee', 'hip'],
      ['hip', 'shoulder'],
      ['shoulder', 'elbow'],
      ['elbow', 'wrist'],
      ['ankle', 'toe'],
    ],
    tracked: ['shoulder', 'elbow', 'wrist'],
    box: _Box(-0.35, -0.05, 0.50, 0.98),
  ),
};

const _teal = Color(0xFF2BB3A3);
const _orange = Color(0xFFFF5A1F);

class DemoFigure extends StatefulWidget {
  const DemoFigure({super.key, required this.move, this.height = 230});

  final TrackedMove move;
  final double height;

  @override
  State<DemoFigure> createState() => _DemoFigureState();
}

class _DemoFigureState extends State<DemoFigure>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spec = moveSpecs[widget.move]!;
    final guide = moveGuides[widget.move]!;
    final rig = _rigs[widget.move]!;
    // ช่วงมุมของตัวจำลองครอบคลุมเกณฑ์ลง/ขึ้นของท่านั้นพอดี
    final top = math.min(spec.upAbove + 15, 172.0);
    final bottom = math.max(spec.downBelow - 10, 30.0);

    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_c.value);
          final angle = top + (bottom - top) * t;
          final inZone = angle <= spec.downBelow || angle >= spec.upAbove;
          final goingBend = _c.status == AnimationStatus.forward;
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _FigurePainter(
                    rig: rig,
                    angle: angle,
                    color: inZone ? _teal : _orange,
                  ),
                ),
              ),
              Positioned(
                top: 6,
                left: 8,
                child: Text(
                  goingBend ? guide.bendLabel : guide.straightLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: inZone ? _teal : Colors.white70,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FigurePainter extends CustomPainter {
  _FigurePainter({required this.rig, required this.angle, required this.color});

  final _Rig rig;
  final double angle;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final b = rig.box;
    final scale = math.min(size.width / b.width, size.height / b.height);
    final dx = (size.width - b.width * scale) / 2;
    final dy = (size.height - b.height * scale) / 2;
    Offset map(Offset u) => Offset(
          dx + (u.dx - b.minX) * scale,
          size.height - dy - (u.dy - b.minY) * scale,
        );

    final j = rig.joints(angle);
    final trackedSet = rig.tracked.toSet();

    // พื้น
    final ground = Paint()
      ..color = Colors.white24
      ..strokeWidth = 2;
    canvas.drawLine(map(_o(b.minX, 0)), map(_o(b.maxX, 0)), ground);

    final bone = Paint()
      ..color = Colors.white70
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final boneHot = Paint()
      ..color = color
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    for (final s in rig.segments) {
      final p1 = j[s[0]];
      final p2 = j[s[1]];
      if (p1 == null || p2 == null) continue;
      final hot = trackedSet.contains(s[0]) && trackedSet.contains(s[1]);
      canvas.drawLine(map(p1), map(p2), hot ? boneHot : bone);
    }

    final head = j['head'];
    if (head != null) {
      canvas.drawCircle(
        map(head),
        0.055 * scale,
        Paint()
          ..color = Colors.white70
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
    }

    for (final entry in j.entries) {
      if (entry.key == 'head' || entry.key == 'toe') continue;
      final hot = trackedSet.contains(entry.key);
      canvas.drawCircle(
        map(entry.value),
        hot ? 7 : 4,
        Paint()..color = hot ? color : Colors.white,
      );
    }

    // ส่วนโค้งและตัวเลขมุมที่จุดหมุน
    final pa = map(j[rig.tracked[0]]!);
    final pb = map(j[rig.tracked[1]]!);
    final pc = map(j[rig.tracked[2]]!);
    final v1 = pa - pb;
    final v2 = pc - pb;
    final a1 = math.atan2(v1.dy, v1.dx);
    final a2 = math.atan2(v2.dy, v2.dx);
    var sweep = a2 - a1;
    while (sweep > math.pi) {
      sweep -= 2 * math.pi;
    }
    while (sweep < -math.pi) {
      sweep += 2 * math.pi;
    }
    canvas.drawArc(
      Rect.fromCircle(center: pb, radius: 26),
      a1,
      sweep,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final mid = a1 + sweep / 2;
    final labelPos = pb + Offset(math.cos(mid), math.sin(mid)) * 46;
    final tp = TextPainter(
      text: TextSpan(
        text: '${angle.round()}°',
        style: TextStyle(
          color: color,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, labelPos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _FigurePainter old) =>
      old.angle != angle || old.color != color || old.rig != rig;
}
