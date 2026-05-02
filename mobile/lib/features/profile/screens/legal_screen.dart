import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';

class LegalScreen extends ConsumerStatefulWidget {
  final String type; // 'privacy' or 'terms'
  const LegalScreen({super.key, required this.type});

  @override
  ConsumerState<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends ConsumerState<LegalScreen> {
  String? _content;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await Dio().get(
        '${ApiConstants.baseUrl}/legal/${widget.type}.json',
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );
      if (!mounted) return;
      setState(() {
        _content = res.data['content'] as String?;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذر تحميل المحتوى';
        _loading = false;
      });
    }
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/legal/${widget.type}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String get _title => widget.type == 'privacy' ? 'سياسة الخصوصية' : 'شروط الاستخدام';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: 'فتح في المتصفح',
            onPressed: _openInBrowser,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
            const SizedBox(height: 12),
            Text(_error!),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              onPressed: _load,
            ),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _MarkdownText(text: _content ?? ''),
    );
  }
}

/// Lightweight markdown renderer (no extra dependency).
/// Handles: # H1, ## H2, ### H3, **bold**, - bullets, blank lines.
class _MarkdownText extends StatelessWidget {
  final String text;
  const _MarkdownText({required this.text});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 12));
        continue;
      }

      if (trimmed.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 12),
          child: Text(
            trimmed.substring(2),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
        ));
        continue;
      }
      if (trimmed.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 8),
          child: Text(
            trimmed.substring(3),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ));
        continue;
      }
      if (trimmed.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text(
            trimmed.substring(4),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ));
        continue;
      }
      if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•  ',
                  style: TextStyle(
                      fontWeight: FontWeight.w900, color: AppColors.primary)),
              Expanded(child: _inlineText(trimmed.substring(2))),
            ],
          ),
        ));
        continue;
      }
      if (trimmed.startsWith('---')) {
        widgets.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(),
        ));
        continue;
      }
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _inlineText(trimmed),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }

  Widget _inlineText(String text) {
    // Handle **bold** spans
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    var last = 0;
    for (final m in regex.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      spans.add(TextSpan(
        text: m.group(1),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ));
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }
    return Text.rich(
      TextSpan(
        children: spans.isEmpty ? [TextSpan(text: text)] : spans,
        style: const TextStyle(fontSize: 14, height: 1.7),
      ),
    );
  }
}
