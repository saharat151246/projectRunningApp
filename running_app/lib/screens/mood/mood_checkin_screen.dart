import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';
import '../../services/run_service.dart';
import '../../services/coach_service.dart';
import '../../services/language_controller.dart';

/// หน้าเช็คอินความรู้สึกหลังวิ่งเสร็จ - ออกแบบตามหลัก UI App Design Skill
/// ธีม: Modern Blush Pink & Warm Charcoal (human-made feel, มินิมอล, ไม่เป็น AI เทมเพลต)
/// รองรับ: หน้าจอโทรศัพท์ทุกขนาด (Small SE, Medium, Large, Foldable) โดยไม่เกิด Layout Overflow / Text Overlap
class MoodCheckinScreen extends StatefulWidget {
  final String runId;
  const MoodCheckinScreen({super.key, required this.runId});

  @override
  State<MoodCheckinScreen> createState() => _MoodCheckinScreenState();
}

class _MoodCheckinScreenState extends State<MoodCheckinScreen> {
  RunMood? _selected;
  double? _sleepHours;
  String? _stressLevel; // 'low', 'medium', 'high'
  String? _weather; // 'cool', 'hot', 'rainy', 'normal'
  final TextEditingController _noteCtrl = TextEditingController();
  bool _saving = false;

  static const _options = RunMood.values;

  Future<void> _save() async {
    final lang = LanguageController.instance;
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  lang.text('กรุณาเลือกความรู้สึกวันนี้ก่อนบันทึกนะครับ', 'Please select how you feel before saving.'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    await RunService.instance.updateMoodCheckin(
      runId: widget.runId,
      mood: _selected,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      sleepHours: _sleepHours,
      stressLevel: _stressLevel,
      weather: _weather,
    );
    CoachService.instance.clearMemoryCache();
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop();
  }

  void _skip() {
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LanguageController.instance,
      builder: (context, _) {
        final lang = LanguageController.instance;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'AI Coach Check-in',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TextButton.icon(
                  onPressed: _saving ? null : _skip,
                  icon: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                  label: Text(
                    lang.text('ข้าม', 'Skip'),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Section
                        Text(
                          lang.text('วันนี้รู้สึกอย่างไร?', 'How do you feel today?'),
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          lang.text(
                            'ข้อมูลนี้ช่วยให้ AI Coach วิเคราะห์ความเสี่ยงบาดเจ็บและปรับแผนฝึกซ้อมให้เหมาะกับคุณ',
                            'This helps AI Coach analyze injury risk and personalize your training plan.',
                          ),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13.5,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 1. Responsive Mood Selector Grid
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final crossAxisCount = width < 340 ? 2 : (width > 600 ? 5 : 3);
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 1.15,
                              ),
                              itemCount: _options.length,
                              itemBuilder: (context, index) {
                                final mood = _options[index];
                                final isSelected = _selected == mood;
                                return _MoodOptionTile(
                                  mood: mood,
                                  isSelected: isSelected,
                                  onTap: () => setState(() => _selected = mood),
                                );
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // 2. Sleep Hours Section
                        _CardContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.bedtime_rounded,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      lang.text('ชั่วโมงนอนเมื่อคืน', 'Sleep last night'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14.5,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (_sleepHours != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${_sleepHours!.toStringAsFixed(1)} ${lang.text('ชม.', 'hrs')}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [4.0, 5.0, 6.0, 7.0, 8.0, 9.0].map((h) {
                                  final isSel = _sleepHours == h;
                                  return _SelectablePill(
                                    label: '${h.toInt()} ${lang.text('ชม.', 'hrs')}',
                                    isSelected: isSel,
                                    onTap: () => setState(() => _sleepHours = isSel ? null : h),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 3. Physical & Weather Conditions Card
                        _CardContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Stress Level
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.psychology_rounded,
                                      size: 18,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    lang.text('ระดับความเครียดสะสม', 'Stress Level'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14.5,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _SelectablePill(
                                    label: lang.text('🟢 ผ่อนคลาย (ต่ำ)', '🟢 Low (Relaxed)'),
                                    isSelected: _stressLevel == 'low',
                                    onTap: () => setState(
                                      () => _stressLevel = _stressLevel == 'low' ? null : 'low',
                                    ),
                                  ),
                                  _SelectablePill(
                                    label: lang.text('🟡 ปานกลาง', '🟡 Moderate'),
                                    isSelected: _stressLevel == 'medium',
                                    onTap: () => setState(
                                      () => _stressLevel = _stressLevel == 'medium' ? null : 'medium',
                                    ),
                                  ),
                                  _SelectablePill(
                                    label: lang.text('🔴 เครียดสูง', '🔴 High'),
                                    isSelected: _stressLevel == 'high',
                                    onTap: () => setState(
                                      () => _stressLevel = _stressLevel == 'high' ? null : 'high',
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),
                              Divider(color: AppColors.divider, height: 1),
                              const SizedBox(height: 16),

                              // Weather
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.gold.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.wb_sunny_rounded,
                                      size: 18,
                                      color: AppColors.gold,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    lang.text('สภาพอากาศขณะวิ่ง', 'Running Weather'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14.5,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _SelectablePill(
                                    label: lang.text('❄️ เย็นสบาย', '❄️ Cool'),
                                    isSelected: _weather == 'cool',
                                    onTap: () => setState(
                                      () => _weather = _weather == 'cool' ? null : 'cool',
                                    ),
                                  ),
                                  _SelectablePill(
                                    label: lang.text('☀️ ร้อนจัด', '☀️ Hot'),
                                    isSelected: _weather == 'hot',
                                    onTap: () => setState(
                                      () => _weather = _weather == 'hot' ? null : 'hot',
                                    ),
                                  ),
                                  _SelectablePill(
                                    label: lang.text('🌧️ ฝนตก', '🌧️ Rainy'),
                                    isSelected: _weather == 'rainy',
                                    onTap: () => setState(
                                      () => _weather = _weather == 'rainy' ? null : 'rainy',
                                    ),
                                  ),
                                  _SelectablePill(
                                    label: lang.text('☁️ ปกติ', '☁️ Normal'),
                                    isSelected: _weather == 'normal',
                                    onTap: () => setState(
                                      () => _weather = _weather == 'normal' ? null : 'normal',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 4. Notes Section Card
                        _CardContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.edit_note_rounded,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    lang.text('เล่ารายละเอียดเพิ่มเติม (ไม่บังคับ)', 'Additional notes (Optional)'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14.5,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _noteCtrl,
                                maxLines: 3,
                                maxLength: 500,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: lang.text(
                                    'เช่น มีอาการตึงขาขวาเล็กน้อย หรือ วิ่งตามเพซเป้าหมายได้ดี...',
                                    'e.g. slight right calf tightness, or felt great keeping target pace...',
                                  ),
                                  hintStyle: TextStyle(
                                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                                    fontSize: 13,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.background,
                                  contentPadding: const EdgeInsets.all(14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: AppColors.divider),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: AppColors.divider),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: AppColors.primary, width: 1.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Action Section
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: PrimaryButton(
                    label: lang.text('บันทึกการเช็คอิน', 'Save Check-in'),
                    icon: Icons.check_circle_rounded,
                    onPressed: _save,
                    loading: _saving,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Custom Card Container
class _CardContainer extends StatelessWidget {
  final Widget child;
  const _CardContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppColors.isDark ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Mood Option Card Component - สัมผัสตอบสนองลื่นไหลแบบ Micro-interaction
class _MoodOptionTile extends StatefulWidget {
  final RunMood mood;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodOptionTile({
    required this.mood,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_MoodOptionTile> createState() => _MoodOptionTileState();
}

class _MoodOptionTileState extends State<_MoodOptionTile> {
  bool _isPressed = false;

  String _getMoodLabel(RunMood mood, LanguageController lang) {
    if (lang.isEnglish) {
      switch (mood) {
        case RunMood.exhausted:
          return 'Exhausted';
        case RunMood.veryTired:
          return 'Very Tired';
        case RunMood.good:
          return 'Good';
        case RunMood.great:
          return 'Great';
        case RunMood.chill:
          return 'Chill';
      }
    }
    return mood.label;
  }

  @override
  Widget build(BuildContext context) {
    final lang = LanguageController.instance;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : (widget.isSelected ? 1.02 : 1.0),
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.isSelected ? AppColors.primary : AppColors.divider,
              width: widget.isSelected ? 2.0 : 1.0,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.mood.emoji,
                style: const TextStyle(fontSize: 26),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    _getMoodLabel(widget.mood, lang),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: widget.isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: widget.isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom Pill Widget สำหรับตัวเลือก Sleep, Stress, Weather
class _SelectablePill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectablePill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: const BoxConstraints(minHeight: 42),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
