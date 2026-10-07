class AcademicYear {
  final String academicYearId;
  final String name;
  final String status; // UPCOMING | ACTIVE | COMPLETED
  final dynamic startDate;
  final dynamic endDate;

  const AcademicYear({
    required this.academicYearId,
    required this.name,
    required this.status,
    this.startDate,
    this.endDate,
  });

  bool get isActive => status == 'ACTIVE';

  factory AcademicYear.fromJson(Map<String, dynamic> json) {
    return AcademicYear(
      academicYearId: json['academicYearId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      startDate: json['startDate'],
      endDate: json['endDate'],
    );
  }

  Map<String, dynamic> toJson() => {
        'academicYearId': academicYearId,
        'name': name,
        'status': status,
        'startDate': startDate,
        'endDate': endDate,
      };
}
