import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../labels.dart';

/// การ์ดน้ำหนักตัว: แสดงค่าล่าสุดและประวัติย้อนหลัง บันทึกวันละ 1 ค่า (แก้ค่าของวันนี้ซ้ำได้)
class WeightCard extends ConsumerWidget {
  const WeightCard({super.key});

  Future<void> _logWeight(BuildContext context, WidgetRef ref, double? current) async {
    final controller =
        TextEditingController(text: current == null ? '' : formatNumber(current));
    final value = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('บันทึกน้ำหนักวันนี้'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(suffixText: 'กก.'),
          onSubmitted: (v) =>
              Navigator.of(ctx).pop(double.tryParse(v.trim().replaceAll(',', '.'))),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(
              double.tryParse(controller.text.trim().replaceAll(',', '.')),
            ),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value <= 0) return;
    await ref.read(bodyMetricsRepositoryProvider).logWeight(weightKg: value);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(recentBodyMetricsProvider);

    return Container(
      decoration: forgeCardDecoration,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: metrics.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, s) => Text('โหลดน้ำหนักไม่สำเร็จ: $e'),
        data: (list) {
          final latest = list.isEmpty ? null : list.first;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('น้ำหนักตัว',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          latest == null
                              ? '— กก.'
                              : '${formatNumber(latest.weightKg)} กก.',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (latest != null)
                          Text(
                            _relativeDay(latest.measuredOn),
                            style: const TextStyle(
                                fontSize: 12, color: ForgeColors.textMuted),
                          ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () =>
                        _logWeight(context, ref, latest?.weightKg),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('บันทึก'),
                  ),
                ],
              ),
              if (list.length > 1) ...[
                const Divider(height: 24, color: ForgeColors.border),
                for (final m in list.skip(1).take(5)) _HistoryRow(metric: m),
              ],
            ],
          );
        },
      ),
    );
  }

  String _relativeDay(DateTime d) {
    final today = DateTime.now();
    final diff = DateTime(today.year, today.month, today.day)
        .difference(DateTime(d.year, d.month, d.day))
        .inDays;
    if (diff == 0) return 'วันนี้';
    if (diff == 1) return 'เมื่อวาน';
    return '${d.day}/${d.month}/${d.year}';
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.metric});
  final BodyMetric metric;

  @override
  Widget build(BuildContext context) {
    final d = metric.measuredOn;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('${d.day}/${d.month}/${d.year}',
              style: const TextStyle(
                  fontSize: 12.5, color: ForgeColors.textSecondary)),
          const Spacer(),
          Text('${formatNumber(metric.weightKg)} กก.',
              style: const TextStyle(fontSize: 12.5)),
        ],
      ),
    );
  }
}
