import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

enum _Step { email, code, password, done }

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  _Step _step = _Step.email;

  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  String? _error;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _setError(String? msg) => setState(() => _error = msg);

  Future<void> _requestCode() async {
    final email = _emailCtrl.text.trim();
    if (!email.contains('@')) {
      _setError('إيميل غير صحيح');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(email);
      if (!mounted) return;
      setState(() => _step = _Step.code);
    } catch (_) {
      _setError('حدث خطأ، حاول لاحقًا');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_codeCtrl.text.trim().length != 6) {
      _setError('الكود 6 أرقام');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).verifyResetCode(
            _emailCtrl.text.trim(),
            _codeCtrl.text.trim(),
          );
      if (!mounted) return;
      setState(() => _step = _Step.password);
    } catch (_) {
      _setError('الكود غير صحيح أو انتهت صلاحيته');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final pass = _newPassCtrl.text;
    if (pass.length < 8 ||
        !RegExp(r'[a-zA-Z]').hasMatch(pass) ||
        !RegExp(r'\d').hasMatch(pass)) {
      _setError('كلمة المرور: 8 حروف على الأقل + حرف ورقم');
      return;
    }
    if (pass != _confirmCtrl.text) {
      _setError('كلمات المرور غير متطابقة');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            _emailCtrl.text.trim(),
            _codeCtrl.text.trim(),
            pass,
          );
      if (!mounted) return;
      setState(() => _step = _Step.done);
    } catch (_) {
      _setError('فشل تحديث كلمة المرور');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('استعادة كلمة المرور')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _Step.email:
        return _emailStep();
      case _Step.code:
        return _codeStep();
      case _Step.password:
        return _passwordStep();
      case _Step.done:
        return _doneStep();
    }
  }

  Widget _wrapper({required IconData icon, required String title, required String subtitle, required List<Widget> children}) {
    return Column(
      key: ValueKey(_step),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.6),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        ...children,
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.danger),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Widget _emailStep() => _wrapper(
        icon: Icons.email_outlined,
        title: 'أدخل بريدك الإلكتروني',
        subtitle: 'هنرسل لك كود مكون من 6 أرقام',
        children: [
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              labelText: 'البريد الإلكتروني',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loading ? null : _requestCode,
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: Colors.white),
                  )
                : const Text('إرسال الكود'),
          ),
        ],
      );

  Widget _codeStep() => _wrapper(
        icon: Icons.pin_outlined,
        title: 'أدخل الكود',
        subtitle: 'تم إرسال كود التحقق إلى\n${_emailCtrl.text.trim()}',
        children: [
          TextField(
            controller: _codeCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 8,
            ),
            decoration: const InputDecoration(
              labelText: 'الكود',
              counterText: '',
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loading ? null : _verifyCode,
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: Colors.white),
                  )
                : const Text('تحقق'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loading
                ? null
                : () => setState(() {
                      _step = _Step.email;
                      _codeCtrl.clear();
                    }),
            child: const Text('غيّرت رأيي - إعادة إدخال الإيميل'),
          ),
        ],
      );

  Widget _passwordStep() => _wrapper(
        icon: Icons.lock_outline,
        title: 'كلمة مرور جديدة',
        subtitle: '8 حروف على الأقل، تحتوي على حرف ورقم',
        children: [
          TextField(
            controller: _newPassCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'كلمة المرور الجديدة',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmCtrl,
            obscureText: _obscure,
            decoration: const InputDecoration(
              labelText: 'تأكيد كلمة المرور',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loading ? null : _resetPassword,
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: Colors.white),
                  )
                : const Text('تحديث كلمة المرور'),
          ),
        ],
      );

  Widget _doneStep() => Column(
        key: const ValueKey('done'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, size: 56, color: AppColors.success),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'تم تحديث كلمة المرور',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'تقدر دلوقتي تسجل دخول بكلمة المرور الجديدة',
            style: TextStyle(color: AppColors.textSecondary, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => context.go('/login'),
            child: const Text('الذهاب لتسجيل الدخول'),
          ),
        ],
      );
}
