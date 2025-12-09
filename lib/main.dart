// Lokasi: lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'firebase_options.dart'; 
import 'features/auth/wrapper.dart'; 

void main() async {
  // 1. Inisialisasi Binding
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Inisialisasi Firebase dengan Error Handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("⚠️ Firebase Error: $e");
  }

  // 3. Jalankan Aplikasi dengan ProviderScope (Wajib untuk Riverpod)
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false, 
      title: 'SyncTask',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Panggil Wrapper sebagai halaman awal (Untuk cek Login/Logout)
      home: const Wrapper(), 
    );
  }
}