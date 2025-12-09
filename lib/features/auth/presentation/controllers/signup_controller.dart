import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupController extends GetxController {
  // --- Controllers untuk Text Field ---
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // Warna untuk Loading/Snackbar (Disimpan disini atau di Constants terpisah)
  final Color _fieldColor = const Color(0xFF1C1C1E);
  final Color _accentColor = const Color(0xFF0A84FF);
  final Color _textSecondary = const Color(0xFF8E8E93);

  // --- MEMBERSIHKAN MEMORY ---
  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  // --- FUNGSI SIGN UP ---
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
      // 3. Buat User Baru di Firebase
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // 4. Kirim Email Verifikasi
      if (userCredential.user != null) {
        await userCredential.user!.sendEmailVerification();
      }

      // 5. Logout User (Agar tidak auto-login sebelum verifikasi)
      await FirebaseAuth.instance.signOut();

      // Tutup Loading
      if (Get.isDialogOpen ?? false) Get.back();

      // 6. Tampilkan Dialog Sukses
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
                Get.back(); // Kembali ke Halaman Login (Previous Page)
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
}