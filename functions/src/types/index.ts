import { Timestamp } from "firebase-admin/firestore";

export type UserRole = "ADMIN" | "TUTOR" | "PARENT";
export type AccountStatus = "ACTIVE" | "PENDING" | "DISABLED";
export type StudentStatus = "ACTIVE" | "COMPLETED" | "DISCONTINUED";
export type AcademicYearStatus = "UPCOMING" | "ACTIVE" | "COMPLETED";
export type OpportunityStatus =
  | "PENDING"
  | "LOCKED"
  | "MISSED_DEADLINE"
  | "COMPLETED_AFTER_DEADLINE"
  | "CANCELLED";
export type StudentAttendanceStatus = "PRESENT" | "LATE" | "ABSENT";
export type DeadlineStatus = "WITHIN_DEADLINE" | "MISSED_DEADLINE";

export interface UserProfile {
  uid: string;
  role: UserRole;
  accountStatus: AccountStatus;
  displayName: string;
  email?: string;
  phoneNumber?: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export interface AdminDoc {
  uid: string;
  name: string;
  email: string;
  status: "ACTIVE" | "DISABLED";
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export interface TutorDoc {
  uid: string;
  name: string;
  mobileNumber: string;
  email: string;
  specializedSubjects: string[];
  currentSchool: string;
  currentPosition: string;
  employmentType: string;
  authorizedClassIds: string[];
  status: "ACTIVE" | "INACTIVE";
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export interface ParentDoc {
  uid: string;
  name: string;
  phoneNumber: string;
  email?: string;
  linkedStudentIds: string[];
  accountStatus: "ACTIVE" | "PENDING";
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export interface ClassDoc {
  classId: string;
  name: string;
  displayOrder: number;
  status: "ACTIVE" | "INACTIVE";
  authorizedTutorIds: string[];
  operatingDays: string[]; // e.g. ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY']
  expectedSessionsPerDay: number; // e.g. 1 or 2
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export interface AcademicYearDoc {
  academicYearId: string;
  name: string;
  startDate: Timestamp;
  endDate: Timestamp;
  status: AcademicYearStatus;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export interface EnrollmentDoc {
  enrollmentId: string;
  academicYearId: string;
  classId: string;
  className: string;
  status: StudentStatus;
  startDate: Timestamp;
  endDate?: Timestamp;
}

export interface StudentDoc {
  studentId: string;
  name: string;
  currentClassId: string;
  currentAcademicYearId: string;
  parentIds: string[];
  parentName: string;
  parentMobileNumber: string;
  schoolName: string;
  status: StudentStatus;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export interface ExpectedOpportunityDoc {
  opportunityId: string;
  academicYearId: string;
  classId: string;
  className: string;
  sessionDate: string; // YYYY-MM-DD
  slotNumber: number;
  status: OpportunityStatus;
  attendanceDeadline: Timestamp;
  allowedCompletionDeadline: Timestamp;
  linkedActualSessionId?: string;
  actualSubject?: string;
  tutorUid?: string;
  tutorName?: string;
  missedDeadlineAt?: Timestamp;
  completedAt?: Timestamp;
  cancellationReason?: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export interface AttendanceRecordDoc {
  studentId: string;
  studentName: string;
  status: StudentAttendanceStatus;
  recordedAt: Timestamp;
}

export interface AttendanceSessionDoc {
  sessionId: string;
  uniqueSessionKey: string;
  opportunityId: string;
  academicYearId: string;
  classId: string;
  className: string;
  subject: string;
  tutorUid: string;
  tutorName: string;
  sessionDate: string; // YYYY-MM-DD
  sessionStatus: "LOCKED" | "COMPLETED_AFTER_DEADLINE";
  deadlineStatus: DeadlineStatus;
  attendanceDeadline: Timestamp;
  confirmedAt: Timestamp;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export interface NotificationDoc {
  notificationId: string;
  parentUid: string;
  studentId: string;
  studentName: string;
  attendanceSessionId: string;
  status: StudentAttendanceStatus;
  subject: string;
  tutorName: string;
  tutorPhoneNumber: string;
  message: string;
  createdAt: Timestamp;
  readAt?: Timestamp;
  deletedAt?: Timestamp;
}

export interface AuditLogDoc {
  logId: string;
  action: string;
  performedByUid: string;
  performedByRole: string;
  targetId: string;
  timestamp: Timestamp;
  metadata: Record<string, any>;
}
