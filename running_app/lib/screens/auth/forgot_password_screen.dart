import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 1; // 1 = ขอ OTP, 2 = กรอก OTP และรหัสใหม่, 3 = สำเร็จ
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _loading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _otpDevHint;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showError('กรุณากรอกอีเมลที่ใช้สมัครบัญชี');
      return;
    }

    setState(() => _loading = true);
    final res = await AuthService.instance.forgotPassword(email: email);
    if (!mounted) return;
    setState(() => _loading = false);

    if (res.success) {
      setState(() {
        _step = 2;
        _otpDevHint = res.otpCode;
      });
      if (res.otpCode != null) {
        _otpCtrl.text = res.otpCode!; // กรอกให้อัตโนมัติในโหมดพัฒนา
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.otpCode != null
              ? 'รหัส OTP (สำหรับทดสอบ): ${res.otpCode}'
              : 'ส่งรหัส OTP ไปยังอีเมลของคุณแล้ว'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      _showError(res.errorMessage ?? 'เกิดข้อผิดพลาดในการขอ OTP');
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    final otp = _otpCtrl.text.trim();
    final newPass = _newPasswordCtrl.text.trim();
    final confirmPass = _confirmPasswordCtrl.text.trim();

    if (otp.length != 6) {
      _showError('กรุณากรอกรหัส OTP 6 หลัก');
      return;
    }
    if (newPass.length < 8) {
      _showError('รหัสผ่านใหม่ต้องมีความยาวอย่างน้อย 8 ตัวอักษร');
      return;
    }
    if (newPass != confirmPass) {
      _showError('รหัสผ่านยืนยันไม่ตรงกัน');
      return;
    }

    setState(() => _loading = true);
    final res = await AuthService.instance.resetPassword(
      email: email,
      otp: otp,
      newPassword: newPass,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (res.success) {
      setState(() => _step = 3);
    } else {
      _showError(res.errorMessage ?? 'เกิดข้อผิดพลาดในการเปลี่ยนรหัสผ่าน');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFE82A2A)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('ลืมรหัสผ่าน'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_step == 1) _buildStep1(),
              if (_step == 2) _buildStep2(),
              if (_step == 3) _buildStep3(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.lock_reset_rounded, size: 36, color: AppColors.primary),
        ),
        const SizedBox(height: 20),
        Text(
          'กู้คืนรหัสผ่าน 🔐',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'กรอกอีเมลที่คุณใช้สมัครบัญชี ระบบจะสร้างรหัส OTP เพื่อยืนยันการตั้งรหัสผ่านใหม่',
          style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'อีเมลที่สมัคร',
            hintText: 'example@email.com',
            prefixIcon: const Icon(Icons.email_outlined),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: 'ขอรับรหัส OTP',
          icon: Icons.send_rounded,
          onPressed: _requestOtp,
          loading: _loading,
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ตั้งรหัสผ่านใหม่ 🔑',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'กรอกรหัส OTP 6 หลัก และกำหนดรหัสผ่านใหม่ของคุณ',
          style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
        ),
        if (_otpDevHint != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'OTP สำหรับทดสอบ: $_otpDevHint',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        TextField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            labelText: 'รหัส OTP 6 หลัก',
            prefixIcon: const Icon(Icons.pin_outlined),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _newPasswordCtrl,
          obscureText: _obscureNew,
          decoration: InputDecoration(
            labelText: 'รหัสผ่านใหม่ (อย่างน้อย 8 ตัวอักษร)',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordCtrl,
          obscureText: _obscureConfirm,
          decoration: InputDecoration(
            labelText: 'ยืนยันรหัสผ่านใหม่',
            prefixIcon: const Icon(Icons.lock_clock_outlined),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: 'ยืนยันการเปลี่ยนรหัสผ่าน',
          icon: Icons.check_circle_outline,
          onPressed: _resetPassword,
          loading: _loading,
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              'เปลี่ยนรหัสผ่านสำเร็จ! 🎉',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'รหัสผ่านของคุณถูกอัปเดตแล้ว สามารถเข้าสู่ระบบด้วยรหัสใหม่ได้ทันที',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 36),
            PrimaryButton(
              label: 'กลับไปหน้าเข้าสู่ระบบ',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
