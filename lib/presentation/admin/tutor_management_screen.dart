import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/tutor.dart';
import '../../state/admin_provider.dart';
import '../../state/api_provider.dart';
import '../common/status_badge.dart';

class TutorManagementScreen extends ConsumerStatefulWidget {
  const TutorManagementScreen({super.key});

  @override
  ConsumerState<TutorManagementScreen> createState() => _TutorManagementScreenState();
}

class _TutorManagementScreenState extends ConsumerState<TutorManagementScreen> {
  String _search = '';

  void _showCreateTutorDialog() {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final subjectsCtrl = TextEditingController();
    final schoolCtrl = TextEditingController();
    final positionCtrl = TextEditingController();
    String employmentType = 'School Teacher';
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Tutor', style: TextStyle(fontWeight: FontWeight.w700)),
              content: SizedBox(
                width: 480,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(labelText: 'Tutor Name *', hintText: 'e.g. Mr. Kumar'),
                          validator: (v) => v == null || v.isEmpty ? 'Tutor name is required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: mobileCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Mobile Number *', hintText: 'e.g. 9876543210'),
                          validator: (v) => v == null || v.length < 10 ? 'Enter valid mobile' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email Address *', hintText: 'e.g. kumar@school.edu'),
                          validator: (v) => v == null || !v.contains('@') ? 'Enter valid email' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: subjectsCtrl,
                          decoration: const InputDecoration(labelText: 'Specialized Subjects', hintText: 'e.g. Mathematics, Physics'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: schoolCtrl,
                          decoration: const InputDecoration(labelText: 'Current School', hintText: 'e.g. Don Bosco Higher Secondary'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: positionCtrl,
                          decoration: const InputDecoration(labelText: 'Current Position', hintText: 'e.g. Senior Math Teacher'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: employmentType,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Employment Type *'),
                          items: const [
                            DropdownMenuItem(value: 'School Teacher', child: Text('School Teacher')),
                            DropdownMenuItem(value: 'Freelance Tutor', child: Text('Freelance Tutor')),
                            DropdownMenuItem(value: 'Visiting Faculty', child: Text('Visiting Faculty')),
                          ],
                          onChanged: (v) => setDialogState(() => employmentType = v ?? 'School Teacher'),
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
                            final subjects = subjectsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                            String cleanEmail = emailCtrl.text.trim().toLowerCase();
                            if (cleanEmail.startsWith('www.')) {
                              cleanEmail = cleanEmail.substring(4);
                            }
                            final api = ref.read(apiServiceProvider);
                            await api.adminCreateTutor({
                              'name': nameCtrl.text.trim(),
                              'mobileNumber': mobileCtrl.text.trim(),
                              'email': cleanEmail,
                              'specializedSubjects': subjects,
                              'currentSchool': schoolCtrl.text.trim(),
                              'currentPosition': positionCtrl.text.trim(),
                              'employmentType': employmentType,
                            });
                            ref.invalidate(adminTutorsProvider);
                            ref.invalidate(adminDashboardStatsProvider);
                            if (mounted) Navigator.pop(ctx);
                          } catch (err) {
                            setDialogState(() => isSaving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $err'), backgroundColor: AppTheme.absent),
                            );
                          }
                        },
                  child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white)) : const Text('Create Tutor'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAuthorizationDialog(Tutor tutor) {
    final classesAsync = ref.read(adminClassesProvider);
    classesAsync.whenData((classes) {
      final selectedClassIds = Set<String>.from(tutor.authorizedClassIds);
      bool isSaving = false;

      showDialog(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text('Authorize Classes for ${tutor.name}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                content: SizedBox(
                  width: 440,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select the classes this tutor is authorized to conduct attendance sessions for:',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      if (classes.isEmpty)
                        const Text('No classes found in the system.')
                      else
                        ...classes.map((c) {
                          final isChecked = selectedClassIds.contains(c.classId);
                          return CheckboxListTile(
                            dense: true,
                            title: Text(c.name, style: const TextStyle(fontSize: 14)),
                            value: isChecked,
                            onChanged: (val) {
                              setDialogState(() {
                                if (val == true) {
                                  selectedClassIds.add(c.classId);
                                } else {
                                  selectedClassIds.remove(c.classId);
                                }
                              });
                            },
                          );
                        }),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            setDialogState(() => isSaving = true);
                            try {
                              final api = ref.read(apiServiceProvider);
                              await api.adminUpdateTutorAuthorization(tutor.uid, selectedClassIds.toList());
                              ref.invalidate(adminTutorsProvider);
                              ref.invalidate(adminClassesProvider);
                              if (mounted) Navigator.pop(ctx);
                            } catch (err) {
                              setDialogState(() => isSaving = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $err'), backgroundColor: AppTheme.absent),
                              );
                            }
                          },
                    child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white)) : const Text('Save Authorizations'),
                  ),
                ],
              );
            },
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final tutorsAsync = ref.watch(adminTutorsProvider);
    final classesAsync = ref.watch(adminClassesProvider);

    final classNames = <String, String>{};
    classesAsync.whenData((classes) {
      for (final c in classes) {
        classNames[c.classId] = c.name;
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Tutor Management & Authorization'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => ref.refresh(adminTutorsProvider)),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
              label: const Text('Add Tutor'),
              onPressed: _showCreateTutorDialog,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search by tutor name, email, or mobile...',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: tutorsAsync.when(
                data: (tutors) {
                  final filtered = tutors.where((t) {
                    return t.name.toLowerCase().contains(_search) ||
                        t.email.toLowerCase().contains(_search) ||
                        t.mobileNumber.contains(_search);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No tutors found.'));
                  }

                  return Card(
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, color: AppTheme.cardBorder),
                      itemBuilder: (context, index) {
                        final tutor = filtered[index];
                        final authorizedNames = tutor.authorizedClassIds.map((id) => classNames[id] ?? id).toList();

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF06B6D4).withAlpha(25),
                            child: Text(
                              tutor.name.isNotEmpty ? tutor.name[0].toUpperCase() : 'T',
                              style: const TextStyle(color: Color(0xFF06B6D4), fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  tutor.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusBadge(status: tutor.status, isSmall: true),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Email: ${tutor.email} • Mobile: ${tutor.mobileNumber}', style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 2),
                              Text('Position: ${tutor.currentPosition} at ${tutor.currentSchool} (${tutor.employmentType})', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: authorizedNames.isEmpty
                                    ? [const Text('No classes authorized yet.', style: TextStyle(color: AppTheme.absent, fontSize: 11))]
                                    : authorizedNames.map((cn) => Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: AppTheme.primary.withAlpha(20), borderRadius: BorderRadius.circular(4)),
                                          child: Text(cn, style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                                        )).toList(),
                              ),
                            ],
                          ),
                          trailing: OutlinedButton.icon(
                            icon: const Icon(Icons.verified_user_outlined, size: 14),
                            label: const Text('Classes', style: TextStyle(fontSize: 12)),
                            onPressed: () => _showAuthorizationDialog(tutor),
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
          ],
        ),
      ),
    );
  }
}
