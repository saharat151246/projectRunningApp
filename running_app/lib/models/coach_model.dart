class CoachAdvice {
  final String advice;
  final String source; // 'gemini' หรือ 'rule-based'
  final int totalRuns;

  CoachAdvice({
    required this.advice,
    required this.source,
    required this.totalRuns,
  });

  factory CoachAdvice.empty() =>
      CoachAdvice(advice: '', source: 'rule-based', totalRuns: 0);

  factory CoachAdvice.fromJson(Map<String, dynamic> json) => CoachAdvice(
        advice: json['advice'] as String? ?? '',
        source: json['source'] as String? ?? 'rule-based',
        totalRuns: (json['stats'] as Map<String, dynamic>?)?['totalRuns'] as int? ?? 0,
      );
}
