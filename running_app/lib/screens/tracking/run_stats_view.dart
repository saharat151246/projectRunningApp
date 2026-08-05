import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// มุมมองสถิติแบบเต็มจอ (Full Stats View) - แสดงระหว่างวิ่งจริง
/// สลับมาจาก TrackingScreen แบบย่อ (แผนที่) ด้วยไอคอนขยาย/ย่อมุมมองมุมซ้ายบน
///
/// โชว์: เวลารวม, เพซของช่วงกม.ปัจจุบัน (อัปเดตสด), ระยะทางรวม
/// และแถบสรุปเพซของแต่ละกม.ที่วิ่งผ่านมา (Splits) พร้อมไฮไลต์ช่วงที่กำลังวิ่งอยู่
class RunStatsView extends StatelessWidget {
  /// เวลารวมทั้งหมดที่วิ่ง (วินาที)
  final int elapsedSeconds;

  /// ระยะทางรวมทั้งหมด (กม.)
  final double distanceKm;

  /// เพซของช่วงกม.ปัจจุบันที่กำลังวิ่งอยู่ (นาที/กม.) - อัปเดตสดทุกวินาที
  final double currentSplitPaceMinPerKm;

  /// เพซเฉลี่ยของแต่ละกม.ที่วิ่งจบไปแล้ว (นาที/กม.) เรียงจากกม.แรกสุด
  final List<double> completedSplitPaces;

  final bool isPaused;
  final VoidCallback onPauseResume;
  final VoidCallback onStop;
  final VoidCallback onCollapse;

  const RunStatsView({
    super.key,
    required this.elapsedSeconds,
    required this.distanceKm,
    required this.currentSplitPaceMinPerKm,
    required this.completedSplitPaces,
    required this.isPaused,
    required this.onPauseResume,
    required this.onStop,
    required this.onCollapse,
  });

  String _formatElapsed(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '${h.toString().padLeft(2, '0')}:$m:$s';
  }

  String _formatPace(double minPerKm) {
    if (minPerKm <= 0 || minPerKm.isInfinite || minPerKm.isNaN) return '-:--';
    final m = minPerKm.floor();
    final s = ((minPerKm - m) * 60).round();
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // ช่วงกม.ปัจจุบันที่ยังวิ่งไม่ครบ (แสดงเป็นแท่งสุดท้าย ไฮไลต์ว่ากำลัง live)
    final hasLiveSplit = distanceKm - completedSplitPaces.length > 0.01;

    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onCollapse,
                    icon: const Icon(Icons.close_fullscreen_rounded,
                        color: Colors.white70, size: 20),
                    tooltip: 'ย่อกลับไปมุมมองแผนที่',
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatElapsed(elapsedSeconds),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      _formatPace(currentSplitPaceMinPerKm),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 76,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ค่าเฉลี่ยช่วง (/กม.)',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      distanceKm.toStringAsFixed(2),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ระยะทาง (กม.)',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSplitsRow(hasLiveSplit),
                    const SizedBox(height: 10),
                    Text(
                      'ช่วง (/กม.)',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            _buildBottomControls(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitsRow(bool hasLiveSplit) {
    final splitCount = completedSplitPaces.length + (hasLiveSplit ? 1 : 0);
    if (splitCount == 0) {
      return SizedBox(
        height: 70,
        child: Center(
          child: Text(
            'ยังไม่ครบ 1 กม. แรก',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12.5),
          ),
        ),
      );
    }

    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: true, // เอาช่วงล่าสุด/ปัจจุบันไว้ให้เห็นก่อนเสมอ
        itemCount: splitCount,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, reversedIndex) {
          final index = splitCount - 1 - reversedIndex;
          final isLive = hasLiveSplit && index == splitCount - 1;
          final pace = isLive ? currentSplitPaceMinPerKm : completedSplitPaces[index];
          return _SplitChip(
            paceLabel: _formatPace(pace),
            isLive: isLive,
          );
        },
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20, 18, 20, 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, -6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: onPauseResume,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPaused ? AppColors.accent : const Color(0xFFFF7A1A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
                        const SizedBox(width: 8),
                        Text(
                          isPaused ? 'ไปต่อ' : 'หยุดชั่วคราว',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 54,
                width: 54,
                child: OutlinedButton(
                  onPressed: onStop,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                  ),
                  child: const Icon(Icons.stop_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SplitChip extends StatelessWidget {
  final String paceLabel;
  final bool isLive;

  const _SplitChip({required this.paceLabel, required this.isLive});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          paceLabel,
          style: TextStyle(
            color: isLive ? Colors.white : Colors.white.withValues(alpha: 0.85),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 76,
          height: 34,
          decoration: BoxDecoration(
            color: isLive
                ? AppColors.accent
                : Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
            border: isLive
                ? Border(bottom: BorderSide(color: AppColors.gold, width: 3))
                : null,
          ),
        ),
      ],
    );
  }
}
