import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../data/repositories/routine_repository.dart';
import '../../domain/enums.dart';
import '../labels.dart';
import 'dialogs.dart';
import 'item_editor_sheet.dart';

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  ExerciseType _type = ExerciseType.strength;

  /// จำแผนที่เลือกไว้ของแต่ละประเภท
  final Map<ExerciseType, String> _selected = {};

  Future<void> _createRoutine() async {
    final type = _type;
    final name = await promptText(
      context,
      title: 'ชื่อแผนใหม่',
      hint: 'เช่น Push / Pull / Legs',
    );
    if (name == null || name.isEmpty) return;
    final id = await ref
        .read(routineRepositoryProvider)
        .create(name: name, type: type);
    if (mounted) setState(() => _selected[type] = id);
  }

  @override
  Widget build(BuildContext context) {
    final routines = ref.watch(routinesByTypeProvider(_type));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Text('แผนของคุณ', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        const Text(
          'เลือกประเภทการฝึก แล้วปรับท่าให้เข้ากับเป้าหมายวันนี้',
          style: TextStyle(color: ForgeColors.textSecondary),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ExerciseType>(
            showSelectedIcon: false,
            segments: [
              for (final t in ExerciseType.values)
                ButtonSegment(value: t, label: Text(t.label)),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
        ),
        const SizedBox(height: 16),
        routines.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, s) => Text('โหลดแผนไม่สำเร็จ: $e'),
          data: _buildRoutines,
        ),
      ],
    );
  }

  Widget _buildRoutines(List<Routine> routines) {
    if (routines.isEmpty) {
      return Container(
        decoration: forgeCardDecoration,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'ยังไม่มีแผนในหมวดนี้',
              style: TextStyle(color: ForgeColors.textSecondary),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _createRoutine,
              icon: const Icon(Icons.add),
              label: const Text('สร้างแผนแรก'),
            ),
          ],
        ),
      );
    }

    final remembered = _selected[_type];
    final selected = routines.firstWhere(
      (r) => r.id == remembered,
      orElse: () => routines.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final r in routines)
              ChoiceChip(
                label: Text(r.name),
                selected: r.id == selected.id,
                onSelected: (_) => setState(() => _selected[_type] = r.id),
              ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: const Text('แผนใหม่'),
              onPressed: _createRoutine,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _RoutineCard(routine: selected),
      ],
    );
  }
}

class _RoutineCard extends ConsumerWidget {
  const _RoutineCard({required this.routine});

  final Routine routine;

  Future<void> _onMenu(BuildContext context, WidgetRef ref, String action) async {
    final repo = ref.read(routineRepositoryProvider);
    if (action == 'rename') {
      final name = await promptText(
        context,
        title: 'เปลี่ยนชื่อแผน',
        initial: routine.name,
      );
      if (name != null && name.isNotEmpty) {
        await repo.rename(routine.id, name);
      }
    } else if (action == 'delete') {
      final ok = await confirmDialog(
        context,
        title: 'ลบแผน "${routine.name}"?',
        message: 'ท่าทั้งหมดในแผนนี้จะถูกลบ (ประวัติการซ้อมที่เคยบันทึกไว้ไม่หาย)',
      );
      if (ok) await repo.delete(routine.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(routineItemsProvider(routine.id));

    return Container(
      decoration: forgeCardDecoration,
      padding: const EdgeInsets.fromLTRB(18, 8, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  routine.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) => _onMenu(context, ref, v),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'rename', child: Text('เปลี่ยนชื่อ')),
                  PopupMenuItem(value: 'delete', child: Text('ลบแผน')),
                ],
              ),
            ],
          ),
          items.when(
            loading: () => const SizedBox.shrink(),
            error: (e, s) => Text('โหลดท่าไม่สำเร็จ: $e'),
            data: (list) {
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'ยังไม่มีท่าในแผนนี้ เพิ่มท่าแรกได้เลย',
                    style: TextStyle(color: ForgeColors.textMuted),
                  ),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < list.length; i++)
                    _ItemRow(
                      index: i,
                      entry: list[i],
                      onTap: () =>
                          showItemEditor(context, routine, existing: list[i]),
                      onDelete: () => ref
                          .read(routineRepositoryProvider)
                          .removeItem(list[i].item.id),
                    ),
                ],
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10, top: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => showItemEditor(context, routine),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('เพิ่มท่าออกกำลังกาย'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.index,
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  final int index;
  final RoutineItemWithExercise entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                (index + 1).toString().padLeft(2, '0'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ForgeColors.textMuted,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.exercise.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    describeItem(entry.item),
                    style: const TextStyle(
                        fontSize: 12, color: ForgeColors.textSecondary),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'ลบท่านี้',
              icon: const Icon(Icons.close, size: 18),
              color: ForgeColors.textMuted,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
