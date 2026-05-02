// Push notification service.
//
// Currently DISABLED until Firebase is configured.
// To enable:
// 1. Create Firebase project at https://console.firebase.google.com
// 2. Add iOS + Android apps
// 3. Place GoogleService-Info.plist in ios/Runner/
// 4. Place google-services.json in android/app/
// 5. Uncomment firebase packages in pubspec.yaml
// 6. Uncomment the implementation below

// ignore_for_file: unused_import

import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import '../providers/providers.dart';

class PushService {
  final Ref ref;
  PushService(this.ref);

  /// Call once after login to register the device token.
  Future<void> setup() async {
    // TODO: Uncomment after Firebase setup
    /*
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }

    final messaging = FirebaseMessaging.instance;

    // Request permission (iOS prompts, Android grants automatically pre-13)
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // For iOS, wait for APNS token first
    if (Platform.isIOS) {
      await messaging.getAPNSToken();
    }

    final token = await messaging.getToken();
    if (token == null) return;

    final platform = Platform.isIOS ? 'IOS' : 'ANDROID';
    await ref.read(notificationsRepositoryProvider).registerDevice(token, platform);

    // Refresh token if it changes
    messaging.onTokenRefresh.listen((newToken) {
      ref.read(notificationsRepositoryProvider).registerDevice(newToken, platform);
    });

    // Foreground messages -> show local snack bar / dialog (handled in UI)
    FirebaseMessaging.onMessage.listen((message) {
      // Could trigger a state update, show a snackbar, etc.
    });

    // Background tap -> handled by initial route or navigator
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      // Navigate based on message.data['type']
    });
    */
  }

  Future<void> teardown() async {
    // Called on logout - unregister token
    /*
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      // Could call DELETE /api/notifications/devices on backend
    }
    await FirebaseMessaging.instance.deleteToken();
    */
  }
}

final pushServiceProvider = Provider<PushService>((ref) => PushService(ref));
