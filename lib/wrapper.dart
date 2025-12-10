import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'homepage.dart';
import 'login.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/projects/screens/dashboard_screen.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Cek status koneksi
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. LOGIC JEMBATAN
        if (snapshot.hasData) {
          // JIKA SUDAH LOGIN -> Arahkan ke Dashboard Anda
          return const DashboardScreen();
        } else {
          // JIKA BELUM LOGIN -> Arahkan ke Login
          return const Login(); 
        }
      },
    );
  }
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Homepage();
          } else {
            return Login();
          }
        },
      ),
    );
  }
}