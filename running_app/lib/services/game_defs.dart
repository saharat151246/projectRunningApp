import 'user_stats.dart';

/// นิยามเหรียญตรา (Badge) พร้อมเงื่อนไขปลดล็อกจริง
class BadgeDef {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final bool Function(UserStats stats) isUnlocked;

  const BadgeDef({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.isUnlocked,
  });
}

/// นิยามภารกิจรายสัปดาห์ (Mission) พร้อมวิธีคำนวณความคืบหน้าจริง
class MissionDef {
  final String id;
  final String title;
  final double target;
  final int rewardPoints;
  final double Function(UserStats stats) currentValue;
  final String unit;

  const MissionDef({
    required this.id,
    required this.title,
    required this.target,
    required this.rewardPoints,
    required this.currentValue,
    required this.unit,
  });

  double progressOf(UserStats stats) {
    final v = currentValue(stats) / target;
    return v.clamp(0.0, 1.0);
  }

  bool isCompleted(UserStats stats) => currentValue(stats) >= target;
}

class GameDefs {
  static const List<BadgeDef> badges = [
    BadgeDef(
      id: 'first_run',
      emoji: '🏅',
      title: 'วิ่งครั้งแรก',
      description: 'จบการวิ่งครั้งแรกของคุณ',
      isUnlocked: _firstRun,
    ),
    BadgeDef(
      id: 'streak_7',
      emoji: '🔥',
      title: 'วิ่งต่อเนื่อง 7 วัน',
      description: 'วิ่งติดต่อกัน 7 วันโดยไม่ขาด',
      isUnlocked: _streak7,
    ),
    BadgeDef(
      id: 'distance_50',
      emoji: '🎯',
      title: 'ครบ 50 กม.',
      description: 'สะสมระยะทางรวมครบ 50 กม.',
      isUnlocked: _distance50,
    ),
    BadgeDef(
      id: 'night_run',
      emoji: '🌙',
      title: 'วิ่งกลางคืน',
      description: 'วิ่งในช่วงเวลา 20:00 - 05:00 น.',
      isUnlocked: _nightRun,
    ),
    BadgeDef(
      id: 'fast_pace',
      emoji: '⚡',
      title: 'เพซต่ำกว่า 5:00',
      description: 'วิ่งด้วยเพซเฉลี่ยต่ำกว่า 5:00 นาที/กม.',
      isUnlocked: _fastPace,
    ),
    BadgeDef(
      id: 'distance_100',
      emoji: '🏆',
      title: 'ครบ 100 กม.',
      description: 'สะสมระยะทางรวมครบ 100 กม.',
      isUnlocked: _distance100,
    ),
  ];

  static const List<MissionDef> missions = [
    MissionDef(
      id: 'weekly_20km',
      title: 'วิ่งให้ครบ 20 กม. สัปดาห์นี้',
      target: 20,
      rewardPoints: 50,
      unit: 'กม.',
      currentValue: _weeklyDistance,
    ),
    MissionDef(
      id: 'streak_5days',
      title: 'วิ่งครบ 5 วันในสัปดาห์นี้',
      target: 5,
      rewardPoints: 30,
      unit: 'วัน',
      currentValue: _weeklyRunDays,
    ),
    MissionDef(
      id: 'morning_x3',
      title: 'วิ่งเช้า (ก่อน 9 โมง) 3 ครั้ง',
      target: 3,
      rewardPoints: 20,
      unit: 'ครั้ง',
      currentValue: _morningRuns,
    ),
  ];

  static bool _firstRun(UserStats s) => s.totalRuns >= 1;
  static bool _streak7(UserStats s) => s.currentStreakDays >= 7;
  static bool _distance50(UserStats s) => s.totalDistanceKm >= 50;
  static bool _nightRun(UserStats s) => s.hasNightRun;
  static bool _fastPace(UserStats s) => s.hasFastPace;
  static bool _distance100(UserStats s) => s.totalDistanceKm >= 100;

  static double _weeklyDistance(UserStats s) => s.weeklyDistanceKm;
  static double _weeklyRunDays(UserStats s) => s.weeklyRunDates.length.toDouble();
  static double _morningRuns(UserStats s) => s.morningRunsThisWeek.toDouble();
}
