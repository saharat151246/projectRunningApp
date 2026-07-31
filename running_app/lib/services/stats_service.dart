import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_stats.dart';
import 'game_defs.dart';

/// ผลลัพธ์หลังบันทึกการวิ่ง - ใช้แสดง popup แจ้งเตือนความสำเร็จใหม่
class RunRecordResult {
  final List<BadgeDef> newlyUnlockedBadges;
  final List<MissionDef> newlyCompletedMissions;
  final int pointsEarned;

  RunRecordResult({
    required this.newlyUnlockedBadges,
    required this.newlyCompletedMissions,
    required this.pointsEarned,
  });
}

/// จัดการสถิติผู้ใช้ทั้งหมด เก็บไว้ในเครื่องด้วย shared_preferences
/// เป็น ChangeNotifier เพื่อให้ทุกหน้าจอที่ฟังอยู่รีเฟรชอัตโนมัติเมื่อมีข้อมูลใหม่
class StatsService extends ChangeNotifier {
  StatsService._();
  static final StatsService instance = StatsService._();

  static const _prefsKey = 'user_stats_v1';

  late UserStats stats;
  bool _initialized = false;
  bool get isInitialized => _initialized;

  String _mondayKeyOf(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return _dateKey(monday);
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        stats = UserStats.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        stats = UserStats(weekStart: _mondayKeyOf(DateTime.now()));
      }
    } else {
      stats = UserStats(weekStart: _mondayKeyOf(DateTime.now()));
    }
    _rolloverWeekIfNeeded();
    _initialized = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(stats.toJson()));
  }

  void _rolloverWeekIfNeeded() {
    final currentMonday = _mondayKeyOf(DateTime.now());
    if (stats.weekStart != currentMonday) {
      stats.weekStart = currentMonday;
      stats.weeklyDistanceKm = 0;
      stats.weeklyRunDates = [];
      stats.morningRunsThisWeek = 0;
      stats.weeklyRewardedMissionIds = [];
    }
  }

  /// เรียกทุกครั้งที่จบการวิ่งจริง (จาก Tracking Screen)
  Future<RunRecordResult> recordRun({
    required double distanceKm,
    required int durationSeconds,
    required DateTime completedAt,
  }) async {
    _rolloverWeekIfNeeded();

    // --- อัปเดตสถิติสะสมรวม ---
    stats.totalDistanceKm += distanceKm;
    stats.totalRuns += 1;

    final todayKey = _dateKey(completedAt);
    final yesterdayKey = _dateKey(completedAt.subtract(const Duration(days: 1)));

    if (stats.lastRunDate == todayKey) {
      // วิ่งซ้ำวันเดียวกัน ไม่นับ streak เพิ่ม
    } else if (stats.lastRunDate == yesterdayKey) {
      stats.currentStreakDays += 1;
    } else {
      stats.currentStreakDays = 1;
    }
    stats.lastRunDate = todayKey;

    // --- อัปเดตตัวนับรายสัปดาห์ ---
    stats.weeklyDistanceKm += distanceKm;
    if (!stats.weeklyRunDates.contains(todayKey)) {
      stats.weeklyRunDates.add(todayKey);
    }
    if (completedAt.hour < 9) {
      stats.morningRunsThisWeek += 1;
    }

    // --- เช็ค event flags สำหรับเหรียญพิเศษ ---
    final hour = completedAt.hour;
    if (hour >= 20 || hour < 5) {
      stats.hasNightRun = true;
    }
    if (distanceKm > 0) {
      final paceMinPerKm = (durationSeconds / 60) / distanceKm;
      if (paceMinPerKm > 0 && paceMinPerKm < 5.0) {
        stats.hasFastPace = true;
      }
    }

    // --- แต้มพื้นฐานจากระยะทาง (10 แต้ม/กม.) ---
    final basePoints = (distanceKm * 10).round();
    stats.totalPoints += basePoints;
    int pointsEarned = basePoints;

    // --- เช็คเหรียญที่ปลดล็อกใหม่ ---
    final newlyUnlocked = <BadgeDef>[];
    for (final badge in GameDefs.badges) {
      if (!stats.achievedBadgeIds.contains(badge.id) && badge.isUnlocked(stats)) {
        stats.achievedBadgeIds.add(badge.id);
        newlyUnlocked.add(badge);
        stats.totalPoints += 50; // โบนัสปลดล็อกเหรียญ
        pointsEarned += 50;
      }
    }

    // --- เช็คภารกิจที่สำเร็จใหม่ในสัปดาห์นี้ ---
    final newlyCompleted = <MissionDef>[];
    for (final mission in GameDefs.missions) {
      if (!stats.weeklyRewardedMissionIds.contains(mission.id) &&
          mission.isCompleted(stats)) {
        stats.weeklyRewardedMissionIds.add(mission.id);
        newlyCompleted.add(mission);
        stats.totalPoints += mission.rewardPoints;
        pointsEarned += mission.rewardPoints;
      }
    }

    await _persist();
    notifyListeners();

    return RunRecordResult(
      newlyUnlockedBadges: newlyUnlocked,
      newlyCompletedMissions: newlyCompleted,
      pointsEarned: pointsEarned,
    );
  }

  /// สำหรับทดสอบ/รีเซ็ตข้อมูลระหว่างพัฒนา
  Future<void> resetAll() async {
    stats = UserStats(weekStart: _mondayKeyOf(DateTime.now()));
    await _persist();
    notifyListeners();
  }
}
