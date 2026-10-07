import { onCall, CallableRequest } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { handleGetInitialUserProfile, handleLinkParentPhone } from "./services/authService";
import {
  handleAdminGetDashboardStats,
  handleAdminGetStudents,
  handleAdminCreateStudent,
  handleAdminGetTutors,
  handleAdminCreateTutor,
  handleAdminUpdateTutorAuthorization,
  handleAdminGetClasses,
  handleAdminCreateClass,
  handleAdminUpdateClass,
  handleAdminGetAcademicYears,
  handleAdminCreateAcademicYear,
  handleAdminSetActiveAcademicYear,
  handleAdminPromoteStudents,
  handleAdminGetPendingAndMissedOpportunities,
  handleAdminCreateExpectedOpportunity,
  handleAdminCancelExpectedOpportunity,
} from "./services/adminService";
import {
  handleTutorGetAuthorizedClasses,
  handleTutorGetClassStudents,
  handleTutorGetPendingOpportunities,
  handleTutorConfirmAttendance,
} from "./services/attendanceService";
import {
  handleParentGetChildren,
  handleParentGetChildDashboard,
  handleParentGetChildAttendanceHistory,
  handleParentCompareChildrenAttendance,
  handleParentGetTutorInfo,
  handleParentGetNotifications,
  handleParentMarkNotificationRead,
  handleParentDeleteNotification,
} from "./services/parentService";
import {
  runDailyExpectedOpportunitiesGeneration,
  runAttendanceDeadlineCheck,
} from "./services/scheduledService";
import { assertRole } from "./utils/auth";

// ==========================================
// 1. AUTH & PROFILE CALLABLES
// ==========================================
export const getInitialUserProfile = onCall(async (request: CallableRequest) => {
  return handleGetInitialUserProfile(request.auth);
});

export const linkParentPhone = onCall(async (request: CallableRequest) => {
  return handleLinkParentPhone(request.auth);
});

// ==========================================
// 2. ADMIN PORTAL CALLABLES
// ==========================================
export const adminGetDashboardStats = onCall(async (request: CallableRequest) => {
  return handleAdminGetDashboardStats(request.auth);
});

export const adminGetStudents = onCall(async (request: CallableRequest) => {
  return handleAdminGetStudents(request.auth);
});

export const adminCreateStudent = onCall(async (request: CallableRequest) => {
  return handleAdminCreateStudent(request.auth, request.data);
});

export const adminGetTutors = onCall(async (request: CallableRequest) => {
  return handleAdminGetTutors(request.auth);
});

export const adminCreateTutor = onCall(async (request: CallableRequest) => {
  return handleAdminCreateTutor(request.auth, request.data);
});

export const adminUpdateTutorAuthorization = onCall(async (request: CallableRequest) => {
  return handleAdminUpdateTutorAuthorization(request.auth, request.data);
});

export const adminGetClasses = onCall(async (request: CallableRequest) => {
  return handleAdminGetClasses(request.auth);
});

export const adminCreateClass = onCall(async (request: CallableRequest) => {
  return handleAdminCreateClass(request.auth, request.data);
});

export const adminUpdateClass = onCall(async (request: CallableRequest) => {
  return handleAdminUpdateClass(request.auth, request.data);
});

export const adminGetAcademicYears = onCall(async (request: CallableRequest) => {
  return handleAdminGetAcademicYears(request.auth);
});

export const adminCreateAcademicYear = onCall(async (request: CallableRequest) => {
  return handleAdminCreateAcademicYear(request.auth, request.data);
});

export const adminSetActiveAcademicYear = onCall(async (request: CallableRequest) => {
  return handleAdminSetActiveAcademicYear(request.auth, request.data);
});

export const adminPromoteStudents = onCall(async (request: CallableRequest) => {
  return handleAdminPromoteStudents(request.auth, request.data);
});

export const adminGetPendingAndMissedOpportunities = onCall(async (request: CallableRequest) => {
  return handleAdminGetPendingAndMissedOpportunities(request.auth);
});

export const adminCreateExpectedOpportunity = onCall(async (request: CallableRequest) => {
  return handleAdminCreateExpectedOpportunity(request.auth, request.data);
});

export const adminCancelExpectedOpportunity = onCall(async (request: CallableRequest) => {
  return handleAdminCancelExpectedOpportunity(request.auth, request.data);
});

// ==========================================
// 3. TUTOR PORTAL CALLABLES
// ==========================================
export const tutorGetAuthorizedClasses = onCall(async (request: CallableRequest) => {
  return handleTutorGetAuthorizedClasses(request.auth);
});

export const tutorGetClassStudents = onCall(async (request: CallableRequest) => {
  return handleTutorGetClassStudents(request.auth, request.data);
});

export const tutorGetPendingOpportunities = onCall(async (request: CallableRequest) => {
  return handleTutorGetPendingOpportunities(request.auth, request.data);
});

export const tutorConfirmAttendance = onCall(async (request: CallableRequest) => {
  return handleTutorConfirmAttendance(request.auth, request.data);
});

// ==========================================
// 4. PARENT PORTAL CALLABLES
// ==========================================
export const parentGetChildren = onCall(async (request: CallableRequest) => {
  return handleParentGetChildren(request.auth);
});

export const parentGetChildDashboard = onCall(async (request: CallableRequest) => {
  return handleParentGetChildDashboard(request.auth, request.data);
});

export const parentGetChildAttendanceHistory = onCall(async (request: CallableRequest) => {
  return handleParentGetChildAttendanceHistory(request.auth, request.data);
});

export const parentCompareChildrenAttendance = onCall(async (request: CallableRequest) => {
  return handleParentCompareChildrenAttendance(request.auth, request.data);
});

export const parentGetTutorInfo = onCall(async (request: CallableRequest) => {
  return handleParentGetTutorInfo(request.auth, request.data);
});

export const parentGetNotifications = onCall(async (request: CallableRequest) => {
  return handleParentGetNotifications(request.auth);
});

export const parentMarkNotificationRead = onCall(async (request: CallableRequest) => {
  return handleParentMarkNotificationRead(request.auth, request.data);
});

export const parentDeleteNotification = onCall(async (request: CallableRequest) => {
  return handleParentDeleteNotification(request.auth, request.data);
});

// ==========================================
// 5. SCHEDULED JOBS
// ==========================================
export const generateDailyExpectedOpportunities = onSchedule("1 0 * * *", async () => {
  await runDailyExpectedOpportunitiesGeneration();
});

export const checkAttendanceDeadlines = onSchedule("5 0 * * *", async () => {
  await runAttendanceDeadlineCheck();
});

// Admin-callable trigger for testing & verification
export const adminTriggerScheduledJobs = onCall(async (request: CallableRequest) => {
  await assertRole(request.auth, ["ADMIN"]);
  const genResult = await runDailyExpectedOpportunitiesGeneration();
  const checkResult = await runAttendanceDeadlineCheck();
  return { success: true, generation: genResult, deadlineCheck: checkResult };
});
