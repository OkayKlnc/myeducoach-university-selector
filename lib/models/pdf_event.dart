class PdfEvent {
  final String id;
  final String userId;
  final String userFullName;
  final String userEmail;
  final String studentName;
  final List<String> universities;
  final DateTime createdAt;

  const PdfEvent({
    required this.id,
    required this.userId,
    required this.userFullName,
    required this.userEmail,
    required this.studentName,
    required this.universities,
    required this.createdAt,
  });

  factory PdfEvent.fromMap(String id, Map<String, dynamic> map) {
    return PdfEvent(
      id: id,
      userId: map['userId'] as String,
      userFullName: map['userFullName'] as String,
      userEmail: map['userEmail'] as String,
      studentName: (map['studentName'] as String?) ?? '',
      universities: List<String>.from(map['universities'] as List? ?? []),
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'userFullName': userFullName,
    'userEmail': userEmail,
    'studentName': studentName,
    'universities': universities,
    'createdAt': createdAt,
  };
}
