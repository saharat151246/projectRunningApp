import 'map_secrets.dart';

/// ตั้งค่าแหล่งแผนที่ที่ใช้ทั้งแอป (เปลี่ยนที่นี่ที่เดียว มีผลกับทุกจอที่มีแผนที่:
/// หน้ารายละเอียดการวิ่ง, หน้าติดตามวิ่งแบบเรียลไทม์, และการ์ดแชร์แบบพื้นหลังแผนที่)
///
/// โทเคนจริงไม่ได้อยู่ในไฟล์นี้ — เก็บแยกไว้ที่ lib/config/map_secrets.dart
/// ซึ่งอยู่ใน .gitignore แล้ว ป้องกันไม่ให้หลุดขึ้น git โดยไม่ตั้งใจ
/// (ดูวิธีตั้งค่า/กู้คืนไฟล์นั้นได้ที่ lib/config/map_secrets.example.dart)
class MapConfig {
  MapConfig._();

  /// อ่านโทเคนจาก map_secrets.dart (ไฟล์ลับ ไม่ขึ้น git) เป็นค่าเริ่มต้น
  /// แต่ถ้าส่ง --dart-define=MAPBOX_ACCESS_TOKEN=pk.xxxx ตอนรัน/บิลด์ จะใช้ค่านั้นแทน
  /// (สะดวกสำหรับ CI/CD ที่ไม่อยากมีไฟล์ลับอยู่ในเครื่อง build เลย)
  static const String mapboxAccessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
    defaultValue: mapboxAccessTokenSecret,
  );

  /// สไตล์แผนที่ของ Mapbox ที่ใช้ทั้งแอป เปลี่ยนได้ตามชอบ เช่น:
  /// 'mapbox/streets-v12'   สีสันมาตรฐาน
  /// 'mapbox/light-v11'     ขาวสว่างมินิมอล
  /// 'mapbox/dark-v11'      มืด เหมาะกับการ์ดแชร์
  /// 'mapbox/outdoors-v12'  เน้นเส้นทาง/ภูมิประเทศ เหมาะกับแอปวิ่ง
  static const String mapboxStyleId = 'mapbox/streets-v12';

  /// true เมื่อมีการใส่โทเคนจริงแล้ว (ไม่ใช่ค่า placeholder เริ่มต้น)
  static bool get hasValidToken =>
      mapboxAccessToken.isNotEmpty &&
      mapboxAccessToken.startsWith('pk.');

  /// URL template สำหรับ TileLayer ของ flutter_map
  static String get tileUrlTemplate =>
      'https://api.mapbox.com/styles/v1/$mapboxStyleId/tiles/{z}/{x}/{y}?access_token=$mapboxAccessToken';

  /// Mapbox กำหนดในเงื่อนไขการใช้งานว่าต้องแสดงเครดิตนี้บนแผนที่เสมอ
  /// (รวมถึงในภาพที่บันทึก/แชร์ออกไปด้วย)
  static const String attribution = '© Mapbox © OpenStreetMap';
}
