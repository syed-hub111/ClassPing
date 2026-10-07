class ParentNotification {
  final String notificationId;
  final String studentId;
  final String studentName;
  final String status;
  final String subject;
  final String tutorName;
  final String tutorPhoneNumber;
  final String message;
  final dynamic createdAt;
  final dynamic readAt;

  const ParentNotification({
    required this.notificationId,
    required this.studentId,
    required this.studentName,
    required this.status,
    required this.subject,
    required this.tutorName,
    required this.tutorPhoneNumber,
    required this.message,
    this.createdAt,
    this.readAt,
  });

  bool get isRead => readAt != null;

  factory ParentNotification.fromJson(Map<String, dynamic> json) {
    return ParentNotification(
      notificationId: json['notificationId'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      studentName: json['studentName'] as String? ?? '',
      status: json['status'] as String? ?? 'PRESENT',
      subject: json['subject'] as String? ?? '',
      tutorName: json['tutorName'] as String? ?? '',
      tutorPhoneNumber: json['tutorPhoneNumber'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: json['createdAt'],
      readAt: json['readAt'],
    );
  }
}
