import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// ✅ IMPORT DASHBOARD (Pastikan path ini benar)
// Jangan pakai 'lib/features...', langsung 'features/...'
import 'features/projects/screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    // Wajib bungkus ProviderScope untuk Riverpod
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TeamTask App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // ⚠️ BAGIAN KRUSIAL:
      // Pastikan ini 'DashboardScreen()', BUKAN 'LoginScreen()' atau 'AuthWrapper()'
      home: const DashboardScreen(),
    );
  }
}