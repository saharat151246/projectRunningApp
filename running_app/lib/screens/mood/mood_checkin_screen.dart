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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _saving ? null : _skip,
                  child: const Text('ข้าม', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'วันนี้รู้สึกยังไงบ้าง? 💭',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'ข้อมูลนี้จะถูกเก็บไว้ให้ AI Coach ใช้ประเมินคำแนะนำให้แม่นยำขึ้น',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 32),

              // ตัวเลือกอารมณ์
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _options.map((mood) {
                  final isSelected = _selected == mood;
                  return GestureDetector(
                    onTap: () => setState(() => _selected = mood),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 96,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.divider,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(mood.emoji, style: const TextStyle(fontSize: 32)),
                          const SizedBox(height: 8),
                          Text(
                            mood.label,
                            style: TextStyle(
                              fontSize: 12.5,
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

              const SizedBox(height: 28),
              const Text('อยากเล่าเพิ่มเติมไหม? (ไม่บังคับ)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: _noteCtrl,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'เช่น วันนี้ปวดเข่านิดหน่อย หรือ วิ่งแล้วสดชื่นมาก...',
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
                  ),
                ),
              ),

              const Spacer(),
              PrimaryButton(
                label: 'บันทึก',
                icon: Icons.check_rounded,
                onPressed: _save,
                loading: _saving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
