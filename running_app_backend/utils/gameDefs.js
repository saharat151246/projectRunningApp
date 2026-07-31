// นิยามเหรียญตรา (Badge) พร้อมเงื่อนไขปลดล็อกจริง - คำนวณจาก UserStats
const BADGES = [
  {
    id: 'first_run',
    emoji: '🏅',
    title: 'วิ่งครั้งแรก',
    description: 'จบการวิ่งครั้งแรกของคุณ',
    isUnlocked: (s) => s.totalRuns >= 1,
  },
  {
    id: 'streak_7',
    emoji: '🔥',
    title: 'วิ่งต่อเนื่อง 7 วัน',
    description: 'วิ่งติดต่อกัน 7 วันโดยไม่ขาด',
    isUnlocked: (s) => s.currentStreakDays >= 7,
  },
  {
    id: 'distance_50',
    emoji: '🎯',
    title: 'ครบ 50 กม.',
    description: 'สะสมระยะทางรวมครบ 50 กม.',
    isUnlocked: (s) => s.totalDistanceKm >= 50,
  },
  {
    id: 'night_run',
    emoji: '🌙',
    title: 'วิ่งกลางคืน',
    description: 'วิ่งในช่วงเวลา 20:00 - 05:00 น.',
    isUnlocked: (s) => s.hasNightRun,
  },
  {
    id: 'fast_pace',
    emoji: '⚡',
    title: 'เพซต่ำกว่า 5:00',
    description: 'วิ่งด้วยเพซเฉลี่ยต่ำกว่า 5:00 นาที/กม.',
    isUnlocked: (s) => s.hasFastPace,
  },
  {
    id: 'distance_100',
    emoji: '🏆',
    title: 'ครบ 100 กม.',
    description: 'สะสมระยะทางรวมครบ 100 กม.',
    isUnlocked: (s) => s.totalDistanceKm >= 100,
  },
];

// นิยามภารกิจรายสัปดาห์ (Mission)
const MISSIONS = [
  {
    id: 'weekly_20km',
    title: 'วิ่งให้ครบ 20 กม. สัปดาห์นี้',
    target: 20,
    unit: 'กม.',
    rewardPoints: 50,
    currentValue: (s) => s.weeklyDistanceKm,
  },
  {
    id: 'streak_5days',
    title: 'วิ่งครบ 5 วันในสัปดาห์นี้',
    target: 5,
    unit: 'วัน',
    rewardPoints: 30,
    currentValue: (s) => s.weeklyRunDates.length,
  },
  {
    id: 'morning_x3',
    title: 'วิ่งเช้า (ก่อน 9 โมง) 3 ครั้ง',
    target: 3,
    unit: 'ครั้ง',
    rewardPoints: 20,
    currentValue: (s) => s.morningRunsThisWeek,
  },
];

module.exports = { BADGES, MISSIONS };
