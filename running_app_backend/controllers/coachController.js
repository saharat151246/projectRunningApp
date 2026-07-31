const Run = require('../models/Run');
const { buildCoachContext } = require('../utils/aiCoach');

const GEMINI_MODEL = 'gemini-3.1-flash-lite';

const SYSTEM_PROMPT = `คุณคือ AI Coach ผู้ช่วยแนะนำการฝึกซ้อมวิ่งในแอปพลิเคชันวิ่ง
กติกา:
- ตอบเป็นภาษาไทย กระชับ 3-4 ประโยค เป็นกันเองเหมือนโค้ชที่ห่วงใย
- เน้นความปลอดภัยและการลดความเสี่ยงบาดเจ็บเป็นอันดับแรก
- ห้ามให้คำวินิจฉัยทางการแพทย์ใดๆ ถ้าพบสัญญาณที่น่ากังวลมาก ให้แนะนำให้ปรึกษาแพทย์/ผู้เชี่ยวชาญแทน
- ใช้ตัวเลขสถิติที่ให้มาประกอบคำแนะนำให้เป็นรูปธรรม
- ถ้ามีข้อมูลความรู้สึกหลังวิ่ง (mood) ที่ผู้ใช้เช็คอินไว้ ให้นำมาพิจารณาร่วมกับสถิติระยะทาง ไม่ใช่ดูแค่ตัวเลขอย่างเดียว
- ห้ามใส่คำนำหรือคำลงท้ายแบบ "แน่นอนครับ" ตอบเนื้อหาคำแนะนำโดยตรง`;

const CHAT_SYSTEM_PROMPT = `คุณคือ AI Coach ผู้ช่วยตอบคำถามเกี่ยวกับการออกกำลังกายในแอปพลิเคชันวิ่ง
กติกา:
- ตอบเฉพาะเรื่องการออกกำลังกาย การวิ่ง การฝึกซ้อม โภชนาการเพื่อการออกกำลังกาย การพักฟื้น และการป้องกันการบาดเจ็บเท่านั้น
- ถ้าคำถามไม่เกี่ยวกับเรื่องเหล่านี้เลย ให้ตอบสุภาพว่าคุณช่วยได้เฉพาะเรื่องการออกกำลังกาย แล้วชวนกลับมาคุยเรื่องนั้น
- ตอบเป็นภาษาไทย กระชับ เข้าใจง่าย เป็นกันเอง ไม่ต้องยาวเกินความจำเป็น
- ห้ามวินิจฉัยอาการทางการแพทย์ ถ้าผู้ใช้เล่าอาการที่น่ากังวล (เช่น เจ็บหน้าอก, หายใจไม่ออก) ให้แนะนำให้ไปพบแพทย์ทันที
- คุณรู้ข้อมูลสถิติการวิ่งของผู้ใช้คนนี้ด้วย (ให้ไว้ด้านล่าง) ใช้ประกอบคำตอบเมื่อเกี่ยวข้อง แต่ไม่ต้องท่องซ้ำทุกครั้งถ้าคำถามไม่เกี่ยวกับสถิติของเขา`;

async function callGemini(promptSummary) {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    throw new Error('GEMINI_API_KEY ไม่ถูกตั้งค่า');
  }

  const url = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${apiKey}`;

  const body = {
    system_instruction: { parts: [{ text: SYSTEM_PROMPT }] },
    contents: [
      {
        role: 'user',
        parts: [{ text: `นี่คือสถิติการวิ่งของผู้ใช้:\n${promptSummary}\n\nช่วยให้คำแนะนำการฝึกซ้อมหน่อย` }],
      },
    ],
  };

  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`Gemini API error ${res.status}: ${errText}`);
  }

  const data = await res.json();
  const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text) {
    throw new Error('Gemini ไม่ส่งข้อความกลับมา');
  }
  return text.trim();
}

/// เรียก Gemini แบบ multi-turn สำหรับหน้า Chat
/// history: [{ role: 'user'|'model', text: string }, ...] เรียงเก่า->ใหม่ (ไม่รวมข้อความล่าสุด)
async function callGeminiChat({ history, message, statsSummary }) {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    throw new Error('GEMINI_API_KEY ไม่ถูกตั้งค่า');
  }

  const url = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${apiKey}`;

  const contents = [
    ...history.map((h) => ({
      role: h.role === 'assistant' ? 'model' : 'user',
      parts: [{ text: h.text }],
    })),
    { role: 'user', parts: [{ text: message }] },
  ];

  const body = {
    system_instruction: {
      parts: [{ text: `${CHAT_SYSTEM_PROMPT}\n\nสถิติผู้ใช้:\n${statsSummary}` }],
    },
    contents,
  };

  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`Gemini API error ${res.status}: ${errText}`);
  }

  const data = await res.json();
  const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text) {
    throw new Error('Gemini ไม่ส่งข้อความกลับมา');
  }
  return text.trim();
}

// GET /api/coach  (ต้อง login ก่อน)
exports.getCoachAdvice = async (req, res) => {
  try {
    const runs = await Run.find({ user_id: req.userId }).select(
      'distance_km duration_sec start_time mood'
    );

    const { stats, promptSummary, fallbackMessage } = buildCoachContext(runs);

    // ไม่มีข้อมูลวิ่งเลย ไม่ต้องเรียก Gemini ให้เปลือง quota
    if (stats.totalRuns === 0) {
      return res.json({ advice: fallbackMessage, stats, source: 'rule-based' });
    }

    try {
      const advice = await callGemini(promptSummary);
      return res.json({ advice, stats, source: 'gemini' });
    } catch (aiErr) {
      // Gemini ใช้ไม่ได้ (ไม่มี key, หมด quota, network error ฯลฯ) -> ใช้ rule-based แทน ไม่ทำให้ request fail
      console.warn('Gemini call failed, falling back to rule-based:', aiErr.message);
      return res.json({ advice: fallbackMessage, stats, source: 'rule-based' });
    }
  } catch (err) {
    console.error('getCoachAdvice error:', err);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดฝั่งเซิร์ฟเวอร์' });
  }
};

// POST /api/coach/chat  (ต้อง login ก่อน)
// body: { message: string, history?: [{ role: 'user'|'assistant', text: string }] }
exports.chat = async (req, res) => {
  try {
    const { message, history } = req.body;
    if (!message || typeof message !== 'string' || !message.trim()) {
      return res.status(400).json({ message: 'กรุณาส่งข้อความคำถาม' });
    }

    const runs = await Run.find({ user_id: req.userId }).select(
      'distance_km duration_sec start_time mood'
    );
    const { promptSummary } = buildCoachContext(runs);

    try {
      const reply = await callGeminiChat({
        history: Array.isArray(history) ? history.slice(-10) : [],
        message: message.trim(),
        statsSummary: promptSummary,
      });
      return res.json({ reply, available: true });
    } catch (aiErr) {
      console.warn('Gemini chat call failed:', aiErr.message);
      return res.json({
        reply:
          'ขออภัยครับ ตอนนี้ระบบแชทยังใช้งานไม่ได้ (อาจเกิดจากยังไม่ได้ตั้งค่า Gemini API Key หรือใช้ครบโควต้าวันนี้แล้ว) ลองใหม่อีกครั้งภายหลังนะครับ',
        available: false,
      });
    }
  } catch (err) {
    console.error('chat error:', err);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดฝั่งเซิร์ฟเวอร์' });
  }
};
