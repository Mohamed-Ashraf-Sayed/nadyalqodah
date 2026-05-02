import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../directory_controller.dart';

class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({super.key});

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  String? _governorate;
  String? _rank;
  String? _specialization;

  @override
  void initState() {
    super.initState();
    final f = ref.read(directoryControllerProvider).filters;
    _governorate = f.governorate;
    _rank = f.judicialRank;
    _specialization = f.specialization;
  }

  @override
  Widget build(BuildContext context) {
    final meta = ref.watch(directoryControllerProvider).meta;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'فلترة الأعضاء',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _dropdown('المحافظة', _governorate, meta?.governorates ?? [], (v) => setState(() => _governorate = v)),
            const SizedBox(height: 12),
            _dropdown('الدرجة الوظيفية', _rank, meta?.ranks ?? [], (v) => setState(() => _rank = v)),
            const SizedBox(height: 12),
            _dropdown('التخصص', _specialization, meta?.specializations ?? [], (v) => setState(() => _specialization = v)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(directoryControllerProvider.notifier).clearFilters();
                      Navigator.pop(context);
                    },
                    child: const Text('مسح الفلاتر'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(directoryControllerProvider.notifier).setFilters(
                            DirectoryFilters(
                              q: ref.read(directoryControllerProvider).filters.q,
                              governorate: _governorate,
                              judicialRank: _rank,
                              specialization: _specialization,
                            ),
                          );
                      Navigator.pop(context);
                    },
                    child: const Text('تطبيق'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _dropdown(String label, String? value, List<String> options, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        const DropdownMenuItem<String>(value: null, child: Text('الكل')),
        ...options.map((o) => DropdownMenuItem(value: o, child: Text(o))),
      ],
      onChanged: onChanged,
    );
  }
}
