import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'signup_view.dart';
import 'forgot.dart';

// IMPORT FILE CONSTANTS BARU
import '../../../../../core/constants/app_colors.dart'; 

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // (Hapus variabel warna manual disini karena sudah ada di AppColors)

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void handleLogin() {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar("Input Error", "Email dan Password tidak boleh kosong",
        backgroundColor: AppColors.surface, // Pakai Constant
        colorText: AppColors.textPrimary);
      return;
    }

    ref.read(authControllerProvider.notifier).login(
      emailController.text.trim(),
      passwordController.text.trim(),
    );
  }

  Widget _buildAppleTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface, // Ganti _fieldColor jadi AppColors.surface
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        cursorColor: AppColors.primary, // Ganti _accentColor jadi AppColors.primary
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          prefixIcon: Icon(icon, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background, // Ganti _backgroundColor
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary), // Agar tombol back putih
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.task_alt, size: 90, color: AppColors.primary),
              
              const SizedBox(height: 20),
              const Text(
                "SyncTask",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Manage your tasks efficiently",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 50),

              _buildAppleTextField(
                controller: emailController, 
                hint: "Email", 
                icon: Icons.mail_outline
              ),
              const SizedBox(height: 16),
              _buildAppleTextField(
                controller: passwordController, 
                hint: "Password", 
                icon: Icons.lock_outline, 
                isPassword: true
              ),
              
              const SizedBox(height: 30),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                    // Perbaikan .withValues sesuai saran sebelumnya
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isLoading 
                    ? const SizedBox(
                        height: 24, width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        "Sign In",
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? ", style: TextStyle(color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: () => Get.to(() => const Signup()),
                    child: const Text(
                      "Sign up",
                      style: TextStyle(
                        color: AppColors.primary, 
                        fontWeight: FontWeight.w600
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),

              TextButton(
                onPressed: () => Get.to(() => const Forgot()),
                child: const Text(
                  "Forgot Password?", 
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}