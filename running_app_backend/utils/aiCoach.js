/// คำนวณสถิติเชิงกฎ (rule-based) จากข้อมูล runs จริง แล้วเตรียมเป็น context
/// สำหรับส่งให้ Gemini สรุปเป็นคำแนะนำภาษาธรรมชาติ
/// ถ้า Gemini ใช้ไม่ได้ (ไม่มี key/error) จะ fallback ไปใช้ fallbackMessage ที่สร้างจากกฎล้วนๆ แทน

const MOOD_LABELS = {
  exhausted: 'เหนื่อย',
  very_tired: 'เหนื่อยมาก',
  good: 'ดี',
  great: 'เยี่ยม',
  chill: 'ไหวชิล',
};

// mood ที่ถือว่าเป็นสัญญาณความเหนื่อยล้าสะสม (ใช้ร่วมกับสถิติระยะทางในการประเมินความเสี่ยง)
const FATIGUE_MOODS = ['exhausted', 'very_tired'];

function daysBetween(a, b) {
  return Math.floor((a.getTime() - b.getTime()) / (1000 * 60 * 60 * 24));
}

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

function buildCoachContext(runs) {
  const now = new Date();

  if (runs.length === 0) {
    return {
      stats: { totalRuns: 0 },
      promptSummary: 'ผู้ใช้ยังไม่มีประวัติการวิ่งเลย',
      fallbackMessage:
        'ยังไม่มีข้อมูลการวิ่งของคุณเลย ลองเริ่มวิ่งครั้งแรกดูก่อน แล้วกลับมาดูคำแนะนำที่นี่ได้เลย 🏃',
    };
  }

  const sortedDesc = [...runs].sort((a, b) => new Date(b.start_time) - new Date(a.start_time));
  const totalRuns = runs.length;
  const totalDistanceKm = runs.reduce((s, r) => s + r.distance_km, 0);
  const longestRunKm = Math.max(...runs.map((r) => r.distance_km));

  const totalDurationSec = runs.reduce((s, r) => s + r.duration_sec, 0);
  const avgPaceMinPerKm =
    totalDistanceKm > 0 ? totalDurationSec / 60 / totalDistanceKm : null;

  const daysSinceLastRun = daysBetween(now, new Date(sortedDesc[0].start_time));

  const dayKeysDesc = sortedDesc.map((r) => new Date(r.start_time).toISOString().slice(0, 10));
  const currentStreakDays = calcStreak(dayKeysDesc);

  // ระยะทางสัปดาห์นี้ vs สัปดาห์ก่อน (ใช้กฎ "เพิ่มไม่เกิน 10% ต่อสัปดาห์" ของนักวิ่ง)
  const last7 = runs.filter((r) => daysBetween(now, new Date(r.start_time)) <= 6);
  const prev7 = runs.filter((r) => {
    const d = daysBetween(now, new Date(r.start_time));
    return d > 6 && d <= 13;
  });
  const thisWeekKm = last7.reduce((s, r) => s + r.distance_km, 0);
  const lastWeekKm = prev7.reduce((s, r) => s + r.distance_km, 0);

  let weeklyChangePercent = null;
  if (lastWeekKm > 0) {
    weeklyChangePercent = ((thisWeekKm - lastWeekKm) / lastWeekKm) * 100;
  }

  const overtrainingRisk = weeklyChangePercent !== null && weeklyChangePercent > 10;
  const inactivityWarning = daysSinceLastRun >= 3;

  // --- วิเคราะห์ความรู้สึกหลังวิ่ง (mood check-in) ที่ผู้ใช้บันทึกไว้ ---
  const runsWithMood = sortedDesc.filter((r) => r.mood);
  const lastMood = runsWithMood.length > 0 ? runsWithMood[0].mood : null;

  const moodCounts = {};
  runsWithMood.forEach((r) => {
    moodCounts[r.mood] = (moodCounts[r.mood] || 0) + 1;
  });

  // เช็คว่าใน 3 ครั้งล่าสุดที่มีการเช็คอิน มีกี่ครั้งที่รู้สึกเหนื่อย/เหนื่อยมาก
  const recentMoodSample = runsWithMood.slice(0, 3);
  const recentFatigueCount = recentMoodSample.filter((r) => FATIGUE_MOODS.includes(r.mood)).length;
  // สัญญาณเตือน: อย่างน้อย 2 ใน 3 ครั้งล่าสุดรู้สึกเหนื่อย/เหนื่อยมาก -> ร่างกายส่งสัญญาณเหนื่อยล้าสะสม
  const fatigueSignal = recentMoodSample.length >= 2 && recentFatigueCount >= 2;

  const stats = {
    totalRuns,
    totalDistanceKm: Math.round(totalDistanceKm * 100) / 100,
    longestRunKm: Math.round(longestRunKm * 100) / 100,
    avgPaceMinPerKm: avgPaceMinPerKm ? Math.round(avgPaceMinPerKm * 100) / 100 : null,
    daysSinceLastRun,
    currentStreakDays,
    thisWeekKm: Math.round(thisWeekKm * 100) / 100,
    lastWeekKm: Math.round(lastWeekKm * 100) / 100,
    weeklyChangePercent:
      weeklyChangePercent !== null ? Math.round(weeklyChangePercent * 10) / 10 : null,
    overtrainingRisk,
    inactivityWarning,
    lastMood,
    moodCounts,
    fatigueSignal,
  };

  const promptSummary = `
- จำนวนครั้งที่วิ่งทั้งหมด: ${totalRuns} ครั้ง
- ระยะทางรวม: ${stats.totalDistanceKm} กม.
- วิ่งไกลที่สุดครั้งเดียว: ${stats.longestRunKm} กม.
- เพซเฉลี่ยรวม: ${stats.avgPaceMinPerKm ?? '-'} นาที/กม.
- วิ่งต่อเนื่อง: ${currentStreakDays} วัน
- ไม่ได้วิ่งมาแล้ว: ${daysSinceLastRun} วัน
- ระยะทางสัปดาห์นี้: ${stats.thisWeekKm} กม. (สัปดาห์ก่อน: ${stats.lastWeekKm} กม., เปลี่ยนแปลง ${stats.weeklyChangePercent ?? '-'}%)
- เสี่ยง overtraining (เพิ่มระยะทางเกิน 10%/สัปดาห์): ${overtrainingRisk ? 'ใช่' : 'ไม่'}
- ไม่ได้วิ่งเกิน 3 วัน: ${inactivityWarning ? 'ใช่' : 'ไม่'}
- ความรู้สึกหลังวิ่งครั้งล่าสุด: ${lastMood ? MOOD_LABELS[lastMood] : 'ไม่ได้เช็คอินไว้'}
- สัญญาณเหนื่อยล้าสะสมจากการเช็คอินความรู้สึก (2 ใน 3 ครั้งล่าสุดรู้สึกเหนื่อย/เหนื่อยมาก): ${fatigueSignal ? 'ใช่' : 'ไม่'}
`.trim();

  // ข้อความสำรอง (rule-based ล้วน) เผื่อ Gemini เรียกไม่สำเร็จ
  const fallbackParts = [];
  if (overtrainingRisk && fatigueSignal) {
    fallbackParts.push(
      `สัปดาห์นี้คุณวิ่งเพิ่มขึ้น ${stats.weeklyChangePercent}% จากสัปดาห์ก่อน และยังรู้สึกเหนื่อยล้าต่อเนื่องจากการเช็คอินล่าสุดหลายครั้ง สัญญาณทั้งสองอย่างนี้บ่งชี้ความเสี่ยงบาดเจ็บสูง แนะนำให้พักหรือลดความหนักลงทันที`
    );
  } else if (overtrainingRisk) {
    fallbackParts.push(
      `สัปดาห์นี้คุณวิ่งเพิ่มขึ้น ${stats.weeklyChangePercent}% จากสัปดาห์ก่อน ซึ่งเกินกฎ "เพิ่มไม่เกิน 10% ต่อสัปดาห์" แนะนำให้ลดความหนักลงหรือพักเพิ่ม เพื่อลดความเสี่ยงบาดเจ็บ`
    );
  } else if (fatigueSignal) {
    fallbackParts.push(
      `จากการเช็คอินความรู้สึกหลังวิ่งล่าสุดหลายครั้ง คุณรู้สึกเหนื่อย/เหนื่อยมากต่อเนื่อง แม้ระยะทางจะยังไม่ได้เพิ่มขึ้นเกินเกณฑ์ ก็ควรฟังร่างกายตัวเองและพิจารณาพักฟื้นเพิ่มเติม`
    );
  }
  if (inactivityWarning) {
    fallbackParts.push(`คุณไม่ได้วิ่งมา ${daysSinceLastRun} วันแล้ว ลองกลับมาวิ่งเบาๆ อีกครั้งเพื่อรักษาความต่อเนื่อง`);
  }
  if (fallbackParts.length === 0) {
    fallbackParts.push(
      `ภาพรวมการวิ่งของคุณตอนนี้อยู่ในเกณฑ์ดี วิ่งต่อเนื่อง ${currentStreakDays} วัน ระยะทางสัปดาห์นี้ ${stats.thisWeekKm} กม. ทำต่อไปแบบนี้ได้เลย`
    );
  }

  return {
    stats,
    promptSummary,
    fallbackMessage: fallbackParts.join(' '),
  };
}

module.exports = { buildCoachContext };
