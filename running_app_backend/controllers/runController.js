const Run = require('../models/Run');
const { MOOD_VALUES } = Run;

// POST /api/runs
exports.createRun = async (req, res) => {
  try {
    const { start_time, end_time, distance_km, duration_sec, avg_pace, route } = req.body;

    if (!start_time || !end_time || distance_km == null || duration_sec == null) {
      return res.status(400).json({ message: 'ข้อมูลการวิ่งไม่ครบ (ต้องมี start_time, end_time, distance_km, duration_sec)' });
    }

    const run = await Run.create({
      user_id: req.userId,
      start_time,
      end_time,
      distance_km,
      duration_sec,
      avg_pace: avg_pace ?? null,
      route: route || [],
    });

    res.status(201).json({ run });
  } catch (err) {
    console.error('createRun error:', err);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดฝั่งเซิร์ฟเวอร์' });
  }
};

// GET /api/runs
exports.getRuns = async (req, res) => {
  try {
    const runs = await Run.find({ user_id: req.userId })
      .sort({ start_time: -1 })
      .limit(50);
    res.json({ runs });
  } catch (err) {
    console.error('getRuns error:', err);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดฝั่งเซิร์ฟเวอร์' });
  }
};

// GET /api/runs/summary
// สรุประยะทางรวมทั้งหมด + ระยะทางรายวันของ 7 วันล่าสุด (ไว้ทำกราฟ)
exports.getSummary = async (req, res) => {
  try {
    const runs = await Run.find({ user_id: req.userId }).sort({ start_time: -1 });

    const totalRuns = runs.length;
    const totalDistanceKm = runs.reduce((sum, r) => sum + r.distance_km, 0);

    const now = new Date();
    const dayKeys = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date(now);
      d.setDate(d.getDate() - i);
      dayKeys.push(d.toISOString().slice(0, 10));
    }

    const weeklyMap = Object.fromEntries(dayKeys.map((k) => [k, 0]));
    runs.forEach((r) => {
      const key = new Date(r.start_time).toISOString().slice(0, 10);
      if (weeklyMap[key] !== undefined) weeklyMap[key] += r.distance_km;
    });
    const weeklyDistance = dayKeys.map((k) => Math.round(weeklyMap[k] * 100) / 100);

    res.json({
      totalRuns,
      totalDistanceKm: Math.round(totalDistanceKm * 100) / 100,
      weeklyDistance,
      weekLabels: dayKeys,
    });
  } catch (err) {
    console.error('getSummary error:', err);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดฝั่งเซิร์ฟเวอร์' });
  }
};

// GET /api/runs/:id  (ดึงรายละเอียดการวิ่งครั้งเดียว รวมเส้นทาง GPS เต็ม)
exports.getRunById = async (req, res) => {
  try {
    const run = await Run.findOne({ _id: req.params.id, user_id: req.userId });
    if (!run) {
      return res.status(404).json({ message: 'ไม่พบข้อมูลการวิ่งนี้' });
    }
    res.json({ run });
  } catch (err) {
    console.error('getRunById error:', err);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดฝั่งเซิร์ฟเวอร์' });
  }
};

// DELETE /api/runs/:id
exports.deleteRun = async (req, res) => {
  try {
    const run = await Run.findOneAndDelete({ _id: req.params.id, user_id: req.userId });
    if (!run) {
      return res.status(404).json({ message: 'ไม่พบข้อมูลการวิ่งนี้' });
    }
    res.json({ message: 'ลบข้อมูลการวิ่งแล้ว' });
  } catch (err) {
    console.error('deleteRun error:', err);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดฝั่งเซิร์ฟเวอร์' });
  }
};

// PATCH /api/runs/:id  (เช็คอินความรู้สึกหลังวิ่ง - mood + note + recovery)
exports.updateRun = async (req, res) => {
  try {
    const { mood, note, sleep_hours, stress_level, weather } = req.body;

    if (mood !== undefined && mood !== null && !MOOD_VALUES.includes(mood)) {
      return res.status(400).json({
        message: `mood ต้องเป็นหนึ่งใน: ${MOOD_VALUES.join(', ')}`,
      });
    }
    if (note !== undefined && note !== null && String(note).length > 500) {
      return res.status(400).json({ message: 'note ต้องไม่เกิน 500 ตัวอักษร' });
    }
    if (stress_level !== undefined && stress_level !== null && !['low', 'medium', 'high'].includes(stress_level)) {
      return res.status(400).json({ message: 'stress_level ต้องเป็น low, medium, หรือ high' });
    }
    if (weather !== undefined && weather !== null && !['cool', 'hot', 'rainy', 'normal'].includes(weather)) {
      return res.status(400).json({ message: 'weather ต้องเป็น cool, hot, rainy, หรือ normal' });
    }

    const update = {};
    if (mood !== undefined) update.mood = mood;
    if (note !== undefined) update.note = note;
    if (sleep_hours !== undefined) update.sleep_hours = sleep_hours != null ? Number(sleep_hours) : null;
    if (stress_level !== undefined) update.stress_level = stress_level;
    if (weather !== undefined) update.weather = weather;

    const run = await Run.findOneAndUpdate(
      { _id: req.params.id, user_id: req.userId },
      { $set: update },
      { new: true }
    );

    if (!run) {
      return res.status(404).json({ message: 'ไม่พบข้อมูลการวิ่งนี้' });
    }

    res.json({ run });
  } catch (err) {
    console.error('updateRun error:', err);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดฝั่งเซิร์ฟเวอร์' });
  }
};
