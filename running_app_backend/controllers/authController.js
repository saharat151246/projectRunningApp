const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { OAuth2Client } = require('google-auth-library');
const User = require('../models/User');

const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

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

// POST /api/auth/google
// รับ Google ID token จากฝั่ง Flutter (ผ่าน google_sign_in package)
// body: { "id_token": "..." }
exports.googleLogin = async (req, res) => {
  try {
    const { id_token } = req.body;

    if (!id_token) {
      return res.status(400).json({ message: 'กรุณาแนบ id_token' });
    }
    if (!process.env.GOOGLE_CLIENT_ID) {
      console.error('googleLogin error: GOOGLE_CLIENT_ID ยังไม่ได้ตั้งค่าใน .env');
      return res.status(500).json({ message: 'เซิร์ฟเวอร์ยังไม่ได้ตั้งค่า Google Sign-In' });
    }

    // ตรวจสอบ id_token กับ Google โดยตรง (verify signature + audience)
    // ป้องกันการปลอมแปลง token ฝั่ง client
    let payload;
    try {
      const ticket = await googleClient.verifyIdToken({
        idToken: id_token,
        audience: process.env.GOOGLE_CLIENT_ID,
      });
      payload = ticket.getPayload();
    } catch (verifyErr) {
      return res.status(401).json({ message: 'id_token ไม่ถูกต้องหรือหมดอายุ' });
    }

    if (!payload?.email) {
      return res.status(401).json({ message: 'ไม่พบอีเมลใน id_token' });
    }

    const email = payload.email.toLowerCase();
    const googleId = payload.sub;

    // หา user จาก google_id ก่อน ถ้าไม่เจอค่อยหาจาก email (เผื่อเคยสมัครด้วย email มาก่อน)
    let user = await User.findOne({ google_id: googleId });

    if (!user) {
      user = await User.findOne({ email });

      if (user) {
        // เคยสมัครด้วย email/password มาก่อน -> ผูก google_id เพิ่มเข้าไปในบัญชีเดิม
        user.google_id = googleId;
        user.auth_provider = user.auth_provider === 'email' ? user.auth_provider : 'google';
        if (!user.avatar_url && payload.picture) user.avatar_url = payload.picture;
        if (payload.email_verified) user.email_verified = true;
        await user.save();
      } else {
        // ยังไม่เคยสมัคร -> สร้าง user ใหม่ (ไม่มี password_hash เพราะ login ผ่าน google)
        user = await User.create({
          name: payload.name || email.split('@')[0],
          email,
          password_hash: null,
          auth_provider: 'google',
          google_id: googleId,
          avatar_url: payload.picture || null,
          email_verified: !!payload.email_verified,
        });
      }
    }

    const token = signToken(user);
    res.json({ token, user: toPublicUser(user) });
  } catch (err) {
    console.error('googleLogin error:', err);
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
