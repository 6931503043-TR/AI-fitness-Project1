import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../data/providers.dart';
import 'body/body_screen.dart';
import 'placeholder_screen.dart';
import 'plan/plan_screen.dart';
import 'work/work_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Row(
          children: [
            Text('FORGE',
                style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            Text('.',
                style: TextStyle(
                    fontWeight: FontWeight.w800, color: ForgeColors.accent)),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: Center(child: _StreakBadge()),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          const PlanScreen(),
          const BodyScreen(),
          // เปิดกล้องเฉพาะตอนอยู่แท็บ Work เท่านั้น (ออกจากแท็บ = ปิดกล้อง)
          _index == 2 ? const WorkScreen() : const SizedBox.shrink(),
          const PlaceholderScreen(
            icon: Icons.chat_bubble_outline,
            title: 'Trainer',
            note: 'แชทเทรนเนอร์ / AI chat อยู่ในเฟสหลัง',
          ),
          const PlaceholderScreen(
            icon: Icons.settings_outlined,
            title: 'Setting',
            note: 'หน่วยน้ำหนัก, ภาษา, สำรองข้อมูล อยู่ในเฟส 3',
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.format_list_bulleted), label: 'Plan'),
          NavigationDestination(
              icon: Icon(Icons.accessibility_new), label: 'Body'),
          NavigationDestination(
              icon: Icon(Icons.camera_alt_outlined),
              selectedIcon: Icon(Icons.camera_alt),
              label: 'Work'),
          NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'Trainer'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Setting'),
        ],
      ),
    );
  }
}

class _StreakBadge extends ConsumerWidget {
  const _StreakBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);
    return streak.when(
      data: (n) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department,
              size: 16, color: ForgeColors.accent),
          const SizedBox(width: 4),
          Text(
            n > 0 ? '$n วันติด' : 'ยังไม่มีสตรีค',
            style: const TextStyle(
                fontSize: 13, color: ForgeColors.textSecondary),
          ),
        ],
      ),
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }
}
