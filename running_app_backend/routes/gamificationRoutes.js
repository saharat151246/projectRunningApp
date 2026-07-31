const express = require('express');
const router = express.Router();
const requireAuth = require('../middleware/authMiddleware');
const { getGamification, createMission, deleteMission } = require('../controllers/gamificationController');

router.use(requireAuth);
router.get('/', getGamification);
router.post('/missions', createMission);
router.delete('/missions/:id', deleteMission);

module.exports = router;
