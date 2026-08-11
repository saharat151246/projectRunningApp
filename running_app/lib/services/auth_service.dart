import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api_config.dart';

/// ผลลัพธ์จากการเรียก Auth API - ใช้บอกหน้าจอว่าสำเร็จหรือไม่ และข้อความ error คืออะไร
class AuthResult {
  final bool success;
  final String? errorMessage;
  final String? otpCode;
  AuthResult({required this.success, this.errorMessage, this.otpCode});
}

/// จัดการ Authentication ทั้งหมด: เรียก API, เก็บ JWT token อย่างปลอดภัย,
/// และเก็บสถานะผู้ใช้ปัจจุบันให้ทั้งแอปเข้าถึงได้
class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  String? _token;
  Map<String, dynamic>? currentUser;

  bool get isLoggedIn => _token != null;
  String? get token => _token;

  /// เรียกตอนเปิดแอป (Splash) เพื่อเช็คว่ามี session ค้างอยู่ไหม
  Future<bool> tryAutoLogin() async {
    final saved = await _storage.read(key: _tokenKey);
    if (saved == null) return false;

    _token = saved;
    final ok = await fetchMe();
    if (!ok) {
      // token หมดอายุหรือไม่ถูกต้อง ล้างทิ้ง
      await logout();
      return false;
    }
    return true;
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'name': name, 'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 12));

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 201) {
        _token = data['token'] as String;
        currentUser = data['user'] as Map<String, dynamic>;
        await _storage.write(key: _tokenKey, value: _token);
        notifyListeners();
        return AuthResult(success: true);
      }
      return AuthResult(success: false, errorMessage: data['message']?.toString());
    } catch (e) {
      return AuthResult(success: false, errorMessage: _friendlyError(e));
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 12));

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200) {
        _token = data['token'] as String;
        currentUser = data['user'] as Map<String, dynamic>;
        await _storage.write(key: _tokenKey, value: _token);
        notifyListeners();
        return AuthResult(success: true);
      }
      return AuthResult(success: false, errorMessage: data['message']?.toString());
    } catch (e) {
      return AuthResult(success: false, errorMessage: _friendlyError(e));
    }
  }

  final _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId: ApiConfig.googleWebClientId,
  );

  /// เข้าสู่ระบบด้วย Google: เปิดหน้าเลือกบัญชี Google ของเครื่อง
  /// ดึง idToken แล้วส่งไปให้ backend verify (POST /api/auth/google)
  Future<AuthResult> loginWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        // ผู้ใช้กดยกเลิกหน้าเลือกบัญชี ไม่ถือเป็น error
        return AuthResult(success: false, errorMessage: null);
      }

      final googleAuth = await account.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        return AuthResult(
          success: false,
          errorMessage: 'ไม่สามารถดึง Google ID token ได้ กรุณาลองใหม่',
        );
      }

      final res = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/google'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'id_token': idToken}),
          )
          .timeout(const Duration(seconds: 12));

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200) {
        _token = data['token'] as String;
        currentUser = data['user'] as Map<String, dynamic>;
        await _storage.write(key: _tokenKey, value: _token);
        notifyListeners();
        return AuthResult(success: true);
      }
      return AuthResult(success: false, errorMessage: data['message']?.toString());
    } catch (e) {
      return AuthResult(success: false, errorMessage: _friendlyError(e));
    }
  }

  Future<bool> fetchMe() async {
    if (_token == null) return false;
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/me'),
        headers: {'Authorization': 'Bearer $_token'},
      ).timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        currentUser = data['user'] as Map<String, dynamic>;
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<AuthResult> updateProfile({
    String? name,
    double? weight,
    double? height,
    int? age,
    String? avatarUrl,
  }) async {
    if (_token == null) {
      return AuthResult(success: false, errorMessage: 'กรุณาเข้าสู่ระบบก่อน');
    }
    try {
      final res = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/auth/me'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_token',
            },
            body: jsonEncode({
              if (name != null) 'name': name,
              if (weight != null) 'weight': weight,
              if (height != null) 'height': height,
              if (age != null) 'age': age,
              if (avatarUrl != null) 'avatar_url': avatarUrl,
            }),
          )
          .timeout(const Duration(seconds: 12));

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200) {
        currentUser = data['user'] as Map<String, dynamic>;
        notifyListeners();
        return AuthResult(success: true);
      }
      return AuthResult(success: false, errorMessage: data['message']?.toString());
    } catch (e) {
      return AuthResult(success: false, errorMessage: _friendlyError(e));
    }
  }

  /// ขอรับรหัส OTP สำหรับตั้งรหัสผ่านใหม่
  Future<AuthResult> forgotPassword({required String email}) async {
    try {
      final res = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/forgot-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email.trim()}),
          )
          .timeout(const Duration(seconds: 12));

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        return AuthResult(
          success: true,
          otpCode: data['otp'] as String?,
        );
      }
      return AuthResult(success: false, errorMessage: data['message']?.toString());
    } catch (e) {
      return AuthResult(success: false, errorMessage: _friendlyError(e));
    }
  }

  /// ยืนยันรหัส OTP และตั้งรหัสผ่านใหม่
  Future<AuthResult> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/reset-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email.trim(),
              'otp': otp.trim(),
              'newPassword': newPassword.trim(),
            }),
          )
          .timeout(const Duration(seconds: 12));

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        return AuthResult(success: true);
      }
      return AuthResult(success: false, errorMessage: data['message']?.toString());
    } catch (e) {
      return AuthResult(success: false, errorMessage: _friendlyError(e));
    }
  }

  Future<void> logout() async {
    _token = null;
    currentUser = null;
    await _storage.delete(key: _tokenKey);
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // ไม่เคย sign-in ด้วย Google หรือเน็ตหลุด ไม่ต้องสน
    }
    notifyListeners();
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('TimeoutException')) {
      return 'เชื่อมต่อ Server ไม่ได้ (Timeout) — เช็คว่า backend รันอยู่หรือไม่';
    }
    if (msg.contains('SocketException') || msg.contains('Connection refused')) {
      return 'เชื่อมต่อ Server ไม่ได้ — เช็คว่า backend รันอยู่ และตั้งค่า IP ถูกต้อง';
    }
    return 'เกิดข้อผิดพลาด: $msg';
  }
}
