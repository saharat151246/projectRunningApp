# ตั้งค่า Google Sign-In ให้ครบ (ฝั่ง Flutter)

โค้ด Dart ทำเสร็จแล้ว (`auth_service.dart`, `login_screen.dart`, `register_screen.dart`)
แต่ Google Sign-In ต้องผูก Client ID กับแพลตฟอร์มเพิ่ม ทำตามนี้ให้ครบก่อนรันจริง:

## 1. สร้าง OAuth Client ใน Google Cloud Console
ไปที่ [console.cloud.google.com/apis/credentials](https://console.cloud.google.com/apis/credentials)
แล้วสร้าง OAuth Client ID **3 ตัว** (ใช้โปรเจกต์เดียวกัน):

| ชนิด | ใช้ที่ไหน |
|---|---|
| **Web application** | ใส่ใน backend `.env` -> `GOOGLE_CLIENT_ID` (ทำไว้แล้วในรอบก่อน) |
| **Android** | ต้องใช้ package name `com.example.running_app` + SHA-1 fingerprint |
| **iOS** | ต้องใช้ Bundle ID จาก `ios/Runner.xcodeproj` |

### หา SHA-1 สำหรับ Android (debug):
```bash
cd android
./gradlew signingReport
```
เอาค่า SHA1 ใต้ `Variant: debug` ไปใส่ตอนสร้าง Android OAuth Client
(ตอน build จริงขึ้น Play Store ต้องเพิ่ม SHA-1 ของ release keystore อีกตัวด้วย)

## 2. Android — ไม่ต้องแก้ไฟล์เพิ่ม
`google_sign_in` บน Android ใช้ SHA-1 + package name ที่ผูกไว้ใน Google Cloud Console โดยตรง ไม่ต้องแก้ `AndroidManifest.xml` เพิ่ม (permission `INTERNET` เพิ่มให้แล้ว)

## 3. iOS — ต้องแก้ `ios/Runner/Info.plist`
เพิ่ม URL scheme ที่เป็น **REVERSED_CLIENT_ID** ของ iOS OAuth Client (หน้าตาแบบ `com.googleusercontent.apps.xxxxxxx`):

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_IOS_CLIENT_ID_REVERSED</string>
    </array>
  </dict>
</array>
```
ค่านี้ดาวน์โหลดได้จากไฟล์ `GoogleService-Info.plist` (ถ้าใช้ Firebase) หรือคัดลอกจากหน้า Credentials ใน Cloud Console โดยกลับลำดับของ Client ID

## 4. ติดตั้ง package
```bash
flutter pub get
```

## 5. ทดสอบ
1. รัน backend ให้พร้อม (`GOOGLE_CLIENT_ID` ใน `.env` ต้องเป็นตัว **Web application**)
2. รันแอป กดปุ่ม "เข้าสู่ระบบด้วย Google"
3. ถ้าขึ้นหน้าเลือกบัญชี Google ได้ = ผูก config ถูกแล้ว ที่เหลือ backend จะ verify token ให้เอง

---
ถ้าติดขั้นตอนไหน ส่ง error message มาดูได้เลย
