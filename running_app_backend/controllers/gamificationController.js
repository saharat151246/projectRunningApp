const Run = require('../models/Run');
const UserMission = require('../models/UserMission');
const { computeGamification } = require('../utils/gamification');

// GET /api/gamification  (ต้อง login ก่อน)
exports.getGamification = async (req, res) => {
  try {
    const runs = await Run.find({ user_id: req.userId }).select(
      'distance_km duration_sec start_time'
    );
    const personalMissions = await UserMission.find({ user_id: req.userId }).sort({ createdAt: -1 });
    const result = computeGamification(runs, personalMissions);
    res.json(result);
  } catch (err) {
    console.error('getGamification error:', err);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดฝั่งเซิร์ฟเวอร์' });
  }
};

exports.createMission = async (req, res) => {
  try {
    const { title, frequency, metric, target, reward } = req.body;
    if (!title?.trim() || !['daily', 'weekly', 'monthly'].includes(frequency) ||
        !['distance', 'runs'].includes(metric) || !Number.isFinite(Number(target)) || Number(target) <= 0) {
      return res.status(400).json({ message: 'ข้อมูลภารกิจไม่ถูกต้อง' });
    }

    const mission = await UserMission.create({
      user_id: req.userId,
      title: title.trim(),
      frequency,
      metric,
      target: Number(target),
      reward: Number.isFinite(Number(reward)) ? Number(reward) : 25,
    });
    res.status(201).json({ mission });
  } catch (err) {
    console.error('createMission error:', err);
    res.status(500).json({ message: 'ไม่สามารถสร้างภารกิจได้' });
  }
};

exports.deleteMission = async (req, res) => {
  try {
    const mission = await UserMission.findOneAndDelete({ _id: req.params.id, user_id: req.userId });
    if (!mission) return res.status(404).json({ message: 'ไม่พบภารกิจ' });
    res.json({ message: 'ลบภารกิจแล้ว' });
  } catch (err) {
    console.error('deleteMission error:', err);
    res.status(500).json({ message: 'ไม่สามารถลบภารกิจได้' });
  }
};
