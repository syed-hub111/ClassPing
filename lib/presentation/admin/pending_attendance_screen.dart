import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/expected_opportunity.dart';
import '../../state/admin_provider.dart';
import '../../state/api_provider.dart';
import '../common/status_badge.dart';

class PendingAttendanceScreen extends ConsumerStatefulWidget {
  const PendingAttendanceScreen({super.key});

  @override
  ConsumerState<PendingAttendanceScreen> createState() => _PendingAttendanceScreenState();
}

class _PendingAttendanceScreenState extends ConsumerState<PendingAttendanceScreen> {
  void _showCreateSlotDialog() {
    final dateCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
    String? selectedClassId;
    int slotNumber = 1;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final classesAsync = ref.watch(adminClassesProvider);

            return AlertDialog(
              title: const Text('Add Expected Session Slot', style: TextStyle(fontWeight: FontWeight.w700)),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    classesAsync.when(
                      data: (classes) {
                        selectedClassId ??= classes.isNotEmpty ? classes.first.classId : null;
                        return DropdownButtonFormField<String>(
                          initialValue: selectedClassId,
                          decoration: const InputDecoration(labelText: 'Class *'),
                          items: classes.map((c) => DropdownMenuItem(value: c.classId, child: Text(c.name))).toList(),
                          onChanged: (v) => setDialogState(() => selectedClassId = v),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (_, _) => const Text('Error loading classes'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: dateCtrl,
                      decoration: const InputDecoration(labelText: 'Session Date (YYYY-MM-DD) *'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: slotNumber,
                      decoration: const InputDecoration(labelText: 'Session Slot Number *'),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Slot 1')),
                        DropdownMenuItem(value: 2, child: Text('Slot 2')),
                        DropdownMenuItem(value: 3, child: Text('Slot 3')),
                      ],
                      onChanged: (v) => setDialogState(() => slotNumber = v ?? 1),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: isSaving || selectedClassId == null
                      ? null
                      : () async {
                          setDialogState(() => isSaving = true);
                          try {
                            final api = ref.read(apiServiceProvider);
                            await api.adminCreateExpectedOpportunity(
                              classId: selectedClassId!,
                              sessionDate: dateCtrl.text.trim(),
                              slotNumber: slotNumber,
                            );
                            ref.invalidate(adminOpportunitiesProvider);
                            ref.invalidate(adminDashboardStatsProvider);
                            if (mounted) Navigator.pop(ctx);
                          } catch (err) {
                            setDialogState(() => isSaving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $err'), backgroundColor: AppTheme.absent),
                            );
                          }
                        },
                  child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white)) : const Text('Add Slot'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCancelDialog(ExpectedOpportunity opp) {
    final reasonCtrl = TextEditingController(text: 'Inclement weather / Holiday');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Cancel Session Slot (${opp.className})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Cancelling this slot marks it as CANCELLED so it will not generate a missed deadline alert.', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: reasonCtrl,
                      decoration: const InputDecoration(labelText: 'Cancellation Reason *'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep Slot')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.absent),
                  onPressed: isSaving
                      ? null
                      : () async {
                          setDialogState(() => isSaving = true);
                          try {
                            final api = ref.read(apiServiceProvider);
                            await api.adminCancelExpectedOpportunity(opp.opportunityId, reasonCtrl.text.trim());
                            ref.invalidate(adminOpportunitiesProvider);
                            ref.invalidate(adminDashboardStatsProvider);
                            if (mounted) Navigator.pop(ctx);
                          } catch (err) {
                            setDialogState(() => isSaving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $err'), backgroundColor: AppTheme.absent),
                            );
                          }
                        },
                  child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white)) : const Text('Confirm Cancellation'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _triggerScheduledJobs() async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.adminTriggerScheduledJobs();
      ref.invalidate(adminOpportunitiesProvider);
      ref.invalidate(adminDashboardStatsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scheduled generation and deadline check completed.'), backgroundColor: AppTheme.present),
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
    final oppsAsync = ref.watch(adminOpportunitiesProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Pending & Missed Attendance Monitor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt_rounded),
            tooltip: 'Trigger Daily Scheduled Check',
            onPressed: _triggerScheduledJobs,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.refresh(adminOpportunitiesProvider),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
              label: const Text('Add Expected Slot'),
              onPressed: _showCreateSlotDialog,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: oppsAsync.when(
          data: (opps) {
            if (opps.isEmpty) {
              return const Center(child: Text('No pending or missed attendance sessions! All attendance is up to date.'));
            }

            return Card(
              child: ListView.separated(
                itemCount: opps.length,
                separatorBuilder: (_, _) => const Divider(height: 1, color: AppTheme.cardBorder),
                itemBuilder: (context, index) {
                  final opp = opps[index];
                  final isMissed = opp.status == 'MISSED_DEADLINE';

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isMissed ? AppTheme.absentLight : AppTheme.lateLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isMissed ? Icons.warning_rounded : Icons.pending_actions_rounded,
                        color: isMissed ? AppTheme.absent : AppTheme.late,
                        size: 20,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(opp.className, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(width: 8),
                        Text('(Slot ${opp.slotNumber})', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        const SizedBox(width: 8),
                        StatusBadge(status: opp.status, isSmall: true),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Session Date: ${opp.sessionDate} • Academic Year: ${opp.academicYearId}', style: const TextStyle(fontSize: 12)),
                        if (isMissed) ...[
                          const SizedBox(height: 2),
                          const Text(
                            'Normal deadline passed. May still be completed within the 7-day allowed period.',
                            style: TextStyle(fontSize: 12, color: AppTheme.absent, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ],
                    ),
                    trailing: opp.isLocked
                        ? null
                        : OutlinedButton(
                            style: OutlinedButton.styleFrom(foregroundColor: AppTheme.absent),
                            onPressed: () => _showCancelDialog(opp),
                            child: const Text('Cancel Slot', style: TextStyle(fontSize: 12)),
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
