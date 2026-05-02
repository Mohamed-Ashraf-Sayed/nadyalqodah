# Qodah - نادي القضاة

أبلكيشن موبايل لنادي القضاة - دليل الأعضاء (المستشارين) مع نظام موافقة من الأدمن، بحث وفلترة، أخبار النادي، إشعارات Push، وتصدير PDF.

## البنية

```
qodah/
├── backend/    # Node.js + Express + Prisma + PostgreSQL
└── mobile/     # Flutter (iOS + Android)
```

## التشغيل السريع

### الباك إند

```bash
cd backend
cp .env.example .env
# اضبط DATABASE_URL والـ JWT secrets

npm install
npx prisma migrate dev --name init
npm run seed   # ينشئ admin@qodah.local / Admin@12345
npm run dev
# السيرفر شغّال على http://localhost:4000
```

### الموبايل

```bash
cd mobile
flutter pub get
flutter run    # على Android Emulator يستخدم http://10.0.2.2:4000 افتراضيًا

# لو على iOS Simulator أو جهاز فعلي:
flutter run --dart-define=API_BASE_URL=http://YOUR-HOST-IP:4000
```

## Stack

- **Backend:** Node.js, Express, Prisma, PostgreSQL, JWT, Multer, PDFKit, Firebase Admin (FCM)
- **Mobile:** Flutter, Riverpod, go_router, Dio, secure_storage, firebase_messaging

## الفيتشرز

- تسجيل عضو جديد بموافقة الأدمن
- دليل أعضاء بالبحث والفلترة (المحافظة، الدرجة الوظيفية، التخصص)
- بطاقة عضو فيها كل البيانات + اتصال/واتساب/إيميل
- تعديل البروفايل ورفع صورة
- أخبار وإعلانات النادي
- إشعارات داخل الأبلكيشن + Push (FCM)
- تصدير الدليل أو بطاقة عضو PDF
- لوحة إدارة جوا الأبلكيشن (موافقة على الطلبات، إدارة الأعضاء، نشر أخبار، إشعار جماعي)

## Auth

JWT access token (15 دقيقة) + refresh token (30 يوم).

## التحقق E2E

1. شغّل الباك إند والموبايل
2. سجّل عضو جديد من الأبلكيشن - هتلاقي الحساب في حالة PENDING
3. سجّل دخول بالأدمن (admin@qodah.local) - هتشوف الطلب في تبويب الإدارة
4. وافق على الطلب - العضو يقدر يدخل الدليل ويبحث
5. اضغط على عضو واتصل/واتس/PDF
6. الأدمن ينشر خبر مع تفعيل "إشعار لكل الأعضاء"
# nadyalqodah
