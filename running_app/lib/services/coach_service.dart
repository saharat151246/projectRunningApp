import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';
import '../models/coach_model.dart';
import '../models/chat_message.dart';

export '../models/coach_model.dart';
export '../models/chat_message.dart';

class ChatReply {
  final String reply;
  final bool available; // false = Gemini ใช้ไม่ได้ตอนนี้ (ข้อความ reply จะเป็น fallback message)
  ChatReply({required this.reply, required this.available});
}

/// เรียก AI Coach API ของ Backend - ได้คำแนะนำจาก Gemini (หรือ rule-based ถ้า Gemini ใช้ไม่ได้)
class CoachService {
  CoachService._();
  static final CoachService instance = CoachService._();

  Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.instance.token}',
      };

  Future<CoachAdvice> fetchAdvice() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/coach'),
        headers: _authHeaders,
      ).timeout(const Duration(seconds: 20)); // Gemini อาจใช้เวลานานกว่า endpoint อื่นเล็กน้อย

      if (res.statusCode != 200) return CoachAdvice.empty();
      return CoachAdvice.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } catch (_) {
      return CoachAdvice.empty();
    }
  }

  /// ส่งข้อความคุยกับ AI Coach พร้อมประวัติการคุยล่าสุด (สำหรับ multi-turn context)
  Future<ChatReply> sendMessage({
    required String message,
    required List<ChatMessage> recentHistory,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/coach/chat'),
            headers: _authHeaders,
            body: jsonEncode({
              'message': message,
              'history': recentHistory.map((m) => m.toHistoryJson()).toList(),
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (res.statusCode != 200) {
        return ChatReply(
          reply: 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง',
          available: false,
        );
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return ChatReply(
        reply: data['reply'] as String? ?? '',
        available: data['available'] as bool? ?? false,
      );
    } catch (e) {
      return ChatReply(
        reply: 'เชื่อมต่อ Server ไม่ได้ กรุณาเช็คว่า backend รันอยู่หรือไม่',
        available: false,
      );
    }
  }
}
