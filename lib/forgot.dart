import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class Forgot extends StatefulWidget {
  const Forgot({super.key});

  @override
  State<Forgot> createState() => _ForgotState();
}

class _ForgotState extends State<Forgot> {
  final TextEditingController emailController = TextEditingController();

  final Color _backgroundColor = const Color(0xFF000000);
  final Color _fieldColor = const Color(0xFF1C1C1E);
  final Color _accentColor = const Color(0xFF0A84FF);
  final Color _textSecondary = const Color(0xFF8E8E93);

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> reset() async {
    // 1. Validasi Inputko
    if (emailController.text.trim().isEmpty) {
      Get.snackbar(
        "Error", 
        "Masukkan email terlebih dahulu!",
        backgroundColor: const Color(0xFF333333),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    // 2. Loading Modern
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _fieldColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const CircularProgressIndicator(color: Colors.white),
        ),
      )
    );

    try {
      // 3. Kirim Reset Password
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim()
      );

      // Tutup Loading
      if (Get.isDialogOpen ?? false) Get.back();

      // 4. Pesan Sukses
      Get.snackbar(
        "Email Sent", 
        "Link reset password telah dikirim. Cek Inbox atau Spam Anda.",
        backgroundColor: Colors.green.shade800,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
      );

      // Opsional: Kembali ke Login setelah sukses
      // Get.back(); 

    } on FirebaseAuthException catch (e) {
      // Tutup Loading
      if (Get.isDialogOpen ?? false) Get.back();

      String pesan = e.message ?? "Terjadi kesalahan.";
      if (e.code == 'user-not-found') {
        pesan = "Email tidak terdaftar.";
      } else if (e.code == 'invalid-email') {
        pesan = "Format email salah.";
      }

      Get.snackbar(
        "Failed", 
        pesan,
        backgroundColor: Colors.red.shade900,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.error_outline, color: Colors.white),
      );
    }
  }

  // Widget Helper (Sama dengan halaman lain)
  Widget _buildAppleTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _fieldColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        cursorColor: _accentColor,
        keyboardType: TextInputType.emailAddress,
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
        iconTheme: const IconThemeData(color: Colors.white), // Tombol back putih
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ikon Kunci Besar
              Icon(Icons.lock_reset, size: 80, color: _accentColor),
              
              const SizedBox(height: 20),
              
              const Text(
                "Reset Password",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              
              const SizedBox(height: 10),
              
              Text(
                "Enter your email address and we'll send you a link to reset your password.",
                textAlign: TextAlign.center,
                style: TextStyle(color: _textSecondary, fontSize: 16, height: 1.5),
              ),
              
              const SizedBox(height: 40),

              // Input Email Gaya Apple
              _buildAppleTextField(
                controller: emailController, 
                hint: "Email Address", 
                icon: Icons.mail_outline
              ),
              
              const SizedBox(height: 30),

              // Tombol Send Link
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: reset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Send Reset Link",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Tombol Cancel / Back (Opsional jika ingin tombol text di bawah)
              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  "Cancel", 
                  style: TextStyle(color: _textSecondary, fontSize: 16)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}