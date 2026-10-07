import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../state/admin_provider.dart';
import '../../state/api_provider.dart';
import '../common/status_badge.dart';

class PromotionScreen extends ConsumerStatefulWidget {
  const PromotionScreen({super.key});

  @override
  ConsumerState<PromotionScreen> createState() => _PromotionScreenState();
}

class _PromotionScreenState extends ConsumerState<PromotionScreen> {
  final Set<String> _selectedStudentIds = {};
  String? _targetClassId;
  String? _targetAcademicYearId;
  String _selectedAction = 'PROMOTE'; // PROMOTE | COMPLETED | DISCONTINUED
  bool _isProcessing = false;

  void _executePromotion() async {
    if (_selectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one student.'), backgroundColor: AppTheme.late),
      );
      return;
    }

    if (_selectedAction == 'PROMOTE') {
      if (_targetClassId == null || _targetAcademicYearId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select target class and target academic year.'), backgroundColor: AppTheme.late),
        );
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      final api = ref.read(apiServiceProvider);
      await api.adminPromoteStudents(
        studentIds: _selectedStudentIds.toList(),
        action: _selectedAction,
        targetClassId: _targetClassId,
        targetAcademicYearId: _targetAcademicYearId,
      );

      ref.invalidate(adminStudentsProvider);
      ref.invalidate(adminDashboardStatsProvider);
      setState(() {
        _isProcessing = false;
        _selectedStudentIds.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Action successful! Historical enrollment and attendance records preserved.'),
            backgroundColor: AppTheme.present,
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.absent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(adminStudentsProvider);
    final classesAsync = ref.watch(adminClassesProvider);
    final ayAsync = ref.watch(adminAcademicYearsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Manual Student Promotion'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => ref.refresh(adminStudentsProvider)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Controls Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Promotion & Transition Action',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Select students below and choose an action. Historical attendance is never overwritten.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 600;
                        final actionDropdown = DropdownButtonFormField<String>(
                          initialValue: _selectedAction,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Action *'),
                          items: const [
                            DropdownMenuItem(value: 'PROMOTE', child: Text('Promote to Next Class', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'COMPLETED', child: Text('Mark Course Completed', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'DISCONTINUED', child: Text('Mark Discontinued', overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (v) => setState(() => _selectedAction = v ?? 'PROMOTE'),
                        );

                        Widget? classDropdown;
                        Widget? yearDropdown;

                        if (_selectedAction == 'PROMOTE') {
                          classDropdown = classesAsync.when(
                            data: (classes) {
                              return DropdownButtonFormField<String>(
                                initialValue: _targetClassId,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: 'Target Class *'),
                                hint: const Text('Select Next Class', overflow: TextOverflow.ellipsis),
                                items: classes.map((c) => DropdownMenuItem(value: c.classId, child: Text(c.name, overflow: TextOverflow.ellipsis))).toList(),
                                onChanged: (v) => setState(() => _targetClassId = v),
                              );
                            },
                            loading: () => const LinearProgressIndicator(),
                            error: (_, _) => const Text('Error'),
                          );

                          yearDropdown = ayAsync.when(
                            data: (years) {
                              return DropdownButtonFormField<String>(
                                initialValue: _targetAcademicYearId,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: 'Target Academic Year *'),
                                hint: const Text('Select Year', overflow: TextOverflow.ellipsis),
                                items: years.map((y) => DropdownMenuItem(value: y.academicYearId, child: Text(y.name, overflow: TextOverflow.ellipsis))).toList(),
                                onChanged: (v) => setState(() => _targetAcademicYearId = v),
                              );
                            },
                            loading: () => const LinearProgressIndicator(),
                            error: (_, _) => const Text('Error'),
                          );
                        }

                        if (isMobile) {
                          return Column(
                            children: [
                              actionDropdown,
                              if (classDropdown != null) ...[
                                const SizedBox(height: 12),
                                classDropdown,
                              ],
                              if (yearDropdown != null) ...[
                                const SizedBox(height: 12),
                                yearDropdown,
                              ],
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: actionDropdown),
                            if (classDropdown != null) ...[
                              const SizedBox(width: 12),
                              Expanded(child: classDropdown),
                            ],
                            if (yearDropdown != null) ...[
                              const SizedBox(width: 12),
                              Expanded(child: yearDropdown),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_selectedStudentIds.length} student(s) selected',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primary),
                        ),
                        ElevatedButton.icon(
                          icon: _isProcessing
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.check_circle_outline_rounded, size: 16),
                          label: Text(_selectedAction == 'PROMOTE' ? 'Execute Promotion' : 'Apply Status Change'),
                          onPressed: _isProcessing ? null : _executePromotion,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Students List
            Expanded(
              child: studentsAsync.when(
                data: (students) {
                  if (students.isEmpty) return const Center(child: Text('No students found.'));

                  final allSelected = _selectedStudentIds.length == students.length;

                  return Card(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                icon: Icon(allSelected ? Icons.deselect_rounded : Icons.select_all_rounded, size: 18),
                                label: Text(allSelected ? 'Deselect All' : 'Select All Students'),
                                onPressed: () {
                                  setState(() {
                                    if (allSelected) {
                                      _selectedStudentIds.clear();
                                    } else {
                                      _selectedStudentIds.addAll(students.map((s) => s.studentId));
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: AppTheme.cardBorder),
                        Expanded(
                          child: ListView.separated(
                            itemCount: students.length,
                            separatorBuilder: (_, _) => const Divider(height: 1, color: AppTheme.cardBorder),
                            itemBuilder: (context, index) {
                              final s = students[index];
                              final isChecked = _selectedStudentIds.contains(s.studentId);

                              return CheckboxListTile(
                                value: isChecked,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedStudentIds.add(s.studentId);
                                    } else {
                                      _selectedStudentIds.remove(s.studentId);
                                    }
                                  });
                                },
                                title: Row(
                                  children: [
                                    Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                    const SizedBox(width: 8),
                                    Text('(${s.studentId})', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                    const SizedBox(width: 8),
                                    StatusBadge(status: s.status, isSmall: true),
                                  ],
                                ),
                                subtitle: Text('School: ${s.schoolName} • Parent: ${s.parentName}', style: const TextStyle(fontSize: 12)),
                              );
                            },
                          ),
                        ),
                      ],
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
