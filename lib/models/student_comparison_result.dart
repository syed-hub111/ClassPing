class StudentComparisonResult {
  final String studentId;
  final String name;
  final String className;
  final double attendancePercentage;
  final int presentCount;
  final int lateCount;
  final int absentCount;
  final int totalSessions;

  const StudentComparisonResult({
    required this.studentId,
    required this.name,
    required this.className,
    required this.attendancePercentage,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
    required this.totalSessions,
  });

  factory StudentComparisonResult.fromJson(Map<String, dynamic> json) {
    return StudentComparisonResult(
      studentId: json['studentId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      className: json['className'] as String? ?? '',
      attendancePercentage: (json['attendancePercentage'] as num?)?.toDouble() ?? 0.0,
      presentCount: (json['presentCount'] as num?)?.toInt() ?? 0,
      lateCount: (json['lateCount'] as num?)?.toInt() ?? 0,
      absentCount: (json['absentCount'] as num?)?.toInt() ?? 0,
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
    );
  }
}
