require('dotenv').config();
const express = require('express');
const cors = require('cors');
const connectDB = require('./config/db');

const authRoutes = require('./routes/authRoutes');
const runRoutes = require('./routes/runRoutes');
const gamificationRoutes = require('./routes/gamificationRoutes');
const coachRoutes = require('./routes/coachRoutes');

const app = express();

connectDB();

app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.json({ message: 'Running App API is running 🏃' });
});

app.use('/api/auth', authRoutes);
app.use('/api/runs', runRoutes);
app.use('/api/gamification', gamificationRoutes);
app.use('/api/coach', coachRoutes);

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});
