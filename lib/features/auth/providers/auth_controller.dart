import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import '../repositories/auth_repository.dart';
import '../../../core/constants/app_colors.dart';

// Provider Logic Utama
final authControllerProvider = NotifierProvider<AuthController, bool>(() {
  return AuthController();
});

class AuthController extends Notifier<bool> {
  @override
  bool build() => false; // false = tidak loading

  // --- LOGIN LOGIC ---
  Future<void> login(String email, String password) async {
    state = true; // Loading Start
    try {
      await ref.read(authRepositoryProvider).signIn(email, password);
      // Sukses? AuthWrapper akan otomatis mengarahkan ke Dashboard
    } catch (e) {
      Get.snackbar("Login Gagal", e.toString(), 
        backgroundColor: AppColors.error, colorText: Colors.white);
    } finally {
      state = false; // Loading Stop
    }
  }

  // --- SIGN UP LOGIC (Pindahan dari SignupController) ---
  Future<void> signUp(String name, String email, String password, String confirmPass) async {
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      Get.snackbar("Error", "Semua kolom harus diisi", backgroundColor: AppColors.surface, colorText: Colors.white);
      return;
    }
    if (password != confirmPass) {
      Get.snackbar("Error", "Password tidak sama", backgroundColor: AppColors.error, colorText: Colors.white);
      return;
    }

    state = true;
    try {
      final repo = ref.read(authRepositoryProvider);
      // Panggil repo untuk create user & simpan ke firestore
      await repo.signUp(email, password, name);

      // Logout agar user login ulang setelah verifikasi
      await repo.signOut();
      
      // Tampilkan Dialog Sukses
      Get.defaultDialog(
        title: "Verifikasi Email",
        middleText: "Link verifikasi telah dikirim ke $email.\nSilakan cek inbox/spam Anda lalu Login.",
        backgroundColor: AppColors.surface,
        titleStyle: const TextStyle(color: Colors.white),
        middleTextStyle: const TextStyle(color: AppColors.textSecondary),
        textConfirm: "OK, Siap",
        confirmTextColor: Colors.white,
        buttonColor: AppColors.primary,
        onConfirm: () {
          Get.back(); // Tutup Dialog
          Get.back(); // Kembali ke Login Screen
        }
      );

    } catch (e) {
      Get.snackbar("Register Gagal", e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
    } finally {
      state = false;
    }
  }

  // --- LOGOUT ---
  Future<void> logout() async {
    await ref.read(authRepositoryProvider).signOut();
  }

  // --- FORGOT PASSWORD ---
  Future<void> forgotPassword(String email) async {
    if (email.isEmpty) {
      Get.snackbar("Error", "Please enter your email", 
        backgroundColor: AppColors.surface, colorText: Colors.white);
      return;
    }

    state = true; // Loading Start
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      
      // Tampilkan Sukses & Tutup Halaman
      Get.snackbar("Email Sent", "Check your inbox to reset password", 
        backgroundColor: Colors.green, colorText: Colors.white);
      Get.back(); // Kembali ke Login Screen otomatis
      
    } catch (e) {
      Get.snackbar("Failed", e.toString(), 
        backgroundColor: AppColors.error, colorText: Colors.white);
    } finally {
      state = false; // Loading Stop
    }
  }
}