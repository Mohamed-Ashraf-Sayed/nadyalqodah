import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/providers.dart';
import '../../auth/auth_controller.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_passwordCtrl.text.isEmpty) {
      setState(() => _error = 'أدخل كلمة المرور');
      return;
    }
    if (_confirmCtrl.text.trim() != 'حذف') {
      setState(() => _error = 'اكتب "حذف" للتأكيد');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).deleteAccount(_passwordCtrl.text);
      // Force auth controller to clear state
      await ref.read(authControllerProvider.notifier).logout();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الحساب')),
      );
      context.go('/login');
    } catch (e) {
      final msg = e.toString();
      String error = 'فشل الحذف';
      if (msg.contains('invalid_password')) {
        error = 'كلمة المرور غير صحيحة';
      } else if (msg.contains('last_super_admin')) {
        error = 'لا يمكن حذف آخر مدير عام';
      }
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حذف الحساب')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.warning_amber_outlined,
                            color: AppColors.danger),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'هذه عملية لا يمكن التراجع عنها',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'بحذف الحساب، سيتم:',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  ..._bullet('إزالة بياناتك من دليل الأعضاء'),
                  ..._bullet('حذف صورتك ومعلوماتك الشخصية'),
                  ..._bullet('إنهاء جميع جلسات الدخول'),
                  ..._bullet('حذف اقتراحاتك وشكاوايا'),
                  const SizedBox(height: 8),
                  const Text(
                    'الأخبار والتعاقدات والأحداث اللي نشرتها كأدمن هتفضل في النظام بدون اسم.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'كلمة المرور',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                hintText: 'أدخل كلمة المرور للتأكيد',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'اكتب "حذف" للتأكيد',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _confirmCtrl,
              decoration: const InputDecoration(
                hintText: 'حذف',
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
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever),
              label: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white),
                    )
                  : const Text('حذف الحساب نهائيًا'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
              ),
              onPressed: _loading ? null : _delete,
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _loading ? null : () => context.pop(),
              child: const Text('إلغاء'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _bullet(String text) => [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ',
                  style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w900)),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 13, height: 1.6),
                ),
              ),
            ],
          ),
        ),
      ];
}
