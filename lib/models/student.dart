class Student {
  final String studentId;
  final String name;
  final String currentClassId;
  final String currentAcademicYearId;
  final String parentName;
  final String parentMobileNumber;
  final String schoolName;
  final String status;
  final List<String> parentIds;

  const Student({
    required this.studentId,
    required this.name,
    required this.currentClassId,
    required this.currentAcademicYearId,
    required this.parentName,
    required this.parentMobileNumber,
    required this.schoolName,
    required this.status,
    this.parentIds = const [],
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      studentId: json['studentId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      currentClassId: json['currentClassId'] as String? ?? '',
      currentAcademicYearId: json['currentAcademicYearId'] as String? ?? '',
      parentName: json['parentName'] as String? ?? '',
      parentMobileNumber: json['parentMobileNumber'] as String? ?? '',
      schoolName: json['schoolName'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      parentIds: (json['parentIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'name': name,
        'currentClassId': currentClassId,
        'currentAcademicYearId': currentAcademicYearId,
        'parentName': parentName,
        'parentMobileNumber': parentMobileNumber,
        'schoolName': schoolName,
        'status': status,
        'parentIds': parentIds,
      };
}
