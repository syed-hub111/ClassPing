class AppConstants {
  static const String appName = 'ClassPing';
  static const String appTagline = 'Tuition Attendance Management System';

  // User Roles
  static const String roleAdmin = 'ADMIN';
  static const String roleTutor = 'TUTOR';
  static const String roleParent = 'PARENT';

  // Student Attendance Statuses (Exactly 3)
  static const String statusPresent = 'PRESENT';
  static const String statusLate = 'LATE';
  static const String statusAbsent = 'ABSENT';

  // Session Deadline Statuses
  static const String deadlineWithin = 'WITHIN_DEADLINE';
  static const String deadlineMissed = 'MISSED_DEADLINE';

  // Opportunity Statuses
  static const String oppPending = 'PENDING';
  static const String oppLocked = 'LOCKED';
  static const String oppMissedDeadline = 'MISSED_DEADLINE';
  static const String oppCompletedAfterDeadline = 'COMPLETED_AFTER_DEADLINE';
  static const String oppCancelled = 'CANCELLED';

  // Student Enrollment Statuses
  static const String studentActive = 'ACTIVE';
  static const String studentCompleted = 'COMPLETED';
  static const String studentDiscontinued = 'DISCONTINUED';

  // Days of week
  static const List<String> daysOfWeek = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY'
  ];
}
