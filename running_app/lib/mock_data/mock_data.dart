/// ข้อมูลจำลอง (Mock Data) สำหรับแสดงผล UI เท่านั้น
/// จะถูกแทนที่ด้วยข้อมูลจริงจาก MongoDB ผ่าน Node.js API ในลำดับถัดไป

class MockRun {
  final String date;
  final double distanceKm;
  final String duration;
  final String pace;

  const MockRun({
    required this.date,
    required this.distanceKm,
    required this.duration,
    required this.pace,
  });
}

class MockBadge {
  final String emoji;
  final String title;
  final bool unlocked;

  const MockBadge({
    required this.emoji,
    required this.title,
    required this.unlocked,
  });
}

class MockMission {
  final String title;
  final double progress; // 0.0 - 1.0
  final String rewardPoints;

  const MockMission({
    required this.title,
    required this.progress,
    required this.rewardPoints,
  });
}

class MockData {
  static const weeklyDistance = [3.2, 5.0, 0.0, 4.1, 6.5, 2.0, 7.8];
  static const weekLabels = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];

  static const recentRuns = [
    MockRun(date: '6 ก.ค. 2569', distanceKm: 5.2, duration: '28:14', pace: '5:26 /กม.'),
    MockRun(date: '4 ก.ค. 2569', distanceKm: 3.0, duration: '16:40', pace: '5:33 /กม.'),
    MockRun(date: '2 ก.ค. 2569', distanceKm: 7.8, duration: '41:02', pace: '5:15 /กม.'),
    MockRun(date: '30 มิ.ย. 2569', distanceKm: 4.1, duration: '23:55', pace: '5:50 /กม.'),
  ];

  static const badges = [
    MockBadge(emoji: '🏅', title: 'วิ่งครั้งแรก', unlocked: true),
    MockBadge(emoji: '🔥', title: 'วิ่งต่อเนื่อง 7 วัน', unlocked: true),
    MockBadge(emoji: '🎯', title: 'ครบ 50 กม.', unlocked: true),
    MockBadge(emoji: '🌙', title: 'วิ่งกลางคืน', unlocked: false),
    MockBadge(emoji: '⚡', title: 'เพซต่ำกว่า 5:00', unlocked: false),
    MockBadge(emoji: '🏆', title: 'ครบ 100 กม.', unlocked: false),
  ];

  static const missions = [
    MockMission(title: 'วิ่งให้ครบ 20 กม. สัปดาห์นี้', progress: 0.65, rewardPoints: '+50'),
    MockMission(title: 'วิ่งต่อเนื่อง 5 วัน', progress: 0.4, rewardPoints: '+30'),
    MockMission(title: 'วิ่งเช้า 3 ครั้ง', progress: 0.33, rewardPoints: '+20'),
  ];

  static const aiTip =
      'สัปดาห์นี้คุณวิ่งมา 18.5 กม. เพิ่มขึ้นจากสัปดาห์ก่อน 12% แนะนำให้พักฟื้นกล้ามเนื้อ 1 วัน ก่อนเพิ่มระยะทางต่อ เพื่อลดความเสี่ยงการบาดเจ็บ';

  static const totalDistanceKm = 128.4;
  static const totalRuns = 32;
  static const totalPoints = 1240;
  static const currentStreak = 4;
}
