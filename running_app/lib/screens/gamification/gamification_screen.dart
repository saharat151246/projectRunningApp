import 'package:flutter/material.dart';
import '../../services/gamification_service.dart';
import '../../services/language_controller.dart';
import '../../theme/app_theme.dart';

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> {
  GamificationData? _data;
  bool _loading = true;
  String _frequency = 'daily';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await GamificationService.instance.fetch();
    if (mounted) setState(() { _data = data; _loading = false; });
  }

  Future<void> _createMission() async {
    final lang = LanguageController.instance;
    final result = await showDialog<_MissionDraft>(
      context: context,
      builder: (_) => const _MissionDialog(),
    );
    if (result == null) return;
    final created = await GamificationService.instance.createMission(
      title: result.title,
      frequency: result.frequency,
      metric: result.metric,
      target: result.target,
      reward: result.reward,
    );
    if (!mounted) return;
    if (created) {
      setState(() => _frequency = result.frequency);
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(lang.text('สร้างภารกิจไม่สำเร็จ กรุณาลองใหม่', 'Failed to create mission. Please try again.')),
      ));
    }
  }

  Future<void> _deleteMission(MissionItem mission) async {
    final deleted = await GamificationService.instance.deleteMission(mission.id);
    if (deleted && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LanguageController.instance,
      builder: (context, _) {
        final lang = LanguageController.instance;
        final data = _data ?? GamificationData.empty();
        final personal = data.personalMissions.where((m) => m.frequency == _frequency).toList();
        final label = {
          'daily': lang.text('รายวัน', 'Daily'),
          'weekly': lang.text('รายสัปดาห์', 'Weekly'),
          'monthly': lang.text('รายเดือน', 'Monthly'),
        }[_frequency]!;

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                children: [
                  Text(
                    lang.text('ภารกิจและเหรียญตรา', 'Missions & Badges'),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lang.text(
                      'สร้างเป้าหมายของคุณ และเก็บแต้มจากทุกก้าวที่ทำสำเร็จ',
                      'Set your goals and earn points with every completed step',
                    ),
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  _pointsCard(data, lang),
                  const SizedBox(height: 24),
                  Text(
                    lang.text('ภารกิจของฉัน', 'My Missions'),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    lang.text(
                      'ความคืบหน้าจะรีเซ็ตตามรอบที่เลือก',
                      'Progress resets according to selected cycle',
                    ),
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  _frequencyTabs(lang),
                  const SizedBox(height: 14),
                  if (_loading)
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    )
                  else if (personal.isEmpty)
                    _emptyMission(label, lang)
                  else
                    ...personal.map((mission) => _missionCard(mission, lang, personal: true)),
                  if (!_loading && _frequency == 'weekly') ...[
                    const SizedBox(height: 22),
                    Text(
                      lang.text('ภารกิจแนะนำประจำสัปดาห์', 'Weekly Recommended Missions'),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    ...data.missions.map((mission) => _missionCard(mission, lang)),
                  ],
                  if (!_loading) ...[
                    const SizedBox(height: 24),
                    Text(
                      lang.text('เหรียญตราของฉัน', 'My Badges'),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: data.badges.map(_badge).toList(),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              left: 20,
              bottom: 20,
              child: FloatingActionButton.extended(
                heroTag: 'createMission',
                onPressed: _createMission,
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.add_task_rounded, color: Colors.white),
                label: Text(
                  lang.text('สร้างภารกิจ', 'Create Mission'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _pointsCard(GamificationData data, LanguageController lang) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: LinearGradient(
        colors: AppColors.goldGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.gold.withValues(alpha: 0.3),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.25),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.stars_rounded, color: Colors.white, size: 34),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            '${data.totalPoints} ${lang.pts}',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            lang.text(
              'วิ่งสะสม ${data.totalDistanceKm.toStringAsFixed(1)} ${lang.km} · ต่อเนื่อง ${data.currentStreakDays} ${lang.days}',
              'Total ${data.totalDistanceKm.toStringAsFixed(1)} ${lang.km} · Streak ${data.currentStreakDays} ${lang.days}',
            ),
            style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ]),
      ),
    ]),
  );

  Widget _frequencyTabs(LanguageController lang) {
    final items = [
      ('daily', lang.text('วัน', 'Day')),
      ('weekly', lang.text('สัปดาห์', 'Week')),
      ('monthly', lang.text('เดือน', 'Month')),
    ];
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        for (final item in items)
          Expanded(child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _frequency = item.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _frequency == item.$1 ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: _frequency == item.$1
                    ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]
                    : null,
              ),
              child: Text(
                item.$2,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: _frequency == item.$1 ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          )),
      ]),
    );
  }

  Widget _emptyMission(String label, LanguageController lang) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
    child: Column(children: [
      Icon(Icons.flag_outlined, color: AppColors.primary, size: 34),
      const SizedBox(height: 10),
      Text(
        lang.text('ยังไม่มีภารกิจ$label', 'No $label missions yet'),
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
      const SizedBox(height: 4),
      Text(
        lang.text('กด “สร้างภารกิจ” เพื่อเริ่มตั้งเป้าหมาย', 'Tap "Create Mission" to start setting goals'),
        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
      ),
    ]),
  );

  Widget _missionCard(MissionItem m, LanguageController lang, {bool personal = false}) {
    final unitLabel = m.unit == 'กม.'
        ? lang.km
        : (m.unit == 'ครั้ง' ? lang.runs : m.unit);
    final completedText = lang.text(' · สำเร็จแล้ว ✓', ' · Completed ✓');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .025), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(m.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5))),
          if (personal)
            IconButton(
              onPressed: () => _deleteMission(m),
              icon: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
              tooltip: lang.text('ลบภารกิจ', 'Delete mission'),
            )
          else
            _reward(m, lang),
        ]),
        if (personal) Align(alignment: Alignment.centerRight, child: _reward(m, lang)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: m.progress,
            minHeight: 8,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation(m.completed ? AppColors.gold : AppColors.primary),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${m.current.toStringAsFixed(m.current % 1 == 0 ? 0 : 1)} / ${m.target.toStringAsFixed(m.target % 1 == 0 ? 0 : 1)} $unitLabel${m.completed ? completedText : ''}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: m.completed ? AppColors.gold : AppColors.textSecondary,
          ),
        ),
      ]),
    );
  }

  Widget _reward(MissionItem m, LanguageController lang) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: (m.completed ? AppColors.gold : AppColors.accent).withValues(alpha: .12),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      m.completed ? lang.text('สำเร็จ ✓', 'Done ✓') : '+${m.reward} pt',
      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: m.completed ? AppColors.gold : AppColors.accent),
    ),
  );

  Widget _badge(BadgeItem b) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: b.unlocked ? AppColors.gold.withValues(alpha: .5) : AppColors.divider,
        width: b.unlocked ? 1.5 : 1,
      ),
    ),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Opacity(opacity: b.unlocked ? 1 : .25, child: Text(b.emoji, style: const TextStyle(fontSize: 32))),
      const SizedBox(height: 6),
      Text(
        b.title,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: b.unlocked ? AppColors.textPrimary : AppColors.textSecondary),
      ),
    ]),
  );
}

class _MissionDraft {
  final String title, frequency, metric;
  final double target;
  final int reward;
  const _MissionDraft(this.title, this.frequency, this.metric, this.target, this.reward);
}

class _MissionDialog extends StatefulWidget {
  const _MissionDialog();
  @override State<_MissionDialog> createState() => _MissionDialogState();
}

class _MissionDialogState extends State<_MissionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _target = TextEditingController();
  String _frequency = 'daily';
  String _metric = 'distance';

  @override void dispose() { _title.dispose(); _target.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LanguageController.instance,
      builder: (context, _) {
        final lang = LanguageController.instance;
        return AlertDialog(
          title: Text(lang.text('สร้างภารกิจของฉัน', 'Create My Mission')),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                  controller: _title,
                  decoration: InputDecoration(
                    labelText: lang.text('ชื่อภารกิจ', 'Mission Name'),
                    hintText: lang.text('เช่น วิ่งรับอรุณ', 'e.g. Morning Run'),
                  ),
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? lang.text('กรุณาระบุชื่อภารกิจ', 'Please enter mission name')
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _frequency,
                  decoration: InputDecoration(labelText: lang.text('รอบภารกิจ', 'Frequency')),
                  items: [
                    DropdownMenuItem(value: 'daily', child: Text(lang.text('รายวัน', 'Daily'))),
                    DropdownMenuItem(value: 'weekly', child: Text(lang.text('รายสัปดาห์', 'Weekly'))),
                    DropdownMenuItem(value: 'monthly', child: Text(lang.text('รายเดือน', 'Monthly'))),
                  ],
                  onChanged: (v) => setState(() => _frequency = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _metric,
                  decoration: InputDecoration(labelText: lang.text('เป้าหมาย', 'Target Metric')),
                  items: [
                    DropdownMenuItem(value: 'distance', child: Text(lang.text('ระยะทาง (กม.)', 'Distance (km)'))),
                    DropdownMenuItem(value: 'runs', child: Text(lang.text('จำนวนครั้งวิ่ง', 'Number of runs'))),
                  ],
                  onChanged: (v) => setState(() => _metric = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _target,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: _metric == 'distance'
                        ? lang.text('เป้าหมาย (กม.)', 'Target (km)')
                        : lang.text('เป้าหมาย (ครั้ง)', 'Target (runs)'),
                  ),
                  validator: (v) => (double.tryParse(v ?? '') ?? 0) > 0
                      ? null
                      : lang.text('ระบุจำนวนที่มากกว่า 0', 'Please enter an amount > 0'),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.text('ยกเลิก', 'Cancel')),
            ),
            FilledButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.pop(context, _MissionDraft(_title.text.trim(), _frequency, _metric, double.parse(_target.text), 25));
                }
              },
              child: Text(lang.text('สร้าง', 'Create')),
            ),
          ],
        );
      },
    );
  }
}
