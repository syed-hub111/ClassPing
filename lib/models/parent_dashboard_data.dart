class ParentDashboardData {
  final String studentId;
  final String studentName;
  final String classId;
  final String className;
  final String academicYearId;
  final String schoolName;
  final double attendancePercentage;
  final int presentCount;
  final int lateCount;
  final int absentCount;
  final int totalEligibleSessions;

  const ParentDashboardData({
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.className,
    required this.academicYearId,
    required this.schoolName,
    required this.attendancePercentage,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
    required this.totalEligibleSessions,
  });

  factory ParentDashboardData.fromJson(Map<String, dynamic> json) {
    return ParentDashboardData(
      studentId: json['studentId'] as String? ?? '',
      studentName: json['studentName'] as String? ?? '',
      classId: json['classId'] as String? ?? '',
      className: json['className'] as String? ?? '',
      academicYearId: json['academicYearId'] as String? ?? '',
      schoolName: json['schoolName'] as String? ?? '',
      attendancePercentage: (json['attendancePercentage'] as num?)?.toDouble() ?? 0.0,
      presentCount: (json['presentCount'] as num?)?.toInt() ?? 0,
      lateCount: (json['lateCount'] as num?)?.toInt() ?? 0,
      absentCount: (json['absentCount'] as num?)?.toInt() ?? 0,
      totalEligibleSessions: (json['totalEligibleSessions'] as num?)?.toInt() ?? 0,
    );
  }
}
