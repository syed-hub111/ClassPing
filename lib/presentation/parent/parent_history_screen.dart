import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../state/parent_provider.dart';
import '../common/status_badge.dart';

class ParentHistoryScreen extends ConsumerWidget {
  const ParentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(parentChildrenProvider);
    final selectedChildId = ref.watch(parentSelectedChildIdProvider);
    final historyAsync = ref.watch(parentHistoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Attendance History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.refresh(parentHistoryProvider),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Child Selector Bar
          childrenAsync.when(
            data: (children) {
              if (children.isEmpty) return const SizedBox.shrink();
              return Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Text(
                        'Child: ',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedChildId ?? children.first['studentId'],
                            isExpanded: true,
                            items: children.map((c) {
                              return DropdownMenuItem(
                                value: c['studentId'] as String,
                                child: Text(
                                  '${c['name']} (${c['className']})',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
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
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),

          // Attendance History Timeline
          historyAsync.when(
            data: (history) {
              if (history.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: const [
                          Icon(Icons.history_toggle_off_rounded, size: 40, color: AppTheme.textMuted),
                          SizedBox(height: 12),
                          Text('No Attendance Records Yet', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          SizedBox(height: 4),
                          Text(
                            'Confirmed roll calls by tutors will appear here automatically.',
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, color: AppTheme.cardBorder),
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: item.status == 'PRESENT'
                              ? AppTheme.presentLight
                              : (item.status == 'LATE' ? AppTheme.lateLight : AppTheme.absentLight),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          item.status == 'PRESENT'
                              ? Icons.check_rounded
                              : (item.status == 'LATE' ? Icons.access_time_rounded : Icons.close_rounded),
                          color: item.status == 'PRESENT'
                              ? AppTheme.present
                              : (item.status == 'LATE' ? AppTheme.late : AppTheme.absent),
                          size: 20,
                        ),
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item.subject, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          StatusBadge(status: item.status, isSmall: true),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Date: ${item.sessionDate} • Tutor: ${item.tutorName}', style: const TextStyle(fontSize: 13)),
                          const SizedBox(height: 2),
                          Text('Class: ${item.className}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
            error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppTheme.absent))),
          ),
        ],
      ),
    );
  }
}
