const express = require('express');
const router = express.Router();
const { register, login, me } = require('../controllers/authController');
const requireAuth = require('../middleware/authMiddleware');

router.post('/register', register);
router.post('/login', login);
router.get('/me', requireAuth, me);

// TODO: /google endpoint จะเพิ่มตอนต่อ Firebase/Google Sign-In จริง

module.exports = router;
