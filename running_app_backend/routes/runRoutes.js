const express = require('express');
const router = express.Router();
const requireAuth = require('../middleware/authMiddleware');
const { createRun, getRuns, getSummary, getRunById, deleteRun, updateRun } = require('../controllers/runController');

// ทุก route ของ runs ต้องล็อกอินก่อนถึงจะใช้ได้
router.use(requireAuth);

router.post('/', createRun);
router.get('/', getRuns);
router.get('/summary', getSummary);
router.get('/:id', getRunById);
router.patch('/:id', updateRun);
router.delete('/:id', deleteRun);

module.exports = router;
