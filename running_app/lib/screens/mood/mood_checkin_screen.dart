import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';
import '../../services/run_service.dart';

/// หน้าเช็คอินความรู้สึกหลังวิ่งเสร็จ - ข้อมูลนี้จะถูกเก็บไว้ให้ AI Coach
/// นำไปวิเคราะห์ร่วมกับสถิติระยะทาง เพื่อประเมินความเสี่ยงบาดเจ็บได้แม่นยำขึ้น
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
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เลือกความรู้สึกก่อนนะครับ')),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _saving ? null : _skip,
                        child: Text('ข้าม', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'วันนี้รู้สึกอย่างไร?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ข้อมูลนี้จะถูกเก็บไว้ให้ AI Coach ใช้ประเมินคำแนะนำให้แม่นยำขึ้น',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 24),

                    // ตัวเลือกอารมณ์
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _options.map((mood) {
                        final isSelected = _selected == mood;
                        return GestureDetector(
                          onTap: () => setState(() => _selected = mood),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: (MediaQuery.of(context).size.width - 68) / 3,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.divider,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(mood.emoji, style: const TextStyle(fontSize: 28)),
                                const SizedBox(height: 6),
                                Text(
                                  mood.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // 💤 ชั่วโมงนอนเมื่อคืน
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('ชั่วโมงนอนเมื่อคืน (ไม่บังคับ)',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                        if (_sleepHours != null)
                          Text('${_sleepHours!.toStringAsFixed(1)} ชม.',
                              style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [4.0, 5.0, 6.0, 7.0, 8.0, 9.0].map((h) {
                        final isSel = _sleepHours == h;
                        return ChoiceChip(
                          label: Text('${h.toInt()} ชม.'),
                          selected: isSel,
                          onSelected: (val) => setState(() => _sleepHours = val ? h : null),
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          side: BorderSide(color: isSel ? AppColors.primary : AppColors.divider),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // 🧘 ระดับความเครียด
                    const Text('ระดับความเครียดวันนี้',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildChoiceChip('ต่ำ', 'low', _stressLevel, (val) => setState(() => _stressLevel = val)),
                        const SizedBox(width: 8),
                        _buildChoiceChip('ปานกลาง', 'medium', _stressLevel, (val) => setState(() => _stressLevel = val)),
                        const SizedBox(width: 8),
                        _buildChoiceChip('สูง', 'high', _stressLevel, (val) => setState(() => _stressLevel = val)),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 🌤️ สภาพอากาศ
                    const Text('สภาพอากาศขณะวิ่ง',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildChoiceChip('❄️ เย็นสบาย', 'cool', _weather, (val) => setState(() => _weather = val)),
                        _buildChoiceChip('☀️ ร้อน', 'hot', _weather, (val) => setState(() => _weather = val)),
                        _buildChoiceChip('🌧️ ฝนตก', 'rainy', _weather, (val) => setState(() => _weather = val)),
                        _buildChoiceChip('☁️ ปกติ', 'normal', _weather, (val) => setState(() => _weather = val)),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Text('อยากเล่าเพิ่มเติมไหม? (ไม่บังคับ)',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteCtrl,
                      maxLines: 3,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: 'เช่น วันนี้ปวดเข่านิดหน่อย หรือ วิ่งแล้วสดชื่นมาก...',
                        filled: true,
                        fillColor: AppColors.surface,
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
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: PrimaryButton(
                label: 'บันทึก',
                icon: Icons.check_rounded,
                onPressed: _save,
                loading: _saving,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip(
      String label, String value, String? current, ValueChanged<String?> onSelect) {
    final isSelected = current == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
      selected: isSelected,
      onSelected: (selected) => onSelect(selected ? value : null),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.divider),
    );
  }
}
