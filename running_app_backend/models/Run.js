const mongoose = require('mongoose');

const MOOD_VALUES = ['exhausted', 'very_tired', 'good', 'great', 'chill'];

const runSchema = new mongoose.Schema(
  {
    user_id: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    start_time: { type: Date, required: true },
    end_time: { type: Date, required: true },
    distance_km: { type: Number, required: true },
    duration_sec: { type: Number, required: true },
    avg_pace: { type: Number, default: null },
    mood: { type: String, enum: MOOD_VALUES, default: null },
    note: { type: String, default: null, maxlength: 500 },
    sleep_hours: { type: Number, default: null, min: 0, max: 24 },
    stress_level: { type: String, enum: ['low', 'medium', 'high'], default: null },
    weather: { type: String, enum: ['cool', 'hot', 'rainy', 'normal'], default: null },
    route: [
      {
        lat: Number,
        lng: Number,
        timestamp: Date,
      },
    ],
  },
  { timestamps: true }
);

module.exports = mongoose.model('Run', runSchema);
module.exports.MOOD_VALUES = MOOD_VALUES;
