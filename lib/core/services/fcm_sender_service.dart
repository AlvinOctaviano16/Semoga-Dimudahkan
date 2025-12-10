import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FcmSenderService {
  // DATA DARI FILE JSON ANDA (synctask-397fe-firebase-adminsdk...)
  final String _serviceAccountEmail = 'firebase-adminsdk-fbsvc@synctask-397fe.iam.gserviceaccount.com';
  final String _projectId = 'synctask-397fe';
  
  // Private Key dari JSON Anda
  final String _privateKey = '''-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDIhw7X6LwGmLyl
luny7zNXqA8Lsyr2HaVPPxmNjpvy8vw5CdpaJVZBGkggmDXozkYNOKqmAjptcnDn
xF6gXeLjDLkt3IAzU6jnoNjD1/wsYH1/eQ/fGGgIQseWX3QQhX3ljKrj6SVkl7CQ
dJSB1yKHQUzegfiG/+swG5nhMAHRxaJcDswVWlBZL1geAFWDTIDVuHBnNHe9EEwJ
lhGlZXRabKdmgf7382rJ3ZfBhhCmN2KA37nUcNMvnoQWVWSmlmB0G2vxXYBtfTtL
74JLSOcaN6kzps9S74/I4d/neICq6IeBiqHPnQIiDTxeJXNbPWZ1odh52WD43qwC
3Pu+wXQnAgMBAAECggEAW9+5NsX8Y79V6z4+GN5sNRScNB2WKOYDR9AeuoMkw0Z9
tfpkLtodbz2F310tkej0InmcgevSbjO5NA791da+LY22SCNXH20MnXdN6UjLUl+x
EBbc5Teu7l3+SNCaAjnPKT1uTHaU+cYgEMdBBU4WlUafW/DLd7rIPCXhNlHC+6MS
kF9+T66DRcKOyEkh+Bjf8crOnYF4O99vziUoQgre5zL9tNIP3Iuut6Qal4VEQPwI
LzoX47O+A7yviD4S3151VVArJMhrui0HjkoutcYtWhqeLjNNyKrnCqTde/6ZtLy+
3E1ZTeSb5Bj4llLlbFT9t18o4Z0EytE746tpY4ZKKQKBgQD+dpYZAgNBgqPvlCYb
xzsVg+vbhWWFGnOzj+JCMHK0wH+bawm02xAysDSsPvsddRCoA3caT96TAiny7sOi
cOW72ICteF3WlFIo2PVSl1nD2yK64PysYuq+4JbjJvgr7EsKifJO6UIJUKhpApEw
EeC7Kg18bZObn88vGoUu1/zZHwKBgQDJvRWSnLAfhmYydwUJIZ/dG5PA7Y5khAPx
oQco0X2Ot8434zUZsaMJ9uBHv+Dr/E05rPNQy+5ewWonmxJfpuWlbIrCLom9HryS
SVtHNpAsBXXbvhKiExel03yK3ZCl0EXFBLBZP95VyBJynxhZ2jhpqRdyJP1cr8FA
3qWFZ5Qb+QKBgDAClc1AGPcqO93++LWzAE3N5xky8PWNCRlu40STuYCq9SiQqHMs
BcFah4WcGGr1ZGAez0Dyos7f0KRaMiUa4e1wKs8P77yFnX7BeH/NuI0AcmwJ+QJZ
Y2sCGtXey2IWIg5p+oKy9demFTBC4LvOE7WceJDqZ7gsDb4YZdpxu+4HAoGBAKe0
oYdk7GD4qGKRYMVLh4sWzsiWc0YKHQE0nTAInvkSwcLiBZWbf27cJWxgDYoADu7A
YPEs5rcs0KOmHSsZIlVXmy5745MtRxPRGalkqYt+6pBHPVQwzPrUifci44mET0vO
bw9ysdDb5sIUkfi4GSd1IwGH0HvJu7zCmhUBmzV5AoGBAP1j5Ph2V/Ojb2z1tc7U
9+8MCE5N4PwsyMjgtAImHpkcr9/qkn0D4MiOvEMqgiSB7bFYFX7qYnbuwu5YNiIL
0WBEK3F89vXN6o3ErzdYXcy26JnGdMCJ/JgnI/B4JoiMMPLh5cqV0YCu2dOZAb+h
f5jmKfflPGKfoTu6sBzC5Hij
-----END PRIVATE KEY-----'''; 

  Future<String> _getAccessToken() async {
    final accountCredentials = auth.ServiceAccountCredentials.fromJson({
      "private_key": _privateKey,
      "client_email": _serviceAccountEmail,
      "client_id": "107581548175199707532", // Client ID dari JSON
      "type": "service_account"
    });

    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    final client = await auth.clientViaServiceAccount(accountCredentials, scopes);
    return client.credentials.accessToken.data;
  }

  Future<void> sendNotification({
    required String targetToken,
    required String title,
    required String body,
  }) async {
    try {
      final String accessToken = await _getAccessToken();
      
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/$_projectId/messages:send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          "message": {
            "token": targetToken,
            "notification": {
              "title": title,
              "body": body,
            },
            "data": {
              "click_action": "FLUTTER_NOTIFICATION_CLICK",
              "sound": "default",
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Notifikasi berhasil dikirim ke target!");
      } else {
        print("❌ Gagal kirim notif: ${response.body}");
      }
    } catch (e) {
      print("Error sending FCM: $e");
    }
  }
}

final fcmSenderProvider = Provider((ref) => FcmSenderService());