import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  task('Tâche', 'task'),
  reward('Récompense', 'reward'),
  sanction('Sanction', 'sanction'),
  starLoss('Perte d\'étoiles', 'star_loss'),
  system('Système', 'system'),
  family('Famille', 'family');

  const NotificationType(this.displayName, this.codeName);
  final String displayName;
  final String codeName;
}

class AppNotification {
  final String id;
  final String userId; // ID de l'utilisateur qui reçoit la notification
  final String? familyId; // ID de la famille (optionnel)
  final String? relatedUserId; // ID de l'utilisateur lié à la notification (ex: enfant qui a complété une tâche)
  final NotificationType type;
  final String title;
  final String? description;
  final Map<String, dynamic>? data; // Données supplémentaires liées à la notification
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  AppNotification({
    required this.id,
    required this.userId,
    this.familyId,
    this.relatedUserId,
    required this.type,
    required this.title,
    this.description,
    this.data,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      userId: map['userId'] as String,
      familyId: map['familyId'] as String?,
      relatedUserId: map['relatedUserId'] as String?,
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.system,
      ),
      title: map['title'] as String,
      description: map['description'] as String?,
      data: map['data'] as Map<String, dynamic>?,
      isRead: map['isRead'] as bool? ?? false,
      createdAt: map['createdAt'] is String
          ? DateTime.parse(map['createdAt'] as String)
          : (map['createdAt'] as Timestamp).toDate(),
      readAt: map['readAt'] != null
          ? map['readAt'] is String
              ? DateTime.parse(map['readAt'] as String)
              : (map['readAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'familyId': familyId,
      'relatedUserId': relatedUserId,
      'type': type.name,
      'title': title,
      'description': description,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? familyId,
    String? relatedUserId,
    NotificationType? type,
    String? title,
    String? description,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      familyId: familyId ?? this.familyId,
      relatedUserId: relatedUserId ?? this.relatedUserId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  // Méthode pour marquer comme lu
  AppNotification markAsRead() {
    return copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );
  }

  // Méthode pour obtenir l'icône en fonction du type
  String get icon {
    switch (type) {
      case NotificationType.task:
        return '✅';
      case NotificationType.reward:
        return '🎁';
      case NotificationType.sanction:
        return '⚠️';
      case NotificationType.starLoss:
        return '💔';
      case NotificationType.system:
        return '🔔';
      case NotificationType.family:
        return '👨‍👩‍👧‍👦';
    }
  }

  // Méthode pour obtenir la couleur en fonction du type
  String get colorType {
    switch (type) {
      case NotificationType.task:
        return 'green';
      case NotificationType.reward:
        return 'blue';
      case NotificationType.sanction:
        return 'red';
      case NotificationType.starLoss:
        return 'orange';
      case NotificationType.system:
        return 'purple';
      case NotificationType.family:
        return 'teal';
    }
  }

  // Méthode pour formater la date
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return "À l'instant";
        }
        return "Il y a ${difference.inMinutes} min";
      }
      return "Il y a ${difference.inHours}h";
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  // Factory pour créer une notification de tâche
  factory AppNotification.taskCompleted({
    required String id,
    required String userId,
    required String familyId,
    required String relatedUserId,
    required String taskTitle,
    required int stars,
  }) {
    return AppNotification(
      id: id,
      userId: userId,
      familyId: familyId,
      relatedUserId: relatedUserId,
      type: NotificationType.task,
      title: 'Tâche complétée',
      description: '$taskTitle a été complétée (+$stars ⭐)',
      data: {
        'taskTitle': taskTitle,
        'stars': stars,
      },
      createdAt: DateTime.now(),
    );
  }

  // Factory pour créer une notification de récompense
  factory AppNotification.rewardExchanged({
    required String id,
    required String userId,
    required String familyId,
    required String relatedUserId,
    required String rewardName,
    required int starsCost,
  }) {
    return AppNotification(
      id: id,
      userId: userId,
      familyId: familyId,
      relatedUserId: relatedUserId,
      type: NotificationType.reward,
      title: 'Récompense échangée',
      description: '$rewardName a été échangée (-$starsCost ⭐)',
      data: {
        'rewardName': rewardName,
        'starsCost': starsCost,
      },
      createdAt: DateTime.now(),
    );
  }

  // Factory pour créer une notification de sanction
  factory AppNotification.sanctionApplied({
    required String id,
    required String userId,
    required String familyId,
    required String relatedUserId,
    required String sanctionName,
  }) {
    return AppNotification(
      id: id,
      userId: userId,
      familyId: familyId,
      relatedUserId: relatedUserId,
      type: NotificationType.sanction,
      title: 'Sanction appliquée',
      description: '$sanctionName a été appliquée',
      data: {
        'sanctionName': sanctionName,
      },
      createdAt: DateTime.now(),
    );
  }

  // Factory pour créer une notification de perte d'étoiles
  factory AppNotification.starsLost({
    required String id,
    required String userId,
    required String familyId,
    required String relatedUserId,
    required String reason,
    required int starsLost,
  }) {
    return AppNotification(
      id: id,
      userId: userId,
      familyId: familyId,
      relatedUserId: relatedUserId,
      type: NotificationType.starLoss,
      title: 'Perte d\'étoiles',
      description: '$reason (-$starsLost ⭐)',
      data: {
        'reason': reason,
        'starsLost': starsLost,
      },
      createdAt: DateTime.now(),
    );
  }

  // Factory pour créer une notification système
  factory AppNotification.system({
    required String id,
    required String userId,
    required String title,
    String? description,
    String? familyId,
  }) {
    return AppNotification(
      id: id,
      userId: userId,
      familyId: familyId,
      type: NotificationType.system,
      title: title,
      description: description,
      createdAt: DateTime.now(),
    );
  }

  // Factory pour créer une notification familiale
  factory AppNotification.family({
    required String id,
    required String userId,
    required String familyId,
    required String title,
    String? description,
    String? relatedUserId,
  }) {
    return AppNotification(
      id: id,
      userId: userId,
      familyId: familyId,
      relatedUserId: relatedUserId,
      type: NotificationType.family,
      title: title,
      description: description,
      createdAt: DateTime.now(),
    );
  }
}