const express = require('express');
const router = express.Router();
const requireAuth = require('../middleware/authMiddleware');
const { getCoachAdvice, chat } = require('../controllers/coachController');

router.use(requireAuth);
router.get('/', getCoachAdvice);
router.post('/chat', chat);

module.exports = router;
