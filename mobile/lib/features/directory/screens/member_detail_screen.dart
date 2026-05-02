import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/member.dart';
import '../../../data/providers/providers.dart';
import '../../../shared/widgets/member_avatar.dart';

final memberDetailProvider =
    FutureProvider.autoDispose.family<Member, String>((ref, id) {
  return ref.read(membersRepositoryProvider).getOne(id);
});

class MemberDetailScreen extends ConsumerWidget {
  final String memberId;
  const MemberDetailScreen({super.key, required this.memberId});

  Future<void> _launch(String scheme, String value) async {
    final uri = Uri.parse('$scheme$value');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(memberDetailProvider(memberId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('بطاقة عضو'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('تعذر تحميل البيانات'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
                onPressed: () => ref.invalidate(memberDetailProvider(memberId)),
              ),
            ],
          ),
        ),
        data: (m) => SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                MemberAvatar(photoUrl: m.photoUrl, name: m.fullNameAr, radius: 56),
                const SizedBox(height: 16),
                Text(m.fullNameAr,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                    textAlign: TextAlign.center),
                if (m.fullNameEn != null && m.fullNameEn!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'الشهرة: ${m.fullNameEn}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 4),
                Text(m.judicialRank,
                    style: const TextStyle(fontSize: 16, color: AppColors.primary)),
                const SizedBox(height: 4),
                Text(m.currentCourt, style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (m.mobile.isNotEmpty)
                      Expanded(
                        child: _actionBtn(
                          icon: Icons.phone,
                          label: 'اتصال',
                          color: AppColors.success,
                          onTap: () => _launch('tel:', m.mobile),
                        ),
                      ),
                    if (m.whatsapp != null && m.whatsapp!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: _actionBtn(
                          icon: Icons.message,
                          label: 'واتساب',
                          color: const Color(0xFF25D366),
                          onTap: () => _launch('https://wa.me/', _normalize(m.whatsapp!)),
                        ),
                      ),
                    ],
                    if (m.userEmail != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: _actionBtn(
                          icon: Icons.email_outlined,
                          label: 'إيميل',
                          color: AppColors.primary,
                          onTap: () => _launch('mailto:', m.userEmail!),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                ..._buildSections(m),
              ],
            ),
          ),
        ),
    );
  }

  List<Widget> _buildSections(Member m) {
    final sections = <Widget>[];
    void addSection(String title, List<({String label, String? value})> rows) {
      final w = _section(title, rows);
      if (w != null) {
        if (sections.isNotEmpty) {
          sections.add(const SizedBox(height: 12));
        }
        sections.add(w);
      }
    }

    addSection('بيانات وظيفية', [
      (label: 'المنصب الحالي', value: m.currentPosition),
      (label: 'التخصص', value: m.specialization),
      (label: 'المحافظة', value: m.governorate),
      (label: 'تاريخ التعيين', value: _fmt(m.appointmentDate)),
    ]);
    addSection('بيانات التواصل', [
      (label: 'الموبايل', value: m.mobile),
      (label: 'واتساب', value: m.whatsapp),
      (label: 'إيميل', value: m.userEmail),
      (label: 'إيميل بديل', value: m.emailSecondary),
    ]);
    addSection('بيانات شخصية', [
      (label: 'تاريخ الميلاد', value: _fmt(m.birthDate)),
      (label: 'العنوان', value: m.address),
    ]);
    return sections;
  }

  String _normalize(String phone) =>
      phone.replaceAll(RegExp(r'[^\d+]'), '').replaceAll('+', '');

  String? _fmt(DateTime? d) => d == null ? null : DateFormat('yyyy/MM/dd', 'ar').format(d);

  /// Returns null when the section has no real data so callers can omit it.
  Widget? _section(String title, List<({String label, String? value})> rows) {
    final filled = rows.where((r) => r.value != null && r.value!.isNotEmpty).toList();
    if (filled.isEmpty) return null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...filled.map(_renderRow),
          ],
        ),
      ),
    );
  }

  Widget _renderRow(({String label, String? value}) row) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(row.label, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(row.value!, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
