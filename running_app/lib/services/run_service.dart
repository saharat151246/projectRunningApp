import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';
import '../models/run_model.dart';

export '../models/run_model.dart';

class RunApiResult {
  final bool success;
  final String? errorMessage;
  final String? runId;
  RunApiResult({required this.success, this.errorMessage, this.runId});
}

class RunSummary {
  final int totalRuns;
  final double totalDistanceKm;
  final List<double> weeklyDistance;
  final List<String> weekLabels; // yyyy-MM-dd ของ 7 วันล่าสุด คู่กับ weeklyDistance

  RunSummary({
    required this.totalRuns,
    required this.totalDistanceKm,
    required this.weeklyDistance,
    required this.weekLabels,
  });

  factory RunSummary.empty() => RunSummary(
        totalRuns: 0,
        totalDistanceKm: 0,
        weeklyDistance: List.filled(7, 0),
        weekLabels: List.filled(7, ''),
      );

  factory RunSummary.fromJson(Map<String, dynamic> json) => RunSummary(
        totalRuns: json['totalRuns'] as int? ?? 0,
        totalDistanceKm: (json['totalDistanceKm'] as num?)?.toDouble() ?? 0,
        weeklyDistance: (json['weeklyDistance'] as List?)
                ?.map((e) => (e as num).toDouble())
                .toList() ??
            List.filled(7, 0),
        weekLabels:
            (json['weekLabels'] as List?)?.map((e) => e.toString()).toList() ??
                List.filled(7, ''),
      );
}

/// เรียก Runs API ของ Backend เพื่อบันทึกและดึงประวัติการวิ่งจริงจาก MongoDB
class RunService {
  RunService._();
  static final RunService instance = RunService._();

  Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthService.instance.token}',
      };

  /// บันทึกการวิ่งที่เพิ่งจบลง MongoDB ผ่าน backend
  Future<RunApiResult> createRun({
    required DateTime startTime,
    required DateTime endTime,
    required double distanceKm,
    required int durationSec,
    double? avgPace,
    List<Map<String, dynamic>> route = const [],
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/runs'),
            headers: _authHeaders,
            body: jsonEncode({
              'start_time': startTime.toIso8601String(),
              'end_time': endTime.toIso8601String(),
              'distance_km': distanceKm,
              'duration_sec': durationSec,
              'avg_pace': avgPace,
              'route': route,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final runId = (data['run'] as Map<String, dynamic>?)?['_id'] as String?;
        return RunApiResult(success: true, runId: runId);
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return RunApiResult(success: false, errorMessage: data['message']?.toString());
    } catch (e) {
      return RunApiResult(success: false, errorMessage: 'บันทึกไม่สำเร็จ: $e');
    }
  }

  /// บันทึกเช็คอินความรู้สึกและข้อมูลฟื้นฟูหลังวิ่ง (mood + note + recovery)
  Future<RunApiResult> updateMoodCheckin({
    required String runId,
    RunMood? mood,
    String? note,
    double? sleepHours,
    String? stressLevel,
    String? weather,
  }) async {
    try {
      final res = await http
          .patch(
            Uri.parse('${ApiConfig.baseUrl}/runs/$runId'),
            headers: _authHeaders,
            body: jsonEncode({
              if (mood != null) 'mood': mood.apiValue,
              if (note != null) 'note': note,
              if (sleepHours != null) 'sleep_hours': sleepHours,
              if (stressLevel != null) 'stress_level': stressLevel,
              if (weather != null) 'weather': weather,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        return RunApiResult(success: true, runId: runId);
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return RunApiResult(success: false, errorMessage: data['message']?.toString());
    } catch (e) {
      return RunApiResult(success: false, errorMessage: 'บันทึกไม่สำเร็จ: $e');
    }
  }

  /// ดึงประวัติการวิ่งทั้งหมด (ล่าสุดก่อน)
  Future<List<RunItem>> fetchRuns() async {
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/runs'), headers: _authHeaders)
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final list = data['runs'] as List? ?? [];
      return list.map((e) => RunItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// ดึงสรุปสถิติรวม + ระยะทางรายวัน 7 วันล่าสุด (สำหรับกราฟ)
  Future<RunSummary> fetchSummary() async {
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/runs/summary'), headers: _authHeaders)
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) return RunSummary.empty();
      return RunSummary.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } catch (_) {
      return RunSummary.empty();
    }
  }

  /// ดึงรายละเอียดการวิ่งครั้งเดียว รวมเส้นทาง GPS เต็ม (สำหรับหน้า Run Detail)
  Future<RunDetail?> fetchRunDetail(String runId) async {
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/runs/$runId'), headers: _authHeaders)
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return RunDetail.fromJson(data['run'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// ลบประวัติการวิ่งตาม runId
  Future<RunApiResult> deleteRun(String runId) async {
    try {
      final res = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/runs/$runId'),
            headers: _authHeaders,
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200 || res.statusCode == 204) {
        return RunApiResult(success: true, runId: runId);
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return RunApiResult(
        success: false,
        errorMessage: data['message']?.toString() ?? 'ไม่สามารถลบรายการได้',
      );
    } catch (e) {
      return RunApiResult(success: false, errorMessage: 'การเชื่อมต่อขัดข้อง: $e');
    }
  }
}
