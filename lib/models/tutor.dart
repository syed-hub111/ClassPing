class Tutor {
  final String uid;
  final String name;
  final String mobileNumber;
  final String email;
  final List<String> specializedSubjects;
  final String currentSchool;
  final String currentPosition;
  final String employmentType;
  final List<String> authorizedClassIds;
  final String status;

  const Tutor({
    required this.uid,
    required this.name,
    required this.mobileNumber,
    required this.email,
    required this.specializedSubjects,
    required this.currentSchool,
    required this.currentPosition,
    required this.employmentType,
    required this.authorizedClassIds,
    required this.status,
  });

  factory Tutor.fromJson(Map<String, dynamic> json) {
    return Tutor(
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      mobileNumber: json['mobileNumber'] as String? ?? '',
      email: json['email'] as String? ?? '',
      specializedSubjects: (json['specializedSubjects'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      currentSchool: json['currentSchool'] as String? ?? '',
      currentPosition: json['currentPosition'] as String? ?? '',
      employmentType: json['employmentType'] as String? ?? '',
      authorizedClassIds: (json['authorizedClassIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'mobileNumber': mobileNumber,
        'email': email,
        'specializedSubjects': specializedSubjects,
        'currentSchool': currentSchool,
        'currentPosition': currentPosition,
        'employmentType': employmentType,
        'authorizedClassIds': authorizedClassIds,
        'status': status,
      };
}
