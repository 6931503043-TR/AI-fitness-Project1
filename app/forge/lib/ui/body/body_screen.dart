import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'recovery_card.dart';
import 'tdee_card.dart';
import 'weight_card.dart';

class BodyScreen extends StatelessWidget {
  const BodyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Text('ร่างกาย', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        const Text(
          'ติดตามความล้าของกล้ามเนื้อ น้ำหนักตัว และพลังงานที่ใช้',
          style: TextStyle(color: ForgeColors.textSecondary),
        ),
        const SizedBox(height: 16),
        const WeightCard(),
        const SizedBox(height: 14),
        const RecoveryCard(),
        const SizedBox(height: 14),
        const TdeeCard(),
      ],
    );
  }
}
