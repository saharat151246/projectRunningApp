const mongoose = require('mongoose');

const userStatsSchema = new mongoose.Schema(
  {
    user_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
    },
    totalDistanceKm: { type: Number, default: 0 },
    totalRuns: { type: Number, default: 0 },
    totalPoints: { type: Number, default: 0 },
    currentStreakDays: { type: Number, default: 0 },
    lastRunDate: { type: String, default: null }, // yyyy-MM-dd

    // event flags สำหรับเหรียญพิเศษ (คงอยู่ถาวรเมื่อปลดล็อกแล้ว)
    hasNightRun: { type: Boolean, default: false },
    hasFastPace: { type: Boolean, default: false },

    achievedBadgeIds: { type: [String], default: [] },

    // ตัวนับรายสัปดาห์ (รีเซ็ตทุกวันจันทร์)
    weekStart: { type: String, required: true }, // yyyy-MM-dd ของวันจันทร์
    weeklyDistanceKm: { type: Number, default: 0 },
    weeklyRunDates: { type: [String], default: [] },
    morningRunsThisWeek: { type: Number, default: 0 },
    weeklyRewardedMissionIds: { type: [String], default: [] },
  },
  { timestamps: true }
);

module.exports = mongoose.model('UserStats', userStatsSchema);
