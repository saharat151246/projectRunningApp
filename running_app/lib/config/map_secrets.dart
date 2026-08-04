/// ไฟล์นี้เก็บ Mapbox Access Token จริง — อยู่ใน .gitignore แล้ว จะไม่ถูก push ขึ้น git
/// ห้ามลบบรรทัด "lib/config/map_secrets.dart" ออกจาก .gitignore
///
/// ถ้าเพิ่ง clone โปรเจกต์มาแล้วไฟล์นี้หายไป (เพราะไม่ได้อยู่ใน git):
/// ให้คัดลอกจาก map_secrets.example.dart แล้วเปลี่ยนชื่อไฟล์เป็น map_secrets.dart
/// จากนั้นใส่โทเคนของตัวเองแทนค่า placeholder ด้านล่าง
const String mapboxAccessTokenSecret =
    'pk.eyJ1IjoiYmFuazE1IiwiYSI6ImNtc2YyMnE2ZTA3OTAyem9qeGxoNjUzcTQifQ.t6v76aZTgrCiFq5FvIsDqQ';
