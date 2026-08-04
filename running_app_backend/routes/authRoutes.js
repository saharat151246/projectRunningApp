const express = require('express');
const router = express.Router();
const { register, login, googleLogin, me, updateProfile } = require('../controllers/authController');
const requireAuth = require('../middleware/authMiddleware');

router.post('/register', register);
router.post('/login', login);
router.post('/google', googleLogin);
router.get('/me', requireAuth, me);
router.put('/me', requireAuth, updateProfile);

module.exports = router;
