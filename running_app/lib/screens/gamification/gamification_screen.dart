import 'package:flutter/material.dart';
import '../../services/gamification_service.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('สร้างภารกิจไม่สำเร็จ กรุณาลองใหม่')));
    }
  }

  Future<void> _deleteMission(MissionItem mission) async {
    final deleted = await GamificationService.instance.deleteMission(mission.id);
    if (deleted && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data ?? GamificationData.empty();
    final personal = data.personalMissions.where((m) => m.frequency == _frequency).toList();
    final label = {'daily': 'รายวัน', 'weekly': 'รายสัปดาห์', 'monthly': 'รายเดือน'}[_frequency]!;
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            children: [
              const Text('ภารกิจและเหรียญตรา 🏆', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('สร้างเป้าหมายของคุณ และเก็บแต้มจากทุกก้าวที่ทำสำเร็จ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),
              _pointsCard(data),
              const SizedBox(height: 24),
              const Text('ภารกิจของฉัน', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 5),
              const Text('ความคืบหน้าจะรีเซ็ตตามรอบที่เลือก', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 14),
              _frequencyTabs(),
              const SizedBox(height: 14),
              if (_loading)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
              else if (personal.isEmpty)
                _emptyMission(label)
              else
                ...personal.map((mission) => _missionCard(mission, personal: true)),
              if (!_loading && _frequency == 'weekly') ...[
                const SizedBox(height: 22),
                const Text('ภารกิจแนะนำประจำสัปดาห์', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 12),
                ...data.missions.map((mission) => _missionCard(mission)),
              ],
              if (!_loading) ...[
                const SizedBox(height: 24),
                const Text('เหรียญตราของฉัน', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12, crossAxisSpacing: 12,
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
            label: const Text('สร้างภารกิจ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _pointsCard(GamificationData data) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: const LinearGradient(
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
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${data.totalPoints} แต้ม', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text('วิ่งสะสม ${data.totalDistanceKm.toStringAsFixed(1)} กม. · ต่อเนื่อง ${data.currentStreakDays} วัน', style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
      ]),
    ]),
  );

  Widget _frequencyTabs() => Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
    child: Row(children: [
      for (final item in const [('daily', 'วัน'), ('weekly', 'สัปดาห์'), ('monthly', 'เดือน')])
        Expanded(child: InkWell(
          borderRadius: BorderRadius.circular(12), onTap: () => setState(() => _frequency = item.$1),
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
            child: Text(item.$2, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: _frequency == item.$1 ? Colors.white : AppColors.textSecondary)),
          ),
        )),
    ]),
  );

  Widget _emptyMission(String label) => Container(
    padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
    child: Column(children: [
      const Icon(Icons.flag_outlined, color: AppColors.primary, size: 34), const SizedBox(height: 10),
      Text('ยังไม่มีภารกิจ$label', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)), const SizedBox(height: 4),
      const Text('กด “สร้างภารกิจ” เพื่อเริ่มตั้งเป้าหมาย', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
    ]),
  );

  Widget _missionCard(MissionItem m, {bool personal = false}) => Container(
    margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .025), blurRadius: 10, offset: const Offset(0, 3))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(m.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5))),
        if (personal) IconButton(onPressed: () => _deleteMission(m), icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary), tooltip: 'ลบภารกิจ')
        else _reward(m),
      ]),
      if (personal) Align(alignment: Alignment.centerRight, child: _reward(m)),
      const SizedBox(height: 10),
      ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: m.progress, minHeight: 8, backgroundColor: AppColors.divider, valueColor: AlwaysStoppedAnimation(m.completed ? AppColors.gold : AppColors.primary))),
      const SizedBox(height: 8),
      Text('${m.current.toStringAsFixed(m.current % 1 == 0 ? 0 : 1)} / ${m.target.toStringAsFixed(m.target % 1 == 0 ? 0 : 1)} ${m.unit}${m.completed ? ' · สำเร็จแล้ว ✓' : ''}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: m.completed ? AppColors.gold : AppColors.textSecondary)),
    ]),
  );

  Widget _reward(MissionItem m) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: (m.completed ? AppColors.gold : AppColors.accent).withValues(alpha: .12), borderRadius: BorderRadius.circular(10)), child: Text(m.completed ? 'สำเร็จ ✓' : '+${m.reward} pt', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: m.completed ? AppColors.gold : AppColors.accent)));

  Widget _badge(BadgeItem b) => Container(decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: b.unlocked ? AppColors.gold.withValues(alpha: .5) : AppColors.divider, width: b.unlocked ? 1.5 : 1)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Opacity(opacity: b.unlocked ? 1 : .25, child: Text(b.emoji, style: const TextStyle(fontSize: 32))), const SizedBox(height: 6), Text(b.title, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: b.unlocked ? AppColors.textPrimary : AppColors.textSecondary))]));
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
  @override Widget build(BuildContext context) => AlertDialog(
    title: const Text('สร้างภารกิจของฉัน'),
    content: Form(key: _formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextFormField(controller: _title, decoration: const InputDecoration(labelText: 'ชื่อภารกิจ', hintText: 'เช่น วิ่งรับอรุณ'), validator: (v) => (v?.trim().isEmpty ?? true) ? 'กรุณาระบุชื่อภารกิจ' : null),
      const SizedBox(height: 12),
      DropdownButtonFormField(initialValue: _frequency, decoration: const InputDecoration(labelText: 'รอบภารกิจ'), items: const [DropdownMenuItem(value: 'daily', child: Text('รายวัน')), DropdownMenuItem(value: 'weekly', child: Text('รายสัปดาห์')), DropdownMenuItem(value: 'monthly', child: Text('รายเดือน'))], onChanged: (v) => setState(() => _frequency = v!)),
      const SizedBox(height: 12),
      DropdownButtonFormField(initialValue: _metric, decoration: const InputDecoration(labelText: 'เป้าหมาย'), items: const [DropdownMenuItem(value: 'distance', child: Text('ระยะทาง (กม.)')), DropdownMenuItem(value: 'runs', child: Text('จำนวนครั้งวิ่ง'))], onChanged: (v) => setState(() => _metric = v!)),
      const SizedBox(height: 12),
      TextFormField(controller: _target, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: _metric == 'distance' ? 'เป้าหมาย (กม.)' : 'เป้าหมาย (ครั้ง)'), validator: (v) => (double.tryParse(v ?? '') ?? 0) > 0 ? null : 'ระบุจำนวนที่มากกว่า 0'),
    ]))),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')), FilledButton(onPressed: () { if (_formKey.currentState!.validate()) Navigator.pop(context, _MissionDraft(_title.text.trim(), _frequency, _metric, double.parse(_target.text), 25)); }, child: const Text('สร้าง'))],
  );
}
