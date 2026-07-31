/// คำนวณเหรียญ/ภารกิจ/แต้ม จากข้อมูล runs จริงของ user (ไม่ persist state แยก
/// แต่คำนวณสดทุกครั้งจาก runs ทั้งหมด เพื่อไม่ให้ข้อมูลเพี้ยนไปจาก MongoDB)

const BADGE_DEFS = [
  { id: 'first_run', emoji: '🏅', title: 'วิ่งครั้งแรก', description: 'จบการวิ่งครั้งแรกของคุณ' },
  { id: 'streak_7', emoji: '🔥', title: 'วิ่งต่อเนื่อง 7 วัน', description: 'วิ่งติดต่อกัน 7 วันโดยไม่ขาด' },
  { id: 'distance_50', emoji: '🎯', title: 'ครบ 50 กม.', description: 'สะสมระยะทางรวมครบ 50 กม.' },
  { id: 'night_run', emoji: '🌙', title: 'วิ่งกลางคืน', description: 'วิ่งในช่วงเวลา 20:00 - 05:00 น.' },
  { id: 'fast_pace', emoji: '⚡', title: 'เพซต่ำกว่า 5:00', description: 'วิ่งด้วยเพซเฉลี่ยต่ำกว่า 5:00 นาที/กม.' },
  { id: 'distance_100', emoji: '🏆', title: 'ครบ 100 กม.', description: 'สะสมระยะทางรวมครบ 100 กม.' },
];

const MISSION_DEFS = [
  { id: 'weekly_20km', title: 'วิ่งให้ครบ 20 กม. สัปดาห์นี้', target: 20, unit: 'กม.', reward: 50 },
  { id: 'streak_5days', title: 'วิ่งครบ 5 วันในสัปดาห์นี้', target: 5, unit: 'วัน', reward: 30 },
  { id: 'morning_x3', title: 'วิ่งเช้า (ก่อน 9 โมง) 3 ครั้ง', target: 3, unit: 'ครั้ง', reward: 20 },
];

function dateKey(d) {
  return new Date(d).toISOString().slice(0, 10);
}

function mondayOf(d) {
  const date = new Date(d);
  const day = date.getUTCDay() || 7; // จันทร์=1 ... อาทิตย์=7
  date.setUTCDate(date.getUTCDate() - day + 1);
  date.setUTCHours(0, 0, 0, 0);
  return date;
}

/// คำนวณ streak วันวิ่งต่อเนื่อง (นับจากวันล่าสุดย้อนหลัง)
function calcStreak(sortedDateKeysDesc) {
  if (sortedDateKeysDesc.length === 0) return 0;
  const uniqueDays = [...new Set(sortedDateKeysDesc)];
  let streak = 1;
  let cursor = new Date(uniqueDays[0]);

  for (let i = 1; i < uniqueDays.length; i++) {
    const prevDay = new Date(cursor);
    prevDay.setUTCDate(prevDay.getUTCDate() - 1);
    const prevKey = prevDay.toISOString().slice(0, 10);
    if (uniqueDays[i] === prevKey) {
      streak += 1;
      cursor = prevDay;
    } else {
      break;
    }
  }
  return streak;
}

/// รับ array ของ Run (mongoose documents หรือ plain objects) แล้วคำนวณสถิติ+เหรียญ+ภารกิจทั้งหมด
function computeGamification(runs, personalMissionDocs = []) {
  const totalRuns = runs.length;
  const totalDistanceKm = runs.reduce((s, r) => s + r.distance_km, 0);

  const sortedDesc = [...runs].sort((a, b) => new Date(b.start_time) - new Date(a.start_time));
  const dayKeysDesc = sortedDesc.map((r) => dateKey(r.start_time));
  const currentStreakDays = calcStreak(dayKeysDesc);

  const hasNightRun = runs.some((r) => {
    const h = new Date(r.start_time).getUTCHours();
    return h >= 20 || h < 5;
  });

  const hasFastPace = runs.some((r) => {
    if (!r.distance_km || r.distance_km <= 0) return false;
    const pace = r.duration_sec / 60 / r.distance_km;
    return pace > 0 && pace < 5.0;
  });

  // --- สัปดาห์ปัจจุบัน (จันทร์ - อาทิตย์) ---
  const weekStart = mondayOf(new Date());
  const thisWeekRuns = runs.filter((r) => new Date(r.start_time) >= weekStart);
  const weeklyDistanceKm = thisWeekRuns.reduce((s, r) => s + r.distance_km, 0);
  const weeklyRunDays = new Set(thisWeekRuns.map((r) => dateKey(r.start_time))).size;
  const morningRunsThisWeek = thisWeekRuns.filter((r) => new Date(r.start_time).getUTCHours() < 9).length;

  const statsForConditions = {
    totalRuns,
    totalDistanceKm,
    currentStreakDays,
    hasNightRun,
    hasFastPace,
  };

  const badgeConditions = {
    first_run: () => statsForConditions.totalRuns >= 1,
    streak_7: () => statsForConditions.currentStreakDays >= 7,
    distance_50: () => statsForConditions.totalDistanceKm >= 50,
    night_run: () => statsForConditions.hasNightRun,
    fast_pace: () => statsForConditions.hasFastPace,
    distance_100: () => statsForConditions.totalDistanceKm >= 100,
  };

  const badges = BADGE_DEFS.map((b) => ({
    ...b,
    unlocked: badgeConditions[b.id](),
  }));

  const missionValues = {
    weekly_20km: weeklyDistanceKm,
    streak_5days: weeklyRunDays,
    morning_x3: morningRunsThisWeek,
  };

  const missions = MISSION_DEFS.map((m) => {
    const current = missionValues[m.id];
    const progress = Math.min(current / m.target, 1);
    return { ...m, current, progress, completed: current >= m.target };
  });

  const personalMissions = personalMissionDocs.map((mission) => {
    const createdAt = new Date(mission.createdAt);
    const now = new Date();
    let periodStart;
    if (mission.frequency === 'daily') {
      periodStart = new Date(now);
      periodStart.setUTCHours(0, 0, 0, 0);
    } else if (mission.frequency === 'weekly') {
      periodStart = mondayOf(now);
    } else {
      periodStart = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1));
    }
    // A mission cannot include runs completed before it was created.
    const activeFrom = createdAt > periodStart ? createdAt : periodStart;
    const periodRuns = runs.filter((r) => new Date(r.start_time) >= activeFrom);
    const current = mission.metric === 'distance'
      ? periodRuns.reduce((sum, r) => sum + r.distance_km, 0)
      : periodRuns.length;
    const unit = mission.metric === 'distance' ? 'กม.' : 'ครั้ง';
    return {
      id: mission._id.toString(),
      title: mission.title,
      frequency: mission.frequency,
      metric: mission.metric,
      target: mission.target,
      unit,
      reward: mission.reward,
      current: Math.round(current * 100) / 100,
      progress: Math.min(current / mission.target, 1),
      completed: current >= mission.target,
      personal: true,
    };
  });

  // แต้ม = 10 แต้ม/กม. + โบนัสเหรียญที่ปลดล็อกแล้ว 50 + โบนัสภารกิจที่สำเร็จในสัปดาห์นี้
  const distancePoints = Math.round(totalDistanceKm * 10);
  const badgePoints = badges.filter((b) => b.unlocked).length * 50;
  const missionPoints = missions.filter((m) => m.completed).reduce((s, m) => s + m.reward, 0) +
    personalMissions.filter((m) => m.completed).reduce((s, m) => s + m.reward, 0);
  const totalPoints = distancePoints + badgePoints + missionPoints;

  return {
    totalRuns,
    totalDistanceKm: Math.round(totalDistanceKm * 100) / 100,
    currentStreakDays,
    totalPoints,
    badges,
    missions,
    personalMissions,
  };
}

module.exports = { computeGamification };
