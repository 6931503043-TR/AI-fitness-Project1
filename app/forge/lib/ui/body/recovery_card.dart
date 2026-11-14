import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../domain/enums.dart';
import '../../domain/recovery.dart';
import '../labels.dart';

/// การ์ดพักฟื้นกล้ามเนื้อ: คำนวณจากประวัติการซ้อมจริง (ไม่ต้องกดยืนยันเอง)
class RecoveryCard extends ConsumerWidget {
  const RecoveryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowProvider).valueOrNull ?? DateTime.now();
    final lastTrained = ref.watch(lastTrainedByMuscleProvider);

    return Container(
      decoration: forgeCardDecoration,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('การพักฟื้นของกล้ามเนื้อ',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          const Text(
            'คำนวณอัตโนมัติจากเซตที่บันทึกไว้ในโหมดซ้อม',
            style: TextStyle(fontSize: 13, color: ForgeColors.textSecondary),
          ),
          const SizedBox(height: 4),
          lastTrained.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('โหลดข้อมูลไม่สำเร็จ: $e'),
            ),
            data: (map) => Column(
              children: [
                for (final muscle in bodyScreenMuscleOrder)
                  _MuscleRow(
                    muscle: muscle,
                    recovery: recoveryOf(
                      muscle: muscle,
                      lastTrained: map[muscle],
                      now: now,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MuscleRow extends StatelessWidget {
  const _MuscleRow({required this.muscle, required this.recovery});

  final MuscleGroup muscle;
  final MuscleRecovery recovery;

  @override
  Widget build(BuildContext context) {
    final color = recovery.isRecovered ? ForgeColors.recovery : ForgeColors.accent;
    final statusText = recovery.isRecovered
        ? 'พร้อมฝึก'
        : 'เหลือ ${recovery.hoursLeft.toStringAsFixed(0)} ชม.';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              muscle.label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: recovery.progress,
                minHeight: 6,
                backgroundColor: ForgeColors.surface2,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              statusText,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                color: recovery.isRecovered
                    ? ForgeColors.recovery
                    : ForgeColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
