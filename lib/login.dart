import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:sync_task_app/forgot.dart';
import 'package:sync_task_app/signup.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Warna Tema
  final Color _backgroundColor = const Color(0xFF000000);
  final Color _fieldColor = const Color(0xFF1C1C1E);
  final Color _accentColor = const Color(0xFF0A84FF);
  final Color _textSecondary = const Color(0xFF8E8E93);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    // 1. Tutup Keyboard
    FocusManager.instance.primaryFocus?.unfocus();

    // 2. Validasi
    if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      Get.snackbar(
        "Missing Input",
        "Email dan Password harus diisi.",
        backgroundColor: const Color(0xFF333333),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    // 3. Tampilkan Loading
    Get.dialog(
      Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _fieldColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const CircularProgressIndicator(color: Colors.white),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      // 4. Proses Login
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        throw FirebaseAuthException(
          code: 'network-request-failed',
          message: 'Koneksi timeout. Cek internet Anda.'
        );
      });

      // --- SUKSES ---
      // Tutup Loading DULUAN sebelum lanjut
      if (Get.isDialogOpen ?? false) Get.back();

    } catch (e) {
      // --- ERROR ---
      
      // 1. TUTUP LOADING DULUAN (WAJIB DISINI)
      // Agar tidak bentrok dengan Snackbar
      if (Get.isDialogOpen ?? false) Get.back();

      // 2. Baru Tampilkan Pesan Error
      String pesanError = "Login failed.";
      
      // Deteksi error spesifik
      if (e.toString().contains("invalid-credential") || 
          e.toString().contains("wrong-password") ||
          e.toString().contains("user-not-found")) {
        pesanError = "Email atau Password salah.";
      } else if (e.toString().contains("network-request-failed")) {
        pesanError = "Koneksi bermasalah.";
      } else if (e.toString().contains("too-many-requests")) {
        pesanError = "Terlalu banyak percobaan. Tunggu sebentar.";
      }

      Get.snackbar(
        "Login Failed",
        pesanError,
        backgroundColor: Colors.red.shade900,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
    } 
    // Kita tidak pakai 'finally' lagi untuk tutup loading, 
    // karena sudah ditutup manual di blok 'try' dan blok 'catch'
    // agar urutannya benar.
  }

  // Widget Helper (TextField)
  Widget _buildAppleTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _fieldColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        cursorColor: _accentColor,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: _textSecondary),
          prefixIcon: Icon(icon, color: _textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.task_alt, size: 90, color: _accentColor),
              const SizedBox(height: 20),
              
              const Text(
                "SyncTask",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Manage your tasks efficiently",
                textAlign: TextAlign.center,
                style: TextStyle(color: _textSecondary, fontSize: 16),
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
                  onPressed: signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Sign In",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ", style: TextStyle(color: _textSecondary)),
                  GestureDetector(
                    onTap: () => Get.to(() => const Signup()),
                    child: Text(
                      "Sign up",
                      style: TextStyle(
                        color: _accentColor, 
                        fontWeight: FontWeight.w600
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),

              TextButton(
                onPressed: () => Get.to(() => const Forgot()),
                child: Text(
                  "Forgot Password?", 
                  style: TextStyle(color: _accentColor, fontWeight: FontWeight.w500)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}