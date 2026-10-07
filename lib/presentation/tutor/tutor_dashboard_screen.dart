import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/class_model.dart';
import '../../models/expected_opportunity.dart';
import '../../state/tutor_provider.dart';
import '../common/status_badge.dart';

class TutorDashboardScreen extends ConsumerWidget {
  const TutorDashboardScreen({super.key});

  void _startMarking(BuildContext context, WidgetRef ref, ClassModel classModel, ExpectedOpportunity opp) async {
    final studentsAsync = await ref.read(tutorClassStudentsProvider(classModel.classId).future);

    ref.read(rollCallProvider.notifier).initForSession(
          classModel: classModel,
          opportunity: opp,
          students: studentsAsync,
        );

    if (context.mounted) {
      context.go('/tutor/mark-attendance');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(tutorAuthorizedClassesProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(tutorAuthorizedClassesProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Authorized Classes',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                SizedBox(height: 4),
                Text(
                  'Select a class and pending attendance opportunity to conduct roll call.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 24),
            classesAsync.when(
              data: (classes) {
                if (classes.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.lock_clock_rounded, size: 40, color: AppTheme.textMuted),
                          SizedBox(height: 12),
                          Text(
                            'No Classes Authorized',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'You do not have any authorized classes assigned yet. Please contact your tuition administrator.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: classes.length,
                  itemBuilder: (context, index) {
                    final c = classes[index];
                    return _ClassCard(
                      classModel: c,
                      onMark: (opp) => _startMarking(context, ref, c, opp),
                    );
                  },
                );
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppTheme.absent))),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassCard extends ConsumerWidget {
  final ClassModel classModel;
  final Function(ExpectedOpportunity) onMark;

  const _ClassCard({required this.classModel, required this.onMark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oppsAsync = ref.watch(tutorPendingOpportunitiesProvider(classModel.classId));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school_rounded, color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classModel.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Operating: ${classModel.operatingDays.map((d) => d.substring(0, 3)).join(", ")}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                const StatusBadge(status: 'ACTIVE', isSmall: true),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppTheme.cardBorder),
            const SizedBox(height: 12),
            const Text(
              'Expected Attendance Sessions:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            oppsAsync.when(
              data: (opps) {
                if (opps.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No pending sessions for this class. (All up to date)',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: opps.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final opp = opps[i];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Date: ${opp.sessionDate}',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('(Slot ${opp.slotNumber})', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                    const SizedBox(width: 8),
                                    StatusBadge(status: opp.status, isSmall: true),
                                  ],
                                ),
                                if (opp.isMissedDeadline) ...[
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Missed normal deadline. May still be completed within the 7-day allowed period.',
                                    style: TextStyle(fontSize: 11, color: AppTheme.absent, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.edit_calendar_rounded, size: 14),
                            label: const Text('Mark Roll Call', style: TextStyle(fontSize: 12)),
                            onPressed: () => onMark(opp),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e', style: const TextStyle(color: AppTheme.absent, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
