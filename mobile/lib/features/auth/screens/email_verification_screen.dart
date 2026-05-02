import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/providers.dart';
import '../auth_controller.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  bool _resending = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_codeCtrl.text.trim().length != 6) {
      setState(() => _error = 'الكود 6 أرقام');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      await ref.read(authRepositoryProvider).confirmEmail(_codeCtrl.text.trim());
      await ref.read(authControllerProvider.notifier).refreshMe();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تأكيد البريد الإلكتروني ✓')),
      );
      Navigator.of(context).pop();
    } catch (_) {
      setState(() => _error = 'الكود غير صحيح أو انتهت صلاحيته');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _info = null;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).requestEmailVerification();
      if (!mounted) return;
      setState(() => _info = 'تم إرسال كود جديد لبريدك');
    } catch (_) {
      setState(() => _error = 'تعذر إرسال الكود الآن');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    return Scaffold(
      appBar: AppBar(title: const Text('تأكيد البريد الإلكتروني')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
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
                  child: const Icon(Icons.mark_email_read_outlined,
                      size: 48, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'تأكد من بريدك الإلكتروني',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'بعتنا كود مكون من 6 أرقام إلى\n${user?.email ?? ''}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
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
              if (_info != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _info!,
                    style: const TextStyle(color: AppColors.success),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _confirm,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: Colors.white),
                      )
                    : const Text('تأكيد الكود'),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: _resending
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 18),
                label: const Text('إعادة إرسال الكود'),
                onPressed: _resending ? null : _resend,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
