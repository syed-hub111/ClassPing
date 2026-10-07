import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../state/admin_provider.dart';
import '../common/metric_card.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardStatsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(adminDashboardStatsProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Overview',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tuition Center Health & Attendance Status',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () => ref.refresh(adminDashboardStatsProvider),
                  tooltip: 'Refresh Stats',
                ),
              ],
            ),
            const SizedBox(height: 24),
            statsAsync.when(
              data: (stats) {
                return LayoutBuilder(builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  return Column(
                    children: [
                      GridView.count(
                        crossAxisCount: isWide ? 4 : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: isWide ? 1.6 : 1.15,
                        children: [
                          MetricCard(
                            title: 'Active Students',
                            value: '${stats['activeStudents'] ?? 0}',
                            icon: Icons.school_outlined,
                            iconColor: AppTheme.primary,
                            onTap: () => context.go('/admin/students'),
                          ),
                          MetricCard(
                            title: 'Active Tutors',
                            value: '${stats['activeTutors'] ?? 0}',
                            icon: Icons.person_outline,
                            iconColor: const Color(0xFF06B6D4),
                            onTap: () => context.go('/admin/tutors'),
                          ),
                          MetricCard(
                            title: 'Active Classes',
                            value: '${stats['activeClasses'] ?? 0}',
                            icon: Icons.meeting_room_outlined,
                            iconColor: const Color(0xFF8B5CF6),
                            onTap: () => context.go('/admin/classes'),
                          ),
                          MetricCard(
                            title: 'Missed Deadlines',
                            value: '${stats['missedDeadlines'] ?? 0}',
                            subtitle: 'Needs Attention',
                            icon: Icons.warning_amber_rounded,
                            iconColor: AppTheme.absent,
                            valueColor: stats['missedDeadlines'] > 0 ? AppTheme.absent : AppTheme.textPrimary,
                            onTap: () => context.go('/admin/pending'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pending & Expected Attendance',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${stats['pendingSessions'] ?? 0} attendance session slot(s) currently pending submission by tutors.',
                                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                                label: const Text('View Pending & Missed Monitor'),
                                onPressed: () => context.go('/admin/pending'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                });
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
              error: (e, _) => Card(
                color: AppTheme.absentLight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error loading stats: $e', style: const TextStyle(color: AppTheme.absent)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
