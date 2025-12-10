import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import '../../data/auth_repository.dart';

// GAYA BARU (Riverpod 3.0): Pakai 'NotifierProvider'
final authControllerProvider = NotifierProvider<AuthController, bool>(() {
  return AuthController();
});

// Class turunan dari 'Notifier<T>' (Bukan StateNotifier lagi)
class AuthController extends Notifier<bool> {
  
  // 1. Initial State ditentukan disini
  @override
  bool build() {
    return false; // false = tidak loading
  }

  // 2. Fungsi Login
  Future<void> login(String email, String password) async {
    state = true; // Loading mulai
    try {
      // Di Riverpod 3.0, kita akses repo pakai 'ref.read' langsung disini
      final repo = ref.read(authRepositoryProvider);
      await repo.signIn(email, password);
      // Sukses? Wrapper nanti otomatis redirect
    } catch (e) {
      Get.snackbar("Login Gagal", e.toString(), 
        backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      state = false; // Loading selesai
    }
  }

  // 3. Fungsi Forgot Password
  Future<void> forgotPassword(String email) async {
    state = true;
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.sendPasswordReset(email);
      Get.snackbar("Sukses", "Cek email Anda untuk reset password!", 
        backgroundColor: Colors.green, colorText: Colors.white);
      Get.back();
    } catch (e) {
      Get.snackbar("Gagal", e.toString(), 
        backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      state = false;
    }
  }

  // 4. Fungsi Logout
  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.signOut();
  }
}