/// ตั้งค่า Base URL ของ Backend API
class ApiConfig {
  /// Production URL (Render.com)
  static const String _productionUrl =
      'https://running-app-backend-1ck1.onrender.com/api';

  /// สามารถ override URL สำหรับพัฒนาบน local ได้:
  /// flutter run --dart-define=API_URL=http://192.168.1.XX:5000/api
  static const String _envUrl = String.fromEnvironment('API_URL');

  /// ถ้ามี --dart-define จะใช้ค่านั้น, ถ้าไม่มีจะใช้ Production URL
  static String get baseUrl {
    if (_envUrl.isNotEmpty) {
      return _envUrl;
    }
    return _productionUrl;
  }

  /// Web application Client ID จาก Google Cloud Console
  static const googleWebClientId =
      '385307095607-63kma56bh9es5ib9aqgcn690t940u30q.apps.googleusercontent.com';
}
