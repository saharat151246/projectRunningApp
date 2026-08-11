import 'package:latlong2/latlong.dart';

/// ค่าความรู้สึกหลังวิ่งที่รองรับ - ต้องตรงกับ MOOD_VALUES ฝั่ง backend (models/Run.js)
enum RunMood { exhausted, veryTired, good, great, chill }

extension RunMoodX on RunMood {
  String get apiValue {
    switch (this) {
      case RunMood.exhausted:
        return 'exhausted';
      case RunMood.veryTired:
        return 'very_tired';
      case RunMood.good:
        return 'good';
      case RunMood.great:
        return 'great';
      case RunMood.chill:
        return 'chill';
    }
  }

  String get emoji {
    switch (this) {
      case RunMood.exhausted:
        return '😩';
      case RunMood.veryTired:
        return '🥵';
      case RunMood.good:
        return '🙂';
      case RunMood.great:
        return '🤩';
      case RunMood.chill:
        return '😎';
    }
  }

  String get label {
    switch (this) {
      case RunMood.exhausted:
        return 'เหนื่อย';
      case RunMood.veryTired:
        return 'เหนื่อยมาก';
      case RunMood.good:
        return 'ดี';
      case RunMood.great:
        return 'เยี่ยม';
      case RunMood.chill:
        return 'ไหวชิล';
    }
  }

  static RunMood? fromApiValue(String? value) {
    switch (value) {
      case 'exhausted':
        return RunMood.exhausted;
      case 'very_tired':
        return RunMood.veryTired;
      case 'good':
        return RunMood.good;
      case 'great':
        return RunMood.great;
      case 'chill':
        return RunMood.chill;
      default:
        return null;
    }
  }
}

/// โมเดลข้อมูลการวิ่งหนึ่งครั้ง - แปลงจาก JSON ที่ได้จาก Backend API
class RunItem {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final double distanceKm;
  final int durationSec;
  final double? avgPace; // นาที/กม.
  final RunMood? mood;

  RunItem({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.distanceKm,
    required this.durationSec,
    this.avgPace,
    this.mood,
  });

  factory RunItem.fromJson(Map<String, dynamic> json) => RunItem(
        id: json['_id'] as String,
        startTime: DateTime.parse(json['start_time'] as String),
        endTime: DateTime.parse(json['end_time'] as String),
        distanceKm: (json['distance_km'] as num).toDouble(),
        durationSec: (json['duration_sec'] as num).toInt(),
        avgPace: (json['avg_pace'] as num?)?.toDouble(),
        mood: RunMoodX.fromApiValue(json['mood'] as String?),
      );
}

/// โมเดลรายละเอียดการวิ่งเต็ม (รวมเส้นทาง GPS ทุกจุด) - ใช้ในหน้า Run Detail
class RunDetail {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final double distanceKm;
  final int durationSec;
  final double? avgPace;
  final List<LatLng> route;
  final RunMood? mood;
  final String? note;
  final double? sleepHours;
  final String? stressLevel;
  final String? weather;

  RunDetail({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.distanceKm,
    required this.durationSec,
    this.avgPace,
    required this.route,
    this.mood,
    this.note,
    this.sleepHours,
    this.stressLevel,
    this.weather,
  });

  factory RunDetail.fromJson(Map<String, dynamic> json) {
    final routeRaw = json['route'] as List? ?? [];
    return RunDetail(
      id: json['_id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      distanceKm: (json['distance_km'] as num).toDouble(),
      durationSec: (json['duration_sec'] as num).toInt(),
      avgPace: (json['avg_pace'] as num?)?.toDouble(),
      mood: RunMoodX.fromApiValue(json['mood'] as String?),
      note: json['note'] as String?,
      sleepHours: (json['sleep_hours'] as num?)?.toDouble(),
      stressLevel: json['stress_level'] as String?,
      weather: json['weather'] as String?,
      route: routeRaw
          .map((p) => LatLng(
                (p['lat'] as num).toDouble(),
                (p['lng'] as num).toDouble(),
              ))
          .toList(),
    );
  }
}
