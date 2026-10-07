class ApiEndpoints {
  // Auth
  static const String getInitialUserProfile = 'getInitialUserProfile';
  static const String linkParentPhone = 'linkParentPhone';

  // Admin
  static const String adminGetDashboardStats = 'adminGetDashboardStats';
  static const String adminGetStudents = 'adminGetStudents';
  static const String adminCreateStudent = 'adminCreateStudent';
  static const String adminGetTutors = 'adminGetTutors';
  static const String adminCreateTutor = 'adminCreateTutor';
  static const String adminUpdateTutorAuthorization = 'adminUpdateTutorAuthorization';
  static const String adminGetClasses = 'adminGetClasses';
  static const String adminCreateClass = 'adminCreateClass';
  static const String adminUpdateClass = 'adminUpdateClass';
  static const String adminGetAcademicYears = 'adminGetAcademicYears';
  static const String adminCreateAcademicYear = 'adminCreateAcademicYear';
  static const String adminSetActiveAcademicYear = 'adminSetActiveAcademicYear';
  static const String adminPromoteStudents = 'adminPromoteStudents';
  static const String adminGetPendingAndMissedOpportunities = 'adminGetPendingAndMissedOpportunities';
  static const String adminCreateExpectedOpportunity = 'adminCreateExpectedOpportunity';
  static const String adminCancelExpectedOpportunity = 'adminCancelExpectedOpportunity';
  static const String adminTriggerScheduledJobs = 'adminTriggerScheduledJobs';

  // Tutor
  static const String tutorGetAuthorizedClasses = 'tutorGetAuthorizedClasses';
  static const String tutorGetClassStudents = 'tutorGetClassStudents';
  static const String tutorGetPendingOpportunities = 'tutorGetPendingOpportunities';
  static const String tutorConfirmAttendance = 'tutorConfirmAttendance';

  // Parent
  static const String parentGetChildren = 'parentGetChildren';
  static const String parentGetChildDashboard = 'parentGetChildDashboard';
  static const String parentGetChildAttendanceHistory = 'parentGetChildAttendanceHistory';
  static const String parentCompareChildrenAttendance = 'parentCompareChildrenAttendance';
  static const String parentGetTutorInfo = 'parentGetTutorInfo';
  static const String parentGetNotifications = 'parentGetNotifications';
  static const String parentMarkNotificationRead = 'parentMarkNotificationRead';
  static const String parentDeleteNotification = 'parentDeleteNotification';
}
