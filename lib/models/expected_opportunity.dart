class ExpectedOpportunity {
  final String opportunityId;
  final String academicYearId;
  final String classId;
  final String className;
  final String sessionDate;
  final int slotNumber;
  final String status;
  final dynamic attendanceDeadline;
  final dynamic allowedCompletionDeadline;
  final String? actualSubject;
  final String? tutorName;

  const ExpectedOpportunity({
    required this.opportunityId,
    required this.academicYearId,
    required this.classId,
    required this.className,
    required this.sessionDate,
    required this.slotNumber,
    required this.status,
    this.attendanceDeadline,
    this.allowedCompletionDeadline,
    this.actualSubject,
    this.tutorName,
  });

  bool get isPending => status == 'PENDING';
  bool get isMissedDeadline => status == 'MISSED_DEADLINE';
  bool get isLocked => status == 'LOCKED' || status == 'COMPLETED_AFTER_DEADLINE';

  factory ExpectedOpportunity.fromJson(Map<String, dynamic> json) {
    return ExpectedOpportunity(
      opportunityId: json['opportunityId'] as String? ?? '',
      academicYearId: json['academicYearId'] as String? ?? '',
      classId: json['classId'] as String? ?? '',
      className: json['className'] as String? ?? '',
      sessionDate: json['sessionDate'] as String? ?? '',
      slotNumber: (json['slotNumber'] as num?)?.toInt() ?? 1,
      status: json['status'] as String? ?? 'PENDING',
      attendanceDeadline: json['attendanceDeadline'],
      allowedCompletionDeadline: json['allowedCompletionDeadline'],
      actualSubject: json['actualSubject'] as String?,
      tutorName: json['tutorName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'opportunityId': opportunityId,
        'academicYearId': academicYearId,
        'classId': classId,
        'className': className,
        'sessionDate': sessionDate,
        'slotNumber': slotNumber,
        'status': status,
        'attendanceDeadline': attendanceDeadline,
        'allowedCompletionDeadline': allowedCompletionDeadline,
        'actualSubject': actualSubject,
        'tutorName': tutorName,
      };
}
