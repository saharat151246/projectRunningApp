import 'package:flutter/material.dart';

import '../config/map_config.dart';

/// ป้ายเครดิตเล็กๆ มุมแผนที่ - Mapbox กำหนดให้ต้องแสดงเสมอตามเงื่อนไขการใช้งาน
/// ใช้ทั้งบนแผนที่แบบโต้ตอบได้ในแอป และซ้อนอยู่ในการ์ดแชร์ที่บันทึกเป็นรูปภาพ
class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        MapConfig.attribution,
        style: const TextStyle(fontSize: 9, color: Colors.black87, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// แบนเนอร์แจ้งเตือนตอนยังไม่ได้ใส่ Mapbox Access Token
/// (แผนที่จะโหลดไทล์ไม่ขึ้นจนกว่าจะตั้งค่าใน lib/config/map_config.dart)
class MapTokenWarning extends StatelessWidget {
  const MapTokenWarning({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.amber.shade700,
      child: const Text(
        'ยังไม่ได้ใส่ Mapbox Access Token — ตั้งค่าใน lib/config/map_config.dart',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
