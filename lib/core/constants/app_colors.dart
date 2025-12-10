import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryBlue=Color(0xFF1E88E5);

  static const Color primaryText = Color(0xFF1F2A37); // Teks gelap untuk Light Mode
  static const Color secondaryText = Color(0xFF6B7280); // Teks abu-abu sekunder

  // Warna Background & Divider
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFF9FAFB); 
  static const Color dividerColor = Color(0xFFE5E7EB);

  // Warna Status/Prioritas (Sesuai Mockup)
  static const Color highPriority = Color(0xFFE53935);   // Merah
  static const Color mediumPriority = Color(0xFFFFB300); // Kuning/Jingga
  static const Color lowPriority = Color(0xFF9C27B0);    // Ungu
  static const Color completedGreen = Color(0xFF4CAF50);
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