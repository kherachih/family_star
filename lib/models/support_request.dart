import 'package:cloud_firestore/cloud_firestore.dart';

enum SupportRequestType {
  suggestion,
  help,
  problem,
}

class SupportRequest {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final SupportRequestType type;
  final String subject;
  final String message;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isResolved;
  final String? adminResponse;

  SupportRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.type,
    required this.subject,
    required this.message,
    required this.createdAt,
    this.updatedAt,
    this.isResolved = false,
    this.adminResponse,
  });

  factory SupportRequest.fromMap(Map<String, dynamic> map) {
    return SupportRequest(
      id: map['id'] as String,
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      userEmail: map['userEmail'] as String,
      type: SupportRequestType.values.firstWhere(
        (e) => e.toString() == 'SupportRequestType.${map['type']}',
        orElse: () => SupportRequestType.suggestion,
      ),
      subject: map['subject'] as String,
      message: map['message'] as String,
      createdAt: map['createdAt'] is String
          ? DateTime.parse(map['createdAt'] as String)
          : (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? map['updatedAt'] is String
              ? DateTime.parse(map['updatedAt'] as String)
              : (map['updatedAt'] as Timestamp).toDate()
          : null,
      isResolved: map['isResolved'] as bool? ?? false,
      adminResponse: map['adminResponse'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'type': type.toString().split('.').last,
      'subject': subject,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isResolved': isResolved,
      'adminResponse': adminResponse,
    };
  }

  SupportRequest copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    SupportRequestType? type,
    String? subject,
    String? message,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isResolved,
    String? adminResponse,
  }) {
    return SupportRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      type: type ?? this.type,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isResolved: isResolved ?? this.isResolved,
      adminResponse: adminResponse ?? this.adminResponse,
    );
  }

  String get typeDisplayName {
    switch (type) {
      case SupportRequestType.suggestion:
        return 'Suggestion';
      case SupportRequestType.help:
        return 'Aide';
      case SupportRequestType.problem:
        return 'Signalement de problème';
    }
  }
}