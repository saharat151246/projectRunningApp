const jwt = require('jsonwebtoken');

/// ตรวจสอบ JWT จาก header "Authorization: Bearer <token>"
/// ถ้าถูกต้อง จะแนบ req.userId ไว้ให้ controller ถัดไปใช้
module.exports = function requireAuth(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'ไม่พบ token กรุณาเข้าสู่ระบบ' });
  }

  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = decoded.id;
    next();
  } catch (err) {
    return res.status(401).json({ message: 'Token ไม่ถูกต้องหรือหมดอายุ' });
  }
};
