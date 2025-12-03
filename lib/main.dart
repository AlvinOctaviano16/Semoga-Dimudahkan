import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'firebase_options.dart'; // ini nnti kalau udh setup firebase
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TODO: Uncomment baris di bawah ini setelah menjalankan 'flutterfire configure'
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  runApp(
    // Wajib membungkus aplikasi dengan ProviderScope agar Riverpod jalan
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
      // Nanti ganti ini ke LoginScreen()
      home: const Scaffold(
        body: Center(child: Text("Setup Project Berhasil!")),
      ),
    );
  }
}