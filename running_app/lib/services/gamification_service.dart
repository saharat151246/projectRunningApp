import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';
import '../models/gamification_model.dart';

export '../models/gamification_model.dart';

/// เรียก Gamification API ของ Backend - คำนวณเหรียญ/ภารกิจ/แต้มสดจากข้อมูล runs จริงใน MongoDB
class GamificationService {
  GamificationService._();
  static final GamificationService instance = GamificationService._();

  Future<GamificationData> fetch() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/gamification'),
        headers: {'Authorization': 'Bearer ${AuthService.instance.token}'},
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) return GamificationData.empty();
      return GamificationData.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } catch (_) {
      return GamificationData.empty();
    }
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.instance.token}',
      };

  Future<bool> createMission({
    required String title,
    required String frequency,
    required String metric,
    required double target,
    required int reward,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/gamification/missions'),
        headers: _headers,
        body: jsonEncode({
          'title': title,
          'frequency': frequency,
          'metric': metric,
          'target': target,
          'reward': reward,
        }),
      ).timeout(const Duration(seconds: 15));
      return res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteMission(String id) async {
    try {
      final res = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/gamification/missions/$id'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
