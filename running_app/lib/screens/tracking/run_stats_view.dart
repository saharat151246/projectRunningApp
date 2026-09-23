import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/language_controller.dart';

/// มุมมองสถิติแบบเต็มจอ (Full Stats View) - แสดงระหว่างวิ่งจริง
/// สลับมาจาก TrackingScreen แบบย่อ (แผนที่) ด้วยไอคอนขยาย/ย่อมุมมองมุมซ้ายบน
class RunStatsView extends StatelessWidget {
  /// เวลารวมทั้งหมดที่วิ่ง (วินาที)
  final int elapsedSeconds;

  /// ระยะทางรวมทั้งหมด (กม.)
  final double distanceKm;

  /// เพซของช่วงกม.ปัจจุบันที่กำลังวิ่งอยู่ (นาที/กม.) - อัปเดตสดทุกวินาที
  final double currentSplitPaceMinPerKm;

  /// เพซเฉลี่ยของแต่ละกม.ที่วิ่งจบไปแล้ว (นาที/กม.) เรียงจากกม.แรกสุด
  final List<double> completedSplitPaces;

  final bool isRunning;
  final bool isPaused;
  final VoidCallback? onStart;
  final VoidCallback onPauseResume;
  final VoidCallback onStop;
  final VoidCallback onCollapse;

  const RunStatsView({
    super.key,
    required this.elapsedSeconds,
    required this.distanceKm,
    required this.currentSplitPaceMinPerKm,
    required this.completedSplitPaces,
    this.isRunning = true,
    required this.isPaused,
    this.onStart,
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
    return AnimatedBuilder(
      animation: LanguageController.instance,
      builder: (context, _) {
        final lang = LanguageController.instance;
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
                        icon: const Icon(Icons.close_fullscreen_rounded, color: Colors.white70, size: 20),
                        tooltip: lang.text('ย่อกลับไปมุมมองแผนที่', 'Collapse to map view'),
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
                          lang.text('ค่าเฉลี่ยช่วง (/กม.)', 'Split Pace (${lang.perKm})'),
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
                          lang.text('ระยะทาง (กม.)', 'Distance (${lang.km})'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildSplitsRow(hasLiveSplit, lang),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                _buildBottomControls(context, lang),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSplitsRow(bool hasLiveSplit, LanguageController lang) {
    final splitCount = completedSplitPaces.length + (hasLiveSplit ? 1 : 0);

    final validPaces = <double>[];
    for (final p in completedSplitPaces) {
      if (p > 0 && !p.isInfinite && !p.isNaN) validPaces.add(p);
    }
    if (hasLiveSplit &&
        currentSplitPaceMinPerKm > 0 &&
        !currentSplitPaceMinPerKm.isInfinite &&
        !currentSplitPaceMinPerKm.isNaN) {
      validPaces.add(currentSplitPaceMinPerKm);
    }

    final double minPaces = validPaces.isEmpty ? 5.0 : validPaces.reduce((a, b) => a < b ? a : b);
    final double maxPaces = validPaces.isEmpty ? 5.0 : validPaces.reduce((a, b) => a > b ? a : b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                lang.text('เพซแบ่งตามกิโลเมตร', 'Kilometer Splits'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (splitCount == 0)
            SizedBox(
              height: 135,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_run_rounded, color: Colors.white.withValues(alpha: 0.25), size: 32),
                    const SizedBox(height: 8),
                    Text(
                      lang.text('เริ่มวิ่งเพื่อสะสมแท่งเพซรายกิโลเมตร', 'Start running to collect kilometer splits'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 135,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                reverse: true,
                itemCount: splitCount,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, reversedIndex) {
                  final index = splitCount - 1 - reversedIndex;
                  final isLive = hasLiveSplit && index == splitCount - 1;
                  final pace = isLive ? currentSplitPaceMinPerKm : completedSplitPaces[index];

                  double fillRatio;
                  if (pace <= 0 || pace.isInfinite || pace.isNaN) {
                    fillRatio = 0.3;
                  } else if (maxPaces == minPaces) {
                    fillRatio = 0.7;
                  } else {
                    fillRatio = 0.35 + 0.55 * ((maxPaces - pace) / (maxPaces - minPaces));
                  }
                  fillRatio = fillRatio.clamp(0.25, 1.0);

                  return _SplitColumnBar(
                    splitLabel: lang.text('กม. ${index + 1}', 'km ${index + 1}'),
                    paceLabel: _formatPace(pace),
                    isLive: isLive,
                    fillRatio: fillRatio,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context, LanguageController lang) {
    String label;
    IconData icon;
    Color buttonColor;
    VoidCallback action;

    if (!isRunning) {
      label = lang.text('เริ่มวิ่ง', 'Start');
      icon = Icons.play_arrow_rounded;
      buttonColor = const Color(0xFFFF7A1A);
      action = onStart ?? onPauseResume;
    } else if (isPaused) {
      label = lang.text('ไปต่อ', 'Resume');
      icon = Icons.play_arrow_rounded;
      buttonColor = AppColors.accent;
      action = onPauseResume;
    } else {
      label = lang.text('หยุดชั่วคราว', 'Pause');
      icon = Icons.pause_rounded;
      buttonColor = const Color(0xFFFF7A1A);
      action = onPauseResume;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 18, 20, 16 + MediaQuery.of(context).padding.bottom),
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
                    onPressed: action,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon),
                        const SizedBox(width: 8),
                        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ),
              if (isRunning) ...[
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
            ],
          ),
        ],
      ),
    );
  }
}

class _SplitColumnBar extends StatelessWidget {
  final String splitLabel;
  final String paceLabel;
  final bool isLive;
  final double fillRatio;

  const _SplitColumnBar({
    required this.splitLabel,
    required this.paceLabel,
    required this.isLive,
    required this.fillRatio,
  });

  @override
  Widget build(BuildContext context) {
    const double maxTrackHeight = 72;
    final double barHeight = (maxTrackHeight * fillRatio).clamp(18.0, maxTrackHeight);

    return SizedBox(
      width: 48,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              paceLabel,
              style: TextStyle(
                color: isLive ? AppColors.gold : Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: maxTrackHeight,
            width: 28,
            alignment: Alignment.bottomCenter,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: barHeight,
              width: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLive
                      ? [const Color(0xFFFFB03A), const Color(0xFFFF5E62)]
                      : AppColors.primaryGradient,
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: (isLive ? AppColors.gold : AppColors.primary).withValues(alpha: isLive ? 0.5 : 0.3),
                    blurRadius: isLive ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: isLive
                    ? Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: isLive ? AppColors.gold.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: isLive ? Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 1) : null,
            ),
            child: Text(
              splitLabel,
              style: TextStyle(
                color: isLive ? AppColors.gold : Colors.white70,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
