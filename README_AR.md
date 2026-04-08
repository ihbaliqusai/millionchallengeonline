# Million Challenge Online - Flutter + Android Hybrid

هذا المشروع يحافظ على اللعبة الأصلية الموجودة داخل مجلد Android، ويضيف فوقها طور أونلاين كامل بواجهة Flutter حديثة مرتبطة بـ Firebase.

## الموجود في هذه النسخة
- تسجيل دخول بالبريد وكلمة المرور
- تسجيل دخول Google
- مزامنة اسم اللاعب مع الواجهة الأصلية عبر `MethodChannel`
- مطابقة سريعة أونلاين
- غرف خاصة بكود
- تحدي الأصدقاء ودعوات مباشرة
- ملف شخصي وإحصائيات وسجل مباريات
- لوحة صدارة مباشرة
- شاشة إعدادات حديثة داخل Flutter
- تصميم جديد أقرب لأسلوب ألعاب الموبايل الحديثة

## Firebase
- اسم الحزمة: `com.Qi7bali.millionchallengeonline`
- ملف Firebase موجود داخل:
  - `android/app/google-services.json`
- يجب تفعيل:
  - Email/Password
  - Google Sign-In
  - Cloud Firestore
- بعد أي تعديل على SHA-1 أو SHA-256 من Firebase يفضّل تنزيل `google-services.json` من جديد واستبداله.

## التشغيل
```bash
flutter clean
flutter pub get
flutter run
```

## نشر قواعد Firestore
```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

## ملاحظات مهمة
- القواعد الحالية مهيأة لتسهيل التطوير والاختبار. قبل النشر الإنتاجي الحقيقي يفضّل تشديد الصلاحيات ونقل إنهاء المباراة وتحديث الإحصائيات إلى Cloud Functions.
- إذا واجهت مشكلة في Google Sign-In فغالبًا السبب هو عدم إضافة SHA-1 و SHA-256 في Firebase لنفس الحزمة.
- هذه البيئة لم تكن تحتوي على Flutter SDK، لذلك لم أستطع تنفيذ build حقيقي هنا. تم تعديل الملفات والمشروع وتجهيزه قدر الإمكان، لكن يبقى التحقق النهائي عندك بتشغيل المشروع محليًا.
