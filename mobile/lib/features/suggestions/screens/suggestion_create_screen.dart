import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/suggestion.dart';
import '../../../data/providers/providers.dart';
import 'suggestions_screen.dart';

class SuggestionCreateScreen extends ConsumerStatefulWidget {
  const SuggestionCreateScreen({super.key});

  @override
  ConsumerState<SuggestionCreateScreen> createState() =>
      _SuggestionCreateScreenState();
}

class _SuggestionCreateScreenState
    extends ConsumerState<SuggestionCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _body = TextEditingController();
  SuggestionType _type = SuggestionType.suggestion;
  bool _isAnonymous = false;
  bool _saving = false;

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(suggestionsRepositoryProvider).create(
            type: _type,
            subject: _subject.text.trim(),
            body: _body.text.trim(),
            isAnonymous: _isAnonymous,
          );
      ref.invalidate(mySuggestionsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال طلبك للإدارة')),
        );
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل الإرسال')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إرسال جديد')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Type selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: SuggestionType.values.map((t) {
                  final selected = t == _type;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _type = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              t == SuggestionType.suggestion
                                  ? Icons.lightbulb_outline
                                  : Icons.report_problem_outlined,
                              color: selected
                                  ? (t == SuggestionType.suggestion
                                      ? AppColors.primary
                                      : AppColors.danger)
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t.label,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: selected
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _subject,
              decoration: const InputDecoration(labelText: 'الموضوع'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _body,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'تفاصيل الطلب',
                alignLabelWithHint: true,
              ),
              validator: (v) =>
                  (v == null || v.trim().length < 10) ? '10 أحرف على الأقل' : null,
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: SwitchListTile(
                value: _isAnonymous,
                onChanged: (v) => setState(() => _isAnonymous = v),
                title: const Text('إخفاء اسمي'),
                subtitle: const Text(
                  'الإدارة فقط هتقدر تشوف اسمك',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
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
                  : const Text('إرسال'),
            ),
          ],
        ),
      ),
    );
  }
}
