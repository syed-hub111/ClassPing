import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/auth_provider.dart';
import '../constants/app_constants.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/auth/parent_phone_link_screen.dart';
import '../../presentation/admin/admin_shell_screen.dart';
import '../../presentation/admin/admin_dashboard_screen.dart';
import '../../presentation/admin/student_management_screen.dart';
import '../../presentation/admin/tutor_management_screen.dart';
import '../../presentation/admin/class_management_screen.dart';
import '../../presentation/admin/academic_year_screen.dart';
import '../../presentation/admin/promotion_screen.dart';
import '../../presentation/admin/pending_attendance_screen.dart';
import '../../presentation/tutor/tutor_shell_screen.dart';
import '../../presentation/tutor/tutor_dashboard_screen.dart';
import '../../presentation/tutor/mark_attendance_screen.dart';
import '../../presentation/parent/parent_shell_screen.dart';
import '../../presentation/parent/parent_dashboard_screen.dart';
import '../../presentation/parent/parent_history_screen.dart';
import '../../presentation/parent/parent_comparison_screen.dart';
import '../../presentation/parent/parent_tutor_info_screen.dart';
import '../../presentation/parent/parent_notifications_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuth = authState.isAuthenticated;
      final isLoggingIn = state.uri.path == '/login' || state.uri.path == '/phone-link';

      if (!isAuth) {
        return isLoggingIn ? null : '/login';
      }

      final role = authState.role;

      // If user is already on login page but authenticated, redirect to appropriate portal
      if (isLoggingIn) {
        if (role == AppConstants.roleAdmin) return '/admin/dashboard';
        if (role == AppConstants.roleTutor) return '/tutor/dashboard';
        if (role == AppConstants.roleParent) return '/parent/dashboard';
      }

      // Guard: Admin can only access /admin
      if (state.uri.path.startsWith('/admin') && role != AppConstants.roleAdmin) {
        return _portalRootForRole(role);
      }

      // Guard: Tutor can only access /tutor
      if (state.uri.path.startsWith('/tutor') && role != AppConstants.roleTutor) {
        return _portalRootForRole(role);
      }

      // Guard: Parent can only access /parent
      if (state.uri.path.startsWith('/parent') && role != AppConstants.roleParent) {
        return _portalRootForRole(role);
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/phone-link',
        builder: (context, state) => const ParentPhoneLinkScreen(),
      ),

      // Admin Routes
      ShellRoute(
        builder: (context, state, child) => AdminShellScreen(child: child),
        routes: [
          GoRoute(path: '/admin', redirect: (_, _) => '/admin/dashboard'),
          GoRoute(path: '/admin/dashboard', builder: (context, state) => const AdminDashboardScreen()),
          GoRoute(path: '/admin/students', builder: (context, state) => const StudentManagementScreen()),
          GoRoute(path: '/admin/tutors', builder: (context, state) => const TutorManagementScreen()),
          GoRoute(path: '/admin/classes', builder: (context, state) => const ClassManagementScreen()),
          GoRoute(path: '/admin/academic-years', builder: (context, state) => const AcademicYearScreen()),
          GoRoute(path: '/admin/promotion', builder: (context, state) => const PromotionScreen()),
          GoRoute(path: '/admin/pending', builder: (context, state) => const PendingAttendanceScreen()),
        ],
      ),

      // Tutor Routes
      ShellRoute(
        builder: (context, state, child) => TutorShellScreen(child: child),
        routes: [
          GoRoute(path: '/tutor', redirect: (_, _) => '/tutor/dashboard'),
          GoRoute(path: '/tutor/dashboard', builder: (context, state) => const TutorDashboardScreen()),
          GoRoute(path: '/tutor/mark-attendance', builder: (context, state) => const MarkAttendanceScreen()),
        ],
      ),

      // Parent Routes
      ShellRoute(
        builder: (context, state, child) => ParentShellScreen(child: child),
        routes: [
          GoRoute(path: '/parent', redirect: (_, _) => '/parent/dashboard'),
          GoRoute(path: '/parent/dashboard', builder: (context, state) => const ParentDashboardScreen()),
          GoRoute(path: '/parent/history', builder: (context, state) => const ParentHistoryScreen()),
          GoRoute(path: '/parent/compare', builder: (context, state) => const ParentComparisonScreen()),
          GoRoute(path: '/parent/tutor-info', builder: (context, state) => const ParentTutorInfoScreen()),
          GoRoute(path: '/parent/notifications', builder: (context, state) => const ParentNotificationsScreen()),
        ],
      ),
    ],
  );
});

String _portalRootForRole(String? role) {
  if (role == AppConstants.roleAdmin) return '/admin/dashboard';
  if (role == AppConstants.roleTutor) return '/tutor/dashboard';
  if (role == AppConstants.roleParent) return '/parent/dashboard';
  return '/login';
}
