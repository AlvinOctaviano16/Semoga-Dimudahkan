import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';
import '../../../core/constants/app_colors.dart';

final authControllerProvider = NotifierProvider<AuthController, bool>(() {
  return AuthController();
});

class AuthController extends Notifier<bool> {
  @override
  bool build() => false; 

  Future<void> login(String email, String password) async {
    state = true;
    try {
      await ref.read(authRepositoryProvider).signIn(email, password);
    } catch (e) {
      Get.snackbar("Login Failed", e.toString(), 
        backgroundColor: AppColors.error, colorText: Colors.white);
    } finally {
      state = false;
    }
  }

  Future<void> signUp(String name, String email, String password, String confirmPass) async {
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      Get.snackbar("Error", "All fields are required", backgroundColor: AppColors.surface, colorText: Colors.white);
      return;
    }
    if (password != confirmPass) {
      Get.snackbar("Error", "Passwords do not match", backgroundColor: AppColors.error, colorText: Colors.white);
      return;
    }

    state = true;
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signUp(email, password, name);
      await repo.signOut(); // Logout ulang
      
      Get.defaultDialog(
        title: "Email Verification",
        middleText: "A verification link has been sent to $email.\nPlease check your inbox/spam and Login.",
        backgroundColor: AppColors.surface,
        titleStyle: const TextStyle(color: Colors.white),
        middleTextStyle: const TextStyle(color: AppColors.textSecondary),
        textConfirm: "OK",
        confirmTextColor: Colors.white,
        buttonColor: AppColors.primary,
        onConfirm: () {
          Get.back(); // Tutup Dialog
          Get.back(); // Kembali ke Login
        }
      );

    } catch (e) {
      Get.snackbar("Registration Failed", e.toString(), backgroundColor: AppColors.error, colorText: Colors.white);
    } finally {
      state = false;
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).signOut();
  }

  Future<void> forgotPassword(String email) async {
    if (email.isEmpty) {
      Get.snackbar("Error", "Please enter your email", 
        backgroundColor: AppColors.surface, colorText: Colors.white);
      return;
    }

    state = true;
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      Get.snackbar("Email Sent", "Check your inbox to reset password", 
        backgroundColor: Colors.green, colorText: Colors.white);
      Get.back();
    } catch (e) {
      Get.snackbar("Failed", e.toString(), 
        backgroundColor: AppColors.error, colorText: Colors.white);
    } finally {
      state = false;
    }
  }

  Future<void> updateProfile({
    required String newName,
    required String email, 
    String? newEmail,      
    String? oldPassword,
    String? newPassword,
  }) async {
    state = true; 
    try {
      final repo = ref.read(authRepositoryProvider);

      bool isEmailChanged = (newEmail != null && newEmail.isNotEmpty && newEmail != email);
      bool isPassChanged = (newPassword != null && newPassword.isNotEmpty);

      if (isEmailChanged || isPassChanged) {
        if (oldPassword == null || oldPassword.isEmpty) {
          Get.snackbar("Attention", "Please enter your Current Password to save changes.", 
            backgroundColor: Colors.orange, colorText: Colors.white, duration: const Duration(seconds: 4));
          state = false;
          return;
        }
        await repo.reauthenticate(email, oldPassword);
      }

      // Update Nama
      if (newName.isNotEmpty) {
        await repo.updateProfile(name: newName.trim());
      }

      // Update Password
      if (isPassChanged) {
        await repo.updatePassword(newPassword!); 
      }

      // Update Email
      if (isEmailChanged) {
         await repo.updateEmail(newEmail!); 
         Get.snackbar("Check Email", "Verification link sent to $newEmail. Click the link to update profile.", 
            backgroundColor: Colors.blue, colorText: Colors.white, duration: const Duration(seconds: 6));
      } else {
         Get.snackbar("Success", "Profile updated successfully!", 
            backgroundColor: Colors.green, colorText: Colors.white);
      }
        
    } on FirebaseAuthException catch (e) {
      // Handle error spesifik Firebase (Bahasa Inggris)
      String pesanError = "An error occurred: ${e.message}";

      if (e.code == 'email-already-in-use') {
        pesanError = "Failed: The email '${newEmail ?? 'provided'}' is already in use.";
      } else if (e.code == 'wrong-password') {
        pesanError = "Incorrect Current Password.";
      } else if (e.code == 'weak-password') {
        pesanError = "New Password is too weak (min. 6 characters).";
      } else if (e.code == 'invalid-email') {
        pesanError = "Invalid email format.";
      } else if (e.code == 'requires-recent-login') {
        pesanError = "Session expired. Please Logout and Login again.";
      }

      Get.snackbar("Save Failed", pesanError, 
        backgroundColor: AppColors.error, colorText: Colors.white, duration: const Duration(seconds: 4));
        
    } catch (e) {
      Get.snackbar("Error", e.toString(), 
        backgroundColor: AppColors.error, colorText: Colors.white);
    } finally {
      state = false; 
    }
  }
}