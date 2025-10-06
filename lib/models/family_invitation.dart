import 'package:cloud_firestore/cloud_firestore.dart';

enum InvitationStatus {
  pending('En attente', 'pending'),
  accepted('Acceptée', 'accepted'),
  rejected('Refusée', 'rejected'),
  expired('Expirée', 'expired');

  const InvitationStatus(this.displayName, this.codeName);
  final String displayName;
  final String codeName;
}

class FamilyInvitation {
  final String id;
  final String familyId;
  final String familyName;
  final String invitedUserId;
  final String invitedUserEmail;
  final String invitedUserName;
  final String invitedByUserId;
  final String invitedByUserName;
  final InvitationStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final DateTime? expiresAt;

  FamilyInvitation({
    required this.id,
    required this.familyId,
    required this.familyName,
    required this.invitedUserId,
    required this.invitedUserEmail,
    required this.invitedUserName,
    required this.invitedByUserId,
    required this.invitedByUserName,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.expiresAt,
  });

  factory FamilyInvitation.fromMap(Map<String, dynamic> map) {
    return FamilyInvitation(
      id: map['id'] as String,
      familyId: map['familyId'] as String,
      familyName: map['familyName'] as String,
      invitedUserId: map['invitedUserId'] as String,
      invitedUserEmail: map['invitedUserEmail'] as String,
      invitedUserName: map['invitedUserName'] as String,
      invitedByUserId: map['invitedByUserId'] as String,
      invitedByUserName: map['invitedByUserName'] as String,
      status: InvitationStatus.values.firstWhere(
        (e) => e.codeName == map['status'],
        orElse: () => InvitationStatus.pending,
      ),
      createdAt: map['createdAt'] is String
          ? DateTime.parse(map['createdAt'] as String)
          : (map['createdAt'] as Timestamp).toDate(),
      respondedAt: map['respondedAt'] != null
          ? map['respondedAt'] is String
              ? DateTime.parse(map['respondedAt'] as String)
              : (map['respondedAt'] as Timestamp).toDate()
          : null,
      expiresAt: map['expiresAt'] != null
          ? map['expiresAt'] is String
              ? DateTime.parse(map['expiresAt'] as String)
              : (map['expiresAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'familyId': familyId,
      'familyName': familyName,
      'invitedUserId': invitedUserId,
      'invitedUserEmail': invitedUserEmail,
      'invitedUserName': invitedUserName,
      'invitedByUserId': invitedByUserId,
      'invitedByUserName': invitedByUserName,
      'status': status.codeName,
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  FamilyInvitation copyWith({
    String? id,
    String? familyId,
    String? familyName,
    String? invitedUserId,
    String? invitedUserEmail,
    String? invitedUserName,
    String? invitedByUserId,
    String? invitedByUserName,
    InvitationStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    DateTime? expiresAt,
  }) {
    return FamilyInvitation(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      familyName: familyName ?? this.familyName,
      invitedUserId: invitedUserId ?? this.invitedUserId,
      invitedUserEmail: invitedUserEmail ?? this.invitedUserEmail,
      invitedUserName: invitedUserName ?? this.invitedUserName,
      invitedByUserId: invitedByUserId ?? this.invitedByUserId,
      invitedByUserName: invitedByUserName ?? this.invitedByUserName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  // Vérifier si l'invitation est expirée
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  // Vérifier si l'invitation est toujours active
  bool get isActive {
    return status == InvitationStatus.pending && !isExpired;
  }

  // Accepter l'invitation
  FamilyInvitation accept() {
    return copyWith(
      status: InvitationStatus.accepted,
      respondedAt: DateTime.now(),
    );
  }

  // Refuser l'invitation
  FamilyInvitation reject() {
    return copyWith(
      status: InvitationStatus.rejected,
      respondedAt: DateTime.now(),
    );
  }

  // Marquer comme expirée
  FamilyInvitation expire() {
    return copyWith(
      status: InvitationStatus.expired,
    );
  }

  // Factory pour créer une nouvelle invitation
  factory FamilyInvitation.create({
    required String familyId,
    required String familyName,
    required String invitedUserId,
    required String invitedUserEmail,
    required String invitedUserName,
    required String invitedByUserId,
    required String invitedByUserName,
    Duration expiryDuration = const Duration(days: 7),
  }) {
    final now = DateTime.now();
    return FamilyInvitation(
      id: '${now.millisecondsSinceEpoch}_${invitedUserId}',
      familyId: familyId,
      familyName: familyName,
      invitedUserId: invitedUserId,
      invitedUserEmail: invitedUserEmail,
      invitedUserName: invitedUserName,
      invitedByUserId: invitedByUserId,
      invitedByUserName: invitedByUserName,
      status: InvitationStatus.pending,
      createdAt: now,
      expiresAt: now.add(expiryDuration),
    );
  }

  // Formater la date d'expiration
  String get formattedExpiryDate {
    if (expiresAt == null) return 'Sans expiration';
    
    final now = DateTime.now();
    final difference = expiresAt!.difference(now);
    
    if (difference.inDays > 0) {
      return 'Expire dans ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Expire dans ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Expire dans ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'Expirée';
    }
  }
}