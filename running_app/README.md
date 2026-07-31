# RunMate — Running App (UI/UX Prototype)

โปรเจคนี้เป็น**เฟสที่ 1: UI/UX เท่านั้น** ยังไม่มีการเชื่อมต่อ Backend/MongoDB/GPS จริง
ทุกหน้าจอใช้ mock data เพื่อให้เห็นภาพรวมของแอปทั้งหมดก่อน

## วิธีรัน

```bash
flutter pub get
flutter run
```

รองรับทั้ง iOS Simulator และ Android Emulator (ต้องมี Flutter SDK ติดตั้งในเครื่องคุณ)

## หน้าจอที่มีอยู่ตอนนี้

| หน้าจอ | ไฟล์ | สถานะ |
|---|---|---|
| Splash | `lib/screens/splash_screen.dart` | ✅ UI |
| Onboarding (3 สไลด์) | `lib/screens/onboarding_screen.dart` | ✅ UI |
| Login (Email + Google button) | `lib/screens/auth/login_screen.dart` | ✅ UI (mock, ยังไม่ auth จริง) |
| Register (Email + Google button) | `lib/screens/auth/register_screen.dart` | ✅ UI (mock) |
| Home (สรุปภาพรวม + AI tip) | `lib/screens/home/home_screen.dart` | ✅ UI + mock data |
| Tracking (จับเวลาวิ่ง) | `lib/screens/tracking/tracking_screen.dart` | ✅ UI, นาฬิกาทำงานจริง, GPS ยังเป็น mock |
| Dashboard (กราฟ+ประวัติ) | `lib/screens/dashboard/dashboard_screen.dart` | ✅ UI + mock data |
| Gamification (เหรียญ/ภารกิจ) | `lib/screens/gamification/gamification_screen.dart` | ✅ UI + mock data |
| Profile | `lib/screens/profile/profile_screen.dart` | ✅ UI |

## โครงสร้างโปรเจค

```
lib/
├── main.dart
├── theme/app_theme.dart          # สี, ฟอนต์, ธีมรวม
├── mock_data/mock_data.dart      # ข้อมูลจำลองทั้งหมด (จะถูกแทนด้วย API จริง)
├── widgets/                      # ปุ่ม, การ์ด ที่ใช้ซ้ำ
└── screens/                      # หน้าจอทั้งหมดตาม module
```

## ขั้นตอนถัดไป (ยังไม่ทำในเฟสนี้)

1. เชื่อม Node.js backend + MongoDB (Auth, Runs, Missions)
2. เชื่อม GPS จริงด้วย `geolocator` + แสดงแผนที่ด้วย `google_maps_flutter`
3. เชื่อม Firebase Auth + Google Sign-In จริง
4. ทำ AI Coach logic (rule-based ก่อน)
5. เชื่อม Gamification ให้ผูกกับข้อมูลจริง

> Dependencies สำหรับขั้นตอนถัดไปถูก comment ไว้ล่วงหน้าใน `pubspec.yaml` แล้ว
