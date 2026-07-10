import 'package:flutter/material.dart';

import 'di.dart';
import '../presentation/auth/auth_gate.dart';

Future<void> bootstrapApp({required String envFile}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies(envFile: envFile);
  runApp(const SentinelApp());
}

class SentinelApp extends StatelessWidget {
  const SentinelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Relato',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}
