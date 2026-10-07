class UserProfile {
  final String uid;
  final String role; // ADMIN | TUTOR | PARENT
  final String accountStatus; // ACTIVE | PENDING | DISABLED
  final String displayName;
  final String? email;
  final String? phoneNumber;

  const UserProfile({
    required this.uid,
    required this.role,
    required this.accountStatus,
    required this.displayName,
    this.email,
    this.phoneNumber,
  });

  bool get isAdmin => role == 'ADMIN';
  bool get isTutor => role == 'TUTOR';
  bool get isParent => role == 'PARENT';
  bool get isActive => accountStatus == 'ACTIVE';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String? ?? '',
      role: json['role'] as String? ?? 'PARENT',
      accountStatus: json['accountStatus'] as String? ?? 'ACTIVE',
      displayName: json['displayName'] as String? ?? '',
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'role': role,
        'accountStatus': accountStatus,
        'displayName': displayName,
        'email': email,
        'phoneNumber': phoneNumber,
      };
}
