# Running App Backend

Backend API (Node.js + Express + MongoDB) สำหรับ Running App

## ก่อนรัน — ต้องแก้ไฟล์ `.env`

เปิดไฟล์ `.env` แล้วแทนที่ `<cluster-address>` ด้วยที่อยู่ cluster จริงของคุณ
หาได้จาก MongoDB Atlas → คลิก **Connect** → **Drivers** → copy connection string มา

ตัวอย่างที่อยู่ cluster (รูปแบบ): `cluster0.ab12cde.mongodb.net`

ตอนนี้ `.env` มีข้อมูลนี้แล้ว (username/password ใส่ให้ตามที่แจ้งมา):
```
MONGO_URI=mongodb+srv://admin:saharat151246@<cluster-address>/running_app?retryWrites=true&w=majority
```

**สำคัญ:** password `saharat151246` ไม่มีอักขระพิเศษ (@ # % / : ?) จึงใส่ตรงๆ ได้เลยไม่ต้อง URL-encode

## วิธีติดตั้งและรัน

```bash
cd running_app_backend
npm install
npm run dev
```

ถ้าสำเร็จจะเห็น:
```
✅ MongoDB connected
🚀 Server running on port 5000
```

ทดสอบเปิดเบราว์เซอร์ไปที่ `http://localhost:5000` ควรเห็น:
```json
{"message": "Running App API is running 🏃"}
```

## โครงสร้างโปรเจค

```
running_app_backend/
├── .env                  # ค่าคอนฟิก (ห้าม commit ขึ้น git)
├── .gitignore
├── server.js             # entry point
├── config/db.js          # เชื่อมต่อ MongoDB
├── models/
│   ├── User.js           # schema ผู้ใช้
│   └── Run.js            # schema ประวัติการวิ่ง
└── routes/
    ├── authRoutes.js      # /api/auth/* (ยังเป็นโครงเปล่า)
    └── runRoutes.js       # /api/runs/* (ยังเป็นโครงเปล่า)
```

## ขั้นตอนถัดไป (ยังไม่ทำในไฟล์ชุดนี้)

1. เชื่อมฝั่ง Flutter app ให้ยิง AI Coach API มาที่นี่ (กำลังทำต่อ)

## API ที่ใช้งานได้จริงแล้ว: AI Coach

### GET /api/coach — ดึงคำแนะนำการฝึกซ้อม (ต้องแนบ Bearer token)

**ก่อนใช้งาน ต้องตั้งค่า Gemini API Key ก่อน:**
1. ไปที่ https://aistudio.google.com/apikey (ไม่ต้องผูกบัตรเครดิต)
2. สร้าง API Key แล้วก็อปมาใส่ใน `.env`:
```
GEMINI_API_KEY=your_key_here
```
3. รีสตาร์ท server (`npm run dev`)

**ถ้าไม่ตั้งค่า GEMINI_API_KEY** ระบบจะไม่ error แต่จะ fallback ไปใช้คำแนะนำแบบ rule-based ล้วนแทนอัตโนมัติ (ดูได้จาก field `source` ในผลลัพธ์)

```json
// Response 200 (เมื่อ Gemini ทำงาน)
{
  "advice": "สัปดาห์นี้คุณวิ่งเพิ่มขึ้น 15% จากสัปดาห์ก่อน...",
  "stats": {
    "totalRuns": 12,
    "totalDistanceKm": 58.4,
    "currentStreakDays": 3,
    "thisWeekKm": 18.2,
    "lastWeekKm": 15.8,
    "weeklyChangePercent": 15.2,
    "overtrainingRisk": true,
    "inactivityWarning": false
  },
  "source": "gemini"
}
```

**หมายเหตุ:** ใช้โมเดล `gemini-2.5-flash-lite` ซึ่งอยู่ใน free tier ของ Google (ไม่มีวันหมดอายุ ไม่ต้องผูกบัตร แต่มี limit ต่อวัน ~1,000-1,500 request/โปรเจค) — ถ้า quota หมดหรือ Gemini error ระบบจะ fallback เป็น rule-based ให้อัตโนมัติ ไม่ทำให้ endpoint ล่ม

## API ที่ใช้งานได้จริงแล้ว: Runs

ทุก endpoint ของ Runs **ต้องแนบ header** `Authorization: Bearer <token>` (token จาก login/register)

### POST /api/runs — บันทึกการวิ่งใหม่
```json
// Request body
{
  "start_time": "2026-07-08T06:00:00.000Z",
  "end_time": "2026-07-08T06:28:00.000Z",
  "distance_km": 5.2,
  "duration_sec": 1680,
  "avg_pace": 5.38,
  "route": [
    { "lat": 13.7563, "lng": 100.5018, "timestamp": "2026-07-08T06:00:05.000Z" }
  ]
}

// Response 201
{ "run": { "_id": "...", "user_id": "...", "distance_km": 5.2, ... } }
```

### GET /api/runs — ดึงประวัติการวิ่งทั้งหมด (ล่าสุดก่อน, ไม่รวม route เต็มเพื่อความเร็ว)
```json
{ "runs": [ { "_id": "...", "distance_km": 5.2, "duration_sec": 1680, "start_time": "..." }, ... ] }
```

### GET /api/runs/summary — สรุปสถิติรวม + ระยะทางรายวัน 7 วันล่าสุด (ใช้ทำกราฟ)
```json
{
  "totalRuns": 12,
  "totalDistanceKm": 58.4,
  "weeklyDistance": [3.2, 5.0, 0, 4.1, 6.5, 2.0, 7.8],
  "weekLabels": ["2026-07-02", "2026-07-03", "...", "2026-07-08"]
}
```

### GET /api/runs/:id — ดึงรายละเอียดการวิ่งครั้งเดียว (รวมเส้นทาง GPS เต็ม)

### DELETE /api/runs/:id — ลบประวัติการวิ่ง

## API ที่ใช้งานได้จริงแล้ว (Register/Login)

### POST /api/auth/register
```json
// Request body
{
  "name": "สมชาย ใจดี",
  "email": "somchai@example.com",
  "password": "mypassword123"
}

// Response 201
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": { "id": "...", "name": "สมชาย ใจดี", "email": "somchai@example.com", ... }
}
```

### POST /api/auth/login
```json
// Request body
{
  "email": "somchai@example.com",
  "password": "mypassword123"
}

// Response 200
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": { "id": "...", "name": "สมชาย ใจดี", ... }
}
```

### GET /api/auth/me
ต้องแนบ header: `Authorization: Bearer <token>`
```json
// Response 200
{ "user": { "id": "...", "name": "สมชาย ใจดี", ... } }
```

### POST /api/auth/google — เข้าสู่ระบบด้วย Google

**ก่อนใช้งาน ต้องตั้งค่า Google Client ID ก่อน:**
1. ไปที่ [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. สร้าง OAuth Client ID ชนิด **Web application** (ใช้ตัวนี้ฝั่ง server แม้ app จะเป็น Android/iOS ก็ตาม เพราะต้อง verify token ด้วย audience ของ web client)
3. ก็อป Client ID มาใส่ใน `.env`:
```
GOOGLE_CLIENT_ID=xxxxxxxx.apps.googleusercontent.com
```
4. รีสตาร์ท server

**ฝั่ง Flutter:** ใช้ package [`google_sign_in`](https://pub.dev/packages/google_sign_in) ล็อกอินแล้วดึง `idToken` จาก account ที่ได้ ส่งมาที่ endpoint นี้

```json
// Request body
{ "id_token": "eyJhbGciOiJSUzI1NiIs..." }

// Response 200
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "...",
    "name": "สมชาย ใจดี",
    "email": "somchai@gmail.com",
    "auth_provider": "google",
    "avatar_url": "https://lh3.googleusercontent.com/...",
    "email_verified": true
  }
}
```

**พฤติกรรม:**
- Server verify `id_token` กับ Google โดยตรง (เช็ค signature + audience) ก่อนเชื่อข้อมูลใดๆ
- ถ้า email เคยสมัครด้วย email/password มาก่อน ระบบจะผูก `google_id` เข้ากับบัญชีเดิมให้อัตโนมัติ (ไม่สร้างบัญชีซ้ำ)
- ถ้ายังไม่เคยสมัคร จะสร้างบัญชีใหม่ให้ทันที ไม่มี `password_hash` (login ผ่าน Google ทางเดียว)
- ถ้า `id_token` ปลอมหรือหมดอายุ ตอบ `401`
- ถ้ายังไม่ได้ตั้งค่า `GOOGLE_CLIENT_ID` ตอบ `500` พร้อม log แจ้งเตือนที่ฝั่ง server

**ทดสอบง่ายๆ ด้วย Postman หรือ curl:**
```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"password123"}'
```
