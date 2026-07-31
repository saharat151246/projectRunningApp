const mongoose = require('mongoose');

const userMissionSchema = new mongoose.Schema(
  {
    user_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    title: { type: String, required: true, trim: true, maxlength: 80 },
    frequency: { type: String, enum: ['daily', 'weekly', 'monthly'], required: true },
    metric: { type: String, enum: ['distance', 'runs'], required: true },
    target: { type: Number, required: true, min: 0.1 },
    reward: { type: Number, default: 25, min: 0 },
  },
  { timestamps: true }
);

module.exports = mongoose.model('UserMission', userMissionSchema);
