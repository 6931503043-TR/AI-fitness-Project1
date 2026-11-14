# FORGE — Flutter + drift (เฟส 1: ฐานข้อมูลและแท็บ Plan)

โฟลเดอร์นี้มีเฉพาะ `lib/` และ `test/` ต้องสร้างโปรเจกต์ Flutter เปล่าก่อน แล้วคัดลอกทับ

## ขั้นตอนติดตั้ง

```bash
# 1) สร้างโปรเจกต์ (ชื่อต้องเป็น forge เพราะเทสต์ import package:forge/...)
flutter create forge --org com.yourname --platforms=android,ios
cd forge

# 2) ติดตั้งแพ็กเกจ (ได้เวอร์ชันล่าสุดที่เข้ากันโดยอัตโนมัติ)
flutter pub add flutter_riverpod drift drift_flutter path_provider uuid
flutter pub add camera google_mlkit_pose_detection google_mlkit_commons
flutter pub add --dev drift_dev build_runner

# 3) คัดลอกโฟลเดอร์ lib/ และ test/ จาก zip ทับของเดิม
#    แล้วลบไฟล์ test/widget_test.dart ที่ flutter สร้างให้ (อ้าง MyApp ซึ่งไม่มีแล้ว)

# 4) สร้างโค้ดของ drift (สร้างไฟล์ lib/data/db/app_database.g.dart)
dart run build_runner build --delete-conflicting-outputs

# 5) ตรวจสอบและรัน
flutter analyze
flutter test
flutter run
```

## โครงสร้าง

```
lib/
  core/theme.dart                 สี/ธีมที่พอร์ตมาจาก CSS ของ HTML เดิม
  domain/                         ตรรกะล้วน ไม่แตะ DB/UI (enums, tdee, recovery, streak)
  data/
    db/tables.dart                สคีมา 8 ตาราง
    db/app_database.dart          ตัว DB, migration, เปิด foreign key
    db/seed.dart                  คลังท่า + แผนตัวอย่าง
    repositories/                 exercise / routine / workout
    providers.dart                Riverpod providers
  ui/                             shell, แท็บ Plan (ใช้งานได้จริง), placeholder ของแท็บอื่น
test/
  domain_test.dart                TDEE, streak, recovery
  database_test.dart              seed, cascade, บันทึกเซต, lastPerformance ฯลฯ
```

## เมื่อแก้ตารางในอนาคต

1. แก้ `tables.dart`
2. เพิ่ม `schemaVersion` ใน `app_database.dart`
3. เขียนขั้นตอนใน `onUpgrade`
4. รัน `dart run build_runner build --delete-conflicting-outputs`

## แท็บ Work (กล้อง AI นับท่า) — ตั้งค่า Android ก่อนรัน

1. `android/app/src/main/AndroidManifest.xml` เพิ่มบรรทัดนี้ไว้ใต้ `<manifest ...>` (ก่อน `<application>`):
   `<uses-permission android:name="android.permission.CAMERA"/>`
2. `android/app/build.gradle` (หรือ `build.gradle.kts`) ตั้ง `minSdk` เป็น 24 แทน `flutter.minSdkVersion`
3. ต่อมือถือ (เปิด USB debugging) แล้ว `flutter run` หรือสร้างไฟล์ติดตั้ง: `flutter build apk --release`
   ไฟล์อยู่ที่ `build/app/outputs/flutter-apk/app-release.apk`

iOS (ทำทีหลัง ต้องใช้ Mac): เพิ่ม `NSCameraUsageDescription` ใน `ios/Runner/Info.plist`
และตั้ง `platform :ios, '15.5'` ใน `ios/Podfile`

แท็บ Work ไม่ทำงานบน Windows/เดสก์ท็อป (จะแสดงข้อความแจ้ง)
