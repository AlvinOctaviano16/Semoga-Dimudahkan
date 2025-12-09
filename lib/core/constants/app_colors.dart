import 'package:flutter/material.dart';

class AppColors {
  // Private constructor agar class ini tidak bisa di-instantiate
  AppColors._();

  // Background Utama (Hitam Pekat)
  static const Color background = Color(0xFF000000);
  
  // Warna Komponen/Card (Abu-abu Gelap)
  // Digunakan untuk TextField, Card, BottomSheet
  static const Color surface = Color(0xFF1C1C1E);
  
  // Warna Utama (iOS Blue)
  // Digunakan untuk Tombol, Link, Icon Aktif
  static const Color primary = Color(0xFF0A84FF);
  
  // Warna Teks
  static const Color textPrimary = Colors.white;       // Judul Utama
  static const Color textSecondary = Color(0xFF8E8E93); // Subtitle/Hint
  
  // Warna Status
  static const Color error = Color(0xFFFF453A); // iOS Red
  static const Color success = Color(0xFF30D158); // iOS Green
}