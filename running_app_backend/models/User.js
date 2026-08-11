const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    password_hash: { type: String, default: null },
    auth_provider: { type: String, enum: ['email', 'google'], default: 'email' },
    google_id: { type: String, default: null },
    avatar_url: { type: String, default: null },
    email_verified: { type: Boolean, default: false },
    weight: { type: Number, default: null },
    height: { type: Number, default: null },
    age: { type: Number, default: null },
    gender: { type: String, default: null },
    reset_otp: { type: String, default: null },
    reset_otp_expires: { type: Date, default: null },
  },
  { timestamps: true }
);

module.exports = mongoose.model('User', userSchema);
