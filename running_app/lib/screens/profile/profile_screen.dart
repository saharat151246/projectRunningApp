import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/theme_controller.dart';
import '../onboarding_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ข้อมูลส่วนตัวสะสมในเครื่อง
  double? _weight;
  double? _height;
  int? _age;

  // เป้าหมายการวิ่ง
  double _weeklyGoalKm = 20.0;
  int _weeklyRunsGoal = 4;

  // การตั้งค่าการแจ้งเตือน
  bool _dailyReminder = true;
  bool _missionAlert = true;
  bool _injuryWarning = true;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfilePrefs();
  }

  Future<void> _loadProfilePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final user = AuthService.instance.currentUser;
    if (!mounted) return;
    setState(() {
      _weight = prefs.getDouble('profile_weight') ?? (user?['weight'] as num?)?.toDouble();
      _height = prefs.getDouble('profile_height') ?? (user?['height'] as num?)?.toDouble();
      _age = prefs.getInt('profile_age') ?? (user?['age'] as num?)?.toInt();
      _weeklyGoalKm = prefs.getDouble('profile_weekly_goal_km') ?? 20.0;
      _weeklyRunsGoal = prefs.getInt('profile_weekly_runs_goal') ?? 4;
      _dailyReminder = prefs.getBool('pref_daily_reminder') ?? true;
      _missionAlert = prefs.getBool('pref_mission_alert') ?? true;
      _injuryWarning = prefs.getBool('pref_injury_warning') ?? true;
      _loading = false;
    });
  }

  Future<void> _saveProfilePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_weight != null) await prefs.setDouble('profile_weight', _weight!);
    if (_height != null) await prefs.setDouble('profile_height', _height!);
    if (_age != null) await prefs.setInt('profile_age', _age!);
    await prefs.setDouble('profile_weekly_goal_km', _weeklyGoalKm);
    await prefs.setInt('profile_weekly_runs_goal', _weeklyRunsGoal);
    await prefs.setBool('pref_daily_reminder', _dailyReminder);
    await prefs.setBool('pref_mission_alert', _missionAlert);
    await prefs.setBool('pref_injury_warning', _injuryWarning);
  }

  // --- 1. แก้ไขข้อมูลส่วนตัว ---
  void _showEditProfileDialog() {
    final user = AuthService.instance.currentUser;
    final nameCtrl = TextEditingController(text: user?['name'] as String? ?? '');
    final weightCtrl = TextEditingController(text: _weight != null ? '$_weight' : '');
    final heightCtrl = TextEditingController(text: _height != null ? '$_height' : '');
    final ageCtrl = TextEditingController(text: _age != null ? '$_age' : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.edit_note_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('แก้ไขข้อมูลส่วนตัว', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'ชื่อ-นามสกุล', prefixIcon: Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'น้ำหนัก (กก.)', prefixIcon: Icon(Icons.monitor_weight_outlined)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: heightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'ส่วนสูง (ซม.)', prefixIcon: Icon(Icons.height_rounded)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ageCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'อายุ (ปี)', prefixIcon: Icon(Icons.cake_outlined)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              final newWeight = double.tryParse(weightCtrl.text.trim());
              final newHeight = double.tryParse(heightCtrl.text.trim());
              final newAge = int.tryParse(ageCtrl.text.trim());

              setState(() {
                if (newWeight != null && newWeight > 0) _weight = newWeight;
                if (newHeight != null && newHeight > 0) _height = newHeight;
                if (newAge != null && newAge > 0) _age = newAge;
              });
              _saveProfilePrefs();

              Navigator.pop(ctx);

              final result = await AuthService.instance.updateProfile(
                name: newName.isNotEmpty ? newName : null,
                weight: newWeight,
                height: newHeight,
                age: newAge,
              );

              if (!mounted) return;
              if (result.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('บันทึกข้อมูลส่วนตัวลงฐานข้อมูลเรียบร้อยแล้ว ✨')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('บันทึกลงฐานข้อมูลไม่สำเร็จ: ${result.errorMessage}')),
                );
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  // --- 2. เป้าหมายการวิ่ง ---
  void _showRunningGoalsDialog() {
    final goalKmCtrl = TextEditingController(text: _weeklyGoalKm.toStringAsFixed(1));
    final goalRunsCtrl = TextEditingController(text: '$_weeklyRunsGoal');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.flag_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('ตั้งเป้าหมายการวิ่ง', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ตั้งเป้าหมายประจำสัปดาห์เพื่อท้าทายตัวเองและรับแต้มสะสมพิเศษ',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: goalKmCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'เป้าหมายระยะทาง (กม./สัปดาห์)',
                prefixIcon: Icon(Icons.straighten_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: goalRunsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'เป้าหมายจำนวนครั้ง (ครั้ง/สัปดาห์)',
                prefixIcon: Icon(Icons.repeat_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () {
              final km = double.tryParse(goalKmCtrl.text.trim());
              final runs = int.tryParse(goalRunsCtrl.text.trim());
              if (km != null && km > 0 && runs != null && runs > 0) {
                setState(() {
                  _weeklyGoalKm = km;
                  _weeklyRunsGoal = runs;
                });
                _saveProfilePrefs();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('อัปเดตเป้าหมายเป็น $km กม./สัปดาห์ เรียบร้อยแล้ว 🎯')),
                );
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  // --- โหมดการแสดงผล (สว่าง / มืด / ตามระบบ) ---
  void _showDisplayModeSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          Widget option(ThemeMode mode, String label, String subtitle, IconData icon) {
            final selected = ThemeController.instance.mode == mode;
            return ListTile(
              onTap: () async {
                await ThemeController.instance.setMode(mode);
                if (mounted) setState(() {});
                setSheetState(() {});
              },
              leading: Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary),
              title: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              trailing: selected
                  ? Icon(Icons.check_circle_rounded, color: AppColors.primary)
                  : Icon(Icons.circle_outlined, color: AppColors.divider),
            );
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 20, 12, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('โหมดการแสดงผล 🌗',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ),
                const SizedBox(height: 12),
                option(ThemeMode.system, 'ตามระบบ', 'ใช้โหมดเดียวกับที่ตั้งไว้ในเครื่อง', Icons.brightness_auto_rounded),
                option(ThemeMode.light, 'สว่าง', 'พื้นหลังสว่าง โทนชมพูมินิมอล', Icons.light_mode_rounded),
                option(ThemeMode.dark, 'มืด', 'พื้นหลังเข้ม ถนอมสายตาตอนกลางคืน', Icons.dark_mode_rounded),
              ],
            ),
          );
        },
      ),
    );
  }


  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('ตั้งค่าการแจ้งเตือน 🔔',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('จัดการการแจ้งเตือนและเตือนซ้อมวิ่งเพื่อรักษาวินัย',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('เตือนซ้อมวิ่งประจำวัน', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('แจ้งเตือนช่วงเช้า/เย็น ให้คุณไม่พลาดวันวิ่ง', style: TextStyle(fontSize: 12)),
                activeThumbColor: AppColors.primary,
                value: _dailyReminder,
                onChanged: (val) {
                  setSheetState(() => _dailyReminder = val);
                  setState(() => _dailyReminder = val);
                  _saveProfilePrefs();
                },
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('แจ้งเตือนภารกิจและเหรียญตรา', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('แจ้งเมื่อใกล้ปลดล็อกเหรียญใหม่หรือทำภารกิจสำเร็จ', style: TextStyle(fontSize: 12)),
                activeThumbColor: AppColors.primary,
                value: _missionAlert,
                onChanged: (val) {
                  setSheetState(() => _missionAlert = val);
                  setState(() => _missionAlert = val);
                  _saveProfilePrefs();
                },
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('คำเตือนเสี่ยงบาดเจ็บจาก AI Coach', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('แจ้งเตือนทันทีเมื่อพบสถิติเสี่ยง Overtraining', style: TextStyle(fontSize: 12)),
                activeThumbColor: AppColors.primary,
                value: _injuryWarning,
                onChanged: (val) {
                  setSheetState(() => _injuryWarning = val);
                  setState(() => _injuryWarning = val);
                  _saveProfilePrefs();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 4. ความเป็นส่วนตัว ---
  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text('ความเป็นส่วนตัว 🛡️', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('การปกป้องข้อมูลของคุณ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              SizedBox(height: 6),
              Text(
                '• ข้อมูลพิกัด GPS ทั้งหมดของคุณจะถูกใช้ประมวลผลเส้นทางวิ่งเท่านั้น และถูกเข้ารหัสอย่างปลอดภัย\n'
                '• รหัสผ่านและ JWT Token ถูกเก็บบน Flutter Secure Storage ของอุปกรณ์อย่างปลอดภัย\n'
                '• ข้อมูลความรู้สึกหลังวิ่งจะถูกใช้โดย AI Coach เพื่อคำนวณความเสี่ยงบาดเจ็บเท่านั้น ไม่มีการนำไปแชร์ให้บุคคลภายนอก',
                style: TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('รับทราบ'),
          ),
        ],
      ),
    );
  }

  // --- 5. ช่วยเหลือ ---
  void _showHelpSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('ศูนย์ช่วยเหลือและคำถามที่พบบ่อย ❓',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  ExpansionTile(
                    leading: Icon(Icons.gps_fixed_rounded, color: AppColors.primary),
                    title: Text('📍 การบันทึก GPS ไม่ตรงทำอย่างไร?', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'ตรวจสอบให้แน่ใจว่าได้เปิด Location Service แบบความแม่นยำสูง (High Accuracy) และอนุญาตสิทธิ์ตำแหน่งแบบ "ขณะใช้แอป" หรือ "ตลอดเวลา"',
                          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    leading: Icon(Icons.psychology_alt_rounded, color: AppColors.accent),
                    title: Text('🤖 AI Coach ประเมินความเสี่ยงอย่างไร?', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'AI Coach วิเคราะห์จากกฎความปลอดภัย 10% (ระยะทางสัปดาห์นี้เทียบกับสัปดาห์ก่อน) ร่วมกับข้อมูลความรู้สึกเหนื่อยล้าที่คุณเช็คอินหลังวิ่ง',
                          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    leading: Icon(Icons.military_tech_rounded, color: AppColors.gold),
                    title: Text('🏆 แต้มและเหรียญตราได้มาจากไหน?', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'ได้ 10 แต้มต่อระยะทางวิ่ง 1 กม., +50 แต้มเมื่อปลดล็อกเหรียญตราใหม่ และได้แต้มโบนัสเมื่อทำภารกิจรายสัปดาห์สำเร็จ',
                          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ส่งข้อความถึงทีมสนับสนุนเรียบร้อย เจ้าหน้าที่จะติดต่อกลับทางอีเมล')),
                  );
                },
                icon: const Icon(Icons.mail_outline_rounded),
                label: const Text('ติดต่อทีมงานช่วยเหลือ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 6. ออกจากระบบพร้อม dialog ยืนยัน ---
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('ออกจากระบบ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('คุณต้องการออกจากระบบ RunMate ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.instance.logout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                (route) => false,
              );
            },
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthService.instance,
      builder: (context, _) {
        final user = AuthService.instance.currentUser;
        final name = user?['name'] as String? ?? 'ผู้ใช้';
        final email = user?['email'] as String? ?? '-';
        final provider = user?['auth_provider'] as String? ?? 'email';

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            const Text('โปรไฟล์',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 24),

            // Profile header
            GestureDetector(
              onTap: _showEditProfileDialog,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 14,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: AppColors.primaryGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(name,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                              const SizedBox(width: 6),
                              Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(email,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              provider == 'google' ? 'เข้าสู่ระบบด้วย Google' : 'เข้าสู่ระบบด้วยอีเมล',
                              style: TextStyle(
                                  color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            if (_loading)
              Center(child: CircularProgressIndicator(color: AppColors.primary))
            else
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: 'น้ำหนัก',
                      value: _weight != null ? '${_weight!.toStringAsFixed(0)} กก.' : '-- กก.',
                      onTap: _showEditProfileDialog,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MiniStat(
                      label: 'ส่วนสูง',
                      value: _height != null ? '${_height!.toStringAsFixed(0)} ซม.' : '-- ซม.',
                      onTap: _showEditProfileDialog,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MiniStat(
                      label: 'อายุ',
                      value: _age != null ? '$_age ปี' : '-- ปี',
                      onTap: _showEditProfileDialog,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 28),
            const Text('บัญชีของฉัน', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 10),
            _MenuTile(
              icon: Icons.person_outline_rounded,
              label: 'แก้ไขข้อมูลส่วนตัว',
              onTap: _showEditProfileDialog,
            ),
            _MenuTile(
              icon: Icons.favorite_border_rounded,
              label: 'เป้าหมายการวิ่ง (${_weeklyGoalKm.toStringAsFixed(0)} กม./สัปดาห์)',
              onTap: _showRunningGoalsDialog,
            ),
            _MenuTile(
              icon: Icons.notifications_none_rounded,
              label: 'การแจ้งเตือน',
              onTap: _showNotificationSettings,
            ),

            const SizedBox(height: 24),
            Text('ทั่วไป', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            _MenuTile(
              icon: Icons.dark_mode_outlined,
              label: 'โหมดการแสดงผล',
              onTap: _showDisplayModeSettings,
            ),
            _MenuTile(
              icon: Icons.privacy_tip_outlined,
              label: 'ความเป็นส่วนตัว',
              onTap: _showPrivacyDialog,
            ),
            _MenuTile(
              icon: Icons.help_outline_rounded,
              label: 'ช่วยเหลือและคำถามที่พบบ่อย',
              onTap: _showHelpSheet,
            ),
            _MenuTile(
              icon: Icons.logout_rounded,
              label: 'ออกจากระบบ',
              isDanger: true,
              onTap: _confirmLogout,
            ),
          ],
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _MiniStat({
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDanger;
  final VoidCallback? onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    this.isDanger = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? Colors.redAccent : AppColors.textPrimary;
    final iconColor = isDanger ? Colors.redAccent : AppColors.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isDanger ? Colors.redAccent : AppColors.primary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
        trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary.withValues(alpha: 0.6), size: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

