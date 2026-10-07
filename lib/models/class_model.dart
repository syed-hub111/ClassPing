class ClassModel {
  final String classId;
  final String name;
  final int displayOrder;
  final String status;
  final List<String> authorizedTutorIds;
  final List<String> operatingDays;
  final int expectedSessionsPerDay;

  const ClassModel({
    required this.classId,
    required this.name,
    required this.displayOrder,
    required this.status,
    required this.authorizedTutorIds,
    required this.operatingDays,
    required this.expectedSessionsPerDay,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      classId: json['classId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 1,
      status: json['status'] as String? ?? 'ACTIVE',
      authorizedTutorIds: (json['authorizedTutorIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      operatingDays: (json['operatingDays'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY'],
      expectedSessionsPerDay: (json['expectedSessionsPerDay'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'classId': classId,
        'name': name,
        'displayOrder': displayOrder,
        'status': status,
        'authorizedTutorIds': authorizedTutorIds,
        'operatingDays': operatingDays,
        'expectedSessionsPerDay': expectedSessionsPerDay,
      };
}
