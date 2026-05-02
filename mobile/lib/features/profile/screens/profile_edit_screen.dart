import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/providers/providers.dart';
import '../../auth/auth_controller.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _ctrls;
  DateTime? _birthDate;
  DateTime? _appointmentDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final m = ref.read(authControllerProvider).member;
    _ctrls = {
      'fullNameAr': TextEditingController(text: m?.fullNameAr ?? ''),
      'fullNameEn': TextEditingController(text: m?.fullNameEn ?? ''),
      'judicialRank': TextEditingController(text: m?.judicialRank ?? ''),
      'currentCourt': TextEditingController(text: m?.currentCourt ?? ''),
      'currentPosition': TextEditingController(text: m?.currentPosition ?? ''),
      'mobile': TextEditingController(text: m?.mobile ?? ''),
      'whatsapp': TextEditingController(text: m?.whatsapp ?? ''),
      'emailSecondary': TextEditingController(text: m?.emailSecondary ?? ''),
      'governorate': TextEditingController(text: m?.governorate ?? ''),
      'specialization': TextEditingController(text: m?.specialization ?? ''),
      'address': TextEditingController(text: m?.address ?? ''),
    };
    _birthDate = m?.birthDate;
    _appointmentDate = m?.appointmentDate;
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      // Required fields kept as is; optional fields sent as null when empty
      const requiredKeys = {'fullNameAr', 'judicialRank', 'currentCourt', 'mobile'};
      final data = <String, dynamic>{};
      for (final e in _ctrls.entries) {
        final value = e.value.text.trim();
        if (value.isEmpty && !requiredKeys.contains(e.key)) {
          data[e.key] = null;
        } else {
          data[e.key] = value;
        }
      }
      if (_birthDate != null) data['birthDate'] = _birthDate!.toIso8601String();
      if (_appointmentDate != null) {
        data['appointmentDate'] = _appointmentDate!.toIso8601String();
      }
      await ref.read(membersRepositoryProvider).updateMine(data);
      await ref.read(authControllerProvider.notifier).refreshMe();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ التعديلات')),
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل الحفظ، حاول مرة أخرى')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate(bool isBirth) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isBirth ? _birthDate : _appointmentDate) ?? DateTime(1990),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل البيانات')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ..._ctrls.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: e.value,
                    decoration: InputDecoration(
                      labelText: _label(e.key),
                      hintText: _hint(e.key),
                    ),
                    validator: _validatorFor(e.key),
                  ),
                )),
            _dateTile('تاريخ التعيين', _appointmentDate, () => _pickDate(false)),
            _dateTile('تاريخ الميلاد', _birthDate, () => _pickDate(true)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                    )
                  : const Text('حفظ التعديلات'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateTile(String label, DateTime? value, VoidCallback onTap) {
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
            value == null ? '—' : DateFormat('yyyy/MM/dd', 'ar').format(value),
          ),
        ),
      ),
    );
  }

  String _label(String key) {
    return const {
      'fullNameAr': 'الاسم رباعي',
      'fullNameEn': 'اسم الشهرة',
      'judicialRank': 'الدرجة الوظيفية',
      'currentCourt': 'المحكمة',
      'currentPosition': 'المنصب الحالي',
      'mobile': 'الموبايل',
      'whatsapp': 'واتساب',
      'emailSecondary': 'إيميل بديل',
      'governorate': 'المحافظة',
      'specialization': 'التخصص',
      'address': 'العنوان',
    }[key] ?? key;
  }

  String? _hint(String key) {
    return const {
      'fullNameAr': 'مثال: أحمد محمد علي حسن',
      'fullNameEn': 'الاسم اللي بيعرفك بيه الزملاء',
    }[key];
  }

  String? Function(String?)? _validatorFor(String key) {
    if (key == 'fullNameAr') {
      return (v) {
        if (v == null || v.trim().isEmpty) return 'مطلوب';
        final words =
            v.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
        if (words.length < 4) return 'الاسم لازم يكون رباعي';
        return null;
      };
    }
    const required = {'judicialRank', 'currentCourt', 'mobile'};
    if (required.contains(key)) {
      return (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null;
    }
    return null;
  }
}
