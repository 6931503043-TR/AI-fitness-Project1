import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../domain/enums.dart';
import '../../domain/tdee.dart';
import '../labels.dart';

/// การ์ดคำนวณ TDEE จากโปรไฟล์ที่บันทึกไว้ (เพศ/อายุ/ส่วนสูง/กิจกรรม) และน้ำหนักล่าสุด
class TdeeCard extends ConsumerStatefulWidget {
  const TdeeCard({super.key});

  @override
  ConsumerState<TdeeCard> createState() => _TdeeCardState();
}

class _TdeeCardState extends ConsumerState<TdeeCard> {
  Gender _gender = Gender.male;
  ActivityLevel _activity = ActivityLevel.moderate;
  final _age = TextEditingController(text: '28');
  final _height = TextEditingController(text: '172');

  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _age.dispose();
    _height.dispose();
    super.dispose();
  }

  /// เติมค่าจากโปรไฟล์ที่บันทึกไว้ครั้งแรกที่มีข้อมูลเท่านั้น
  /// (ไม่เขียนทับสิ่งที่ผู้ใช้กำลังพิมพ์อยู่ในฟอร์มเวลาข้อมูลรีเฟรช)
  void _hydrateOnce(UserProfile? profile) {
    if (_initialized || profile == null) return;
    _initialized = true;
    _gender = profile.gender;
    _activity = profile.activityLevel;
    _age.text = '${DateTime.now().year - profile.birthYear}';
    _height.text = formatNumber(profile.heightCm);
  }

  Future<void> _save() async {
    final age = int.tryParse(_age.text.trim());
    final height = double.tryParse(_height.text.trim().replaceAll(',', '.'));
    if (age == null || height == null || age <= 0 || height <= 0) return;

    setState(() => _saving = true);
    await ref.read(profileRepositoryProvider).save(
          gender: _gender,
          birthYear: DateTime.now().year - age,
          heightCm: height,
          activityLevel: _activity,
        );
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final weightAsync = ref.watch(recentBodyMetricsProvider);

    profileAsync.whenData(_hydrateOnce);

    final weightList = weightAsync.valueOrNull;
    final weight =
        (weightList != null && weightList.isNotEmpty) ? weightList.first.weightKg : null;
    final age = int.tryParse(_age.text.trim());
    final height = double.tryParse(_height.text.trim().replaceAll(',', '.'));

    double? bmr;
    double? tdee;
    if (weight != null && age != null && height != null) {
      bmr = bmrMifflinStJeor(
          gender: _gender, weightKg: weight, heightCm: height, age: age);
      tdee = calcTdee(bmr, _activity);
    }

    return Container(
      decoration: forgeCardDecoration,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('คำนวณพลังงานที่ใช้ต่อวัน (TDEE)',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            weight == null
                ? 'บันทึกน้ำหนักตัวด้านบนก่อนเพื่อให้คำนวณได้'
                : 'ใช้น้ำหนักล่าสุดที่บันทึกไว้ (${formatNumber(weight)} กก.)',
            style: const TextStyle(fontSize: 13, color: ForgeColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<Gender>(
                  initialValue: _gender,
                  decoration: const InputDecoration(labelText: 'เพศ'),
                  items: const [
                    DropdownMenuItem(value: Gender.male, child: Text('ชาย')),
                    DropdownMenuItem(value: Gender.female, child: Text('หญิง')),
                  ],
                  onChanged: (v) => setState(() => _gender = v ?? _gender),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _age,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'อายุ'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _height,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'ส่วนสูง (ซม.)'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<ActivityLevel>(
            initialValue: _activity,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'ระดับกิจกรรม'),
            items: const [
              DropdownMenuItem(
                  value: ActivityLevel.sedentary,
                  child: Text('น้อยมาก (นั่งทำงาน ไม่ค่อยขยับ)')),
              DropdownMenuItem(
                  value: ActivityLevel.light,
                  child: Text('น้อย (ออกกำลังกาย 1-3 วัน/สัปดาห์)')),
              DropdownMenuItem(
                  value: ActivityLevel.moderate,
                  child: Text('ปานกลาง (ออกกำลังกาย 3-5 วัน/สัปดาห์)')),
              DropdownMenuItem(
                  value: ActivityLevel.active,
                  child: Text('มาก (ออกกำลังกาย 6-7 วัน/สัปดาห์)')),
              DropdownMenuItem(
                  value: ActivityLevel.athlete,
                  child: Text('มากที่สุด (นักกีฬา / ใช้แรงงานหนัก)')),
            ],
            onChanged: (v) => setState(() => _activity = v ?? _activity),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _StatBox(label: 'BMR', value: bmr)),
              const SizedBox(width: 10),
              Expanded(child: _StatBox(label: 'TDEE โดยประมาณ', value: tdee)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'กำลังบันทึก…' : 'บันทึกข้อมูลนี้'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});
  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ForgeColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ForgeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: ForgeColors.textSecondary)),
          const SizedBox(height: 2),
          Text(
            value == null ? '—' : '${value!.round()} kcal',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
