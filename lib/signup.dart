import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
// import 'package:sync_task_app/wrapper.dart'; // Wrapper tidak dipakai disini lagi

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  // Controller
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // Warna Tema
  final Color _backgroundColor = const Color(0xFF000000);
  final Color _fieldColor = const Color(0xFF1C1C1E);
  final Color _accentColor = const Color(0xFF0A84FF);
  final Color _textSecondary = const Color(0xFF8E8E93);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // --- FUNGSI SIGN UP DENGAN VERIFIKASI ---
  Future<void> signUp() async {
    FocusManager.instance.primaryFocus?.unfocus();

    // 1. Validasi Input
    if (emailController.text.trim().isEmpty || 
        passwordController.text.trim().isEmpty ||
        confirmPasswordController.text.trim().isEmpty) {
      Get.snackbar("Error", "Semua kolom harus diisi.", 
        backgroundColor: const Color(0xFF333333), colorText: Colors.white);
      return;
    }

    if (passwordController.text.trim() != confirmPasswordController.text.trim()) {
      Get.snackbar("Error", "Password tidak sama!", 
        backgroundColor: Colors.red.shade900, colorText: Colors.white);
      return;
    }

    if (passwordController.text.trim().length < 6) {
      Get.snackbar("Weak Password", "Password minimal 6 karakter.", 
        backgroundColor: Colors.orange.shade900, colorText: Colors.white);
      return;
    }

    // 2. Tampilkan Loading
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
      // 3. Buat User Baru
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // 4. KIRIM EMAIL VERIFIKASI
      if (userCredential.user != null) {
        await userCredential.user!.sendEmailVerification();
      }

      // 5. Logout User (Penting!)
      // Kita logout agar mereka tidak masuk ke Home sebelum verifikasi
      await FirebaseAuth.instance.signOut();

      // Tutup Loading (Dialog Create User)
      if (Get.isDialogOpen ?? false) Get.back();

      // 6. Tampilkan Dialog Sukses & Instruksi
      await Get.dialog(
        AlertDialog(
          backgroundColor: _fieldColor,
          title: const Text("Verify Your Email", style: TextStyle(color: Colors.white)),
          content: Text(
            "Link verifikasi telah dikirim ke ${emailController.text}.\n\nSilakan cek inbox/spam Anda, verifikasi akun, lalu Login kembali.",
            style: TextStyle(color: _textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back(); // Tutup Dialog
                Get.back(); // Kembali ke Halaman Login
              },
              child: Text("OK, I Understand", style: TextStyle(color: _accentColor)),
            ),
          ],
        ),
        barrierDismissible: false,
      );

    } catch (e) {
      // Tutup Loading jika error
      if (Get.isDialogOpen ?? false) Get.back();

      String pesan = "Gagal mendaftar.";
      if (e.toString().contains("email-already-in-use")) {
        pesan = "Email sudah terdaftar. Silakan Login.";
      } else if (e.toString().contains("weak-password")) {
        pesan = "Password terlalu lemah.";
      } else if (e.toString().contains("invalid-email")) {
        pesan = "Format email salah.";
      }

      Get.snackbar(
        "Registration Failed", 
        pesan,
        backgroundColor: Colors.red.shade900,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  // Widget Helper Input (Sama seperti sebelumnya)
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
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Create Account",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Join SyncTask and start organizing",
                textAlign: TextAlign.center,
                style: TextStyle(color: _textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 40),

              _buildAppleTextField(
                controller: emailController, 
                hint: "Email Address", 
                icon: Icons.mail_outline
              ),
              const SizedBox(height: 16),
              _buildAppleTextField(
                controller: passwordController, 
                hint: "Password", 
                icon: Icons.lock_outline,
                isPassword: true
              ),
              const SizedBox(height: 16),
              _buildAppleTextField(
                controller: confirmPasswordController, 
                hint: "Confirm Password", 
                icon: Icons.lock_reset,
                isPassword: true
              ),

              const SizedBox(height: 30),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Sign Up",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account? ", style: TextStyle(color: _textSecondary)),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Text(
                      "Sign In",
                      style: TextStyle(
                        color: _accentColor, 
                        fontWeight: FontWeight.w600
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}