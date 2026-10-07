import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../state/parent_provider.dart';
import '../common/metric_card.dart';

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(parentChildrenProvider);
    final selectedChildId = ref.watch(parentSelectedChildIdProvider);
    final dashboardAsync = ref.watch(parentDashboardDataProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(parentChildrenProvider);
          ref.invalidate(parentDashboardDataProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Header with Child Selector Dropdown (Section 17: ONE selected child at a time)
            childrenAsync.when(
              data: (children) {
                if (children.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.phonelink_erase_rounded, size: 48, color: AppTheme.textMuted),
                          const SizedBox(height: 16),
                          const Text(
                            'No Children Linked Yet',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Please complete mobile number verification to link your registered children.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => context.go('/phone-link'),
                            child: const Text('Verify Mobile Number'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My Children (Select Active Child)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        // Dropdown showing ONE selected child
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.primary, width: 1.5),
                            borderRadius: BorderRadius.circular(10),
                            color: AppTheme.primary.withAlpha(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedChildId ?? children.first['studentId'],
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primary),
                              items: children.map((c) {
                                return DropdownMenuItem<String>(
                                  value: c['studentId'] as String,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.face_rounded, color: AppTheme.primary, size: 20),
                                      const SizedBox(width: 10),
                                      Text(
                                        c['name'] as String,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '(${c['className']})',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (newId) {
                                if (newId != null) {
                                  ref.read(parentSelectedChildIdProvider.notifier).select(newId);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error loading children: $e'),
            ),

            const SizedBox(height: 20),

            // Metrics for the ONE selected child (Section 12 & 17)
            dashboardAsync.when(
              data: (data) {
                if (data == null) {
                  return const SizedBox.shrink();
                }

                final percent = data.attendancePercentage;
                final isGood = percent >= 75.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Child Summary Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: AppTheme.primary.withAlpha(25),
                              child: Text(
                                data.studentName.isNotEmpty ? data.studentName[0].toUpperCase() : 'C',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data.studentName,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Class: ${data.className} • ${data.schoolName}',
                                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isGood ? AppTheme.presentLight : AppTheme.lateLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${percent.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: isGood ? const Color(0xFF047857) : const Color(0xFFB45309),
                                    ),
                                  ),
                                  Text(
                                    'Attendance',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isGood ? const Color(0xFF047857) : const Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Present, Late, Absent Counts
                    LayoutBuilder(builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 650;
                      return GridView.count(
                        crossAxisCount: isWide ? 4 : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: isWide ? 1.6 : 1.15,
                        children: [
                          MetricCard(
                            title: 'Present Sessions',
                            value: '${data.presentCount}',
                            subtitle: 'Attended on time',
                            icon: Icons.check_circle_outline_rounded,
                            iconColor: AppTheme.present,
                            valueColor: AppTheme.present,
                          ),
                          MetricCard(
                            title: 'Late Sessions',
                            value: '${data.lateCount}',
                            subtitle: 'Attended late',
                            icon: Icons.access_time_rounded,
                            iconColor: AppTheme.late,
                            valueColor: AppTheme.late,
                          ),
                          MetricCard(
                            title: 'Absent Sessions',
                            value: '${data.absentCount}',
                            subtitle: 'Did not attend',
                            icon: Icons.cancel_outlined,
                            iconColor: AppTheme.absent,
                            valueColor: AppTheme.absent,
                          ),
                          MetricCard(
                            title: 'Total Eligible Sessions',
                            value: '${data.totalEligibleSessions}',
                            subtitle: 'Confirmed tuition classes',
                            icon: Icons.format_list_numbered_rounded,
                            iconColor: AppTheme.primary,
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 20),

                    // Quick Nav buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.history_rounded, size: 16),
                            label: const Text('View Full Attendance History'),
                            onPressed: () => context.go('/parent/history'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.school_outlined, size: 16),
                            label: const Text('View Tutor Info'),
                            onPressed: () => context.go('/parent/tutor-info'),
                          ),
                        ),
                      ],
                    ),
                  ],
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
