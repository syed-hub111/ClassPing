import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../state/admin_provider.dart';
import '../../state/api_provider.dart';
import '../common/status_badge.dart';

class AcademicYearScreen extends ConsumerStatefulWidget {
  const AcademicYearScreen({super.key});

  @override
  ConsumerState<AcademicYearScreen> createState() => _AcademicYearScreenState();
}

class _AcademicYearScreenState extends ConsumerState<AcademicYearScreen> {
  void _showCreateYearDialog() {
    final year = DateTime.now().year;
    final nameCtrl = TextEditingController(text: '$year-${year + 1}');
    final startCtrl = TextEditingController(text: '$year-06-01');
    final endCtrl = TextEditingController(text: '${year + 1}-04-30');
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Academic Year', style: TextStyle(fontWeight: FontWeight.w700)),
              content: SizedBox(
                width: 440,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Academic Year Name *', hintText: 'e.g. 2026-2027'),
                        validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: startCtrl,
                        decoration: const InputDecoration(labelText: 'Start Date (YYYY-MM-DD) *'),
                        validator: (v) => v == null || v.length < 10 ? 'Enter valid date' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: endCtrl,
                        decoration: const InputDecoration(labelText: 'End Date (YYYY-MM-DD) *'),
                        validator: (v) => v == null || v.length < 10 ? 'Enter valid date' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSaving = true);
                          try {
                            final api = ref.read(apiServiceProvider);
                            await api.adminCreateAcademicYear({
                              'name': nameCtrl.text.trim(),
                              'startDate': startCtrl.text.trim(),
                              'endDate': endCtrl.text.trim(),
                            });
                            ref.invalidate(adminAcademicYearsProvider);
                            if (mounted) Navigator.pop(ctx);
                          } catch (err) {
                            setDialogState(() => isSaving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $err'), backgroundColor: AppTheme.absent),
                            );
                          }
                        },
                  child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white)) : const Text('Create Year'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _setActiveYear(String yearId) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.adminSetActiveAcademicYear(yearId);
      ref.invalidate(adminAcademicYearsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Active academic year updated.'), backgroundColor: AppTheme.present),
        );
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $err'), backgroundColor: AppTheme.absent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final yearsAsync = ref.watch(adminAcademicYearsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Academic Years'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => ref.refresh(adminAcademicYearsProvider)),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Academic Year'),
              onPressed: _showCreateYearDialog,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: yearsAsync.when(
          data: (years) {
            if (years.isEmpty) {
              return const Center(child: Text('No academic years configured.'));
            }

            return Card(
              child: ListView.separated(
                itemCount: years.length,
                separatorBuilder: (_, _) => const Divider(height: 1, color: AppTheme.cardBorder),
                itemBuilder: (context, index) {
                  final year = years[index];
                  final isActive = year.isActive;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.present.withAlpha(25) : AppTheme.cardBorder,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        color: isActive ? AppTheme.present : AppTheme.textSecondary,
                        size: 22,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(year.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(width: 8),
                        StatusBadge(status: year.status, isSmall: true),
                      ],
                    ),
                    subtitle: const Text('Configured Tuition Academic Session', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    trailing: isActive
                        ? const Chip(
                            label: Text('Currently Active', style: TextStyle(color: AppTheme.present, fontSize: 11, fontWeight: FontWeight.bold)),
                            backgroundColor: AppTheme.presentLight,
                            side: BorderSide.none,
                          )
                        : OutlinedButton(
                            onPressed: () => _setActiveYear(year.academicYearId),
                            child: const Text('Set as Active', style: TextStyle(fontSize: 12)),
                          ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppTheme.absent))),
        ),
      ),
    );
  }
}
