# Qodah Mobile (Flutter)

أبلكيشن نادي القضاة - دليل الأعضاء.

## المتطلبات

- Flutter 3.19+
- Dart 3.3+
- Xcode (للـ iOS) / Android Studio

## التشغيل

```bash
flutter pub get

# مع الإيموليتر Android (الباك إند على localhost:4000):
flutter run

# مع الـ iOS Simulator:
flutter run -d ios --dart-define=API_BASE_URL=http://localhost:4000

# مع جهاز فعلي (استخدم IP الجهاز الـ host):
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:4000
```

> Android Emulator بيشوف الـ host machine على `10.0.2.2` (هو الـ default).

## البناء

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://api.qodah.example.com
flutter build ipa --release --dart-define=API_BASE_URL=https://api.qodah.example.com
```

## بنية الكود

- `lib/core` - الإعدادات والـ networking والـ theme والـ routing
- `lib/data` - الموديلز، الـ repositories، providers
- `lib/features` - شاشات كل feature (auth, directory, profile, news, notifications, admin)
- `lib/shared/widgets` - widgets مشتركة

## State Management

Riverpod للـ state. Repositories بترجع بيانات من API عبر Dio + interceptors تتعامل مع الـ JWT.

## Firebase / Push (اختياري للبداية)

عشان push notifications تشتغل لازم:
1. أضف `google-services.json` في `android/app/`
2. أضف `GoogleService-Info.plist` في `ios/Runner/`
3. شغّل `flutter pub get` بعد ضبط `firebase_core`

في الباك إند، حدد `FIREBASE_SERVICE_ACCOUNT` على path للـ service account JSON.
