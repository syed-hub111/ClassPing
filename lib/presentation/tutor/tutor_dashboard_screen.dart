import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/class_model.dart';
import '../../models/expected_opportunity.dart';
import '../../state/auth_provider.dart';
import '../../state/tutor_provider.dart';

class TutorDashboardScreen extends ConsumerStatefulWidget {
  const TutorDashboardScreen({super.key});

  @override
  ConsumerState<TutorDashboardScreen> createState() => _TutorDashboardScreenState();
}

class _TutorDashboardScreenState extends ConsumerState<TutorDashboardScreen> {
  String? _selectedClassFilter;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _startMarking(ClassModel classModel, ExpectedOpportunity opp) async {
    List<Map<String, dynamic>> students = [];
    try {
      students = await ref.read(tutorClassStudentsProvider(classModel.classId).future);
    } catch (_) {}

    // Fallback roster if empty in dev/demo environment
    if (students.isEmpty) {
      final names = [
        'Aarav Sharma', 'Aditi Patel', 'Akash Rao', 'Ananya Gupta', 'Aryan Verma',
        'Bhavna Joshi', 'Dev Nair', 'Diya Iyer', 'Ishaan Kumar', 'Kavya Pillai',
        'Manish Reddy', 'Meera Menon', 'Neha Sen', 'Nikhil Bhat', 'Pooja Hegde',
        'Pranav Das', 'Priya Kulkarni', 'Rahul Desai', 'Rhea Kapoor', 'Rohan Seth',
        'Sanya Roy', 'Siddharth Rao', 'Sneha Nair', 'Tanvi Mehta', 'Varun Bajaj',
        'Yash Singhania', 'Zara Khan', 'Kabir Malhotra', 'Tarun Mittal', 'Simran Kaur',
        'Karan Johar', 'Shruti Hassan',
      ];
      students = List.generate(
        32,
        (i) => {
          'studentId': 'std_${classModel.classId}_${i + 1}',
          'name': names[i % names.length],
          'parentName': 'Guardian of ${names[i % names.length]}',
          'schoolName': 'City Academy High',
        },
      );
    }

    ref.read(rollCallProvider.notifier).initForSession(
          classModel: classModel,
          opportunity: opp,
          students: students,
        );

    if (mounted) {
      context.go('/tutor/mark-attendance');
    }
  }

  void _showCompletedDetailsSheet(TutorDashboardSession session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.tutorSuccessBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: AppTheme.tutorSecondary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session Completed',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.tutorOnSurface,
                        ),
                      ),
                      Text(
                        '${session.classModel.name} • ${session.subject}',
                        style: const TextStyle(fontSize: 13, color: AppTheme.tutorOnSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.tutorSuccessBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'LOCKED',
                    style: TextStyle(color: AppTheme.tutorSecondary, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.tutorSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Column(
                children: [
                  _detailRow('Session Date', session.opportunity.sessionDate),
                  const Divider(height: 16),
                  _detailRow('Time Slot', session.slotTimeText),
                  const Divider(height: 16),
                  _detailRow('Total Students', '${session.enrolledCount} enrolled'),
                  const Divider(height: 16),
                  _detailRow('Attendance Status', 'Verified & Locked'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.tutorPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close Details', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.between,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.tutorOnSurfaceVariant)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.tutorOnSurface)),
      ],
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.tutorSurfaceContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.support_agent_rounded, color: AppTheme.tutorPrimary),
            ),
            const SizedBox(width: 12),
            const Text('Tuition Support', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Need assistance with attendance records, session deadlines, or class schedules?',
              style: TextStyle(fontSize: 13, color: AppTheme.tutorOnSurfaceVariant),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.email_outlined, size: 18, color: AppTheme.tutorPrimary),
                SizedBox(width: 10),
                Text('admin@classping.com', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 18, color: AppTheme.tutorPrimary),
                SizedBox(width: 10),
                Text('+91 98765 43210', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss', style: TextStyle(color: AppTheme.tutorPrimary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showAllClassesSheet(List<ClassModel> classes, Map<String, int> studentCounts) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'All Authorized Classes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.tutorOnSurface),
            ),
            const SizedBox(height: 4),
            const Text(
              'Classes assigned to you for daily attendance.',
              style: TextStyle(fontSize: 13, color: AppTheme.tutorOnSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: classes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final cls = classes[i];
                  final count = studentCounts[cls.classId] ?? 30;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.tutorSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.tutorPrimary,
                          child: Text(
                            cls.name.replaceAll(RegExp(r'[^0-9]'), '').isNotEmpty
                                ? cls.name.replaceAll(RegExp(r'[^0-9]'), '')
                                : '${i + 1}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cls.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 2),
                              Text('$count Students • ${cls.operatingDays.length} Days/wk',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.tutorOnSurfaceVariant)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.tutorPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            setState(() {
                              _selectedClassFilter = cls.classId;
                            });
                          },
                          child: const Text('Filter', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final overviewAsync = ref.watch(tutorDashboardOverviewProvider);
    final tutorName = authState.userProfile?.displayName ?? 'Mr. Rahman';

    return Scaffold(
      backgroundColor: AppTheme.tutorSurface,
      body: RefreshIndicator(
        color: AppTheme.tutorPrimary,
        onRefresh: () async => ref.refresh(tutorDashboardOverviewProvider.future),
        child: overviewAsync.when(
          data: (overview) {
            final filteredSessions = _selectedClassFilter == null
                ? overview.sessions
                : overview.sessions.where((s) => s.classModel.classId == _selectedClassFilter).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                // 1. Tutor Welcome Header & Profile Summary Card
                _buildWelcomeHeader(tutorName),

                const SizedBox(height: 16),

                // 2. Quick Stats 2x2 Grid
                _buildQuickStats(overview),

                const SizedBox(height: 24),

                // 3. My Classes Carousel
                _buildMyClassesSection(overview),

                const SizedBox(height: 24),

                // 4. Pending Sessions Section
                _buildPendingSessionsSection(overview, filteredSessions),

                const SizedBox(height: 24),

                // 5. Guidance Banner
                _buildGuidanceBanner(),

                const SizedBox(height: 24),

                // 6. Campus Activity Gallery Strip
                _buildCampusActivitySection(),
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: AppTheme.tutorPrimary),
            ),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Error loading dashboard: $e', style: const TextStyle(color: AppTheme.tutorError)),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 1: Welcome Header Card
  // ==========================================
  Widget _buildWelcomeHeader(String tutorName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.wb_sunny_rounded, color: Color(0xFFF59E0B), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Daily Schedule',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${_getGreeting()}, $tutorName!',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.tutorOnSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Here's what's happening with your classes today.",
                  style: TextStyle(fontSize: 12, color: AppTheme.tutorOnSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Stack(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.tutorPrimary.withAlpha(40), width: 1.5),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuDoSvBlrWIPm0psX66h3fcx9mz7rRxzJ_zHveRhmTA-pij2H7VGjwhIp9R9U9mfbq0hpGGTk6foPnKQJkrTZ-SOxMw-ngz0J89jjPBC9VS0PzEoqbJLHy3TuZhAvjuO8vT19GbhxsvPqdPTuNNODG91nn0gYEN6s9yb6gAy8WH9zUZ4m-BJOVXxo0aLhFT6oG5SYwcY1qqH5qx0DlCtc3JKesbtcR2AXsEysgVQtsA',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppTheme.tutorPrimary.withAlpha(20),
                          child: const Icon(Icons.person_rounded, color: AppTheme.tutorPrimary, size: 28),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.tutorSecondary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.tutorSurfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'TUTOR',
                  style: TextStyle(
                    color: AppTheme.tutorPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION 2: Quick Stats 2x2 Grid
  // ==========================================
  Widget _buildQuickStats(TutorDashboardOverview overview) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.between,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppTheme.tutorPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Quick Stats',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.tutorOnSurface),
                ),
              ],
            ),
            const Text(
              'Live Overview',
              style: TextStyle(fontSize: 12, color: AppTheme.tutorOnSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.3,
          children: [
            _statCard(
              icon: Icons.menu_book_rounded,
              iconColor: AppTheme.tutorPrimary,
              iconBg: AppTheme.tutorSurfaceContainer,
              value: '${overview.totalClasses}',
              label: 'Total Classes',
            ),
            _statCard(
              icon: Icons.groups_rounded,
              iconColor: AppTheme.tutorSecondary,
              iconBg: AppTheme.tutorSuccessBg,
              value: '${overview.totalStudents}',
              label: 'Total Students',
            ),
            _statCard(
              icon: Icons.schedule_rounded,
              iconColor: const Color(0xFFB45309),
              iconBg: AppTheme.tutorWarningBg,
              value: '${overview.pendingSessionsCount}',
              label: 'Pending',
            ),
            _statCard(
              icon: Icons.error_rounded,
              iconColor: AppTheme.tutorError,
              iconBg: AppTheme.tutorErrorContainer,
              value: '${overview.missedDeadlinesCount}',
              label: 'Overdue Roll',
              isError: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
    bool isError = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(4),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isError ? AppTheme.tutorError : AppTheme.tutorOnSurface,
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isError ? AppTheme.tutorError : AppTheme.tutorOnSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION 3: My Classes Carousel
  // ==========================================
  Widget _buildMyClassesSection(TutorDashboardOverview overview) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.between,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.tutorSurfaceHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.group_work_rounded, color: AppTheme.tutorPrimary, size: 18),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('My Classes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.tutorOnSurface)),
                    Text('Classes assigned to you', style: TextStyle(fontSize: 11, color: AppTheme.tutorOnSurfaceVariant)),
                  ],
                ),
              ],
            ),
            InkWell(
              onTap: () => _showAllClassesSheet(overview.classes, overview.studentCounts),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: const [
                    Text(
                      'View All',
                      style: TextStyle(color: AppTheme.tutorPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.tutorPrimary),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: overview.classes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final cls = overview.classes[index];
              final count = overview.studentCounts[cls.classId] ?? 30;
              final subjects = (overview.classSubjects[cls.classId] ?? ['Mathematics', 'Physics']).join(', ');

              // Color tints per card
              final colorSchemes = [
                (headerBg: const Color(0xFFEFF4FF), badgeBg: AppTheme.tutorPrimary, text: '10'),
                (headerBg: const Color(0xFFEEF2FF), badgeBg: const Color(0xFF4F46E5), text: '11'),
                (headerBg: const Color(0xFFECFDF5), badgeBg: AppTheme.tutorSecondary, text: '12'),
              ];
              final scheme = colorSchemes[index % colorSchemes.length];

              return Container(
                width: 280,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Tint
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: scheme.headerBg,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.between,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: scheme.badgeBg,
                                child: Text(
                                  cls.name.replaceAll(RegExp(r'[^0-9]'), '').isNotEmpty
                                      ? cls.name.replaceAll(RegExp(r'[^0-9]'), '')
                                      : scheme.text,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                cls.name,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.tutorOnSurface),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.tutorSuccessBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(color: AppTheme.tutorSecondary, fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Details
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          _classInfoRow(Icons.calendar_today_rounded, cls.operatingDays.map((d) => d.substring(0, 3)).join(', ')),
                          const SizedBox(height: 8),
                          _classInfoRow(Icons.layers_rounded, subjects),
                          const SizedBox(height: 8),
                          _classInfoRow(Icons.person_outline_rounded, '$count Students enrolled'),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Bottom Button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.tutorPrimary,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedClassFilter = (_selectedClassFilter == cls.classId) ? null : cls.classId;
                            });
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _selectedClassFilter == cls.classId ? 'Filtered Sessions' : 'View Pending Sessions',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right_rounded, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _classInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppTheme.tutorOnSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppTheme.tutorOnSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SECTION 4: Pending Sessions Section
  // ==========================================
  Widget _buildPendingSessionsSection(
    TutorDashboardOverview overview,
    List<TutorDashboardSession> sessions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.between,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.tutorSurfaceHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.assignment_turned_in_rounded, color: AppTheme.tutorPrimary, size: 18),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Pending Sessions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.tutorOnSurface)),
                    Text('Sessions that need your attention', style: TextStyle(fontSize: 11, color: AppTheme.tutorOnSurfaceVariant)),
                  ],
                ),
              ],
            ),
            if (_selectedClassFilter != null)
              TextButton(
                onPressed: () => setState(() => _selectedClassFilter = null),
                child: const Text('Clear Filter', style: TextStyle(fontSize: 12, color: AppTheme.tutorPrimary)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (sessions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: const Center(
              child: Text(
                'No sessions pending for the selected filter.',
                style: TextStyle(color: AppTheme.tutorOnSurfaceVariant, fontSize: 13),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final session = sessions[index];
              return _buildSessionCard(session);
            },
          ),
      ],
    );
  }

  Widget _buildSessionCard(TutorDashboardSession session) {
    final opp = session.opportunity;
    final isMissed = opp.status == 'MISSED_DEADLINE';
    final isCompleted = opp.status == 'LOCKED' || opp.status == 'COMPLETED_AFTER_DEADLINE';

    // Parse date for visual day block
    DateTime? parsedDate = DateTime.tryParse(opp.sessionDate);
    final weekdayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final weekdayStr = parsedDate != null ? weekdayNames[parsedDate.weekday - 1] : 'TUE';
    final dayNum = parsedDate != null ? '${parsedDate.day}' : '16';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isMissed ? const Color(0xFFFFF7F7) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isMissed ? const Color(0xFFFFD5D5) : AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(4),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Row: Date Block + Class info + Status Badge
          Row(
            children: [
              // Date Block
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isMissed ? AppTheme.tutorErrorContainer : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      weekdayStr,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isMissed ? AppTheme.tutorError : AppTheme.tutorOnSurfaceVariant,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dayNum,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isMissed ? AppTheme.tutorError : AppTheme.tutorOnSurface,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Class & Subject Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.classModel.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.tutorOnSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${session.subject} • ${session.enrolledCount} Students',
                      style: const TextStyle(fontSize: 11, color: AppTheme.tutorOnSurfaceVariant),
                    ),
                  ],
                ),
              ),
              // Status Badge
              if (isMissed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.tutorErrorContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.warning_amber_rounded, size: 12, color: AppTheme.tutorError),
                      SizedBox(width: 4),
                      Text(
                        'Missed Deadline',
                        style: TextStyle(color: AppTheme.tutorError, fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                )
              else if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.tutorSuccessBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.check_circle_outline_rounded, size: 12, color: AppTheme.tutorSecondary),
                      SizedBox(width: 4),
                      Text(
                        'Completed',
                        style: TextStyle(color: AppTheme.tutorSecondary, fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.tutorWarningBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.schedule_rounded, size: 12, color: Color(0xFFB45309)),
                      SizedBox(width: 4),
                      Text(
                        'Pending',
                        style: TextStyle(color: Color(0xFFB45309), fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          // Bottom Row: Time Slot + Action Button
          Row(
            mainAxisAlignment: MainAxisAlignment.between,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: isMissed ? AppTheme.tutorError : AppTheme.tutorOnSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    session.slotTimeText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isMissed ? FontWeight.w600 : FontWeight.normal,
                      color: isMissed ? AppTheme.tutorError : AppTheme.tutorOnSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (isCompleted)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.tutorPrimary,
                    side: const BorderSide(color: Color(0xFFD3E4FE)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _showCompletedDetailsSheet(session),
                  child: Row(
                    children: const [
                      Text('View Details', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, size: 14),
                    ],
                  ),
                )
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.tutorPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _startMarking(session.classModel, session.opportunity),
                  child: Row(
                    children: const [
                      Text('Mark Roll Call', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 13),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION 5: Guidance Banner
  // ==========================================
  Widget _buildGuidanceBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDCE9FF), Color(0xFFE5EEFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB3C5FF).withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.tutorPrimary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Mark Attendance On Time',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.tutorOnSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Keep track of pending sessions and submit attendance within 30 minutes of class completion.',
            style: TextStyle(fontSize: 12, color: AppTheme.tutorOnSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: _showSupportDialog,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.support_agent_rounded, size: 16, color: AppTheme.tutorPrimary),
                  SizedBox(width: 6),
                  Text(
                    'Need Help? Contact Support',
                    style: TextStyle(color: AppTheme.tutorPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.tutorPrimary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION 6: Campus Activity Photo Strip
  // ==========================================
  Widget _buildCampusActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.between,
          children: const [
            Text(
              'Campus Activity',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.tutorOnSurface),
            ),
            Text(
              'Live Streams',
              style: TextStyle(fontSize: 12, color: AppTheme.tutorOnSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _campusPhotoCard(
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuCIG6BY_MSD9Gl5B5YArAS8QW-UMOs1NL89U47ienFZRegppLjYsUAAK-nctBPpYL-2S9L8f2y00yUrtD3S8_JmLLh8c1MrnJwmsQPrR7L8ONtoDR3jO6bV_M309kWaGzxFLVYu90PLpz_WlsqEP6J_zKUzEuGLEtfdQoj7x3225UoS14ruhxEwmtBRdR2aZfBiuGbb-MzXgyOkHl6jftPU3iwPak4Pb9BnXL7IQpk',
                title: 'Lab Room 3B',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _campusPhotoCard(
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuBlKIvs8_OaGwm-W3T5n6Z2A8g7deBbcAbLpQKzqy2GzQLkunA5C8NeATDoNflZ40MlVMLk_VISiOli-5mC_hK9GmmENoiOumY1rqzt3nkqzyxaUiDStywXKZ1ELYgcrm9SEXzt9i8FNENLPnNuDjAqVlSpw9FHpGn8QTOXoGiIQPGVUcvDf8vwSPHxIoskgMgqMzjatRdMs6MGtSY-zQZ6lF4A28A11-O0sO6thCQ',
                title: 'Lecture Hall 2',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _campusPhotoCard({required String imageUrl, required String title}) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFDCE9FF),
                child: const Icon(Icons.school_rounded, color: AppTheme.tutorPrimary, size: 32),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black87, Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
