import 'dart:io' show Platform;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../domain/rep_counter.dart';

bool get _cameraSupported =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);

/// จุดข้อต่อ 3 จุด (ต้นทาง-จุดหมุน-ปลาย) ของแต่ละท่า ซ้ายและขวา
List<List<PoseLandmarkType>> _triples(TrackedMove m) {
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

class WorkScreen extends ConsumerStatefulWidget {
  const WorkScreen({super.key});

  @override
  ConsumerState<WorkScreen> createState() => _WorkScreenState();
}

class _WorkScreenState extends ConsumerState<WorkScreen> {
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

  TrackedMove _move = TrackedMove.squat;
  late RepCounter _counter = RepCounter(moveSpecs[_move]!);

  bool _running = false;
  bool _busy = false;
  bool _detected = false;
  double? _angle;

  @override
  void initState() {
    super.initState();
    if (_cameraSupported) _initCamera();
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

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _error = 'ไม่พบกล้องในเครื่องนี้');
        return;
      }
      // เริ่มจากกล้องหน้า (ตั้งมือถือหันหาตัวเองได้ง่ายและเห็นจอตอนซ้อม)
      final front = _cameras.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.front);
      _cameraIndex = front >= 0 ? front : 0;
      _detector ??= PoseDetector(
        options: PoseDetectorOptions(
          mode: PoseDetectionMode.stream,
          model: PoseDetectionModel.base,
        ),
      );
      await _startController();
    } on CameraException catch (e) {
      if (mounted) {
        setState(() => _error = 'เปิดกล้องไม่ได้ (${e.code}) — ตรวจสอบว่าอนุญาตการใช้กล้องแล้ว');
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
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    _controller = controller;
    await controller.initialize();
    if (!mounted) return;
    setState(() => _error = null);
    if (_running) await controller.startImageStream(_onFrame);
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    try {
      await _startController();
    } on CameraException catch (e) {
      if (mounted) setState(() => _error = 'สลับกล้องไม่สำเร็จ (${e.code})');
    }
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
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

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

  /// มุมเฉลี่ยของข้างที่ตรวจจับได้มั่นใจพอ (likelihood >= 0.5) คืน null ถ้าไม่เห็นครบ
  double? _angleFrom(Map<PoseLandmarkType, PoseLandmark> lm) {
    final angles = <double>[];
    for (final t in _triples(_move)) {
      final p = t.map((k) => lm[k]).toList();
      if (p.any((e) => e == null || e.likelihood < 0.5)) continue;
      final a = angleDeg(
        Pt(p[0]!.x, p[0]!.y),
        Pt(p[1]!.x, p[1]!.y),
        Pt(p[2]!.x, p[2]!.y),
      );
      if (!a.isNaN) angles.add(a);
    }
    if (angles.isEmpty) return null;
    return angles.reduce((a, b) => a + b) / angles.length;
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_busy || !_running) return;
    _busy = true;
    try {
      final input = _toInputImage(image);
      final detector = _detector;
      if (input == null || detector == null) return;

      final poses = await detector.processImage(input);
      if (!mounted || !_running) return;

      final angle = poses.isEmpty ? null : _angleFrom(poses.first.landmarks);
      var repDone = false;
      if (angle != null) repDone = _counter.update(angle);
      if (repDone) HapticFeedback.lightImpact();

      setState(() {
        _detected = angle != null;
        _angle = angle;
      });
    } catch (e) {
      debugPrint('pose frame error: $e');
    } finally {
      _busy = false;
    }
  }

  Future<void> _start() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    _counter.reset();
    setState(() {
      _running = true;
      _detected = false;
      _angle = null;
    });
    await c.startImageStream(_onFrame);
  }

  Future<void> _stopAndSave() async {
    final c = _controller;
    setState(() => _running = false);
    if (c != null && c.value.isStreamingImages) await c.stopImageStream();

    final reps = _counter.reps;
    if (reps <= 0) return;

    final repo = ref.read(workoutRepositoryProvider);
    final spec = moveSpecs[_move]!;
    final workoutId = await repo.start();
    await repo.logSet(workoutId: workoutId, exerciseId: spec.exerciseId, reps: reps);
    await repo.finish(workoutId);

    _counter.reset();
    if (!mounted) return;
    setState(() => _angle = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('บันทึกแล้ว: ${spec.label} $reps ครั้ง')),
    );
  }

  void _changeMove(TrackedMove m) {
    if (_running) return;
    setState(() {
      _move = m;
      _counter = RepCounter(moveSpecs[m]!);
      _angle = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraSupported) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'แท็บ Work ใช้กล้อง AI ได้เฉพาะ Android/iOS\nรันบนมือถือเพื่อทดสอบ',
            textAlign: TextAlign.center,
            style: TextStyle(color: ForgeColors.textSecondary),
          ),
        ),
      );
    }

    final spec = moveSpecs[_move]!;
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Text('Work', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(spec.hint,
            style: const TextStyle(color: ForgeColors.textSecondary)),
        const SizedBox(height: 14),
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
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: Container(
              color: ForgeColors.surface2,
              child: _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_error!, textAlign: TextAlign.center),
                      ),
                    )
                  : ready
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: controller.value.previewSize!.height,
                                height: controller.value.previewSize!.width,
                                child: CameraPreview(controller),
                              ),
                            ),
                            Positioned(
                              top: 12,
                              left: 12,
                              child: _Pill(
                                text: !_running
                                    ? 'พร้อม'
                                    : _detected
                                        ? 'ตรวจพบร่างกาย'
                                        : 'ยังไม่เห็นข้อต่อครบ',
                                color: !_running
                                    ? ForgeColors.textSecondary
                                    : _detected
                                        ? ForgeColors.recovery
                                        : ForgeColors.danger,
                              ),
                            ),
                            if (_angle != null)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: _Pill(
                                  text: 'มุม ${_angle!.round()}°',
                                  color: ForgeColors.textSecondary,
                                ),
                              ),
                          ],
                        )
                      : const Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Column(
            children: [
              Text(
                '${_counter.reps}',
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
              const Text('ครั้ง',
                  style: TextStyle(color: ForgeColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: !ready ? null : (_running ? _stopAndSave : _start),
                style: _running
                    ? FilledButton.styleFrom(
                        backgroundColor: ForgeColors.surface2,
                        foregroundColor: ForgeColors.text,
                      )
                    : null,
                child: Text(_running ? 'หยุดและบันทึกเซต' : 'เริ่มซ้อม'),
              ),
            ),
            if (_cameras.length > 1) ...[
              const SizedBox(width: 10),
              IconButton.outlined(
                tooltip: 'สลับกล้อง',
                onPressed: _running ? null : _flipCamera,
                icon: const Icon(Icons.cameraswitch_outlined),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'ระบบนับจากมุมข้อต่อ เกณฑ์เป็นค่าเริ่มต้นที่ยังไม่ได้จูน อาจนับพลาดหรือไม่นับ ขึ้นกับมุมกล้องและแสง',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: ForgeColors.textMuted),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: color)),
    );
  }
}
