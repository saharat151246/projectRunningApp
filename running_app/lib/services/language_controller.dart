import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// จัดการภาษาหลักของแอป (ไทย / อังกฤษ)
/// บันทึกค่าลง SharedPreferences และแจ้งเตือนให้ทั้งแอป rebuild ทันทีเมื่อเปลี่ยนภาษา
class LanguageController extends ChangeNotifier {
  LanguageController._();
  static final LanguageController instance = LanguageController._();

  static const _prefKey = 'pref_app_language';
  String _code = 'th';
  int rebuildToken = 0;

  String get code => _code;
  bool get isThai => _code == 'th';
  bool get isEnglish => _code == 'en';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    _code = prefs.getString(_prefKey) ?? 'th';
  }

  /// สลับภาษาระหว่าง th และ en
  Future<void> toggleLanguage() async {
    final next = _code == 'th' ? 'en' : 'th';
    await setLanguage(next);
  }

  Future<void> setLanguage(String langCode) async {
    if (_code == langCode) return;
    _code = langCode;
    rebuildToken++;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _code);
  }

  /// คืนค่าข้อความตามภาษาปัจจุบัน
  String text(String th, String en) {
    return _code == 'th' ? th : en;
  }

  // หน่วยวัดทั่วไป
  String get km => isThai ? 'กม.' : 'km';
  String get perKm => isThai ? '/กม.' : '/km';
  String get kcal => isThai ? 'แคลอรี่' : 'kcal';
  String get runs => isThai ? 'ครั้ง' : 'runs';
  String get days => isThai ? 'วัน' : 'days';
  String get pts => isThai ? 'แต้ม' : 'pts';

  /// แปลงวันที่ตามภาษา
  String formatDate(DateTime d) {
    if (isThai) {
      const months = [
        'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
        'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
      ];
      final buddhistYear = d.year + 543;
      return '${d.day} ${months[d.month - 1]} $buddhistYear';
    } else {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    }
  }

  /// แปลงวันในสัปดาห์
  String weekdayLabel(int weekday) {
    if (isThai) {
      const labels = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];
      return labels[(weekday - 1) % 7];
    } else {
      const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
      return labels[(weekday - 1) % 7];
    }
  }
}

/// Helper สั้นๆ ให้เรียกง่ายใน UI
String tr(String th, String en) => LanguageController.instance.text(th, en);
