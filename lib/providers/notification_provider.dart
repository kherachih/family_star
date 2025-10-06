import 'package:flutter/foundation.dart';
import '../models/notification.dart' as model;
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<model.AppNotification> _notifications = [];
  List<model.AppNotification> _unreadNotifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;

  List<model.AppNotification> get notifications => _notifications;
  List<model.AppNotification> get unreadNotifications => _unreadNotifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialiser le provider avec un ID utilisateur
  void initialize(String userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      loadNotifications();
      listenToNotifications();
      listenToUnreadCount();
    }
  }

  // Charger toutes les notifications
  Future<void> loadNotifications() async {
    if (_currentUserId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notifications = await _notificationService.getNotificationsByUserId(_currentUserId!);
      _unreadNotifications = await _notificationService.getUnreadNotificationsByUserId(_currentUserId!);
      _unreadCount = _unreadNotifications.length;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Écouter les notifications en temps réel
  void listenToNotifications() {
    if (_currentUserId == null) return;

    _notificationService.getNotificationsStreamByUserId(_currentUserId!).listen(
      (notifications) {
        _notifications = notifications;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        debugPrint('Error in notifications stream: $error');
        notifyListeners();
      },
    );
  }

  // Écouter les notifications non lues en temps réel
  void listenToUnreadNotifications() {
    if (_currentUserId == null) return;

    _notificationService.getUnreadNotificationsStreamByUserId(_currentUserId!).listen(
      (unreadNotifications) {
        _unreadNotifications = unreadNotifications;
        _unreadCount = unreadNotifications.length;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        debugPrint('Error in unread notifications stream: $error');
        notifyListeners();
      },
    );
  }

  // Écouter le nombre de notifications non lues en temps réel
  void listenToUnreadCount() {
    if (_currentUserId == null) return;

    _notificationService.getUnreadNotificationsCountStream(_currentUserId!).listen(
      (count) {
        _unreadCount = count;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        debugPrint('Error in unread count stream: $error');
        notifyListeners();
      },
    );
  }

  // Marquer une notification comme lue
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markNotificationAsRead(notificationId);
      
      // Mettre à jour localement
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].markAsRead();
      }
      
      final unreadIndex = _unreadNotifications.indexWhere((n) => n.id == notificationId);
      if (unreadIndex != -1) {
        _unreadNotifications.removeAt(unreadIndex);
        _unreadCount = _unreadNotifications.length;
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error marking notification as read: $e');
      notifyListeners();
    }
  }

  // Marquer toutes les notifications comme lues
  Future<void> markAllAsRead() async {
    if (_currentUserId == null) return;

    try {
      await _notificationService.markAllNotificationsAsRead(_currentUserId!);
      
      // Mettre à jour localement
      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].markAsRead();
      }
      
      _unreadNotifications.clear();
      _unreadCount = 0;
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error marking all notifications as read: $e');
      notifyListeners();
    }
  }

  // Supprimer une notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      
      // Mettre à jour localement
      _notifications.removeWhere((n) => n.id == notificationId);
      _unreadNotifications.removeWhere((n) => n.id == notificationId);
      _unreadCount = _unreadNotifications.length;
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting notification: $e');
      notifyListeners();
    }
  }

  // Supprimer toutes les notifications
  Future<void> deleteAllNotifications() async {
    if (_currentUserId == null) return;

    try {
      await _notificationService.deleteAllNotifications(_currentUserId!);
      
      // Mettre à jour localement
      _notifications.clear();
      _unreadNotifications.clear();
      _unreadCount = 0;
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting all notifications: $e');
      notifyListeners();
    }
  }

  // Supprimer les anciennes notifications
  Future<void> deleteOldNotifications({int daysToKeep = 30}) async {
    if (_currentUserId == null) return;

    try {
      await _notificationService.deleteOldNotifications(_currentUserId!, daysToKeep: daysToKeep);
      
      // Recharger les notifications
      await loadNotifications();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting old notifications: $e');
      notifyListeners();
    }
  }

  // Créer une notification de tâche complétée
  Future<void> createTaskCompletedNotification({
    required String familyId,
    required String relatedUserId,
    required String taskTitle,
    required int stars,
  }) async {
    if (_currentUserId == null) return;

    try {
      await _notificationService.createTaskCompletedNotification(
        userId: _currentUserId!,
        familyId: familyId,
        relatedUserId: relatedUserId,
        taskTitle: taskTitle,
        stars: stars,
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating task completed notification: $e');
      notifyListeners();
    }
  }

  // Créer une notification de récompense échangée
  Future<void> createRewardExchangedNotification({
    required String familyId,
    required String relatedUserId,
    required String rewardName,
    required int starsCost,
  }) async {
    if (_currentUserId == null) return;

    try {
      await _notificationService.createRewardExchangedNotification(
        userId: _currentUserId!,
        familyId: familyId,
        relatedUserId: relatedUserId,
        rewardName: rewardName,
        starsCost: starsCost,
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating reward exchanged notification: $e');
      notifyListeners();
    }
  }

  // Créer une notification de sanction appliquée
  Future<void> createSanctionAppliedNotification({
    required String familyId,
    required String relatedUserId,
    required String sanctionName,
  }) async {
    if (_currentUserId == null) return;

    try {
      await _notificationService.createSanctionAppliedNotification(
        userId: _currentUserId!,
        familyId: familyId,
        relatedUserId: relatedUserId,
        sanctionName: sanctionName,
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating sanction applied notification: $e');
      notifyListeners();
    }
  }

  // Créer une notification de perte d'étoiles
  Future<void> createStarsLostNotification({
    required String familyId,
    required String relatedUserId,
    required String reason,
    required int starsLost,
  }) async {
    if (_currentUserId == null) return;

    try {
      await _notificationService.createStarsLostNotification(
        userId: _currentUserId!,
        familyId: familyId,
        relatedUserId: relatedUserId,
        reason: reason,
        starsLost: starsLost,
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating stars lost notification: $e');
      notifyListeners();
    }
  }

  // Créer une notification système
  Future<void> createSystemNotification({
    required String title,
    String? description,
    String? familyId,
  }) async {
    if (_currentUserId == null) return;

    try {
      await _notificationService.createSystemNotification(
        userId: _currentUserId!,
        title: title,
        description: description,
        familyId: familyId,
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating system notification: $e');
      notifyListeners();
    }
  }

  // Créer une notification familiale
  Future<void> createFamilyNotification({
    required String familyId,
    required String title,
    String? description,
    String? relatedUserId,
  }) async {
    if (_currentUserId == null) return;

    try {
      await _notificationService.createFamilyNotification(
        userId: _currentUserId!,
        familyId: familyId,
        title: title,
        description: description,
        relatedUserId: relatedUserId,
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating family notification: $e');
      notifyListeners();
    }
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
      await _notificationService.sendNotificationToFamily(
        familyId: familyId,
        title: title,
        description: description,
        type: type,
        relatedUserId: relatedUserId,
        data: data,
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('Error sending notification to family: $e');
      notifyListeners();
    }
  }

  // Effacer les erreurs
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Réinitialiser le provider
  void reset() {
    _notifications.clear();
    _unreadNotifications.clear();
    _unreadCount = 0;
    _isLoading = false;
    _error = null;
    _currentUserId = null;
    notifyListeners();
  }
}