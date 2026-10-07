class AttendanceHistoryItem {
  final String sessionId;
  final String sessionDate;
  final String subject;
  final String status; // PRESENT | LATE | ABSENT
  final String tutorName;
  final String className;
  final String academicYearId;
  final String deadlineStatus; // WITHIN_DEADLINE | MISSED_DEADLINE
  final String sessionStatus;

  const AttendanceHistoryItem({
    required this.sessionId,
    required this.sessionDate,
    required this.subject,
    required this.status,
    required this.tutorName,
    required this.className,
    required this.academicYearId,
    required this.deadlineStatus,
    required this.sessionStatus,
  });

  factory AttendanceHistoryItem.fromJson(Map<String, dynamic> json) {
    return AttendanceHistoryItem(
      sessionId: json['sessionId'] as String? ?? '',
      sessionDate: json['sessionDate'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      status: json['status'] as String? ?? 'PRESENT',
      tutorName: json['tutorName'] as String? ?? '',
      className: json['className'] as String? ?? '',
      academicYearId: json['academicYearId'] as String? ?? '',
      deadlineStatus: json['deadlineStatus'] as String? ?? 'WITHIN_DEADLINE',
      sessionStatus: json['sessionStatus'] as String? ?? 'LOCKED',
    );
  }
}
