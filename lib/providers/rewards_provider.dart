import 'package:flutter/foundation.dart';
import '../models/reward.dart';
import '../models/sanction.dart';
import '../models/reward_exchange.dart';
import '../models/sanction_applied.dart';
import '../models/child.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class RewardsProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<Reward> _rewards = [];
  List<Sanction> _sanctions = [];
  List<RewardExchange> _rewardExchanges = [];
  List<SanctionApplied> _sanctionsApplied = [];

  bool _isLoading = false;
  String? _error;

  List<Reward> get rewards => _rewards;
  List<Sanction> get sanctions => _sanctions;
  List<RewardExchange> get rewardExchanges => _rewardExchanges;
  List<SanctionApplied> get sanctionsApplied => _sanctionsApplied;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Reward methods
  Future<void> loadRewards(String parentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _rewards = await _firestoreService.getRewardsByParentId(parentId);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading rewards: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addReward(Reward reward) async {
    try {
      await _firestoreService.createReward(reward);
      await loadRewards(reward.parentId);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding reward: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateReward(Reward reward) async {
    try {
      await _firestoreService.updateReward(reward);
      await loadRewards(reward.parentId);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating reward: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteReward(String rewardId, String parentId) async {
    try {
      await _firestoreService.deleteReward(rewardId);
      await loadRewards(parentId);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting reward: $e');
      notifyListeners();
      rethrow;
    }
  }

  // Sanction methods
  Future<void> loadSanctions(String parentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sanctions = await _firestoreService.getSanctionsByParentId(parentId);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading sanctions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSanction(Sanction sanction) async {
    try {
      await _firestoreService.createSanction(sanction);
      await loadSanctions(sanction.parentId);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding sanction: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateSanction(Sanction sanction) async {
    try {
      await _firestoreService.updateSanction(sanction);
      await loadSanctions(sanction.parentId);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating sanction: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteSanction(String sanctionId, String parentId) async {
    try {
      await _firestoreService.deleteSanction(sanctionId);
      await loadSanctions(parentId);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting sanction: $e');
      notifyListeners();
      rethrow;
    }
  }

  // Reward Exchange methods
  Future<void> loadRewardExchanges(String childId) async {
    try {
      _rewardExchanges = await _firestoreService.getRewardExchangesByChildId(childId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading reward exchanges: $e');
      notifyListeners();
    }
  }

  Future<bool> exchangeReward(Child child, Reward reward, Function(Child) updateChild) async {
    // Vérifier si l'enfant a assez d'étoiles positives
    if (child.stars < reward.starsCost) {
      _error = 'Pas assez d\'étoiles (${child.stars}/${reward.starsCost})';
      notifyListeners();
      return false;
    }

    try {
      // Créer l'échange
      final exchange = RewardExchange(
        childId: child.id,
        rewardId: reward.id ?? '',
        rewardName: reward.name,
        starsCost: reward.starsCost,
      );

      await _firestoreService.createRewardExchange(exchange);

      // Déduire les étoiles de l'enfant et remettre à 0 si égal au coût
      final newStars = child.stars - reward.starsCost;
      final updatedChild = child.copyWith(
        stars: newStars,
      );

      await updateChild(updatedChild);
      await loadRewardExchanges(child.id);

      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error exchanging reward: $e');
      notifyListeners();
      return false;
    }
  }

  Future<void> markRewardCompleted(String exchangeId) async {
    try {
      await _firestoreService.markRewardExchangeCompleted(exchangeId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error marking reward completed: $e');
      notifyListeners();
      rethrow;
    }
  }

  // Sanction Applied methods
  Future<void> loadSanctionsApplied(String childId) async {
    try {
      _sanctionsApplied = await _firestoreService.getSanctionsAppliedByChildId(childId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading sanctions applied: $e');
      notifyListeners();
    }
  }

  Future<bool> applySanction(Child child, Sanction sanction, Function(Child) updateChild) async {
    // Vérifier si l'enfant a assez d'étoiles négatives
    // Si la sanction coûte 15, l'enfant doit avoir -15 ou moins (ex: -15, -20, -30)
    if (child.stars > -sanction.starsCost) {
      _error = 'Pas assez d\'étoiles négatives (${child.stars}/-${sanction.starsCost})';
      notifyListeners();
      return false;
    }

    try {
      // Calculer la date de fin si une durée est spécifiée
      DateTime? endsAt;
      if (sanction.durationValue != null && sanction.durationUnit != null) {
        final durationInHours = sanction.durationInHours;
        if (durationInHours != null) {
          endsAt = DateTime.now().add(Duration(hours: durationInHours));
        }
      }

      // Créer la sanction appliquée
      final appliedSanction = SanctionApplied(
        childId: child.id,
        sanctionId: sanction.id ?? '',
        sanctionName: sanction.name,
        starsCost: sanction.starsCost,
        durationValue: sanction.durationValue,
        durationUnit: sanction.durationUnit,
        endsAt: endsAt,
      );

      await _firestoreService.createSanctionApplied(appliedSanction);

      // Planifier une notification pour la fin de la sanction
      if (endsAt != null) {
        try {
          final notificationService = NotificationService();
          await notificationService.init();
          
          // Générer un ID unique pour la notification
          final notificationId = DateTime.now().millisecondsSinceEpoch % 100000;
          
          final notificationScheduled = await notificationService.scheduleSanctionEndNotification(
            id: notificationId,
            childName: child.name,
            sanctionName: sanction.name,
            endTime: endsAt,
          );
          
          if (!notificationScheduled) {
            debugPrint('La notification pour la fin de la sanction n\'a pas pu être planifiée, mais la sanction est toujours appliquée.');
          }
        } catch (e) {
          debugPrint('Erreur lors de la planification de la notification: $e');
          // Ne pas bloquer l'application si la notification échoue
        }
      }

      // Ajouter les étoiles pour réduire les étoiles négatives (remettre à 0 si égal)
      final newStars = child.stars + sanction.starsCost;
      final updatedChild = child.copyWith(stars: newStars);

      await updateChild(updatedChild);
      await loadSanctionsApplied(child.id);

      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error applying sanction: $e');
      notifyListeners();
      return false;
    }
  }

  Future<void> deactivateSanction(String sanctionId) async {
    try {
      // Récupérer la sanction appliquée pour pouvoir annuler la notification
      final sanctionApplied = _sanctionsApplied.firstWhere(
        (s) => s.id == sanctionId,
        orElse: () => throw Exception('Sanction not found'),
      );

      // Annuler la notification si elle existe
      if (sanctionApplied.endsAt != null) {
        final notificationService = NotificationService();
        await notificationService.init();
        
        // Utiliser le même ID que lors de la création de la notification
        final notificationId = sanctionApplied.appliedAt.millisecondsSinceEpoch % 100000;
        await notificationService.cancelNotification(notificationId);
      }

      await _firestoreService.deactivateSanctionApplied(sanctionId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deactivating sanction: $e');
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}