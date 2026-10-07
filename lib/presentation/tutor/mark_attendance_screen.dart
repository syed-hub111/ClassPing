import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../state/tutor_provider.dart';
import '../common/status_badge.dart';

class MarkAttendanceScreen extends ConsumerStatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  ConsumerState<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends ConsumerState<MarkAttendanceScreen> {
  final _subjectCtrl = TextEditingController();

  final List<String> _suggestedSubjects = [
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'English',
    'Social Science',
    'Computer Science',
  ];

  @override
  void initState() {
    super.initState();
    final state = ref.read(rollCallProvider);
    if (state.subject.isNotEmpty) {
      _subjectCtrl.text = state.subject;
    }
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rollCallState = ref.watch(rollCallProvider);

    if (rollCallState.selectedClass == null || rollCallState.selectedOpportunity == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mark Attendance')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No active session selected.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.go('/tutor/dashboard'),
                child: const Text('Return to Classes'),
              ),
            ],
          ),
        ),
      );
    }

    if (rollCallState.step == 'REVIEW') {
      return _buildReviewView(context, rollCallState);
    }

    if (rollCallState.step == 'LOCKED') {
      return _buildLockedView(context, rollCallState);
    }

    // Default: Step 1 = MARK
    return _buildMarkView(context, rollCallState);
  }

  Widget _buildMarkView(BuildContext context, RollCallState state) {
    final opp = state.selectedOpportunity!;
    final cls = state.selectedClass!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/tutor/dashboard'),
        ),
        title: Text('Roll Call • ${cls.name}'),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.cardBorder)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${state.students.length} students to mark',
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('Review Roll Call'),
              onPressed: () {
                final ok = ref.read(rollCallProvider.notifier).validateAndProceedToReview();
                if (!ok && state.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.errorMessage!), backgroundColor: AppTheme.absent),
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cls.name} (Slot ${opp.slotNumber})',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Session Date: ${opp.sessionDate}',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: opp.status, isSmall: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Flexible Subject Input (Section 10)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Subject Selection (Flexible / Substitute-friendly) *',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'You may conduct and record attendance for any subject taught during this session.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _subjectCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Enter subject name e.g. Mathematics',
                      prefixIcon: Icon(Icons.menu_book_rounded, size: 20),
                    ),
                    onChanged: (v) => ref.read(rollCallProvider.notifier).setSubject(v),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _suggestedSubjects.map((s) {
                      return ActionChip(
                        label: Text(s, style: const TextStyle(fontSize: 12)),
                        onPressed: () {
                          _subjectCtrl.text = s;
                          ref.read(rollCallProvider.notifier).setSubject(s);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Roll call controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Student Roll Call', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              Row(
                children: [
                  TextButton(
                    onPressed: () => ref.read(rollCallProvider.notifier).markAll('PRESENT'),
                    child: const Text('Mark All Present', style: TextStyle(color: AppTheme.present, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => ref.read(rollCallProvider.notifier).markAll('ABSENT'),
                    child: const Text('Mark All Absent', style: TextStyle(color: AppTheme.absent)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Students list
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.students.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: AppTheme.cardBorder),
              itemBuilder: (context, index) {
                final student = state.students[index];
                final sId = student['studentId'] as String;
                final sName = student['name'] as String;
                final currentStatus = state.studentStatuses[sId] ?? 'PRESENT';

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primary.withAlpha(25),
                        child: Text(
                          sName.isNotEmpty ? sName[0].toUpperCase() : 'S',
                          style: const TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            Text(student['schoolName'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Present / Late / Absent Toggle
                      _buildStatusToggle(
                        currentStatus: currentStatus,
                        onChanged: (newStatus) => ref.read(rollCallProvider.notifier).setStudentStatus(sId, newStatus),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatusToggle({required String currentStatus, required Function(String) onChanged}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleButton('PRESENT', 'P', currentStatus, AppTheme.present, AppTheme.presentLight, onChanged),
          _toggleButton('LATE', 'L', currentStatus, AppTheme.late, AppTheme.lateLight, onChanged),
          _toggleButton('ABSENT', 'A', currentStatus, AppTheme.absent, AppTheme.absentLight, onChanged),
        ],
      ),
    );
  }

  Widget _toggleButton(String status, String label, String current, Color color, Color bg, Function(String) onTap) {
    final isSelected = current == status;
    return InkWell(
      onTap: () => onTap(status),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? bg : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: isSelected ? color : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildReviewView(BuildContext context, RollCallState state) {
    int present = 0;
    int late = 0;
    int absent = 0;

    for (final s in state.students) {
      final st = state.studentStatuses[s['studentId']] ?? 'PRESENT';
      if (st == 'PRESENT') present++;
      if (st == 'LATE') late++;
      if (st == 'ABSENT') absent++;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => ref.read(rollCallProvider.notifier).backToMark(),
        ),
        title: const Text('Review Roll Call Summary'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            color: AppTheme.primary.withAlpha(15),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Class: ${state.selectedClass?.name}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Date: ${state.selectedOpportunity?.sessionDate}',
                        style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Subject: ${state.subject}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _countChip('PRESENT', present, AppTheme.present, AppTheme.presentLight),
                      _countChip('LATE', late, AppTheme.late, AppTheme.lateLight),
                      _countChip('ABSENT', absent, AppTheme.absent, AppTheme.absentLight),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (state.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.absentLight, borderRadius: BorderRadius.circular(8)),
              child: Text(state.errorMessage!, style: const TextStyle(color: AppTheme.absent)),
            ),
            const SizedBox(height: 16),
          ],

          const Text('Student Roll Call Verification', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.students.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: AppTheme.cardBorder),
              itemBuilder: (context, index) {
                final s = state.students[index];
                final sId = s['studentId'] as String;
                final status = state.studentStatuses[sId] ?? 'PRESENT';

                return ListTile(
                  dense: true,
                  title: Text(s['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(s['schoolName'] as String, style: const TextStyle(fontSize: 12)),
                  trailing: StatusBadge(status: status, isSmall: true),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Confirm & Lock Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.primary,
            ),
            icon: state.isSubmitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.lock_outline_rounded),
            label: const Text('Confirm & Lock Attendance', style: TextStyle(fontSize: 15)),
            onPressed: state.isSubmitting ? null : () => ref.read(rollCallProvider.notifier).confirmAndLock(),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: state.isSubmitting ? null : () => ref.read(rollCallProvider.notifier).backToMark(),
            child: const Text('Back to Edit Roll Call'),
          ),
        ],
      ),
    );
  }

  Widget _countChip(String label, int count, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildLockedView(BuildContext context, RollCallState state) {
    final result = state.confirmationResult;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(color: AppTheme.presentLight, shape: BoxShape.circle),
                      child: const Icon(Icons.check_circle_rounded, color: AppTheme.present, size: 48),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Attendance Confirmed & Locked',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'The session has been recorded authoritatively in the backend. Parent notifications have been triggered.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    if (result != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Session Status:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                StatusBadge(status: result['sessionStatus'] ?? 'LOCKED', isSmall: true),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Deadline Status:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                StatusBadge(status: result['deadlineStatus'] ?? 'WITHIN_DEADLINE', isSmall: true),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                      onPressed: () => context.go('/tutor/dashboard'),
                      child: const Text('Return to Classes'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
