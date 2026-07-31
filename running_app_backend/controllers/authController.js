const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

function signToken(user) {
  return jwt.sign(
    { id: user._id, email: user.email },
    process.env.JWT_SECRET,
    { expiresIn: '30d' }
  );
}

function toPublicUser(user) {
  return {
    id: user._id,
    name: user.name,
    email: user.email,
    auth_provider: user.auth_provider,
    avatar_url: user.avatar_url,
    email_verified: user.email_verified,
    weight: user.weight,
    height: user.height,
    age: user.age,
    gender: user.gender,
  };
}

// POST /api/auth/register
exports.register = async (req, res) => {
  try {
    const { name, email, password } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ message: 'กรุณากรอกชื่อ, อีเมล และรหัสผ่านให้ครบ' });
    }
    if (password.length < 8) {
      return res.status(400).json({ message: 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร' });
    }

    const existing = await User.findOne({ email: email.toLowerCase() });
    if (existing) {
      return res.status(409).json({ message: 'อีเมลนี้ถูกใช้สมัครไปแล้ว' });
    }

    const password_hash = await bcrypt.hash(password, 10);

    const user = await User.create({
      name,
      email: email.toLowerCase(),
      password_hash,
      auth_provider: 'email',
    });

    const token = signToken(user);
    res.status(201).json({ token, user: toPublicUser(user) });
  } catch (err) {
    console.error('register error:', err);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดฝั่งเซิร์ฟเวอร์' });
  }
};

// POST /api/auth/login
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'กรุณากรอกอีเมลและรหัสผ่าน' });
    }

    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user || !user.password_hash) {
      return res.status(401).json({ message: 'อีเมลหรือรหัสผ่านไม่ถูกต้อง' });
    }

    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      return res.status(401).json({ message: 'อีเมลหรือรหัสผ่านไม่ถูกต้อง' });
    }

    const token = signToken(user);
    res.json({ token, user: toPublicUser(user) });
  } catch (err) {
    console.error('login error:', err);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดฝั่งเซิร์ฟเวอร์' });
  }
};

// GET /api/auth/me  (ต้องแนบ JWT ผ่าน middleware ก่อน)
exports.me = async (req, res) => {
  try {
    const user = await User.findById(req.userId);
    if (!user) return res.status(404).json({ message: 'ไม่พบผู้ใช้' });
    res.json({ user: toPublicUser(user) });
  } catch (err) {
    console.error('me error:', err);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดฝั่งเซิร์ฟเวอร์' });
  }
};
