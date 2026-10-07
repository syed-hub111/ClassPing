import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../state/admin_provider.dart';
import '../../state/api_provider.dart';
import '../common/status_badge.dart';

class StudentManagementScreen extends ConsumerStatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  ConsumerState<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends ConsumerState<StudentManagementScreen> {
  String _search = '';

  void _showCreateStudentDialog() {
    final nameCtrl = TextEditingController();
    final idCtrl = TextEditingController();
    final parentNameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final schoolCtrl = TextEditingController();
    String? selectedClassId;
    String? selectedAyId;
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final classesAsync = ref.watch(adminClassesProvider);
            final ayAsync = ref.watch(adminAcademicYearsProvider);

            return AlertDialog(
              title: const Text('Add New Student', style: TextStyle(fontWeight: FontWeight.w700)),
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
                          decoration: const InputDecoration(labelText: 'Student Name *', hintText: 'e.g. Arjun Kumar'),
                          validator: (v) => v == null || v.isEmpty ? 'Student name is required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: idCtrl,
                          decoration: const InputDecoration(labelText: 'Student ID *', hintText: 'e.g. STU-2026-001'),
                          validator: (v) => v == null || v.isEmpty ? 'Student ID is required' : null,
                        ),
                        const SizedBox(height: 12),
                        classesAsync.when(
                          data: (classes) {
                            if (classes.isEmpty) return const Text('Please create a class first.');
                            selectedClassId ??= classes.first.classId;
                            return DropdownButtonFormField<String>(
                              initialValue: selectedClassId,
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'Current Class *'),
                              items: classes.map((c) => DropdownMenuItem(value: c.classId, child: Text(c.name, overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (v) => setDialogState(() => selectedClassId = v),
                            );
                          },
                          loading: () => const CircularProgressIndicator(),
                          error: (e, _) => Text('Error loading classes: $e'),
                        ),
                        const SizedBox(height: 12),
                        ayAsync.when(
                          data: (years) {
                            if (years.isEmpty) return const Text('Please create an academic year first.');
                            selectedAyId ??= years.first.academicYearId;
                            return DropdownButtonFormField<String>(
                              initialValue: selectedAyId,
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'Academic Year *'),
                              items: years.map((y) => DropdownMenuItem(value: y.academicYearId, child: Text(y.name, overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (v) => setDialogState(() => selectedAyId = v),
                            );
                          },
                          loading: () => const CircularProgressIndicator(),
                          error: (e, _) => Text('Error loading academic years: $e'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: parentNameCtrl,
                          decoration: const InputDecoration(labelText: 'Parent Name *', hintText: 'e.g. Raj Kumar'),
                          validator: (v) => v == null || v.isEmpty ? 'Parent name is required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Parent Mobile Number *', hintText: 'e.g. 9876543210'),
                          validator: (v) => v == null || v.length < 10 ? 'Enter valid 10-digit mobile' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: schoolCtrl,
                          decoration: const InputDecoration(
                            labelText: 'School Name *',
                            hintText: 'e.g. Don Bosco Higher Secondary School',
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'School name is required' : null,
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
                            await api.adminCreateStudent({
                              'name': nameCtrl.text.trim(),
                              'studentId': idCtrl.text.trim(),
                              'currentClassId': selectedClassId,
                              'currentAcademicYearId': selectedAyId,
                              'parentName': parentNameCtrl.text.trim(),
                              'parentMobileNumber': phoneCtrl.text.trim(),
                              'schoolName': schoolCtrl.text.trim(),
                            });
                            ref.invalidate(adminStudentsProvider);
                            ref.invalidate(adminDashboardStatsProvider);
                            if (mounted) Navigator.pop(ctx);
                          } catch (err) {
                            setDialogState(() => isSaving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $err'), backgroundColor: AppTheme.absent),
                            );
                          }
                        },
                  child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white)) : const Text('Create Student'),
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
    final studentsAsync = ref.watch(adminStudentsProvider);
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
        title: const Text('Student Management'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => ref.refresh(adminStudentsProvider)),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.person_add_rounded, size: 16),
              label: const Text('Add Student'),
              onPressed: _showCreateStudentDialog,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search by student name or ID...',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: studentsAsync.when(
                data: (students) {
                  final filtered = students.where((s) {
                    return s.name.toLowerCase().contains(_search) || s.studentId.toLowerCase().contains(_search);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No students found.', style: TextStyle(color: AppTheme.textSecondary)));
                  }

                  return Card(
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, color: AppTheme.cardBorder),
                      itemBuilder: (context, index) {
                        final student = filtered[index];
                        final className = classNames[student.currentClassId] ?? student.currentClassId;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primary.withAlpha(25),
                            child: Text(
                              student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
                              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  student.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text('(${student.studentId})', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Class: $className • School: ${student.schoolName}', style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 2),
                              Text('Parent: ${student.parentName} (${student.parentMobileNumber})', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            ],
                          ),
                          trailing: StatusBadge(status: student.status, isSmall: true),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading students: $e', style: const TextStyle(color: AppTheme.absent))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
