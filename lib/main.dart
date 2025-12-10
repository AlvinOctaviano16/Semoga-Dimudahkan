import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';

import 'firebase_options.dart';

import 'core/auth_wrapper.dart';
import 'core/constants/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print("🚀 1. Binding Initialized");

  // 👇 PERBAIKAN INISIALISASI (Pakai Try-Catch agar tidak Crash)
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        name: 'synctask-app', // Beri nama unik agar aman
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("✅ 2. Firebase Baru Saja Dinyalakan");
    } else {
      print("⚠️ 2. Firebase Sudah Menyala Sebelumnya (Skip Init)");
    }
  } catch (e) {
    print("❌ Error Firebase Init: $e");
    // Lanjut saja, jangan crash.
  }

  runApp(
    const ProviderScope(
      child: SyncTaskApp(),
    ),
  );
}

class SyncTaskApp extends StatelessWidget {
  const SyncTaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'SyncTask',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          surface: AppColors.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}