import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/notification.dart' as model;
import '../models/family_invitation.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _notificationsCollection = 'notifications';
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Créer une notification
  Future<void> createNotification(model.AppNotification notification) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(notification.id)
          .set(notification.toMap());
      debugPrint('Notification créée: ${notification.id}');
    } catch (e) {
      debugPrint('Erreur lors de la création de la notification: $e');
      rethrow;
    }
  }

  // Obtenir toutes les notifications d'un utilisateur
  Future<List<model.AppNotification>> getNotificationsByUserId(String userId, {int limit = 50}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => model.AppNotification.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des notifications: $e');
      return [];
    }
  }

  // Obtenir les notifications non lues d'un utilisateur
  Future<List<model.AppNotification>> getUnreadNotificationsByUserId(String userId, {int limit = 50}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => model.AppNotification.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des notifications non lues: $e');
      return [];
    }
  }

  // Obtenir le nombre de notifications non lues
  Future<int> getUnreadNotificationsCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      return querySnapshot.count ?? 0;
    } catch (e) {
      debugPrint('Erreur lors du comptage des notifications non lues: $e');
      return 0;
    }
  }

  // Marquer une notification comme lue
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .update({
        'isRead': true,
        'readAt': DateTime.now().toIso8601String(),
      });
      debugPrint('Notification marquée comme lue: $notificationId');
    } catch (e) {
      debugPrint('Erreur lors du marquage de la notification comme lue: $e');
      rethrow;
    }
  }

  // Marquer toutes les notifications d'un utilisateur comme lues
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': DateTime.now().toIso8601String(),
        });
      }

      await batch.commit();
      debugPrint('Toutes les notifications de l\'utilisateur $userId ont été marquées comme lues');
    } catch (e) {
      debugPrint('Erreur lors du marquage de toutes les notifications comme lues: $e');
      rethrow;
    }
  }

  // Supprimer une notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .delete();
      debugPrint('Notification supprimée: $notificationId');
    } catch (e) {
      debugPrint('Erreur lors de la suppression de la notification: $e');
      rethrow;
    }
  }

  // Supprimer toutes les notifications d'un utilisateur
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('Toutes les notifications de l\'utilisateur $userId ont été supprimées');
    } catch (e) {
      debugPrint('Erreur lors de la suppression de toutes les notifications: $e');
      rethrow;
    }
  }

  // Supprimer les anciennes notifications (plus de X jours)
  Future<void> deleteOldNotifications(String userId, {int daysToKeep = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      
      final querySnapshot = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('Anciennes notifications supprimées pour l\'utilisateur $userId');
    } catch (e) {
      debugPrint('Erreur lors de la suppression des anciennes notifications: $e');
      rethrow;
    }
  }

  // Stream pour les notifications d'un utilisateur (temps réel)
  Stream<List<model.AppNotification>> getNotificationsStreamByUserId(String userId, {int limit = 50}) {
    return _firestore
        .collection(_notificationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => model.AppNotification.fromMap(doc.data()))
            .toList());
  }

  // Stream pour les notifications non lues d'un utilisateur (temps réel)
  Stream<List<model.AppNotification>> getUnreadNotificationsStreamByUserId(String userId, {int limit = 50}) {
    return _firestore
        .collection(_notificationsCollection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => model.AppNotification.fromMap(doc.data()))
            .toList());
  }

  // Stream pour le nombre de notifications non lues (temps réel)
  Stream<int> getUnreadNotificationsCountStream(String userId) {
    return _firestore
        .collection(_notificationsCollection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Méthodes pratiques pour créer des notifications spécifiques

  // Créer une notification de tâche complétée
  Future<void> createTaskCompletedNotification({
    required String userId,
    required String familyId,
    required String relatedUserId,
    required String taskTitle,
    required int stars,
  }) async {
    final notificationId = DateTime.now().millisecondsSinceEpoch.toString();
    final notification = model.AppNotification.taskCompleted(
      id: notificationId,
      userId: userId,
      familyId: familyId,
      relatedUserId: relatedUserId,
      taskTitle: taskTitle,
      stars: stars,
    );
    await createNotification(notification);
  }

  // Créer une notification de récompense échangée
  Future<void> createRewardExchangedNotification({
    required String userId,
    required String familyId,
    required String relatedUserId,
    required String rewardName,
    required int starsCost,
  }) async {
    final notificationId = DateTime.now().millisecondsSinceEpoch.toString();
    final notification = model.AppNotification.rewardExchanged(
      id: notificationId,
      userId: userId,
      familyId: familyId,
      relatedUserId: relatedUserId,
      rewardName: rewardName,
      starsCost: starsCost,
    );
    await createNotification(notification);
  }

  // Créer une notification de sanction appliquée
  Future<void> createSanctionAppliedNotification({
    required String userId,
    required String familyId,
    required String relatedUserId,
    required String sanctionName,
  }) async {
    final notificationId = DateTime.now().millisecondsSinceEpoch.toString();
    final notification = model.AppNotification.sanctionApplied(
      id: notificationId,
      userId: userId,
      familyId: familyId,
      relatedUserId: relatedUserId,
      sanctionName: sanctionName,
    );
    await createNotification(notification);
  }

  // Créer une notification de perte d'étoiles
  Future<void> createStarsLostNotification({
    required String userId,
    required String familyId,
    required String relatedUserId,
    required String reason,
    required int starsLost,
  }) async {
    final notificationId = DateTime.now().millisecondsSinceEpoch.toString();
    final notification = model.AppNotification.starsLost(
      id: notificationId,
      userId: userId,
      familyId: familyId,
      relatedUserId: relatedUserId,
      reason: reason,
      starsLost: starsLost,
    );
    await createNotification(notification);
  }

  // Créer une notification système
  Future<void> createSystemNotification({
    required String userId,
    required String title,
    String? description,
    String? familyId,
  }) async {
    final notificationId = DateTime.now().millisecondsSinceEpoch.toString();
    final notification = model.AppNotification.system(
      id: notificationId,
      userId: userId,
      familyId: familyId,
      title: title,
      description: description,
    );
    await createNotification(notification);
  }

  // Créer une notification familiale
  Future<void> createFamilyNotification({
    required String userId,
    required String familyId,
    required String title,
    String? description,
    String? relatedUserId,
  }) async {
    final notificationId = DateTime.now().millisecondsSinceEpoch.toString();
    final notification = model.AppNotification.family(
      id: notificationId,
      userId: userId,
      familyId: familyId,
      title: title,
      description: description,
      relatedUserId: relatedUserId,
    );
    await createNotification(notification);
  }

  // Envoyer une notification à tous les membres d'une famille
  Future<void> sendNotificationToFamily({
    required String familyId,
    required String title,
    String? description,
    required model.NotificationType type,
    String? relatedUserId,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Récupérer tous les membres de la famille
      final familyDoc = await _firestore.collection('families').doc(familyId).get();
      if (!familyDoc.exists) {
        debugPrint('Famille non trouvée: $familyId');
        return;
      }

      final familyData = familyDoc.data()!;
      final List<String> parentIds = List<String>.from(familyData['parentIds'] ?? []);
      final List<String> childIds = List<String>.from(familyData['childIds'] ?? []);
      
      final allMemberIds = [...parentIds, ...childIds];
      
      // Créer une notification pour chaque membre
      final batch = _firestore.batch();
      for (final memberId in allMemberIds) {
        final notificationId = DateTime.now().millisecondsSinceEpoch.toString() + '_' + memberId;
        final notification = model.AppNotification(
          id: notificationId,
          userId: memberId,
          familyId: familyId,
          relatedUserId: relatedUserId,
          type: type,
          title: title,
          description: description,
          data: data,
          createdAt: DateTime.now(),
        );
        
        final notificationRef = _firestore.collection(_notificationsCollection).doc(notificationId);
        batch.set(notificationRef, notification.toMap());
      }
      
      await batch.commit();
      debugPrint('Notification envoyée à tous les membres de la famille $familyId');
    } catch (e) {
      debugPrint('Erreur lors de l\'envoi de la notification à la famille: $e');
      rethrow;
    }
  }

  // Initialiser le service de notifications locales
  Future<void> init() async {
    if (_initialized) return;

    // Initialiser les données de fuseau horaire
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
    debugPrint('Service de notifications locales initialisé');
  }

  // Gérer le clic sur une notification
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification cliquée: ${response.payload}');
    // TODO: Naviguer vers la page appropriée en fonction du payload
  }

  // Planifier une notification pour l'expiration d'une sanction
  Future<bool> scheduleSanctionExpirationNotification({
    required int id,
    required String childName,
    required String sanctionName,
    required DateTime endTime,
  }) async {
    try {
      await _localNotifications.zonedSchedule(
        id,
        'Sanction terminée',
        'La sanction "$sanctionName" de $childName est terminée',
        tz.TZDateTime.from(endTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'sanction_expiration',
            'Expiration des sanctions',
            channelDescription: 'Notifications quand une sanction se termine',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('Notification planifiée pour l\'expiration de la sanction');
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la planification de la notification: $e');
      return false;
    }
  }

  // Annuler une notification planifiée
  Future<void> cancelNotification(int id) async {
    try {
      await _localNotifications.cancel(id);
      debugPrint('Notification $id annulée');
    } catch (e) {
      debugPrint('Erreur lors de l\'annulation de la notification: $e');
    }
  }

  // Afficher une notification immédiatement
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'general_notifications',
        'Notifications générales',
        channelDescription: 'Notifications générales de l\'application',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );

    await _localNotifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Créer une notification d'invitation de famille
  Future<void> createFamilyInvitationNotification({
    required String userId,
    required String familyId,
    required String familyName,
    required String invitedByUserName,
    required String invitationId,
  }) async {
    final notificationId = DateTime.now().millisecondsSinceEpoch.toString();
    final notification = model.AppNotification(
      id: notificationId,
      userId: userId,
      familyId: familyId,
      type: model.NotificationType.family,
      title: 'Invitation à rejoindre une famille',
      description: '$invitedByUserName vous a invité à rejoindre la famille "$familyName"',
      data: {
        'type': 'family_invitation',
        'invitationId': invitationId,
        'familyId': familyId,
        'familyName': familyName,
        'invitedByUserName': invitedByUserName,
      },
      createdAt: DateTime.now(),
    );
    await createNotification(notification);
  }

  // Envoyer une notification d'invitation de famille
  Future<void> sendFamilyInvitationNotification({
    required String invitedUserId,
    required String familyId,
    required String familyName,
    required String invitedByUserName,
    required String invitationId,
  }) async {
    await createFamilyInvitationNotification(
      userId: invitedUserId,
      familyId: familyId,
      familyName: familyName,
      invitedByUserName: invitedByUserName,
      invitationId: invitationId,
    );
  }

  // Créer une notification d'acceptation d'invitation
  Future<void> createFamilyInvitationAcceptedNotification({
    required String userId,
    required String familyId,
    required String familyName,
    required String acceptedUserName,
  }) async {
    final notificationId = DateTime.now().millisecondsSinceEpoch.toString();
    final notification = model.AppNotification(
      id: notificationId,
      userId: userId,
      familyId: familyId,
      relatedUserId: acceptedUserName,
      type: model.NotificationType.family,
      title: 'Invitation acceptée',
      description: '$acceptedUserName a accepté de rejoindre votre famille',
      data: {
        'type': 'family_invitation_accepted',
        'familyId': familyId,
        'familyName': familyName,
        'acceptedUserName': acceptedUserName,
      },
      createdAt: DateTime.now(),
    );
    await createNotification(notification);
  }

  // Envoyer une notification d'acceptation d'invitation à tous les membres de la famille
  Future<void> sendFamilyInvitationAcceptedNotification({
    required String familyId,
    required String familyName,
    required String acceptedUserName,
    String? excludeUserId, // Exclure l'utilisateur qui a accepté
  }) async {
    try {
      // Récupérer tous les membres de la famille
      final familyDoc = await _firestore.collection('families').doc(familyId).get();
      if (!familyDoc.exists) {
        debugPrint('Famille non trouvée: $familyId');
        return;
      }

      final familyData = familyDoc.data()!;
      final List<String> parentIds = List<String>.from(familyData['parentIds'] ?? []);
      
      // Filtrer pour exclure l'utilisateur spécifié si nécessaire
      final targetUserIds = excludeUserId != null
          ? parentIds.where((id) => id != excludeUserId).toList()
          : parentIds;
      
      // Créer une notification pour chaque membre
      final batch = _firestore.batch();
      for (final memberId in targetUserIds) {
        final notificationId = DateTime.now().millisecondsSinceEpoch.toString() + '_' + memberId;
        final notification = model.AppNotification(
          id: notificationId,
          userId: memberId,
          familyId: familyId,
          relatedUserId: acceptedUserName,
          type: model.NotificationType.family,
          title: 'Invitation acceptée',
          description: '$acceptedUserName a accepté de rejoindre votre famille',
          data: {
            'type': 'family_invitation_accepted',
            'familyId': familyId,
            'familyName': familyName,
            'acceptedUserName': acceptedUserName,
          },
          createdAt: DateTime.now(),
        );
        
        final notificationRef = _firestore.collection(_notificationsCollection).doc(notificationId);
        batch.set(notificationRef, notification.toMap());
      }
      
      await batch.commit();
      debugPrint('Notification d\'acceptation envoyée à tous les membres de la famille $familyId');
    } catch (e) {
      debugPrint('Erreur lors de l\'envoi de la notification d\'acceptation: $e');
      rethrow;
    }
  }

  // Créer une notification de refus d'invitation
  Future<void> createFamilyInvitationRejectedNotification({
    required String userId,
    required String familyId,
    required String familyName,
    required String rejectedUserName,
  }) async {
    final notificationId = DateTime.now().millisecondsSinceEpoch.toString();
    final notification = model.AppNotification(
      id: notificationId,
      userId: userId,
      familyId: familyId,
      type: model.NotificationType.family,
      title: 'Invitation refusée',
      description: '$rejectedUserName a refusé l\'invitation à rejoindre votre famille',
      data: {
        'type': 'family_invitation_rejected',
        'familyId': familyId,
        'familyName': familyName,
        'rejectedUserName': rejectedUserName,
      },
      createdAt: DateTime.now(),
    );
    await createNotification(notification);
  }

  // Envoyer une notification de refus d'invitation à tous les membres de la famille
  Future<void> sendFamilyInvitationRejectedNotification({
    required String familyId,
    required String familyName,
    required String rejectedUserName,
  }) async {
    try {
      // Récupérer tous les membres de la famille
      final familyDoc = await _firestore.collection('families').doc(familyId).get();
      if (!familyDoc.exists) {
        debugPrint('Famille non trouvée: $familyId');
        return;
      }

      final familyData = familyDoc.data()!;
      final List<String> parentIds = List<String>.from(familyData['parentIds'] ?? []);
      
      // Créer une notification pour chaque membre
      final batch = _firestore.batch();
      for (final memberId in parentIds) {
        final notificationId = DateTime.now().millisecondsSinceEpoch.toString() + '_' + memberId;
        final notification = model.AppNotification(
          id: notificationId,
          userId: memberId,
          familyId: familyId,
          type: model.NotificationType.family,
          title: 'Invitation refusée',
          description: '$rejectedUserName a refusé l\'invitation à rejoindre votre famille',
          data: {
            'type': 'family_invitation_rejected',
            'familyId': familyId,
            'familyName': familyName,
            'rejectedUserName': rejectedUserName,
          },
          createdAt: DateTime.now(),
        );
        
        final notificationRef = _firestore.collection(_notificationsCollection).doc(notificationId);
        batch.set(notificationRef, notification.toMap());
      }
      
      await batch.commit();
      debugPrint('Notification de refus envoyée à tous les membres de la famille $familyId');
    } catch (e) {
      debugPrint('Erreur lors de l\'envoi de la notification de refus: $e');
      rethrow;
    }
  }
}