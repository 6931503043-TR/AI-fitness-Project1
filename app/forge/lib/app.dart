import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'ui/shell.dart';

class ForgeApp extends StatelessWidget {
  const ForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FORGE',
      debugShowCheckedModeBanner: false,
      theme: buildForgeTheme(),
      home: const AppShell(),
    );
  }
}
