class CoachAdvice {
  final String advice;
  final String source; // 'gemini' หรือ 'rule-based'
  final int totalRuns;
  final bool overtrainingRisk;
  final bool fatigueSignal;
  final double? weeklyChangePercent;
  final double thisWeekKm;
  final double lastWeekKm;
  final bool inactivityWarning;

  CoachAdvice({
    required this.advice,
    required this.source,
    required this.totalRuns,
    this.overtrainingRisk = false,
    this.fatigueSignal = false,
    this.weeklyChangePercent,
    this.thisWeekKm = 0.0,
    this.lastWeekKm = 0.0,
    this.inactivityWarning = false,
  });

  factory CoachAdvice.empty() => CoachAdvice(
        advice: '',
        source: 'rule-based',
        totalRuns: 0,
        overtrainingRisk: false,
        fatigueSignal: false,
        thisWeekKm: 0.0,
        lastWeekKm: 0.0,
        inactivityWarning: false,
      );

  factory CoachAdvice.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    return CoachAdvice(
      advice: json['advice'] as String? ?? '',
      source: json['source'] as String? ?? 'rule-based',
      totalRuns: stats['totalRuns'] as int? ?? 0,
      overtrainingRisk: stats['overtrainingRisk'] as bool? ?? false,
      fatigueSignal: stats['fatigueSignal'] as bool? ?? false,
      weeklyChangePercent: (stats['weeklyChangePercent'] as num?)?.toDouble(),
      thisWeekKm: (stats['thisWeekKm'] as num?)?.toDouble() ?? 0.0,
      lastWeekKm: (stats['lastWeekKm'] as num?)?.toDouble() ?? 0.0,
      inactivityWarning: stats['inactivityWarning'] as bool? ?? false,
    );
  }
}

class DailyPlanItem {
  final String title;
  final String activityType; // 'easy_run' | 'interval' | 'long_run' | 'rest'
  final double targetDistanceKm;
  final String targetPace;
  final String rationale;
  final String tips;
  final String source;

  DailyPlanItem({
    required this.title,
    required this.activityType,
    required this.targetDistanceKm,
    required this.targetPace,
    required this.rationale,
    required this.tips,
    this.source = 'rule-based',
  });

  factory DailyPlanItem.empty() => DailyPlanItem(
        title: 'วิ่งตามความสะดวก',
        activityType: 'easy_run',
        targetDistanceKm: 3.0,
        targetPace: '6:30 - 7:00',
        rationale: 'รักษารอบขาและความฟิตต่อเนื่อง',
        tips: 'วิ่งช้าสลับเดินได้ตามสบาย',
      );

  factory DailyPlanItem.fromJson(Map<String, dynamic> json) {
    final plan = json['plan'] as Map<String, dynamic>? ?? {};
    return DailyPlanItem(
      title: plan['title'] as String? ?? 'แผนซ้อมประจำวัน',
      activityType: plan['activityType'] as String? ?? 'easy_run',
      targetDistanceKm: (plan['targetDistanceKm'] as num?)?.toDouble() ?? 0.0,
      targetPace: plan['targetPace'] as String? ?? '-',
      rationale: plan['rationale'] as String? ?? '',
      tips: plan['tips'] as String? ?? '',
      source: json['source'] as String? ?? 'rule-based',
    );
  }
}

class CoachInsightReport {
  final int totalRuns;
  final int analyzedRunsCount;
  final double? goodSleepAvgPace;
  final double? poorSleepAvgPace;
  final int? sleepPaceDiffSec;
  final String? bestWeather;
  final double? lowStressAvgPace;
  final double? highStressAvgPace;
  final String summary;

  CoachInsightReport({
    required this.totalRuns,
    required this.analyzedRunsCount,
    this.goodSleepAvgPace,
    this.poorSleepAvgPace,
    this.sleepPaceDiffSec,
    this.bestWeather,
    this.lowStressAvgPace,
    this.highStressAvgPace,
    required this.summary,
  });

  factory CoachInsightReport.empty() => CoachInsightReport(
        totalRuns: 0,
        analyzedRunsCount: 0,
        summary: 'ยังไม่มีข้อมูลเพียงพอสำหรับการวิเคราะห์ระยะยาว',
      );

  factory CoachInsightReport.fromJson(Map<String, dynamic> json) {
    final insights = json['insights'] as Map<String, dynamic>? ?? {};
    return CoachInsightReport(
      totalRuns: insights['totalRuns'] as int? ?? 0,
      analyzedRunsCount: insights['analyzedRunsCount'] as int? ?? 0,
      goodSleepAvgPace: (insights['goodSleepAvgPace'] as num?)?.toDouble(),
      poorSleepAvgPace: (insights['poorSleepAvgPace'] as num?)?.toDouble(),
      sleepPaceDiffSec: insights['sleepPaceDiffSec'] as int?,
      bestWeather: insights['bestWeather'] as String?,
      lowStressAvgPace: (insights['lowStressAvgPace'] as num?)?.toDouble(),
      highStressAvgPace: (insights['highStressAvgPace'] as num?)?.toDouble(),
      summary: json['summary'] as String? ?? 'สะสมข้อมูลวิ่งเพิ่มขึ้นเพื่อดู Insight เชิงลึก',
    );
  }
}

