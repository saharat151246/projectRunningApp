/// โมเดลเก็บสถิติสะสมของผู้ใช้ - persist ไว้ในเครื่องด้วย shared_preferences
/// (จะย้ายไปเก็บใน MongoDB ผ่าน backend เมื่อเชื่อมต่อระบบจริงในลำดับถัดไป)
class UserStats {
  double totalDistanceKm;
  int totalRuns;
  int totalPoints;
  int currentStreakDays;
  String? lastRunDate; // yyyy-MM-dd

  // Badge achievement flags ที่คำนวณจาก event ตอนจบการวิ่ง (ไม่ใช่ threshold สะสม)
  bool hasNightRun; // เคยวิ่งช่วง 20:00-05:00
  bool hasFastPace; // เคยวิ่งเพซต่ำกว่า 5:00 /กม.

  // เหรียญที่ปลดล็อกแล้ว (เก็บ id ไว้ไม่ให้ล็อกกลับแม้ streak จะขาดทีหลัง)
  List<String> achievedBadgeIds;

  // ตัวนับรายสัปดาห์ (รีเซ็ตทุกวันจันทร์)
  String weekStart; // yyyy-MM-dd ของวันจันทร์สัปดาห์ปัจจุบัน
  double weeklyDistanceKm;
  List<String> weeklyRunDates; // วันที่ (yyyy-MM-dd) ที่วิ่งในสัปดาห์นี้ ไม่ซ้ำ
  int morningRunsThisWeek; // วิ่งก่อน 9 โมงเช้า
  List<String> weeklyRewardedMissionIds;

  UserStats({
    this.totalDistanceKm = 0,
    this.totalRuns = 0,
    this.totalPoints = 0,
    this.currentStreakDays = 0,
    this.lastRunDate,
    this.hasNightRun = false,
    this.hasFastPace = false,
    List<String>? achievedBadgeIds,
    required this.weekStart,
    this.weeklyDistanceKm = 0,
    List<String>? weeklyRunDates,
    this.morningRunsThisWeek = 0,
    List<String>? weeklyRewardedMissionIds,
  })  : achievedBadgeIds = achievedBadgeIds ?? [],
        weeklyRunDates = weeklyRunDates ?? [],
        weeklyRewardedMissionIds = weeklyRewardedMissionIds ?? [];

  Map<String, dynamic> toJson() => {
        'totalDistanceKm': totalDistanceKm,
        'totalRuns': totalRuns,
        'totalPoints': totalPoints,
        'currentStreakDays': currentStreakDays,
        'lastRunDate': lastRunDate,
        'hasNightRun': hasNightRun,
        'hasFastPace': hasFastPace,
        'achievedBadgeIds': achievedBadgeIds,
        'weekStart': weekStart,
        'weeklyDistanceKm': weeklyDistanceKm,
        'weeklyRunDates': weeklyRunDates,
        'morningRunsThisWeek': morningRunsThisWeek,
        'weeklyRewardedMissionIds': weeklyRewardedMissionIds,
      };

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
        totalDistanceKm: (json['totalDistanceKm'] as num?)?.toDouble() ?? 0,
        totalRuns: json['totalRuns'] as int? ?? 0,
        totalPoints: json['totalPoints'] as int? ?? 0,
        currentStreakDays: json['currentStreakDays'] as int? ?? 0,
        lastRunDate: json['lastRunDate'] as String?,
        hasNightRun: json['hasNightRun'] as bool? ?? false,
        hasFastPace: json['hasFastPace'] as bool? ?? false,
        achievedBadgeIds:
            (json['achievedBadgeIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
        weekStart: json['weekStart'] as String,
        weeklyDistanceKm: (json['weeklyDistanceKm'] as num?)?.toDouble() ?? 0,
        weeklyRunDates:
            (json['weeklyRunDates'] as List?)?.map((e) => e.toString()).toList() ?? [],
        morningRunsThisWeek: json['morningRunsThisWeek'] as int? ?? 0,
        weeklyRewardedMissionIds:
            (json['weeklyRewardedMissionIds'] as List?)?.map((e) => e.toString()).toList() ??
                [],
      );
}
