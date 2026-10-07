import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../state/auth_provider.dart';
import '../../state/tutor_provider.dart';

class TutorShellScreen extends ConsumerStatefulWidget {
  final Widget child;

  const TutorShellScreen({super.key, required this.child});

  @override
  ConsumerState<TutorShellScreen> createState() => _TutorShellScreenState();
}

class _TutorShellScreenState extends ConsumerState<TutorShellScreen> {
  int _activeNavIndex = 0; // 0: Dashboard, 1: Classes, 2: Attendance, 3: Alerts, 4: Settings

  void _onNavTap(int index) {
    setState(() => _activeNavIndex = index);

    if (index == 0) {
      context.go('/tutor/dashboard');
    } else if (index == 1) {
      _showClassesSheet();
    } else if (index == 2) {
      context.go('/tutor/dashboard');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Showing all pending and overdue attendance sessions below.'),
          duration: Duration(seconds: 2),
          backgroundColor: AppTheme.tutorPrimary,
        ),
      );
    } else if (index == 3) {
      _showAlertsSheet();
    } else if (index == 4) {
      _showSettingsSheet();
    }
  }

  void _showClassesSheet() {
    final overview = ref.read(tutorDashboardOverviewProvider).value;
    final classes = overview?.classes ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
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
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'My Assigned Classes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.tutorOnSurface),
            ),
            const SizedBox(height: 4),
            const Text(
              'Batches authorized for your roll call submissions.',
              style: TextStyle(fontSize: 12, color: AppTheme.tutorOnSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: classes.isEmpty
                  ? const Center(child: Text('No classes found.'))
                  : ListView.separated(
                      itemCount: classes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final cls = classes[i];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.tutorSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppTheme.tutorPrimary,
                                child: Text(
                                  cls.name.replaceAll(RegExp(r'[^0-9]'), '').isNotEmpty
                                      ? cls.name.replaceAll(RegExp(r'[^0-9]'), '')
                                      : '${i + 1}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(cls.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text(
                                      'Operating: ${cls.operatingDays.map((d) => d.substring(0, 3)).join(", ")}',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.tutorOnSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.tutorSuccessBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Active',
                                  style: TextStyle(color: AppTheme.tutorSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
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

  void _showAlertsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
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
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.between,
              children: [
                const Text(
                  'Attendance Alerts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.tutorOnSurface),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.tutorErrorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('3 New', style: TextStyle(color: AppTheme.tutorError, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _alertTile(
                    title: 'Overdue: Class 12 - A Chemistry',
                    subtitle: 'Monday Session (Slot 3) has passed its normal submission deadline. Please mark roll call within 7 days.',
                    time: '1h ago',
                    isUrgent: true,
                  ),
                  const SizedBox(height: 10),
                  _alertTile(
                    title: 'Upcoming Session: Class 10 - A',
                    subtitle: 'Slot 1 scheduled today from 9:00 AM to 10:00 AM. Roll call opens at session completion.',
                    time: '3h ago',
                    isUrgent: false,
                  ),
                  const SizedBox(height: 10),
                  _alertTile(
                    title: 'Attendance Confirmed: Class 10 - A',
                    subtitle: 'Sunday roll call for Physics has been locked and parent notifications were dispatched.',
                    time: 'Yesterday',
                    isUrgent: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _alertTile({required String title, required String subtitle, required String time, required bool isUrgent}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUrgent ? const Color(0xFFFFF7F7) : AppTheme.tutorSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isUrgent ? const Color(0xFFFFD5D5) : AppTheme.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isUrgent ? AppTheme.tutorErrorContainer : AppTheme.tutorSurfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUrgent ? Icons.warning_amber_rounded : Icons.notifications_active_outlined,
              color: isUrgent ? AppTheme.tutorError : AppTheme.tutorPrimary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.between,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isUrgent ? AppTheme.tutorError : AppTheme.tutorOnSurface,
                        ),
                      ),
                    ),
                    Text(time, style: const TextStyle(fontSize: 10, color: AppTheme.tutorOnSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppTheme.tutorOnSurfaceVariant, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsSheet() {
    final authState = ref.watch(authProvider);
    final user = authState.userProfile;

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
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tutor Account & Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.tutorOnSurface),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppTheme.tutorSurfaceContainer,
                child: Icon(Icons.person, color: AppTheme.tutorPrimary),
              ),
              title: Text(user?.displayName ?? 'Mr. Rahman', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(user?.email ?? 'tutor@classping.com', style: const TextStyle(fontSize: 12)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppTheme.tutorSurfaceContainer, borderRadius: BorderRadius.circular(10)),
                child: const Text('TUTOR', style: TextStyle(color: AppTheme.tutorPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
            const Divider(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.notifications_outlined, color: AppTheme.tutorOnSurfaceVariant),
              title: const Text('Attendance Push Notifications', style: TextStyle(fontSize: 14)),
              trailing: Switch.adaptive(
                value: true,
                activeColor: AppTheme.tutorPrimary,
                onChanged: (_) {},
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lock_outline_rounded, color: AppTheme.tutorOnSurfaceVariant),
              title: const Text('App Lock & Biometrics', style: TextStyle(fontSize: 14)),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () {},
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.tutorErrorContainer,
                  foregroundColor: AppTheme.tutorError,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ref.read(authProvider.notifier).signOut();
                  if (context.mounted) context.go('/login');
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final isMarkingScreen = location.contains('/tutor/mark-attendance');

    return Scaffold(
      backgroundColor: AppTheme.tutorSurface,
      appBar: isMarkingScreen
          ? null
          : AppBar(
              backgroundColor: AppTheme.tutorSurface,
              elevation: 0,
              toolbarHeight: 64,
              scrolledUnderElevation: 1,
              titleSpacing: 16,
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.tutorPrimaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppTheme.tutorSecondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Active Today',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.tutorOnSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      const Text(
                        'Dashboard',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.tutorOnSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppTheme.tutorPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
                  ),
                  tooltip: 'Tutor Account',
                  onPressed: _showSettingsSheet,
                ),
                const SizedBox(width: 8),
              ],
            ),
      body: widget.child,
      bottomNavigationBar: isMarkingScreen
          ? null
          : Container(
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(240),
                border: const Border(top: BorderSide(color: Color(0xFFE5EEFF), width: 1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(6),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _navItem(0, Icons.dashboard_rounded, 'Dashboard'),
                    _navItem(1, Icons.menu_book_rounded, 'Classes'),
                    _navItem(2, Icons.fact_check_rounded, 'Attendance'),
                    _navItem(3, Icons.notifications_rounded, 'Alerts', badge: '3'),
                    _navItem(4, Icons.settings_rounded, 'Settings'),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, {String? badge}) {
    final isActive = _activeNavIndex == index;
    final color = isActive ? AppTheme.tutorPrimary : AppTheme.tutorOnSurfaceVariant;

    return InkWell(
      onTap: () => _onNavTap(index),
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 56,
        height: 52,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 22, color: color),
                if (badge != null)
                  Positioned(
                    top: -3,
                    right: -7,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      decoration: const BoxDecoration(
                        color: AppTheme.tutorError,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
