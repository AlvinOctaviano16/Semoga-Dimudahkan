import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/projects/screens/dashboard_screen.dart';

// Import Dashboard (Nanti kita restore file ini)
// SEMENTARA kita pakai Placeholder dulu biar gak error saat run
class DashboardPlaceholder extends StatelessWidget {
  const DashboardPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => FirebaseAuth.instance.signOut(), 
          child: const Text("Logout (Test)")
        )
      ),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (snapshot.hasData) {
          // Redirect ke Real Dashboard
          return const DashboardScreen(); 
        }

        return const LoginScreen();
      },
    );
  }
}