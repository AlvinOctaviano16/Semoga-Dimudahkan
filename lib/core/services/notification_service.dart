import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. BACKGROUND HANDLER (Wajib di luar class & top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Disini kita bisa handle notifikasi saat app mati total
  // Tapi biasanya Firebase sudah otomatis menampilkannya di tray system
  print("Handling a background message: ${message.messageId}");
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Inisialisasi Service
  Future<void> initialize() async {
    // A. Request Permission (Wajib untuk Android 13+ & iOS)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      print('User declined or has not accepted permission');
      return;
    }

    // B. Setup Local Notification (Untuk menampilkan notif saat App sedang DIBUKA/Foreground)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Pastikan icon ini ada

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle jika notifikasi diklik saat app terbuka
        print("Notification Tapped: ${response.payload}");
        // Nanti kita bisa pasang navigasi ke Chat/Task di sini
      },
    );

    // C. Setup Listener Firebase
    // 1. Saat App di Foreground (Layar nyala) -> Tampilkan Local Notif
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    // 2. Setup Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Fungsi Menampilkan Notifikasi Lokal
  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel', // ID Channel (Harus sama dengan manifest)
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: message.data.toString(), // Kirim data jika diklik
      );
    }
  }

  // Ambil Token FCM (Untuk dikirim ke server/teman agar bisa ditarget)
  Future<String?> getToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      print("🔥 FCM TOKEN (Simpan ini untuk test): $token");
      return token;
    } catch (e) {
      print("Error getting FCM Token: $e");
      return null;
    }
  }
}

// Provider Global
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});