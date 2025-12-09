import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
class Forgot extends ConsumerStatefulWidget {
  const Forgot({super.key});

  @override
  ConsumerState<Forgot> createState() => _ForgotState();
}

class _ForgotState extends ConsumerState<Forgot> {
  final TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Pantau status loading dari AuthController
    final isLoading = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(hintText: "Enter your email"),
            ),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () {
                      // PANGGIL CONTROLLER LEWAT RIVERPOD
                      ref.read(authControllerProvider.notifier).forgotPassword(
                            emailController.text.trim(),
                          );
                    },
                    child: const Text("Send Reset Link"),
                  ),
          ],
        ),
      ),
    );
  }
}