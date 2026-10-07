import { Timestamp } from "firebase-admin/firestore";

/**
 * Normalizes a subject name for uniqueness comparison
 */
export function normalizeSubject(subject: string): string {
  return subject.trim().toLowerCase().replace(/\s+/g, "_");
}

/**
 * Normalizes a phone number to standard format
 * e.g., "+919876543210" or "9876543210" -> standard digits
 */
export function normalizePhoneNumber(phone: string): string {
  let cleaned = phone.replace(/[^\d+]/g, "");
  if (cleaned.startsWith("+")) {
    return cleaned;
  }
  // Default to +91 if 10 digits
  if (cleaned.length === 10) {
    return `+91${cleaned}`;
  }
  return `+${cleaned}`;
}

/**
 * Formats a Date object as YYYY-MM-DD
 */
export function formatDateKey(d: Date): string {
  const year = d.getFullYear();
  const month = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

/**
 * Computes attendance deadline:
 * "End of the following day at 23:59:59"
 * e.g. sessionDate: 2026-09-16 -> deadline: 2026-09-17 23:59:59
 */
export function computeAttendanceDeadline(sessionDateStr: string): Timestamp {
  const [year, month, day] = sessionDateStr.split("-").map(Number);
  // Date constructor months are 0-indexed
  const deadlineDate = new Date(Date.UTC(year, month - 1, day + 1, 23, 59, 59, 999));
  return Timestamp.fromDate(deadlineDate);
}

/**
 * Computes deterministic allowed late completion deadline:
 * "sessionDate + 7 calendar days at 23:59:59"
 * e.g. sessionDate: 2026-09-16 -> allowed completion: 2026-09-23 23:59:59
 */
export function computeAllowedCompletionDeadline(sessionDateStr: string): Timestamp {
  const [year, month, day] = sessionDateStr.split("-").map(Number);
  const allowedDate = new Date(Date.UTC(year, month - 1, day + 7, 23, 59, 59, 999));
  return Timestamp.fromDate(allowedDate);
}

/**
 * Maps day of week integer (0=Sunday, 1=Monday, ... 6=Saturday) to standard day name string
 */
export function getDayName(d: Date): string {
  const days = ["SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY"];
  return days[d.getDay()];
}
