import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'angle_gauge.dart';
import 'demo_figure.dart';
import 'move_guides.dart';
import 'pose_painter.dart';
import 'rep_counter.dart';

const _teal = Color(0xFF2BB3A3);
const _orange = Color(0xFFFF5A1F);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ล็อกจอแนวตั้ง เพื่อให้พิกัดเส้นโครงร่างตรงกับภาพกล้อง
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MotionApp());
}

class MotionApp extends StatelessWidget {
  const MotionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Motion Tracking Prototype',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _orange,
          brightness: Brightness.dark,
        ),
      ),
      home: const MotionScreen(),
    );
  }
}

/// ข้อต่อ 3 จุด (ต้นทาง-จุดหมุน-ปลาย) ของแต่ละท่า ซ้ายและขวา (ตามตัวคน)
List<List<PoseLandmarkType>> triplesFor(TrackedMove m) {
  switch (m) {
    case TrackedMove.squat:
      return const [
        [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
        [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
      ];
    case TrackedMove.pushUp:
    case TrackedMove.curl:
      return const [
        [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
        [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
      ];
  }
}

class _Side {
  _Side(this.angle, this.likelihood, this.triple);
  final double angle;
  final double likelihood;
  final List<PoseLandmarkType> triple;
}

/// ผลการวัดมุมหนึ่งเฟรม: มุมที่ใช้ และข้างที่ถูกใช้คำนวณ (เรียงข้างที่ชัดที่สุดก่อน)
class _Measurement {
  _Measurement(this.angle, this.sides);
  final double angle;
  final List<List<PoseLandmarkType>> sides;
}

class MotionScreen extends StatefulWidget {
  const MotionScreen({super.key});

  @override
  State<MotionScreen> createState() => _MotionScreenState();
}

class _MotionScreenState extends State<MotionScreen> {
  static const _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  CameraController? _controller;
  PoseDetector? _detector;
  String? _error;
  bool _accurate = false;
  ResolutionPreset _res = ResolutionPreset.medium;
  double _smoothing = 0.4;
  String _zoomText = '';

  TrackedMove _move = TrackedMove.squat;
  late RepCounter _counter =
      RepCounter(moveSpecs[_move]!, smoothing: _smoothing);
  final Set<TrackedMove> _seenGuides = {};

  bool _running = false;
  bool _busy = false;

  // ผลล่าสุดจากการตรวจจับ
  Pose? _pose;
  Size? _imageSize;
  InputImageRotation? _lastRotation;
  _Measurement? _measurement;
  double? _angle;
  double? _minAngle;
  double? _maxAngle;
  DateTime _lastRepAt = DateTime.fromMillisecondsSinceEpoch(0);
  String _status = 'พร้อม';

  // ตัวเลขวัดประสิทธิภาพ
  double _inferMs = 0;
  double _fps = 0;
  int _frames = 0;
  DateTime _fpsStart = DateTime.now();

  bool get _supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void initState() {
    super.initState();
    if (_supported) _initCamera();
  }

  @override
  void dispose() {
    final c = _controller;
    if (c != null) {
      if (c.value.isStreamingImages) c.stopImageStream();
      c.dispose();
    }
    _detector?.close();
    super.dispose();
  }

  PoseDetector _makeDetector() => PoseDetector(
        options: PoseDetectorOptions(
          mode: PoseDetectionMode.stream,
          model: _accurate
              ? PoseDetectionModel.accurate
              : PoseDetectionModel.base,
        ),
      );

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _error = 'ไม่พบกล้องในเครื่องนี้');
        return;
      }
      final front = _cameras
          .indexWhere((c) => c.lensDirection == CameraLensDirection.front);
      _cameraIndex = front >= 0 ? front : 0;
      _detector ??= _makeDetector();
      await _startController();
    } on CameraException catch (e) {
      if (mounted) {
        setState(() => _error =
            'เปิดกล้องไม่ได้ (${e.code})\nตรวจสอบว่าอนุญาตการใช้กล้อง และเพิ่ม permission ใน AndroidManifest แล้ว');
      }
    }
  }

  Future<void> _startController() async {
    final old = _controller;
    if (old != null) {
      if (old.value.isStreamingImages) await old.stopImageStream();
      await old.dispose();
    }
    final controller = CameraController(
      _cameras[_cameraIndex],
      _res,
      enableAudio: false,
      imageFormatGroup:
          Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );
    _controller = controller;
    await controller.initialize();

    // ซูมออกให้กว้างที่สุดเท่าที่กล้องรองรับ (บางรุ่นมีเลนส์ไวด์ ทำให้ยืนใกล้ขึ้นได้)
    try {
      final minZ = await controller.getMinZoomLevel();
      await controller.setZoomLevel(minZ);
      _zoomText = 'ซูม ${minZ.toStringAsFixed(1)}x';
    } catch (_) {
      _zoomText = '';
    }

    if (!mounted) return;
    setState(() => _error = null);
    if (_running) await controller.startImageStream(_onFrame);
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2 || _running) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    try {
      await _startController();
    } on CameraException catch (e) {
      if (mounted) setState(() => _error = 'สลับกล้องไม่สำเร็จ (${e.code})');
    }
  }

  Future<void> _setRes(ResolutionPreset r) async {
    if (_running || r == _res) return;
    setState(() => _res = r);
    try {
      await _startController();
    } on CameraException catch (e) {
      if (mounted) setState(() => _error = 'เปลี่ยนความละเอียดไม่สำเร็จ (${e.code})');
    }
  }

  Future<void> _setAccurate(bool v) async {
    if (_running) return;
    final old = _detector;
    setState(() {
      _accurate = v;
      _detector = _makeDetector();
    });
    await old?.close();
  }

  InputImage? _toInputImage(CameraImage image) {
    final controller = _controller;
    if (controller == null) return null;
    final camera = _cameras[_cameraIndex];
    final sensor = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensor);
    } else {
      var comp = _orientations[controller.value.deviceOrientation];
      if (comp == null) return null;
      comp = camera.lensDirection == CameraLensDirection.front
          ? (sensor + comp) % 360
          : (sensor - comp + 360) % 360;
      rotation = InputImageRotationValue.fromRawValue(comp);
    }
    if (rotation == null) {
      _status = 'ERR: หา rotation ไม่ได้ (sensor=$sensor)';
      return null;
    }

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      _status = 'ERR: ฟอร์แมตภาพไม่รองรับ (raw=${image.format.raw})';
      return null;
    }
    if (image.planes.length != 1) {
      _status = 'ERR: จำนวน plane = ${image.planes.length} (ต้องเป็น 1)';
      return null;
    }
    final plane = image.planes.first;
    _lastRotation = rotation;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  /// วัดมุมจากข้างที่เห็นชัดพอ (likelihood >= 0.5)
  /// ท่าที่ตั้ง bestSideOnly (วิดพื้น) ใช้เฉพาะข้างที่ชัดที่สุด ท่าอื่นเฉลี่ยทั้งสองข้าง
  _Measurement? _measure(Map<PoseLandmarkType, PoseLandmark> lm) {
    final spec = moveSpecs[_move]!;
    final found = <_Side>[];
    for (final t in triplesFor(_move)) {
      final p = t.map((k) => lm[k]).toList();
      if (p.any((e) => e == null)) continue;
      final minL = p.map((e) => e!.likelihood).reduce(math.min);
      if (minL < 0.5) continue;
      final a = angleDeg(
        Pt(p[0]!.x, p[0]!.y),
        Pt(p[1]!.x, p[1]!.y),
        Pt(p[2]!.x, p[2]!.y),
      );
      if (a.isNaN) continue;
      found.add(_Side(a, minL, t));
    }
    if (found.isEmpty) return null;
    found.sort((x, y) => y.likelihood.compareTo(x.likelihood));
    if (spec.bestSideOnly || found.length == 1) {
      return _Measurement(found.first.angle, [found.first.triple]);
    }
    final avg = found.map((s) => s.angle).reduce((a, b) => a + b) / found.length;
    return _Measurement(avg, found.map((s) => s.triple).toList());
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_busy || !_running) return;
    _busy = true;
    final sw = Stopwatch()..start();
    try {
      final input = _toInputImage(image);
      final detector = _detector;
      if (input == null || detector == null) {
        if (mounted) setState(() {});
        return;
      }

      final poses = await detector.processImage(input);
      if (!mounted || !_running) return;

      final pose = poses.isEmpty ? null : poses.first;
      final m = pose == null ? null : _measure(pose.landmarks);
      final angle = m?.angle;
      var repDone = false;
      if (angle != null) {
        repDone = _counter.update(angle);
        _minAngle = _minAngle == null ? angle : math.min(_minAngle!, angle);
        _maxAngle = _maxAngle == null ? angle : math.max(_maxAngle!, angle);
      }
      if (repDone) {
        _lastRepAt = DateTime.now();
        HapticFeedback.lightImpact();
      }

      // วัด FPS และเวลาประมวลผลต่อเฟรม
      sw.stop();
      final ms = sw.elapsedMilliseconds.toDouble();
      _inferMs = _inferMs == 0 ? ms : _inferMs * 0.8 + ms * 0.2;
      _frames++;
      final now = DateTime.now();
      final elapsed = now.difference(_fpsStart).inMilliseconds;
      if (elapsed >= 1000) {
        _fps = _frames * 1000 / elapsed;
        _frames = 0;
        _fpsStart = now;
      }

      setState(() {
        _pose = pose;
        _measurement = m;
        _imageSize = Size(image.width.toDouble(), image.height.toDouble());
        _angle = angle;
        _status = pose == null
            ? 'ไม่พบร่างกายในภาพ'
            : angle == null
                ? 'เห็นร่างกาย แต่ข้อต่อของท่านี้ไม่ชัดพอ'
                : 'กำลังติดตาม';
      });
    } catch (e) {
      debugPrint('frame error: $e');
      if (mounted) setState(() => _status = 'ERR: $e');
    } finally {
      _busy = false;
    }
  }

  Future<void> _onStartPressed() async {
    // ครั้งแรกของแต่ละท่า แสดงวิธีทำท่าก่อนเริ่ม
    if (!_seenGuides.contains(_move)) {
      final go = await _showGuide(_move, forStart: true);
      if (!go || !mounted) return;
    }
    await _start();
  }

  Future<bool> _showGuide(TrackedMove m, {bool forStart = false}) async {
    final go = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _GuideSheet(move: m, forStart: forStart),
    );
    _seenGuides.add(m);
    return go ?? false;
  }

  Future<void> _start() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    _counter.reset();
    setState(() {
      _running = true;
      _pose = null;
      _measurement = null;
      _angle = null;
      _minAngle = null;
      _maxAngle = null;
      _status = 'เริ่มแล้ว รอตรวจจับ…';
    });
    await c.startImageStream(_onFrame);
  }

  Future<void> _stop() async {
    final c = _controller;
    setState(() {
      _running = false;
      _pose = null;
      _measurement = null;
      _status = 'หยุดแล้ว';
    });
    if (c != null && c.value.isStreamingImages) await c.stopImageStream();
  }

  void _changeMove(TrackedMove m) {
    if (_running) return;
    setState(() {
      _move = m;
      _counter = RepCounter(moveSpecs[m]!, smoothing: _smoothing);
      _angle = null;
      _measurement = null;
      _minAngle = null;
      _maxAngle = null;
    });
  }

  Color get _focusColor {
    final a = _angle;
    if (a == null) return _orange;
    return (a <= _counter.downBelow || a >= _counter.upAbove) ? _teal : _orange;
  }

  /// ข้อความบอกว่าต้องทำอะไรต่อ (ตอบโจทย์ "ต้องลง/ขึ้นถึงจุดไหน")
  String _cue(MoveGuide guide) {
    if (!_running) return 'กด "เริ่ม" เพื่อเริ่มนับ';
    final a = _angle;
    if (a == null) return 'ยังไม่เห็นข้อต่อที่ต้องใช้ ดูรายการจุดด้านล่าง';
    if (DateTime.now().difference(_lastRepAt).inMilliseconds < 700) {
      return '✓ ครบ 1 ครั้ง';
    }
    if (!_counter.armed) {
      return 'เริ่มจากท่า "${guide.straightLabel}" ให้สุดก่อน (มุมต้องเกิน ${_counter.upAbove.round()}° ตอนนี้ ${a.round()}°)';
    }
    if (!_counter.isDown) {
      return '${guide.bendLabel}ต่อ ต้องต่ำกว่า ${_counter.downBelow.round()}° (ตอนนี้ ${a.round()}°)';
    }
    return '${guide.straightLabel}ต่อ ต้องเกิน ${_counter.upAbove.round()}° (ตอนนี้ ${a.round()}°)';
  }

  Widget _preview() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    final ps = c.value.previewSize!;
    // ล็อกจอแนวตั้ง: preview กว้าง = ps.height, สูง = ps.width
    final canvas = Size(ps.height, ps.width);
    final pose = _pose;
    final imageSize = _imageSize;
    final rotation = _lastRotation;
    final sides = _measurement?.sides ?? const <List<PoseLandmarkType>>[];

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: canvas.width,
        height: canvas.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(c),
            if (_running && pose != null && imageSize != null && rotation != null)
              CustomPaint(
                painter: PosePainter(
                  pose: pose,
                  imageSize: imageSize,
                  rotation: rotation,
                  lens: _cameras[_cameraIndex].lensDirection,
                  focusSides: sides,
                  focusColor: _focusColor,
                  angleText: _angle == null ? null : '${_angle!.round()}°',
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// รายการจุดที่ต้องเห็น (✓ เห็นชัด / ✗ ไม่เห็น) ช่วยหาระยะวางมือถือที่ใกล้ที่สุดที่ยังใช้ได้
  Widget _visibility(MoveGuide guide) {
    final lm = _pose?.landmarks;
    final triples = triplesFor(_move);
    const sides = ['ซ้าย', 'ขวา'];
    final rows = <Widget>[];
    for (var i = 0; i < triples.length; i++) {
      final spans = <InlineSpan>[
        TextSpan(
          text: '${sides[i]}: ',
          style: const TextStyle(color: Colors.white70),
        ),
      ];
      for (var j = 0; j < 3; j++) {
        final l = lm?[triples[i][j]];
        final ok = l != null && l.likelihood >= 0.5;
        spans.add(TextSpan(
          text: '${guide.jointNames[j]} ${ok ? '✓' : '✗'}   ',
          style: TextStyle(
            color: !_running
                ? Colors.white38
                : ok
                    ? _teal
                    : Colors.redAccent,
          ),
        ));
      }
      rows.add(Text.rich(TextSpan(children: spans),
          style: const TextStyle(fontSize: 12.5)));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  @override
  Widget build(BuildContext context) {
    if (!_supported) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'โปรโตไทป์นี้ใช้ได้เฉพาะ Android/iOS\nรันบนมือถือจริงด้วย flutter run',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final ready = _controller?.value.isInitialized ?? false;
    final guide = moveGuides[_move]!;
    final cue = _cue(guide);
    final previewSize = _controller?.value.previewSize;
    final sizeText = previewSize == null
        ? ''
        : '  ·  ภาพ ${previewSize.width.toInt()}x${previewSize.height.toInt()}';
    final repFlash = cue.startsWith('✓');

    return Scaffold(
      appBar: AppBar(title: const Text('Motion Tracking Prototype')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<TrackedMove>(
                showSelectedIcon: false,
                segments: [
                  for (final m in TrackedMove.values)
                    ButtonSegment(value: m, label: Text(moveSpecs[m]!.label)),
                ],
                selected: {_move},
                onSelectionChanged: _running ? null : (s) => _changeMove(s.first),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _showGuide(_move),
                icon: const Icon(Icons.play_circle_outline, size: 20),
                label: const Text('ดูวิธีทำท่านี้'),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Container(color: Colors.black26, child: _preview()),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: repFlash ? _teal.withValues(alpha: 0.25) : Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                cue,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            AngleGauge(
              angle: _angle,
              downBelow: _counter.downBelow,
              upAbove: _counter.upAbove,
              bendLabel: guide.bendLabel,
              straightLabel: guide.straightLabel,
              minSeen: _minAngle,
              maxSeen: _maxAngle,
            ),
            Center(
              child: Text(
                '${_counter.reps}',
                style: const TextStyle(
                    fontSize: 72, fontWeight: FontWeight.w700, height: 1.1),
              ),
            ),
            const Center(
                child: Text('ครั้ง', style: TextStyle(color: Colors.white70))),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: !ready ? null : (_running ? _stop : _onStartPressed),
                    child: Text(_running ? 'หยุด' : 'เริ่ม'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => setState(() {
                    _counter.reset();
                    _minAngle = null;
                    _maxAngle = null;
                  }),
                  child: const Text('รีเซ็ต'),
                ),
                if (_cameras.length > 1) ...[
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    tooltip: 'สลับกล้อง',
                    onPressed: _running ? null : _flipCamera,
                    icon: const Icon(Icons.cameraswitch_outlined),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            Text('จุดที่ระบบต้องเห็น (ซ้าย/ขวาของตัวคน)',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 4),
            _visibility(guide),
            const SizedBox(height: 6),
            Text(guide.cameraTip,
                style: const TextStyle(fontSize: 12, color: Colors.white54)),
            const SizedBox(height: 10),
            Text(_status,
                style: TextStyle(
                  fontSize: 12,
                  color: _status.startsWith('ERR')
                      ? Colors.redAccent
                      : Colors.white54,
                )),
            Text(
              'FPS ${_fps.toStringAsFixed(1)}  ·  ${_inferMs.toStringAsFixed(0)} ms/เฟรม  ·  ${_zoomText.isEmpty ? 'ซูมปรับไม่ได้' : _zoomText}$sizeText',
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
            Text(
              _angle == null || _minAngle == null || _maxAngle == null
                  ? 'มุมตอนนี้: —'
                  : 'มุมตอนนี้ ${_angle!.round()}°  ต่ำสุด ${_minAngle!.round()}°  สูงสุด ${_maxAngle!.round()}°',
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
            const Divider(height: 28),
            const Text('จูนและทดลอง',
                style: TextStyle(fontWeight: FontWeight.w600)),
            Text('นับ "${guide.bendLabel}" เมื่อมุมต่ำกว่า ${_counter.downBelow.round()}°',
                style: const TextStyle(fontSize: 13)),
            Slider(
              min: 20,
              max: 140,
              value: _counter.downBelow.clamp(20, 140).toDouble(),
              onChanged: (v) => setState(() => _counter.downBelow = v),
            ),
            Text('นับครบ 1 ครั้งเมื่อ "${guide.straightLabel}" เกิน ${_counter.upAbove.round()}°',
                style: const TextStyle(fontSize: 13)),
            Slider(
              min: 120,
              max: 180,
              value: _counter.upAbove.clamp(120, 180).toDouble(),
              onChanged: (v) => setState(() => _counter.upAbove = v),
            ),
            const Text(
              'วิธีจูน: ทำท่าสุดทางทั้งสองด้าน 1 รอบ ดูค่า "ต่ำสุด/สูงสุด" แล้วตั้งเกณฑ์ให้อยู่ระหว่างสองค่านั้น',
              style: TextStyle(fontSize: 12, color: Colors.white54),
            ),
            Text('ความเรียบของมุม ${_smoothing.toStringAsFixed(2)} (สูง = ตอบสนองเร็วขึ้น แต่มุมสั่นมากขึ้น)',
                style: const TextStyle(fontSize: 13)),
            Slider(
              min: 0.2,
              max: 1.0,
              value: _smoothing,
              onChanged: (v) => setState(() {
                _smoothing = v;
                _counter.smoothing = v;
              }),
            ),
            const Text('ความละเอียดภาพที่ส่งให้ตรวจจับ',
                style: TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            SegmentedButton<ResolutionPreset>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: ResolutionPreset.low, label: Text('ต่ำ')),
                ButtonSegment(value: ResolutionPreset.medium, label: Text('กลาง')),
                ButtonSegment(value: ResolutionPreset.high, label: Text('สูง')),
              ],
              selected: {_res},
              onSelectionChanged: _running ? null : (s) => _setRes(s.first),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 4, bottom: 6),
              child: Text(
                'ลดความละเอียดเพื่อลดความหน่วง แต่การตรวจจับอาจแม่นน้อยลง ดูขนาดภาพที่ใช้ในบรรทัด FPS',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('โมเดลแม่นยำขึ้น (ช้าลง)'),
              subtitle: const Text('ลองเปิดถ้าท่าวิดพื้นจับข้อต่อไม่ดี แล้วดู FPS'),
              value: _accurate,
              onChanged: _running ? null : _setAccurate,
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideSheet extends StatelessWidget {
  const _GuideSheet({required this.move, required this.forStart});

  final TrackedMove move;
  final bool forStart;

  @override
  Widget build(BuildContext context) {
    final spec = moveSpecs[move]!;
    final guide = moveGuides[move]!;
    final h2 = Theme.of(context)
        .textTheme
        .titleSmall
        ?.copyWith(fontWeight: FontWeight.w700);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            Text('ท่า${spec.label}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(8),
              child: DemoFigure(move: move),
            ),
            const SizedBox(height: 6),
            Text(
              'เส้นหนาคือข้อต่อที่ระบบวัดมุม สีเขียวอมฟ้า = ถึงโซนเป้าหมาย (ต่ำกว่า ${spec.downBelow.round()}° หรือเกิน ${spec.upAbove.round()}°) ต้องไปถึงทั้งสองโซนจึงนับ 1 ครั้ง',
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
            const SizedBox(height: 16),
            Text('วิธีทำ', style: h2),
            const SizedBox(height: 4),
            for (var i = 0; i < guide.steps.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text('${i + 1}. ${guide.steps[i]}'),
              ),
            const SizedBox(height: 12),
            Text('ข้อผิดพลาดที่พบบ่อย', style: h2),
            const SizedBox(height: 4),
            for (final m in guide.mistakes)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text('• $m'),
              ),
            const SizedBox(height: 12),
            Text('การวางกล้อง', style: h2),
            const SizedBox(height: 4),
            Text(guide.cameraTip),
            const SizedBox(height: 16),
            if (forStart) ...[
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('เข้าใจแล้ว เริ่มเลย'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('ปิด'),
              ),
            ] else
              FilledButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('ปิด'),
              ),
          ],
        ),
      ),
    );
  }
}
