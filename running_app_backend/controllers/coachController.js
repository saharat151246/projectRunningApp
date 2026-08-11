const Run = require('../models/Run');
const { buildCoachContext, buildFallbackDailyPlan } = require('../utils/aiCoach');

const GEMINI_MODEL = 'gemini-3.1-flash-lite';

const SYSTEM_PROMPT = `คุณคือ AI Coach ผู้ช่วยแนะนำการฝึกซ้อมวิ่งในแอปพลิเคชันวิ่ง
กติกา:
- ตอบเป็นภาษาไทย กระชับ 3-4 ประโยค เป็นกันเองเหมือนโค้ชที่ห่วงใย
- เน้นความปลอดภัยและการลดความเสี่ยงบาดเจ็บเป็นอันดับแรก
- ห้ามให้คำวินิจฉัยทางการแพทย์ใดๆ ถ้าพบสัญญาณที่น่ากังวลมาก ให้แนะนำให้ปรึกษาแพทย์/ผู้เชี่ยวชาญแทน
- ใช้ตัวเลขสถิติที่ให้มาประกอบคำแนะนำให้เป็นรูปธรรม
- ถ้ามีข้อมูลความรู้สึกหลังวิ่ง (mood), ชั่วโมงนอน (sleep_hours), ความเครียด (stress_level) ที่ผู้ใช้เช็คอินไว้ ให้นำมาพิจารณาร่วมกับสถิติระยะทาง ไม่ใช่ดูแค่ตัวเลขอย่างเดียว
- ห้ามใส่คำนำหรือคำลงท้ายแบบ "แน่นอนครับ" ตอบเนื้อหาคำแนะนำโดยตรง`;

const CHAT_SYSTEM_PROMPT = `คุณคือ AI Coach ผู้ช่วยตอบคำถามเกี่ยวกับการออกกำลังกายในแอปพลิเคชันวิ่ง
กติกา:
- ตอบเฉพาะเรื่องการออกกำลังกาย การวิ่ง การฝึกซ้อม โภชนาการเพื่อการออกกำลังกาย การพักฟื้น และการป้องกันการบาดเจ็บเท่านั้น
- ถ้าคำถามไม่เกี่ยวกับเรื่องเหล่านี้เลย ให้ตอบสุภาพว่าคุณช่วยได้เฉพาะเรื่องการออกกำลังกาย แล้วชวนกลับมาคุยเรื่องนั้น
- ตอบเป็นภาษาไทย กระชับ เข้าใจง่าย เป็นกันเอง ไม่ต้องยาวเกินความจำเป็น
- ห้ามวินิจฉัยอาการทางการแพทย์ ถ้าผู้ใช้เล่าอาการที่น่ากังวล (เช่น เจ็บหน้าอก, หายใจไม่ออก) ให้แนะนำให้ไปพบแพทย์ทันที
- คุณรู้ข้อมูลสถิติการวิ่งของผู้ใช้คนนี้ด้วย (ให้ไว้ด้านล่าง) ใช้ประกอบคำตอบเมื่อเกี่ยวข้อง แต่ไม่ต้องท่องซ้ำทุกครั้งถ้าคำถามไม่เกี่ยวกับสถิติของเขา`;

const DAILY_PLAN_PROMPT = `คุณคือ AI Coach ที่เชี่ยวชาญด้านการวางแผนซ้อมวิ่งรายวัน
จงสร้างแผนซ้อมสำหรับวันนี้ให้ผู้ใช้ โดยพิจารณาจากสถิติและข้อมูลการพักฟื้นล่าสุด (ชั่วโมงนอน, ความเครียด, ความเหนื่อยล้าสะสม, overtraining risk)
ข้อบังคับ: ตอบเป็น JSON เท่านั้น รูปแบบ:
{
  "title": "ชื่อแผนซ้อมเป็นภาษาไทย (กระชับ 3-5 คำ)",
  "activityType": "easy_run" | "interval" | "long_run" | "rest",
  "targetDistanceKm": 4.5 (เป็นตัวเลข 0 ถ้าเป็นวันพัก),
  "targetPace": "6:15 - 6:45" (หรือ "-" ถ้าเป็นวันพัก),
  "rationale": "เหตุผลว่าทำไมวันนี้ถึงแนะนำแผนนี้ (อิงจากนอน/ความเครียด/ความเหนื่อยสะสม 1-2 ประโยค)",
  "tips": "คำแนะนำเพิ่มเติมสั้นๆ 1 ประโยค"
}`;

async function callGeminiDailyPlan(promptSummary) {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) throw new Error('GEMINI_API_KEY ไม่ถูกตั้งค่า');

  const url = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${apiKey}`;

  const body = {
    system_instruction: { parts: [{ text: DAILY_PLAN_PROMPT }] },
    contents: [
      {
        role: 'user',
        parts: [{ text: `นี่คือสถิติและข้อมูลการพักฟื้นของผู้ใช้:\n${promptSummary}\n\nช่วยสร้างแผนซ้อม JSON สำหรับวันนี้` }],
      },
    ],
    generationConfig: { responseMimeType: 'application/json' },
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
  if (!text) throw new Error('Gemini ไม่ส่งข้อความกลับมา');
  return JSON.parse(text);
}

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
      'distance_km duration_sec start_time mood note sleep_hours stress_level weather'
    );

    const { stats, promptSummary, fallbackMessage } = buildCoachContext(runs);

    if (stats.totalRuns === 0) {
      return res.json({ advice: fallbackMessage, stats, source: 'rule-based' });
    }

    try {
      const advice = await callGemini(promptSummary);
      return res.json({ advice, stats, source: 'gemini' });
    } catch (aiErr) {
      console.warn('Gemini call failed, falling back to rule-based:', aiErr.message);
      return res.json({ advice: fallbackMessage, stats, source: 'rule-based' });
    }
  } catch (err) {
    console.error('getCoachAdvice error:', err);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดฝั่งเซิร์ฟเวอร์' });
  }
};

// GET /api/coach/daily-plan (สร้างแผนซ้อมรายวันตามสถิติและ recovery)
exports.getDailyPlan = async (req, res) => {
  try {
    const runs = await Run.find({ user_id: req.userId }).select(
      'distance_km duration_sec start_time mood note sleep_hours stress_level weather'
    );

    const { stats, promptSummary } = buildCoachContext(runs);

    try {
      const plan = await callGeminiDailyPlan(promptSummary);
      return res.json({ plan, stats, source: 'gemini' });
    } catch (aiErr) {
      console.warn('Gemini daily plan failed, using fallback:', aiErr.message);
      const fallbackPlan = buildFallbackDailyPlan(stats);
      return res.json({ plan: fallbackPlan, stats, source: 'rule-based' });
    }
  } catch (err) {
    console.error('getDailyPlan error:', err);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดฝั่งเซิร์ฟเวอร์' });
  }
};

const { buildCoachContext, buildFallbackDailyPlan, computeLongTermInsights } = require('../utils/aiCoach');

const GEMINI_MODEL = 'gemini-3.1-flash-lite';

const INSIGHTS_SYSTEM_PROMPT = `คุณคือ AI Athlete Data Analyst ที่วิเคราะห์ความสัมพันธ์ระหว่างการนอน, ความเครียด, สภาพอากาศ กับสมรรถภาพการวิ่ง
จงเขียนสรุปพฤติกรรมระยะยาว (3-4 ประโยคเป็นภาษาไทย) จากสถิติที่ได้รับ เน้นชี้ให้เห็นจุดแข็งและสิ่งที่ควรปรับปรุงเกี่ยวกับการพักฟื้นกับการวิ่งอย่างเห็นภาพ`;

async function callGeminiInsights(insightsSummary) {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) throw new Error('GEMINI_API_KEY ไม่ถูกตั้งค่า');

  const url = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${apiKey}`;

  const body = {
    system_instruction: { parts: [{ text: INSIGHTS_SYSTEM_PROMPT }] },
    contents: [
      {
        role: 'user',
        parts: [{ text: `นี่คือผลการคำนวณสถิติความสัมพันธ์ระยะยาวของผู้ใช้:\n${JSON.stringify(insightsSummary, null, 2)}\n\nช่วยวิเคราะห์พฤติกรรมระยะยาวให้หน่อย` }],
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
  if (!text) throw new Error('Gemini ไม่ส่งข้อความกลับมา');
  return text.trim();
}

// GET /api/coach/insights (ดึงผลวิเคราะห์เชิงลึกระยะยาว)
exports.getInsights = async (req, res) => {
  try {
    const runs = await Run.find({ user_id: req.userId }).select(
      'distance_km duration_sec avg_pace start_time mood note sleep_hours stress_level weather'
    );

    const insights = computeLongTermInsights(runs);

    let summaryText = 'สะสมข้อมูลการวิ่งและเช็คอินการพักฟื้นเพิ่มเติม เพื่อให้ AI วิเคราะห์แนวโน้มระยะยาวได้แม่นยำยิ่งขึ้น';

    try {
      if (insights.analyzedRunsCount >= 1) {
        summaryText = await callGeminiInsights(insights);
      }
    } catch (aiErr) {
      console.warn('Gemini insights failed:', aiErr.message);
      if (insights.sleepPaceDiffSec != null && insights.sleepPaceDiffSec > 0) {
        summaryText = `เมื่อคุณนอน 7+ ชั่วโมง เพซวิ่งของคุณเร็วขึ้นประมาณ ${insights.sleepPaceDiffSec} วินาที/กม. แสดงให้เห็นว่าการนอนหลับส่งผลโดยตรงต่อฟอร์มการวิ่งของคุณ`;
      }
    }

    return res.json({
      insights,
      summary: summaryText,
    });
  } catch (err) {
    console.error('getInsights error:', err);
    res.status(500).json({ message: 'เกิดข้อผิดพลาดฝั่งเซิร์ฟเวอร์' });
  }
};

// POST /api/coach/chat  (ต้อง login ก่อน)
exports.chat = async (req, res) => {
  try {
    const { message, history } = req.body;
    if (!message || typeof message !== 'string' || !message.trim()) {
      return res.status(400).json({ message: 'กรุณาส่งข้อความคำถาม' });
    }

    const runs = await Run.find({ user_id: req.userId }).select(
      'distance_km duration_sec start_time mood note sleep_hours stress_level weather'
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
