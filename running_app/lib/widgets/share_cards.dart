import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';

import '../models/run_model.dart';
import '../theme/app_theme.dart';
import '../config/map_config.dart';
import 'map_attribution.dart';

/// สไตล์การ์ดที่แชร์ได้ - เพิ่มสไตล์ใหม่ในอนาคตแค่เพิ่ม enum + widget แล้วต่อใน
/// [ShareCardPickerSheet._cardFor]
enum ShareCardStyle {
  minimalDark('มินิมอล', Icons.crop_din_rounded),
  mapBackground('พื้นหลังแผนที่', Icons.map_rounded);

  final String label;
  final IconData icon;
  const ShareCardStyle(this.label, this.icon);
}

/// ขนาดอ้างอิงของการ์ด (สัดส่วน 9:16 แบบ Instagram Story)
/// ตอน capture จะใช้ pixelRatio 3 ทำให้ได้ไฟล์จริงขนาด 1080x1920
const double kShareCardDesignWidth = 360;
const double kShareCardDesignHeight = 640;

String _paceLabel(double? minPerKm) {
  if (minPerKm == null || minPerKm <= 0) return '--:--';
  final m = minPerKm.floor();
  final s = ((minPerKm - m) * 60).round();
  return '$m:${s.toString().padLeft(2, '0')}';
}

String _durationLabel(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m}m ${s.toString().padLeft(2, '0')}s';
}

String _durationLabelTh(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m น. $s วิ';
}

/// จับภาพ widget ใดๆ เป็น PNG โดยไม่ต้องแสดงบนจอจริง
/// (แทรกไว้นอกขอบเขตจอผ่าน Overlay แล้วรอเฟรม/ไทล์แผนที่โหลดก่อน capture)
Future<Uint8List> captureShareCard(BuildContext context, Widget card) async {
  final key = GlobalKey();
  final overlay = Overlay.of(context, rootOverlay: true);
  final entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -10000,
      top: 0,
      child: Material(
        type: MaterialType.transparency,
        child: RepaintBoundary(key: key, child: card),
      ),
    ),
  );
  overlay.insert(entry);
  try {
    // รอให้ layout เสร็จ + ให้เวลาไทล์แผนที่ (ภาพจากเน็ต) โหลดก่อน capture
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    await Future.delayed(const Duration(milliseconds: 900));

    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw StateError('ไม่สามารถสร้างภาพสำหรับแชร์ได้');
    }
    final image = await renderObject.toImage(pixelRatio: 3.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) throw StateError('ไม่สามารถสร้างภาพสำหรับแชร์ได้');
    return bytes.buffer.asUint8List();
  } finally {
    entry.remove();
  }
}

/// วาดเส้นทางวิ่งให้พอดีกับกล่องที่กำหนด รักษาสัดส่วนจริง (uniform scale)
class _RoutePainter extends CustomPainter {
  final List<LatLng> route;
  final Color color;
  _RoutePainter(this.route, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (route.length < 2) return;
    final lats = route.map((p) => p.latitude);
    final lngs = route.map((p) => p.longitude);
    final minLat = lats.reduce((a, b) => a < b ? a : b);
    final maxLat = lats.reduce((a, b) => a > b ? a : b);
    final minLng = lngs.reduce((a, b) => a < b ? a : b);
    final maxLng = lngs.reduce((a, b) => a > b ? a : b);
    final latRange = (maxLat - minLat).abs() < 0.00001 ? 0.00001 : maxLat - minLat;
    final lngRange = (maxLng - minLng).abs() < 0.00001 ? 0.00001 : maxLng - minLng;

    final scale = (size.width / lngRange < size.height / latRange)
        ? size.width / lngRange
        : size.height / latRange;
    final routeW = lngRange * scale;
    final routeH = latRange * scale;
    final offsetX = (size.width - routeW) / 2;
    final offsetY = (size.height - routeH) / 2;

    Offset project(LatLng p) => Offset(
          offsetX + (p.longitude - minLng) * scale,
          offsetY + (maxLat - p.latitude) * scale,
        );

    final path = ui.Path()..moveTo(project(route.first).dx, project(route.first).dy);
    for (final p in route.skip(1)) {
      final o = project(p);
      path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(project(route.last), 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
      oldDelegate.route != route || oldDelegate.color != color;
}

class _StatLine extends StatelessWidget {
  final String label;
  final String value;
  const _StatLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  final Color textColor;
  const _BrandMark({this.textColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: AppColors.primaryGradient),
            borderRadius: BorderRadius.circular(5),
          ),
          alignment: Alignment.center,
          child: const Text('🏃', style: TextStyle(fontSize: 11)),
        ),
        const SizedBox(width: 6),
        Text('RunMate',
            style: TextStyle(
                color: textColor, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
      ],
    );
  }
}

/// สไตล์ที่ 1: การ์ดมินิมอลพื้นดำ เน้นตัวเลข (ของเดิม ปรับสัดส่วนเป็น 9:16)
class MinimalShareCard extends StatelessWidget {
  final RunDetail run;
  const MinimalShareCard({super.key, required this.run});

  @override
  Widget build(BuildContext context) {
    final hasRoute = run.route.length > 1;
    return Container(
      width: kShareCardDesignWidth,
      height: kShareCardDesignHeight,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 48),
          _StatLine(label: 'DISTANCE', value: '${run.distanceKm.toStringAsFixed(2)} km'),
          const SizedBox(height: 22),
          _StatLine(label: 'PACE', value: '${_paceLabel(run.avgPace)} /km'),
          const SizedBox(height: 22),
          _StatLine(label: 'TIME', value: _durationLabel(run.durationSec)),
          const SizedBox(height: 28),
          Expanded(
            child: hasRoute
                ? SizedBox.expand(
                    child: CustomPaint(painter: _RoutePainter(run.route, AppColors.primary)),
                  )
                : Center(
                    child: Text('NO GPS ROUTE RECORDED',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5)),
                  ),
          ),
          const SizedBox(height: 20),
          const _BrandMark(),
          const SizedBox(height: 36),
        ],
      ),
    );
  }
}

/// สไตล์ที่ 2: การ์ดพื้นหลังแผนที่จริง (สไตล์ Strava) ใช้ FlutterMap ครอบเต็มการ์ด
/// แล้ววางสถิติทับด้วย gradient scrim ให้อ่านง่าย
class MapShareCard extends StatelessWidget {
  final RunDetail run;
  const MapShareCard({super.key, required this.run});

  @override
  Widget build(BuildContext context) {
    final hasRoute = run.route.length > 1;
    return Container(
      width: kShareCardDesignWidth,
      height: kShareCardDesignHeight,
      color: AppColors.secondary,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasRoute)
            IgnorePointer(
              child: FlutterMap(
                options: MapOptions(
                  initialCameraFit: CameraFit.bounds(
                    bounds: LatLngBounds.fromPoints(run.route),
                    padding: const EdgeInsets.fromLTRB(30, 110, 30, 210),
                  ),
                  interactionOptions:
                      const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  TileLayer(
                    urlTemplate: MapConfig.tileUrlTemplate,
                    userAgentPackageName: 'com.example.running_app',
                  ),
                  PolylineLayer(polylines: [
                    Polyline(points: run.route, color: AppColors.primary, strokeWidth: 5),
                  ]),
                  MarkerLayer(markers: [
                    Marker(
                      point: run.route.last,
                      width: 14,
                      height: 14,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          if (!hasRoute)
            Center(
              child: Icon(Icons.map_outlined,
                  color: Colors.white.withValues(alpha: 0.2), size: 40),
            ),

          // scrim บน-ล่างให้ตัวหนังสืออ่านง่ายบนพื้นแผนที่
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0, 0.2, 0.55, 1],
                ),
              ),
            ),
          ),

          const Positioned(top: 36, left: 0, right: 0, child: Center(child: _BrandMark())),

          Positioned(
            left: 20,
            right: 20,
            bottom: 32,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MapStat('ระยะทาง', '${run.distanceKm.toStringAsFixed(2)} กม.'),
                _MapStat('เพซ', '${_paceLabel(run.avgPace)} /กม.'),
                _MapStat('เวลา', _durationLabelTh(run.durationSec)),
              ],
            ),
          ),

          if (hasRoute)
            const Positioned(left: 12, bottom: 8, child: MapAttribution()),
        ],
      ),
    );
  }
}

class _MapStat extends StatelessWidget {
  final String label;
  final String value;
  const _MapStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

/// Bottom sheet ให้ผู้ใช้เลือกสไตล์การ์ด (สไลด์ดูตัวอย่างแบบ Strava) ก่อนกดแชร์จริง
class ShareCardPickerSheet extends StatefulWidget {
  final RunDetail run;
  final String shareText;
  const ShareCardPickerSheet({super.key, required this.run, required this.shareText});

  @override
  State<ShareCardPickerSheet> createState() => _ShareCardPickerSheetState();
}

class _ShareCardPickerSheetState extends State<ShareCardPickerSheet> {
  final _pageController = PageController();
  int _index = 0;
  bool _sharing = false;

  static const _styles = ShareCardStyle.values;

  Widget _cardFor(ShareCardStyle style) {
    switch (style) {
      case ShareCardStyle.minimalDark:
        return MinimalShareCard(run: widget.run);
      case ShareCardStyle.mapBackground:
        return MapShareCard(run: widget.run);
    }
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final card = _cardFor(_styles[_index]);
      final bytes = await captureShareCard(context, card);
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          text: widget.shareText,
          subject: 'ผลการวิ่งจาก RunMate',
          files: [XFile.fromData(bytes, mimeType: 'image/png')],
          fileNameOverrides: ['runmate-${widget.run.id}.png'],
          sharePositionOrigin:
              box == null ? null : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถสร้างการ์ดสำหรับแชร์ได้')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Text('เลือกสไตล์การ์ดที่จะแชร์',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            SizedBox(
              height: 440,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _styles.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  return Center(
                    child: AspectRatio(
                      aspectRatio: kShareCardDesignWidth / kShareCardDesignHeight,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: kShareCardDesignWidth,
                            height: kShareCardDesignHeight,
                            child: _cardFor(_styles[i]),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_styles.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),
            Text(_styles[_index].label,
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _sharing ? null : _share,
                  icon: _sharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.ios_share_rounded),
                  label: Text(_sharing ? 'กำลังสร้างการ์ด...' : 'แชร์การ์ดนี้'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
