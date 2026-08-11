const express = require('express');
const router = express.Router();
const requireAuth = require('../middleware/authMiddleware');
const { getCoachAdvice, getDailyPlan, getInsights, chat } = require('../controllers/coachController');

router.use(requireAuth);
router.get('/', getCoachAdvice);
router.get('/daily-plan', getDailyPlan);
router.get('/insights', getInsights);
router.post('/chat', chat);

module.exports = router;
