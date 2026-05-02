import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/providers/providers.dart';
import 'news_screen.dart';

class NewsCreateScreen extends ConsumerStatefulWidget {
  const NewsCreateScreen({super.key});

  @override
  ConsumerState<NewsCreateScreen> createState() => _NewsCreateScreenState();
}

class _NewsCreateScreenState extends ConsumerState<NewsCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _notify = true;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(newsRepositoryProvider).create(
            title: _title.text.trim(),
            body: _body.text.trim(),
            notifyAll: _notify,
          );
      ref.invalidate(newsListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم نشر الخبر')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('نشر خبر جديد')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'عنوان الخبر'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _body,
              maxLines: 8,
              decoration: const InputDecoration(labelText: 'تفاصيل الخبر'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _notify,
              onChanged: (v) => setState(() => _notify = v),
              title: const Text('إرسال إشعار لكل الأعضاء'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                    )
                  : const Text('نشر'),
            ),
          ],
        ),
      ),
    );
  }
}
