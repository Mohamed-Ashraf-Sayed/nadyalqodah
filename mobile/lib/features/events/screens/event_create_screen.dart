import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/providers.dart';
import 'events_screen.dart';

class EventCreateScreen extends ConsumerStatefulWidget {
  const EventCreateScreen({super.key});

  @override
  ConsumerState<EventCreateScreen> createState() => _EventCreateScreenState();
}

class _EventCreateScreenState extends ConsumerState<EventCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _category = TextEditingController();
  DateTime? _startsAt;
  DateTime? _endsAt;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    _category.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial ?? DateTime.now()),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startsAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر تاريخ ووقت الحدث')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(eventsRepositoryProvider).create(
            title: _title.text.trim(),
            description: _description.text.trim().isEmpty
                ? null
                : _description.text.trim(),
            location: _location.text.trim().isEmpty
                ? null
                : _location.text.trim(),
            category: _category.text.trim().isEmpty
                ? null
                : _category.text.trim(),
            startsAt: _startsAt!,
            endsAt: _endsAt,
          );
      ref.invalidate(eventsListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم نشر الحدث')),
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل النشر')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _dateField(String label, DateTime? value, ValueChanged<DateTime?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final picked = await _pickDateTime(value);
          if (picked != null) onChanged(picked);
        },
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(Icons.event, size: 20),
          ),
          child: Text(
            value == null
                ? 'اختر التاريخ والوقت'
                : DateFormat('EEEE dd MMM yyyy - hh:mm a', 'ar').format(value),
            style: TextStyle(
              color: value == null ? AppColors.textSecondary : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة حدث')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'عنوان الحدث'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _category,
              decoration: const InputDecoration(
                labelText: 'الفئة (اختياري)',
                hintText: 'اجتماع، احتفال، رحلة، تدريب...',
              ),
            ),
            const SizedBox(height: 12),
            _dateField('بداية الحدث', _startsAt,
                (v) => setState(() => _startsAt = v)),
            _dateField('نهاية الحدث (اختياري)', _endsAt,
                (v) => setState(() => _endsAt = v)),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(
                labelText: 'المكان (اختياري)',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'تفاصيل الحدث (اختياري)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white),
                    )
                  : const Text('نشر الحدث'),
            ),
          ],
        ),
      ),
    );
  }
}
