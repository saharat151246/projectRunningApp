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

