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

function buildCoachContext(runs, user = null) {
  const now = new Date();

  // คำนวณ BMI ของผู้ใช้
  let bmi = null;
  let bmiCategory = null;
  if (user?.weight && user?.height && user.height > 0) {
    const heightM = user.height / 100;
    bmi = Math.round((user.weight / (heightM * heightM)) * 10) / 10;
    if (bmi < 18.5) bmiCategory = 'น้ำหนักน้อย';
    else if (bmi < 23) bmiCategory = 'สมส่วน';
    else if (bmi < 25) bmiCategory = 'ท้วม';
    else bmiCategory = 'น้ำหนักเกินเกณฑ์';
  }

  const userProfileSummary = user
    ? `
ข้อมูลประจำตัวผู้ใช้:
- ชื่อ: ${user.name}
- อายุ: ${user.age ? `${user.age} ปี` : 'ไม่ได้ระบุ'}
- น้ำหนัก: ${user.weight ? `${user.weight} กก.` : 'ไม่ได้ระบุ'} | ส่วนสูง: ${user.height ? `${user.height} ซม.` : 'ไม่ได้ระบุ'}
- ค่า BMI: ${bmi ? `${bmi} (${bmiCategory})` : 'ไม่ได้ระบุ'}
- ระดับนักวิ่ง: ${user.level || 'คนทั่วไป'}
- เป้าหมายการวิ่ง: ${user.goal || 'เพื่อสุขภาพ'}
- โรคประจำตัว / ข้อจำกัดสุขภาพ: ${user.medical_condition && user.medical_condition.trim() !== '' ? user.medical_condition : 'ไม่มี'}
`.trim()
    : '';

  if (runs.length === 0) {
    const hasMed = user?.medical_condition && user.medical_condition.trim() !== '' && user.medical_condition !== 'ไม่มี';
    const fallback = `ยินดีต้อนรับคุณ ${user?.name || ''}! ยังไม่มีข้อมูลประวัติการวิ่ง ${hasMed ? `เนื่องจากมีบันทึกโรคประจำตัว (${user.medical_condition}) แนะนำให้เริ่มเดินสลับวิ่งเบาๆ และฟังร่างกายเสมอ` : 'ลองเริ่มวิ่งก้าวแรกเบาๆ วันนี้ได้เลย'} แล้ว AI Coach จะคอยติดตามและให้คำแนะนำส่วนบุคคลครับ 🏃✨`;

    return {
      stats: { totalRuns: 0 },
      promptSummary: `${userProfileSummary}\nผู้ใช้ยังไม่มีประวัติการวิ่งเลย (เพิ่งเริ่มต้น)`,
      fallbackMessage: fallback.trim(),
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

  // --- วิเคราะห์ recovery factors (ชั่วโมงนอน, ความเครียด, สภาพอากาศ) ---
  const lastRunWithRecovery = sortedDesc.find((r) => r.sleep_hours != null || r.stress_level || r.weather);
  const lastSleepHours = lastRunWithRecovery?.sleep_hours ?? null;
  const lastStressLevel = lastRunWithRecovery?.stress_level ?? null;
  const lastWeather = lastRunWithRecovery?.weather ?? null;

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
    lastSleepHours,
    lastStressLevel,
    lastWeather,
    moodCounts,
    fatigueSignal,
  };

  const promptSummary = `
${userProfileSummary ? `${userProfileSummary}\n` : ''}สถิติการวิ่งของผู้ใช้:
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
- สัญญาณเหนื่อยล้าสะสม (2 ใน 3 ครั้งล่าสุดรู้สึกเหนื่อย/เหนื่อยมาก): ${fatigueSignal ? 'ใช่' : 'ไม่'}
- ชั่วโมงนอนล่าสุด: ${lastSleepHours ? `${lastSleepHours} ชั่วโมง` : 'ไม่ได้บันทึก'}
- ระดับความเครียดล่าสุด: ${lastStressLevel ?? 'ไม่ได้บันทึก'}
- สภาพอากาศล่าสุด: ${lastWeather ?? 'ไม่ได้บันทึก'}
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
  if (lastSleepHours != null && lastSleepHours < 6) {
    fallbackParts.push(`ชั่วโมงนอนครั้งล่าสุดค่อนข้างน้อย (${lastSleepHours} ชม.) ควรระวังเรื่องการสะสมความเหนื่อยล้า`);
  }
  if (inactivityWarning) {
    fallbackParts.push(`คุณไม่ได้วิ่งมา ${daysSinceLastRun} วันแล้ว ลองกลับมาวิ่งเบาๆ อีกครั้งเพื่อรักษาความต่อเนื่อง`);
  }
  if (user?.medical_condition && user.medical_condition.trim() !== '' && user.medical_condition !== 'ไม่มี') {
    fallbackParts.push(`(ข้อควรระวังเรื่องสุขภาพ: อย่าลืมตรวจดูอาการ ${user.medical_condition} และหลีกเลี่ยงการหักโหมเกินขีดจำกัด)`);
  }
  if (fallbackParts.length === 0) {
    fallbackParts.push(
      `ภาพรวมการวิ่งของคุณตอนนี้อยู่ในเกณฑ์ดี วิ่งต่อเนื่อง ${currentStreakDays} วัน ระยะทางสัปดาห์นี้ ${stats.thisWeekKm} กม. มุ่งสู่เป้าหมาย${user?.goal || 'เพื่อสุขภาพ'}ได้ต่อเนื่องเลยครับ`
    );
  }

  return {
    stats,
    promptSummary,
    fallbackMessage: fallbackParts.join(' '),
  };
}

function buildFallbackDailyPlan(stats, user = null) {
  const isBeginner = user?.level === 'มือสมัครเล่น';
  const hasMedical = user?.medical_condition && user.medical_condition.trim() !== '' && user.medical_condition !== 'ไม่มี';

  if (stats.overtrainingRisk || stats.fatigueSignal || (stats.lastSleepHours != null && stats.lastSleepHours < 5)) {
    return {
      title: 'วันพักฟื้นร่างกาย (Active Recovery Day)',
      activityType: 'rest',
      targetDistanceKm: 0,
      targetPace: '-',
      rationale: 'ตรวจพบสัญญาณเหนื่อยล้าสะสมหรือนอนน้อย วันนี้แนะนำให้พักผ่อน ยืดเหยียดกล้ามเนื้อ หรือเดินเบาๆ เพื่อให้ร่างกายซ่อมแซมเต็มที่',
      tips: hasMedical
        ? `ดูแลอาการ ${user.medical_condition} เป็นพิเศษ จิบน้ำเรื่อยๆ และเข้านอนให้เร็วขึ้น`
        : 'จิบน้ำเรื่อยๆ และพยายามเข้านอนให้เร็วขึ้นในคืนนี้',
    };
  }
  if (stats.daysSinceLastRun >= 3) {
    return {
      title: 'วิ่งฟื้นฟูเบาๆ (Easy Comeback Run)',
      activityType: 'easy_run',
      targetDistanceKm: isBeginner ? 2.0 : 3.0,
      targetPace: isBeginner ? '7:30 - 8:30' : '6:45 - 7:30',
      rationale: 'ไม่ได้วิ่งมาหลายวันแล้ว แนะนำให้เริ่มต้นด้วยการวิ่งเหยาะๆ จังหวะสบายๆ เพื่อปรับสภาพร่างกาย',
      tips: 'ไม่ต้องเร่งความเร็ว เน้นหายใจสบายๆ คุยเป็นประโยคได้',
    };
  }

  // ปรับตามเป้าหมาย (Goal)
  if (user?.goal === 'เพื่อสร้างหุ่น') {
    return {
      title: 'วิ่งโซน 2 เบิร์นไขมัน (Fat Burning Zone 2)',
      activityType: 'easy_run',
      targetDistanceKm: isBeginner ? 3.0 : 5.0,
      targetPace: isBeginner ? '7:15 - 8:00' : '6:30 - 7:00',
      rationale: 'การวิ่งต่อเนื่องที่ความหนักปานกลาง (โซน 2) จะดึงไขมันมาใช้เป็นพลังงานได้มีประสิทธิภาพสูงสุดเพื่อสร้างหุ่น',
      tips: 'รักษาอัตราการเต้นหัวใจให้คงที่ สามารถพูดคุยได้โดยไม่หอบเหนื่อย',
    };
  }

  if (user?.goal === 'เพื่อแข่งขัน') {
    return {
      title: isBeginner ? 'วิ่งจับจังหวะสม่ำเสมอ (Pace Rhythm Run)' : 'วิ่งพัฒนาความเร็วและคงทน (Tempo Progression)',
      activityType: 'interval',
      targetDistanceKm: isBeginner ? 4.0 : 6.0,
      targetPace: isBeginner ? '6:30 - 7:00' : '5:45 - 6:15',
      rationale: 'ฝึกซ้อมคุมเพซให้คงที่ เพื่อเตรียมพร้อมสำหรับการลงแข่งขันและเพิ่มความอึดของกล้ามเนื้อ',
      tips: 'วอร์มอัพยืดเส้น 10 นาทีก่อนเริ่ม และคูลดาวน์ให้เพียงพอ',
    };
  }

  return {
    title: 'วิ่งเพื่อสร้างความคงทน (Aerobic Endurance Run)',
    activityType: 'easy_run',
    targetDistanceKm: isBeginner ? 3.0 : 5.0,
    targetPace: isBeginner ? '7:00 - 7:45' : '6:15 - 6:45',
    rationale: 'ร่างกายของคุณอยู่ในสภาพพร้อมซ้อม ซ้อมระยะทางกำลังดีที่โซน 2 เพื่อเพิ่มความแข็งแรงของหัวใจและสุขภาพโดยรวม',
    tips: 'วอร์มอัพ 5 นาที และคูลดาวน์หลังวิ่งเสร็จ',
  };
}

function computeLongTermInsights(runs) {
  const runsWithPace = runs.filter((r) => r.avg_pace != null && r.avg_pace > 0);
  
  // 1. Sleep Impact
  const goodSleepRuns = runsWithPace.filter((r) => r.sleep_hours != null && r.sleep_hours >= 7);
  const poorSleepRuns = runsWithPace.filter((r) => r.sleep_hours != null && r.sleep_hours < 6);

  const goodSleepAvgPace = goodSleepRuns.length > 0
    ? goodSleepRuns.reduce((s, r) => s + r.avg_pace, 0) / goodSleepRuns.length
    : null;
  const poorSleepAvgPace = poorSleepRuns.length > 0
    ? poorSleepRuns.reduce((s, r) => s + r.avg_pace, 0) / poorSleepRuns.length
    : null;

  let sleepPaceDiffSec = null;
  if (goodSleepAvgPace && poorSleepAvgPace) {
    // Pace is in minutes per km. Difference in seconds per km:
    sleepPaceDiffSec = Math.round((poorSleepAvgPace - goodSleepAvgPace) * 60);
  }

  // 2. Weather conditions
  const weatherMap = {};
  runsWithPace.forEach((r) => {
    if (r.weather) {
      if (!weatherMap[r.weather]) weatherMap[r.weather] = { count: 0, totalPace: 0 };
      weatherMap[r.weather].count += 1;
      weatherMap[r.weather].totalPace += r.avg_pace;
    }
  });

  let bestWeather = null;
  let bestWeatherPace = Infinity;
  Object.keys(weatherMap).forEach((w) => {
    const avg = weatherMap[w].totalPace / weatherMap[w].count;
    if (avg < bestWeatherPace) {
      bestWeatherPace = avg;
      bestWeather = w;
    }
  });

  // 3. Stress impact
  const lowStressRuns = runsWithPace.filter((r) => r.stress_level === 'low');
  const highStressRuns = runsWithPace.filter((r) => r.stress_level === 'high');

  const lowStressAvgPace = lowStressRuns.length > 0
    ? lowStressRuns.reduce((s, r) => s + r.avg_pace, 0) / lowStressRuns.length
    : null;
  const highStressAvgPace = highStressRuns.length > 0
    ? highStressRuns.reduce((s, r) => s + r.avg_pace, 0) / highStressRuns.length
    : null;

  return {
    totalRuns: runs.length,
    analyzedRunsCount: runsWithPace.length,
    goodSleepAvgPace: goodSleepAvgPace ? Math.round(goodSleepAvgPace * 100) / 100 : null,
    poorSleepAvgPace: poorSleepAvgPace ? Math.round(poorSleepAvgPace * 100) / 100 : null,
    sleepPaceDiffSec,
    bestWeather,
    lowStressAvgPace: lowStressAvgPace ? Math.round(lowStressAvgPace * 100) / 100 : null,
    highStressAvgPace: highStressAvgPace ? Math.round(highStressAvgPace * 100) / 100 : null,
  };
}

module.exports = { buildCoachContext, buildFallbackDailyPlan, computeLongTermInsights };
