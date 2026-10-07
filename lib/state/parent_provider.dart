import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/parent_dashboard_data.dart';
import '../models/attendance_history_item.dart';
import '../models/student_comparison_result.dart';
import '../models/tutor_info.dart';
import '../models/parent_notification.dart';
import 'api_provider.dart';

final parentChildrenProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final children = await api.parentGetChildren();

  // If no child is selected yet, select the first child automatically
  if (children.isNotEmpty) {
    final currentSelected = ref.read(parentSelectedChildIdProvider);
    if (currentSelected == null) {
      ref.read(parentSelectedChildIdProvider.notifier).select(children.first['studentId'] as String?);
    }
  }
  return children;
});

class SelectedChildNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}

final parentSelectedChildIdProvider =
    NotifierProvider.autoDispose<SelectedChildNotifier, String?>(SelectedChildNotifier.new);

final parentDashboardDataProvider = FutureProvider.autoDispose<ParentDashboardData?>((ref) async {
  final studentId = ref.watch(parentSelectedChildIdProvider);
  if (studentId == null) return null;
  final api = ref.watch(apiServiceProvider);
  return api.parentGetChildDashboard(studentId);
});

final parentHistoryProvider = FutureProvider.autoDispose<List<AttendanceHistoryItem>>((ref) async {
  final studentId = ref.watch(parentSelectedChildIdProvider);
  if (studentId == null) return [];
  final api = ref.watch(apiServiceProvider);
  return api.parentGetChildAttendanceHistory(studentId);
});

final parentTutorInfoProvider = FutureProvider.autoDispose<List<TutorInfo>>((ref) async {
  final studentId = ref.watch(parentSelectedChildIdProvider);
  if (studentId == null) return [];
  final api = ref.watch(apiServiceProvider);
  return api.parentGetTutorInfo(studentId);
});

final parentComparisonProvider =
    FutureProvider.autoDispose.family<List<StudentComparisonResult>, List<String>>((ref, studentIds) async {
  if (studentIds.length < 2) return [];
  final api = ref.watch(apiServiceProvider);
  return api.parentCompareChildrenAttendance(studentIds);
});

class ParentNotificationsNotifier extends AsyncNotifier<List<ParentNotification>> {
  @override
  Future<List<ParentNotification>> build() async {
    final api = ref.watch(apiServiceProvider);
    return api.parentGetNotifications();
  }

  Future<void> loadNotifications() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.parentMarkNotificationRead(notificationId);
      ref.invalidateSelf();
    } catch (_) {}
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.parentDeleteNotification(notificationId);
      ref.invalidateSelf();
    } catch (_) {}
  }
}

final parentNotificationsProvider =
    AsyncNotifierProvider.autoDispose<ParentNotificationsNotifier, List<ParentNotification>>(
  ParentNotificationsNotifier.new,
);
