import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/class_model.dart';
import '../../state/admin_provider.dart';
import '../../state/api_provider.dart';
import '../common/status_badge.dart';

class ClassManagementScreen extends ConsumerStatefulWidget {
  const ClassManagementScreen({super.key});

  @override
  ConsumerState<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends ConsumerState<ClassManagementScreen> {
  void _showClassDialog([ClassModel? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final orderCtrl = TextEditingController(text: '${existing?.displayOrder ?? 1}');
    int sessionsPerDay = existing?.expectedSessionsPerDay ?? 1;
    final selectedDays = Set<String>.from(
      existing?.operatingDays ?? ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY'],
    );
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'Add New Class' : 'Edit Class', style: const TextStyle(fontWeight: FontWeight.w700)),
              content: SizedBox(
                width: 480,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(labelText: 'Class Name *', hintText: 'e.g. 10th Standard'),
                          validator: (v) => v == null || v.isEmpty ? 'Class name is required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: orderCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Display Order *', hintText: '1, 2, 3...'),
                        ),
                        const SizedBox(height: 16),
                        const Text('Daily Expected Sessions Count:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        Row(
                          children: [1, 2, 3].map((cnt) {
                            final isSelected = sessionsPerDay == cnt;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text('$cnt Session${cnt > 1 ? 's' : ''}/Day'),
                                selected: isSelected,
                                onSelected: (val) {
                                  if (val) setDialogState(() => sessionsPerDay = cnt);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        const Text('Configured Operating Days:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: AppConstants.daysOfWeek.map((day) {
                            final isSelected = selectedDays.contains(day);
                            return FilterChip(
                              label: Text(day.substring(0, 3)),
                              selected: isSelected,
                              onSelected: (val) {
                                setDialogState(() {
                                  if (val) {
                                    selectedDays.add(day);
                                  } else {
                                    if (selectedDays.length > 1) selectedDays.remove(day);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
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
                            final order = int.tryParse(orderCtrl.text.trim()) ?? 1;
                            if (existing == null) {
                              await api.adminCreateClass({
                                'name': nameCtrl.text.trim(),
                                'displayOrder': order,
                                'operatingDays': selectedDays.toList(),
                                'expectedSessionsPerDay': sessionsPerDay,
                              });
                            } else {
                              await api.adminUpdateClass(existing.classId, {
                                'name': nameCtrl.text.trim(),
                                'displayOrder': order,
                                'operatingDays': selectedDays.toList(),
                                'expectedSessionsPerDay': sessionsPerDay,
                              });
                            }
                            ref.invalidate(adminClassesProvider);
                            ref.invalidate(adminDashboardStatsProvider);
                            if (mounted) Navigator.pop(ctx);
                          } catch (err) {
                            setDialogState(() => isSaving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $err'), backgroundColor: AppTheme.absent),
                            );
                          }
                        },
                  child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white)) : const Text('Save Class'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(adminClassesProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Class Management'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => ref.refresh(adminClassesProvider)),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Class'),
              onPressed: () => _showClassDialog(),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: classesAsync.when(
          data: (classes) {
            if (classes.isEmpty) {
              return const Center(child: Text('No classes found. Add your first class.'));
            }

            return Card(
              child: ListView.separated(
                itemCount: classes.length,
                separatorBuilder: (_, _) => const Divider(height: 1, color: AppTheme.cardBorder),
                itemBuilder: (context, index) {
                  final c = classes[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF8B5CF6).withAlpha(25),
                      child: Text('${c.displayOrder}', style: const TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
                    ),
                    title: Row(
                      children: [
                        Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(width: 8),
                        StatusBadge(status: c.status, isSmall: true),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Expected: ${c.expectedSessionsPerDay} session(s)/day • Operating: ${c.operatingDays.map((d) => d.substring(0, 3)).join(", ")}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Authorized Tutors: ${c.authorizedTutorIds.length}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _showClassDialog(c),
                      tooltip: 'Edit Class',
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
