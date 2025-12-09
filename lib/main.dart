import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sync_task_app/wrapper.dart';
import 'firebase_options.dart'; 
import 'package:get/get.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // --- BAGIAN PENGAMAN (FIX) ---
  // Kita bungkus dengan try-catch agar aplikasi TIDAK CRASH
  // meskipun terjadi error "Duplicate App"
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint("✅ Firebase Berhasil Connect!");
    } else {
      debugPrint("ℹ️ Firebase sudah jalan sebelumnya (Aman).");
    }
  } catch (e) {
    // Kalau error, kita print saja tapi JANGAN hentikan aplikasi
    debugPrint("⚠️ Error Firebase (Diabaikan): $e");
  }
  // -----------------------------

  // Baris ini sekarang AMAN dan pasti tereksekusi
  runApp(const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // Tambahkan debug false biar banner miring hilang
      debugShowCheckedModeBanner: false, 
      title: 'TeamTask App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const Wrapper(), // Gunakan const biar lebih optimal
    );
  }
}