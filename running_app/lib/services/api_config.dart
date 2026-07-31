import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// ตั้งค่า Base URL ของ Backend API
///
/// สำคัญ: ที่อยู่ "localhost" มีความหมายต่างกันไปตามที่รันแอป
/// - Android Emulator: ต้องใช้ 10.0.2.2 (ชี้กลับไปที่เครื่อง host)
/// - iOS Simulator: ใช้ localhost ได้ตรงๆ
/// - Web (Chrome): ใช้ localhost ได้ตรงๆ
/// - อุปกรณ์จริง (มือถือจริงต่อ USB/WiFi): ต้องใช้ IP ของเครื่องคอมพิวเตอร์ในวง LAN
///   เช่น 192.168.1.xx (เช็คได้จาก `ipconfig` บน Windows) แล้วต้องอยู่วง WiFi เดียวกัน
class ApiConfig {
  static String get baseUrl {
    const port = 5000;
    if (kIsWeb) {
      return 'http://localhost:$port/api';
    }
    if (Platform.isAndroid) {
      // TODO: ถ้าทดสอบบนมือถือจริง ให้เปลี่ยนเป็น IP เครื่องคอมพิวเตอร์ในวง LAN แทน
      return 'http://10.84.88.60:$port/api';
    }
    // iOS Simulator และแพลตฟอร์มอื่นๆ
    return 'http://localhost:$port/api';
  }
}
