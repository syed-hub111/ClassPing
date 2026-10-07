class TutorInfo {
  final String name;
  final String mobileNumber;
  final List<String> specializedSubjects;
  final String currentSchool;
  final String currentPosition;

  const TutorInfo({
    required this.name,
    required this.mobileNumber,
    required this.specializedSubjects,
    required this.currentSchool,
    required this.currentPosition,
  });

  factory TutorInfo.fromJson(Map<String, dynamic> json) {
    return TutorInfo(
      name: json['name'] as String? ?? '',
      mobileNumber: json['mobileNumber'] as String? ?? '',
      specializedSubjects: (json['specializedSubjects'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      currentSchool: json['currentSchool'] as String? ?? '',
      currentPosition: json['currentPosition'] as String? ?? '',
    );
  }
}
