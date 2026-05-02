import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ctrls = <String, TextEditingController>{
    'email': TextEditingController(),
    'password': TextEditingController(),
    'fullNameAr': TextEditingController(),
    'fullNameEn': TextEditingController(),
    'judicialRank': TextEditingController(),
    'currentCourt': TextEditingController(),
    'mobile': TextEditingController(),
    'whatsapp': TextEditingController(),
    'address': TextEditingController(),
    'governorate': TextEditingController(),
    'specialization': TextEditingController(),
    'currentPosition': TextEditingController(),
  };
  DateTime? _birthDate;
  DateTime? _appointmentDate;

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(BuildContext ctx, bool isBirth) async {
    final initial = isBirth ? (_birthDate ?? DateTime(1980)) : (_appointmentDate ?? DateTime(2010));
    final picked = await showDatePicker(
      context: ctx,
      initialDate: initial,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isBirth) {
          _birthDate = picked;
        } else {
          _appointmentDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final body = <String, dynamic>{
      for (final e in _ctrls.entries)
        if (e.value.text.trim().isNotEmpty) e.key: e.value.text.trim(),
      if (_birthDate != null) 'birthDate': _birthDate!.toIso8601String(),
      if (_appointmentDate != null) 'appointmentDate': _appointmentDate!.toIso8601String(),
    };
    final ok = await ref.read(authControllerProvider.notifier).register(body);
    if (ok && mounted) context.go('/awaiting');
  }

  Widget _field(
    String key,
    String label, {
    bool required = false,
    TextInputType? keyboard,
    bool obscure = false,
    String? Function(String?)? validator,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _ctrls[key],
        obscureText: obscure,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label, hintText: hint),
        validator: validator ??
            (required
                ? (v) => (v == null || v.trim().isEmpty) ? 'الحقل مطلوب' : null
                : null),
      ),
    );
  }

  String? _validateFullName(String? v) {
    if (v == null || v.trim().isEmpty) return 'الحقل مطلوب';
    final words = v.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.length < 4) return 'الاسم لازم يكون رباعي (4 أسماء على الأقل)';
    return null;
  }

  Widget _dateField(String label, DateTime? value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
          ),
          child: Text(
            value == null ? 'اختر التاريخ' : DateFormat('yyyy/MM/dd', 'ar').format(value),
            style: TextStyle(color: value == null ? AppColors.textSecondary : AppColors.textPrimary),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل عضوية جديدة')),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _section('بيانات الحساب'),
                _field('email', 'البريد الإلكتروني', required: true, keyboard: TextInputType.emailAddress),
                _field('password', 'كلمة المرور (8 أحرف على الأقل)', required: true, obscure: true),
                _section('البيانات الأساسية'),
                _field(
                  'fullNameAr',
                  'الاسم رباعي',
                  required: true,
                  validator: _validateFullName,
                  hint: 'مثال: أحمد محمد علي حسن',
                ),
                _field(
                  'fullNameEn',
                  'اسم الشهرة',
                  hint: 'الاسم اللي بيعرفك بيه الزملاء',
                ),
                _field('judicialRank', 'الدرجة الوظيفية (مثال: مستشار)', required: true),
                _field('currentCourt', 'المحكمة الحالية', required: true),
                _field('currentPosition', 'المنصب الحالي'),
                _section('بيانات التواصل'),
                _field('mobile', 'رقم الموبايل', required: true, keyboard: TextInputType.phone),
                _field('whatsapp', 'رقم واتساب', keyboard: TextInputType.phone),
                _section('بيانات وظيفية وشخصية'),
                _field('governorate', 'المحافظة'),
                _field('specialization', 'التخصص'),
                _dateField('تاريخ التعيين', _appointmentDate, () => _pickDate(context, false)),
                _dateField('تاريخ الميلاد', _birthDate, () => _pickDate(context, true)),
                _field('address', 'العنوان'),
                if (state.error != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(state.error!, style: const TextStyle(color: AppColors.danger)),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: state.loading ? null : _submit,
                  child: state.loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                      : const Text('تسجيل الطلب'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'الطلب هيتراجع من إدارة النادي قبل التفعيل',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'بالتسجيل، أنت توافق على ',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    InkWell(
                      onTap: () => context.push('/legal/terms'),
                      child: const Text(
                        'شروط الاستخدام',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Text(
                      ' و ',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    InkWell(
                      onTap: () => context.push('/legal/privacy'),
                      child: const Text(
                        'سياسة الخصوصية',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      );
}
