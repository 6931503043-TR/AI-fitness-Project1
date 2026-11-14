import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../data/repositories/routine_repository.dart';
import '../../domain/enums.dart';
import '../labels.dart';

/// เปิดฟอร์มเพิ่มท่าในแผน (existing == null) หรือแก้ท่าที่มีอยู่
Future<void> showItemEditor(
  BuildContext context,
  Routine routine, {
  RoutineItemWithExercise? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ItemEditorSheet(routine: routine, existing: existing),
  );
}

class ItemEditorSheet extends ConsumerStatefulWidget {
  const ItemEditorSheet({super.key, required this.routine, this.existing});

  final Routine routine;
  final RoutineItemWithExercise? existing;

  @override
  ConsumerState<ItemEditorSheet> createState() => _ItemEditorSheetState();
}

class _ItemEditorSheetState extends ConsumerState<ItemEditorSheet> {
  static const _newKey = '__new__';

  String? _exerciseId;
  MuscleGroup _muscle = MuscleGroup.chest;
  String? _error;
  bool _saving = false;

  final _name = TextEditingController();
  final _sets = TextEditingController(text: '3');
  final _reps = TextEditingController();
  final _weight = TextEditingController();
  final _duration = TextEditingController(); // หน่วย: นาที (ทศนิยมได้ เช่น 0.5)

  bool get _isStrength => widget.routine.type == ExerciseType.strength;
  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _exerciseId = e.exercise.id;
      _sets.text = '${e.item.targetSets}';
      _reps.text = e.item.targetReps?.toString() ?? '';
      final w = e.item.targetWeightKg;
      _weight.text = w == null ? '' : formatNumber(w);
      final d = e.item.targetDurationSec;
      _duration.text = d == null ? '' : formatNumber(d / 60);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _sets.dispose();
    _reps.dispose();
    _weight.dispose();
    _duration.dispose();
    super.dispose();
  }

  double? _parseDouble(String s) =>
      double.tryParse(s.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    var exerciseId = _exerciseId;
    if (exerciseId == null) {
      setState(() => _error = 'เลือกท่าก่อน');
      return;
    }
    if (exerciseId == _newKey && _name.text.trim().isEmpty) {
      setState(() => _error = 'กรอกชื่อท่าใหม่ก่อน');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final sets = math.max(1, math.min(99, int.tryParse(_sets.text.trim()) ?? 1));
    final reps = _isStrength ? int.tryParse(_reps.text.trim()) : null;
    final weight = _isStrength ? _parseDouble(_weight.text) : null;
    final minutes = _isStrength ? null : _parseDouble(_duration.text);
    final durationSec = minutes == null ? null : (minutes * 60).round();

    try {
      if (exerciseId == _newKey) {
        exerciseId = await ref.read(exerciseRepositoryProvider).create(
              name: _name.text,
              type: widget.routine.type,
              primaryMuscle: _isStrength ? _muscle : MuscleGroup.fullBody,
            );
      }

      final repo = ref.read(routineRepositoryProvider);
      final existing = widget.existing;
      if (existing == null) {
        await repo.addItem(
          routineId: widget.routine.id,
          exerciseId: exerciseId,
          sets: sets,
          reps: reps,
          weightKg: weight,
          durationSec: durationSec,
        );
      } else {
        await repo.updateItem(
          existing.item.id,
          sets: sets,
          reps: reps,
          weightKg: weight,
          durationSec: durationSec,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'บันทึกไม่สำเร็จ: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercises = ref.watch(exercisesByTypeProvider(widget.routine.type));

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _editing ? 'แก้ไขท่าในแผน' : 'เพิ่มท่าในแผน',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (_editing)
              Text(
                widget.existing!.exercise.name,
                style: Theme.of(context).textTheme.titleMedium,
              )
            else
              exercises.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, s) => Text('โหลดรายการท่าไม่สำเร็จ: $e'),
                data: (list) => DropdownButtonFormField<String>(
                  initialValue: _exerciseId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'ท่าออกกำลังกาย'),
                  items: [
                    for (final e in list)
                      DropdownMenuItem(value: e.id, child: Text(e.name)),
                    const DropdownMenuItem(
                      value: _newKey,
                      child: Text('+ สร้างท่าใหม่…'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _exerciseId = v),
                ),
              ),
            if (_exerciseId == _newKey) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'ชื่อท่าใหม่'),
              ),
              if (_isStrength) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<MuscleGroup>(
                  initialValue: _muscle,
                  decoration:
                      const InputDecoration(labelText: 'กล้ามเนื้อหลัก'),
                  items: [
                    for (final m in MuscleGroup.values)
                      if (m != MuscleGroup.fullBody)
                        DropdownMenuItem(value: m, child: Text(m.label)),
                  ],
                  onChanged: (v) => setState(() => _muscle = v ?? _muscle),
                ),
              ],
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sets,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'เซต'),
                  ),
                ),
                const SizedBox(width: 10),
                if (_isStrength) ...[
                  Expanded(
                    child: TextField(
                      controller: _reps,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'ครั้ง'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _weight,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'กก.'),
                    ),
                  ),
                ] else
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _duration,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'เวลาต่อเซต (นาที)',
                        helperText: 'เช่น 0.5 = 30 วินาที',
                      ),
                    ),
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_editing ? 'บันทึกการแก้ไข' : 'เพิ่มท่า'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
