class BadgeItem {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final bool unlocked;

  BadgeItem({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.unlocked,
  });

  factory BadgeItem.fromJson(Map<String, dynamic> json) => BadgeItem(
        id: json['id'] as String,
        emoji: json['emoji'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        unlocked: json['unlocked'] as bool? ?? false,
      );
}

class MissionItem {
  final String id;
  final String title;
  final double target;
  final String unit;
  final int reward;
  final double current;
  final double progress;
  final bool completed;
  final String? frequency;
  final bool personal;

  MissionItem({
    required this.id,
    required this.title,
    required this.target,
    required this.unit,
    required this.reward,
    required this.current,
    required this.progress,
    required this.completed,
    this.frequency,
    this.personal = false,
  });

  factory MissionItem.fromJson(Map<String, dynamic> json) => MissionItem(
        id: json['id'] as String,
        title: json['title'] as String,
        target: (json['target'] as num).toDouble(),
        unit: json['unit'] as String,
        reward: json['reward'] as int,
        current: (json['current'] as num).toDouble(),
        progress: (json['progress'] as num).toDouble(),
        completed: json['completed'] as bool? ?? false,
        frequency: json['frequency'] as String?,
        personal: json['personal'] as bool? ?? false,
      );
}

class GamificationData {
  final int totalRuns;
  final double totalDistanceKm;
  final int currentStreakDays;
  final int totalPoints;
  final List<BadgeItem> badges;
  final List<MissionItem> missions;
  final List<MissionItem> personalMissions;

  GamificationData({
    required this.totalRuns,
    required this.totalDistanceKm,
    required this.currentStreakDays,
    required this.totalPoints,
    required this.badges,
    required this.missions,
    required this.personalMissions,
  });

  factory GamificationData.empty() => GamificationData(
        totalRuns: 0,
        totalDistanceKm: 0,
        currentStreakDays: 0,
        totalPoints: 0,
        badges: [],
        missions: [],
        personalMissions: [],
      );

  factory GamificationData.fromJson(Map<String, dynamic> json) => GamificationData(
        totalRuns: json['totalRuns'] as int? ?? 0,
        totalDistanceKm: (json['totalDistanceKm'] as num?)?.toDouble() ?? 0,
        currentStreakDays: json['currentStreakDays'] as int? ?? 0,
        totalPoints: json['totalPoints'] as int? ?? 0,
        badges: (json['badges'] as List? ?? [])
            .map((e) => BadgeItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        missions: (json['missions'] as List? ?? [])
            .map((e) => MissionItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        personalMissions: (json['personalMissions'] as List? ?? [])
            .map((e) => MissionItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
