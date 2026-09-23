import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/language_toggle.dart';
import '../../services/auth_service.dart';
import '../../services/language_controller.dart';
import '../main_navigation.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _medicalCtrl = TextEditingController();

  String _selectedLevel = 'คนทั่วไป';
  String _selectedGoal = 'เพื่อสุขภาพ';

  bool _obscure = true;
  bool _loading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _weightCtrl.addListener(_onBodyStatsChanged);
    _heightCtrl.addListener(_onBodyStatsChanged);
  }

  void _onBodyStatsChanged() {
    setState(() {});
  }

  double? get _calculatedBmi {
    final w = double.tryParse(_weightCtrl.text.trim());
    final h = double.tryParse(_heightCtrl.text.trim());
    if (w != null && h != null && w > 0 && h > 0) {
      final heightM = h / 100;
      return w / (heightM * heightM);
    }
    return null;
  }

  String get _bmiCategoryText {
    final bmi = _calculatedBmi;
    if (bmi == null) return '';
    final isTh = LanguageController.instance.isThai;
    if (bmi < 18.5) return isTh ? 'น้ำหนักน้อย' : 'Underweight';
    if (bmi < 23) return isTh ? 'สมส่วน' : 'Normal';
    if (bmi < 25) return isTh ? 'ท้วม' : 'Overweight';
    return isTh ? 'เกินเกณฑ์' : 'Obese';
  }

  Future<void> _handleRegister() async {
    final isTh = LanguageController.instance.isThai;
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    final weight = double.tryParse(_weightCtrl.text.trim());
    final height = double.tryParse(_heightCtrl.text.trim());
    final age = int.tryParse(_ageCtrl.text.trim());
    final medicalCondition = _medicalCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorText = isTh ? 'กรุณากรอกข้อมูลบัญชีให้ครบ' : 'Please fill in all required fields');
      return;
    }
    if (password.length < 8) {
      setState(() => _errorText = isTh ? 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร' : 'Password must be at least 8 characters');
      return;
    }

    if (_weightCtrl.text.trim().isNotEmpty && (weight == null || weight <= 0 || weight > 300)) {
      setState(() => _errorText = isTh ? 'กรุณาระบุน้ำหนักให้ถูกต้อง' : 'Please enter a valid weight');
      return;
    }
    if (_heightCtrl.text.trim().isNotEmpty && (height == null || height <= 0 || height > 260)) {
      setState(() => _errorText = isTh ? 'กรุณาระบุส่วนสูงให้ถูกต้อง' : 'Please enter a valid height');
      return;
    }
    if (_ageCtrl.text.trim().isNotEmpty && (age == null || age <= 0 || age > 120)) {
      setState(() => _errorText = isTh ? 'กรุณาระบุอายุให้ถูกต้อง' : 'Please enter a valid age');
      return;
    }

    setState(() {
      _loading = true;
      _errorText = null;
    });

    final result = await AuthService.instance.register(
      name: name,
      email: email,
      password: password,
      weight: weight,
      height: height,
      age: age,
      medicalCondition: medicalCondition.isNotEmpty ? medicalCondition : 'ไม่มี',
      level: _selectedLevel,
      goal: _selectedGoal,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    } else {
      setState(() => _errorText = result.errorMessage ?? (isTh ? 'สมัครสมาชิกไม่สำเร็จ' : 'Registration failed'));
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _loading = true;
      _errorText = null;
    });

    final result = await AuthService.instance.loginWithGoogle();

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    } else if (result.errorMessage != null) {
      setState(() => _errorText = result.errorMessage);
    }
  }

  @override
  void dispose() {
    _weightCtrl.removeListener(_onBodyStatsChanged);
    _heightCtrl.removeListener(_onBodyStatsChanged);
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _ageCtrl.dispose();
    _medicalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LanguageController.instance,
      builder: (context, _) {
        final isTh = LanguageController.instance.isThai;
        final bmi = _calculatedBmi;

        final levelOptions = [
          {
            'id': 'มือสมัครเล่น',
            'title': isTh ? 'มือสมัครเล่น' : 'Beginner',
            'desc': isTh ? 'เพิ่งเริ่มต้นวิ่ง หรือวิ่งสัปดาห์ละ 1-2 ครั้ง' : 'New to running or jogs 1-2 times a week',
            'tag': isTh ? 'เริ่มต้น' : 'Starter',
            'icon': Icons.directions_walk_rounded,
          },
          {
            'id': 'คนทั่วไป',
            'title': isTh ? 'คนทั่วไป' : 'Regular',
            'desc': isTh ? 'วิ่งออกกำลังกายสม่ำเสมอ ร่างกายคุ้นเคยกับการวิ่ง' : 'Runs regularly for stamina and overall fitness',
            'tag': isTh ? 'สม่ำเสมอ' : 'Active',
            'icon': Icons.directions_run_rounded,
          },
          {
            'id': 'มือโปร',
            'title': isTh ? 'มือโปร' : 'Advanced',
            'desc': isTh ? 'ซ้อมอย่างมีแบบแผน มีเป้าหมายเวลาหรือลงแข่ง' : 'Structured training with pace targets and races',
            'tag': isTh ? 'จริงจัง' : 'Performance',
            'icon': Icons.speed_rounded,
          },
        ];

        final goalOptions = [
          {
            'id': 'เพื่อสุขภาพ',
            'title': isTh ? 'เพื่อสุขภาพ' : 'General Health',
            'desc': isTh ? 'เพิ่มความแข็งแรงของหัวใจ ผ่อนคลาย และรักษาสุขภาพ' : 'Cardiovascular endurance, stamina, and well-being',
            'icon': Icons.favorite_border_rounded,
          },
          {
            'id': 'เพื่อสร้างหุ่น',
            'title': isTh ? 'เพื่อสร้างหุ่น' : 'Fitness & Physique',
            'desc': isTh ? 'เผาผลาญไขมันในโซน 2 กระชับสัดส่วนและควบคุมน้ำหนัก' : 'Fat burn in Zone 2, toning, and weight management',
            'icon': Icons.accessibility_new_rounded,
          },
          {
            'id': 'เพื่อแข่งขัน',
            'title': isTh ? 'เพื่อแข่งขัน' : 'Race & Speed',
            'desc': isTh ? 'พัฒนาเพซ ฝึกซ้อมคอร์ท และเตรียมพร้อมสำหรับวันแข่งขัน' : 'Intervals, tempo runs, and race readiness',
            'icon': Icons.flag_outlined,
          },
        ];

        final quickMedicalChips = isTh
            ? ['ไม่มี', 'หอบหืด', 'ความดันโลหิต', 'โรคหัวใจ', 'ปวดข้อ/เข่า', 'เบาหวาน']
            : ['None', 'Asthma', 'Hypertension', 'Heart condition', 'Joint pain', 'Diabetes'];

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 16),
                child: LanguageToggle(compact: true),
              ),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        isTh ? 'สร้างบัญชีนักวิ่ง' : 'Create Account',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isTh
                            ? 'ตั้งค่าข้อมูลของคุณเพื่อช่วยให้โค้ชออกแบบตารางซ้อมที่เหมาะกับร่างกายคุณ'
                            : 'Set up your profile so our training coach can tailor workouts to your body.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13.5,
                          height: 1.45,
                        ),
                      ),

                      const SizedBox(height: 24),

                      if (_errorText != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorText!,
                                  style: TextStyle(
                                    color: AppColors.primaryDark,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // 1. Account Section
                      _SectionTitle(title: isTh ? 'ข้อมูลบัญชี' : 'Account Details'),
                      const SizedBox(height: 10),

                      _InputLabel(label: isTh ? 'ชื่อ-นามสกุล' : 'Full Name', isRequired: true),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          hintText: isTh ? 'เช่น สมชาย ใจมั่น' : 'e.g. Alex Hunter',
                          prefixIcon: Icon(Icons.person_outline_rounded, size: 20, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 14),

                      _InputLabel(label: isTh ? 'อีเมล' : 'Email Address', isRequired: true),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'you@example.com',
                          prefixIcon: Icon(Icons.mail_outline_rounded, size: 20, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 14),

                      _InputLabel(label: isTh ? 'รหัสผ่าน' : 'Password', isRequired: true),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          hintText: isTh ? 'อย่างน้อย 8 ตัวอักษร' : 'Minimum 8 characters',
                          prefixIcon: Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.textSecondary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),

                      const SizedBox(height: 26),

                      // 2. Physical & Health Section
                      _SectionTitle(title: isTh ? 'ข้อมูลสรีระและสุขภาพ' : 'Body & Health'),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _InputLabel(label: isTh ? 'น้ำหนัก (กก.)' : 'Weight (kg)'),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _weightCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    hintText: isTh ? 'เช่น 65' : '65',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _InputLabel(label: isTh ? 'ส่วนสูง (ซม.)' : 'Height (cm)'),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _heightCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    hintText: isTh ? 'เช่น 175' : '175',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _InputLabel(label: isTh ? 'อายุ (ปี)' : 'Age (yrs)'),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _ageCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: isTh ? 'เช่น 25' : '25',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if (bmi != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'BMI: ${bmi.toStringAsFixed(1)}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text('•', style: TextStyle(color: AppColors.textSecondary)),
                              ),
                              Text(
                                _bmiCategoryText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      _InputLabel(label: isTh ? 'โรคประจำตัว / ข้อจำกัดสุขภาพ' : 'Medical conditions / Limitations'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _medicalCtrl,
                        decoration: InputDecoration(
                          hintText: isTh ? 'ไม่มี หรือระบุ เช่น หอบหืด, เจ็บเข่า' : 'None, or asthma, joint injury...',
                          prefixIcon: Icon(Icons.shield_outlined, size: 20, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: quickMedicalChips.map((chipText) {
                          final isSelected = _medicalCtrl.text.trim().toLowerCase() == chipText.toLowerCase();
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _medicalCtrl.text = chipText;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primaryLight : AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.divider,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                chipText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 26),

                      // 3. Level Section
                      _SectionTitle(title: isTh ? 'ระดับความคุ้นเคยกับการวิ่ง' : 'Running Experience'),
                      const SizedBox(height: 10),

                      Column(
                        children: levelOptions.map((opt) {
                          final isSelected = _selectedLevel == opt['id'];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () => setState(() => _selectedLevel = opt['id'] as String),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.surface : AppColors.surface.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.divider,
                                    width: isSelected ? 1.8 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.primaryLight : AppColors.background,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        opt['icon'] as IconData,
                                        size: 19,
                                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                opt['title'] as String,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: AppColors.background,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  opt['tag'] as String,
                                                  style: TextStyle(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            opt['desc'] as String,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                                      color: isSelected ? AppColors.primary : AppColors.divider,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 22),

                      // 4. Goal Section
                      _SectionTitle(title: isTh ? 'เป้าหมายหลักของคุณ' : 'Primary Goal'),
                      const SizedBox(height: 10),

                      Column(
                        children: goalOptions.map((opt) {
                          final isSelected = _selectedGoal == opt['id'];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () => setState(() => _selectedGoal = opt['id'] as String),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.surface : AppColors.surface.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.divider,
                                    width: isSelected ? 1.8 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.primaryLight : AppColors.background,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        opt['icon'] as IconData,
                                        size: 19,
                                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            opt['title'] as String,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            opt['desc'] as String,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                                      color: isSelected ? AppColors.primary : AppColors.divider,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 26),

                      PrimaryButton(
                        label: isTh ? 'สมัครสมาชิก' : 'Create Account',
                        onPressed: _handleRegister,
                        loading: _loading,
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(child: Divider(color: AppColors.divider)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              isTh ? 'หรือ' : 'or',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: AppColors.divider)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      SocialLoginButton(
                        label: isTh ? 'ดำเนินการต่อด้วย Google' : 'Continue with Google',
                        onPressed: _loading ? null : _handleGoogleLogin,
                      ),

                      const SizedBox(height: 28),

                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isTh ? 'มีบัญชีอยู่แล้ว? ' : 'Already have an account? ',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13.5,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Text(
                                  isTh ? 'เข้าสู่ระบบ' : 'Sign In',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  final String label;
  final bool isRequired;

  const _InputLabel({required this.label, this.isRequired = false});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
          color: AppColors.textPrimary,
          fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
        ),
        children: isRequired
            ? [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ]
            : null,
      ),
    );
  }
}
