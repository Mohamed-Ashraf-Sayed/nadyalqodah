import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/member.dart';
import '../../../data/providers/providers.dart';
import 'admin_screen.dart';

class AdminMemberEditScreen extends ConsumerStatefulWidget {
  final String memberId;
  const AdminMemberEditScreen({super.key, required this.memberId});

  @override
  ConsumerState<AdminMemberEditScreen> createState() =>
      _AdminMemberEditScreenState();
}

class _AdminMemberEditScreenState extends ConsumerState<AdminMemberEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _ctrls;
  DateTime? _birthDate;
  DateTime? _appointmentDate;
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _ctrls = {
      'fullNameAr': TextEditingController(),
      'fullNameEn': TextEditingController(),
      'judicialRank': TextEditingController(),
      'currentCourt': TextEditingController(),
      'currentPosition': TextEditingController(),
      'mobile': TextEditingController(),
      'whatsapp': TextEditingController(),
      'emailSecondary': TextEditingController(),
      'governorate': TextEditingController(),
      'specialization': TextEditingController(),
      'address': TextEditingController(),
    };
    _load();
  }

  Future<void> _load() async {
    try {
      final m = await ref
          .read(adminRepositoryProvider)
          .getMember(widget.memberId);
      _hydrate(m);
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = 'تعذر تحميل بيانات العضو';
        });
      }
    }
  }

  void _hydrate(Member m) {
    _ctrls['fullNameAr']!.text = m.fullNameAr;
    _ctrls['fullNameEn']!.text = m.fullNameEn ?? '';
    _ctrls['judicialRank']!.text = m.judicialRank;
    _ctrls['currentCourt']!.text = m.currentCourt;
    _ctrls['currentPosition']!.text = m.currentPosition ?? '';
    _ctrls['mobile']!.text = m.mobile;
    _ctrls['whatsapp']!.text = m.whatsapp ?? '';
    _ctrls['emailSecondary']!.text = m.emailSecondary ?? '';
    _ctrls['governorate']!.text = m.governorate ?? '';
    _ctrls['specialization']!.text = m.specialization ?? '';
    _ctrls['address']!.text = m.address ?? '';
    _birthDate = m.birthDate;
    _appointmentDate = m.appointmentDate;
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فيه حقول مطلوبة فاضية، تأكد من البيانات'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      const requiredKeys = {
        'fullNameAr',
        'judicialRank',
        'currentCourt',
        'mobile',
      };
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
      await ref
          .read(adminRepositoryProvider)
          .updateMember(widget.memberId, data);
      ref.invalidate(pendingProvider);
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
      appBar: AppBar(title: const Text('تعديل بيانات عضو')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(child: Text(_loadError!))
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.shield_outlined,
                                size: 18, color: AppColors.accent),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'وضع الإدارة: التعديلات هتتحفظ مباشرة على البيانات الرسمية للعضو',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ..._ctrls.entries.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextFormField(
                              controller: e.value,
                              decoration: InputDecoration(
                                labelText: _label(e.key),
                              ),
                              validator: _validatorFor(e.key),
                            ),
                          )),
                      _dateTile('تاريخ التعيين', _appointmentDate,
                          () => _pickDate(false)),
                      _dateTile(
                          'تاريخ الميلاد', _birthDate, () => _pickDate(true)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
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

  String? Function(String?)? _validatorFor(String key) {
    // Admin edit is more lenient than self-edit: only require non-empty
    // for the truly mandatory fields. No 4-word rule on names.
    const required = {'fullNameAr', 'judicialRank', 'currentCourt', 'mobile'};
    if (required.contains(key)) {
      return (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null;
    }
    return null;
  }
}
