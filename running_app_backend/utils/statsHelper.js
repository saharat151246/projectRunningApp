const UserStats = require('../models/UserStats');
const { BADGES, MISSIONS } = require('./gameDefs');

/// วันที่ปัจจุบันของ server ในรูปแบบ yyyy-MM-dd (UTC)
function todayKeyNow() {
  return new Date().toISOString().slice(0, 10);
}

/// หา "วันจันทร์" ของสัปดาห์ที่ dateKey (yyyy-MM-dd) นั้นอยู่
function mondayKeyOf(dateKey) {
  const d = new Date(dateKey + 'T00:00:00Z');
  const day = d.getUTCDay() || 7; // Sun=0 -> 7, Mon=1 ... Sat=6
  if (day !== 1) d.setUTCDate(d.getUTCDate() - (day - 1));
  return d.toISOString().slice(0, 10);
}

/// ดึงเลขชั่วโมง (0-23) ตรงจาก ISO string ที่ client ส่งมา โดยไม่ผ่านการแปลง timezone ของ Date object
/// (กันปัญหาเวลาชั่วโมงเพี้ยนจาก timezone offset ระหว่าง client/server)
function extractHourFromIso(isoStr) {
  const match = /T(\d{2}):/.exec(String(isoStr));
  return match ? parseInt(match[1], 10) : new Date(isoStr).getUTCHours();
}

/// ดึงวันที่ (yyyy-MM-dd) ตรงจาก ISO string ที่ client ส่งมา
function extractDateKeyFromIso(isoStr) {
  return String(isoStr).slice(0, 10);
}

function rolloverIfNeeded(stats) {
  const currentMonday = mondayKeyOf(todayKeyNow());
  if (stats.weekStart !== currentMonday) {
    stats.weekStart = currentMonday;
    stats.weeklyDistanceKm = 0;
    stats.weeklyRunDates = [];
    stats.morningRunsThisWeek = 0;
    stats.weeklyRewardedMissionIds = [];
  }
}

async function getOrCreateStats(userId) {
  let stats = await UserStats.findOne({ user_id: userId });
  if (!stats) {
    stats = await UserStats.create({ user_id: userId, weekStart: mondayKeyOf(todayKeyNow()) });
  }
  rolloverIfNeeded(stats);
  return stats;
}

/// อัปเดตสถิติ/เหรียญ/ภารกิจ หลังจากบันทึกการวิ่งใหม่สำเร็จ
/// คืนค่า newly unlocked badges/missions + แต้มที่ได้รับรอบนี้ ไว้ให้ frontend แสดง popup
async function recordRunForStats(userId, { distanceKm, durationSec, endTimeIso }) {
  const stats = await getOrCreateStats(userId);

  const todayKey = extractDateKeyFromIso(endTimeIso);
  const hour = extractHourFromIso(endTimeIso);

  stats.totalDistanceKm += distanceKm;
  stats.totalRuns += 1;

  const yesterday = new Date(todayKey + 'T00:00:00Z');
  yesterday.setUTCDate(yesterday.getUTCDate() - 1);
  const yesterdayKey = yesterday.toISOString().slice(0, 10);

  if (stats.lastRunDate === todayKey) {
    // วิ่งซ้ำวันเดียวกัน ไม่นับ streak เพิ่ม
  } else if (stats.lastRunDate === yesterdayKey) {
    stats.currentStreakDays += 1;
  } else {
    stats.currentStreakDays = 1;
  }
  stats.lastRunDate = todayKey;

  stats.weeklyDistanceKm += distanceKm;
  if (!stats.weeklyRunDates.includes(todayKey)) {
    stats.weeklyRunDates.push(todayKey);
  }
  if (hour < 9) {
    stats.morningRunsThisWeek += 1;
  }

  if (hour >= 20 || hour < 5) {
    stats.hasNightRun = true;
  }
  if (distanceKm > 0) {
    const paceMinPerKm = (durationSec / 60) / distanceKm;
    if (paceMinPerKm > 0 && paceMinPerKm < 5.0) {
      stats.hasFastPace = true;
    }
  }

  const basePoints = Math.round(distanceKm * 10);
  stats.totalPoints += basePoints;
  let pointsEarned = basePoints;

  const newlyUnlockedBadges = [];
  for (const badge of BADGES) {
    if (!stats.achievedBadgeIds.includes(badge.id) && badge.isUnlocked(stats)) {
      stats.achievedBadgeIds.push(badge.id);
      newlyUnlockedBadges.push({ id: badge.id, emoji: badge.emoji, title: badge.title });
      stats.totalPoints += 50; // โบนัสปลดล็อกเหรียญ
      pointsEarned += 50;
    }
  }

  const newlyCompletedMissions = [];
  for (const mission of MISSIONS) {
    if (
      !stats.weeklyRewardedMissionIds.includes(mission.id) &&
      mission.currentValue(stats) >= mission.target
    ) {
      stats.weeklyRewardedMissionIds.push(mission.id);
      newlyCompletedMissions.push({ id: mission.id, title: mission.title, rewardPoints: mission.rewardPoints });
      stats.totalPoints += mission.rewardPoints;
      pointsEarned += mission.rewardPoints;
    }
  }

  await stats.save();
  return { stats, newlyUnlockedBadges, newlyCompletedMissions, pointsEarned };
}

module.exports = { getOrCreateStats, recordRunForStats, mondayKeyOf, todayKeyNow };
