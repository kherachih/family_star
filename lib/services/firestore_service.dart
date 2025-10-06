import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:async/async.dart';
import '../models/parent.dart';
import '../models/child.dart';
import '../models/family.dart';
import '../models/task.dart';
import '../models/star_loss.dart';
import '../models/reward.dart';
import '../models/sanction.dart';
import '../models/reward_exchange.dart';
import '../models/sanction_applied.dart';
import '../models/history_item.dart';
import '../models/family_invitation.dart';
import '../models/support_request.dart';
import '../models/tutorial_state.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static const String _parentsCollection = 'parents';
  static const String _childrenCollection = 'children';
  static const String _tasksCollection = 'tasks';
  static const String _starLossesCollection = 'star_losses';
  static const String _rewardsCollection = 'rewards';
  static const String _sanctionsCollection = 'sanctions';
  static const String _rewardExchangesCollection = 'reward_exchanges';
  static const String _sanctionsAppliedCollection = 'sanctions_applied';
  static const String _familiesCollection = 'families';
  static const String _familyInvitationsCollection = 'family_invitations';
  static const String _supportRequestsCollection = 'support_requests';
  static const String _tutorialStatesCollection = 'tutorial_states';

  // Parent operations
  Future<void> createParent(Parent parent) async {
    await _firestore
        .collection(_parentsCollection)
        .doc(parent.id)
        .set(parent.toMap());
  }

  Future<Parent?> getParentByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection(_parentsCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return Parent.fromMap(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      debugPrint('Error getting parent by email: $e');
      return null;
    }
  }

  Future<Parent?> getParentById(String id) async {
    try {
      final doc = await _firestore
          .collection(_parentsCollection)
          .doc(id)
          .get();

      if (doc.exists && doc.data() != null) {
        return Parent.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting parent by id: $e');
      return null;
    }
  }

  Future<void> updateParent(Parent parent) async {
    await _firestore
        .collection(_parentsCollection)
        .doc(parent.id)
        .update(parent.toMap());
  }

  // Child operations
  Future<void> createChild(Child child) async {
    await _firestore
        .collection(_childrenCollection)
        .doc(child.id)
        .set(child.toMap());
  }

  Future<List<Child>> getChildrenByFamilyId(String familyId) async {
    try {
      debugPrint('🔍 Firestore: Recherche enfants pour familyId: $familyId');

      // Tentative SANS orderBy pour éviter les problèmes d'index
      final querySnapshot = await _firestore
          .collection(_childrenCollection)
          .where('familyId', isEqualTo: familyId)
          .get();

      debugPrint('📊 Firestore: ${querySnapshot.docs.length} document(s) trouvé(s)');

      final children = querySnapshot.docs
          .map((doc) {
            debugPrint('   📄 Document: ${doc.id}');
            final data = doc.data();
            debugPrint('   📋 Données: ${data.toString()}');
            return Child.fromMap(data);
          })
          .toList();

      // Trier en local par nom
      children.sort((a, b) => a.name.compareTo(b.name));

      return children;
    } catch (e) {
      debugPrint('❌ Firestore Error getting children: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Pour la compatibilité avec l'ancien code
  Future<List<Child>> getChildrenByParentId(String parentId) async {
    try {
      debugPrint('🔍 Firestore: Recherche enfants pour parentId: $parentId');

      // Rechercher avec l'ancien champ parentId
      final querySnapshot = await _firestore
          .collection(_childrenCollection)
          .where('parentId', isEqualTo: parentId)
          .get();

      debugPrint('📊 Firestore: ${querySnapshot.docs.length} document(s) trouvé(s)');

      final children = querySnapshot.docs
          .map((doc) {
            debugPrint('   📄 Document: ${doc.id}');
            final data = doc.data();
            debugPrint('   📋 Données: ${data.toString()}');
            return Child.fromMap(data);
          })
          .toList();

      // Trier en local par nom
      children.sort((a, b) => a.name.compareTo(b.name));

      return children;
    } catch (e) {
      debugPrint('❌ Firestore Error getting children by parentId: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Méthode universelle qui cherche avec familyId ou parentId
  Future<List<Child>> getChildrenByFamilyOrParentId(String id) async {
    print('🔍 Recherche universelle d\'enfants pour ID: $id');
    
    // Essayer d'abord avec familyId
    var children = await getChildrenByFamilyId(id);
    print('📊 Résultat recherche par familyId: ${children.length} enfant(s) trouvé(s)');
    
    // Si aucun enfant trouvé, essayer avec parentId
    if (children.isEmpty) {
      children = await getChildrenByParentId(id);
      print('📊 Résultat recherche par parentId: ${children.length} enfant(s) trouvé(s)');
    }
    
    print('✅ Total final: ${children.length} enfant(s) trouvé(s) pour ID: $id');
    return children;
  }

  Future<Child?> getChildById(String id) async {
    try {
      final doc = await _firestore
          .collection(_childrenCollection)
          .doc(id)
          .get();

      if (doc.exists && doc.data() != null) {
        return Child.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting child by id: $e');
      return null;
    }
  }

  Future<void> updateChild(Child child) async {
    await _firestore
        .collection(_childrenCollection)
        .doc(child.id)
        .update(child.toMap());
  }

  Future<void> deleteChild(String id) async {
    // Start a batch to delete child and all related data
    final batch = _firestore.batch();

    // Delete the child document
    batch.delete(_firestore.collection(_childrenCollection).doc(id));

    // Delete all tasks for this child
    final tasksSnapshot = await _firestore
        .collection(_tasksCollection)
        .where('childId', isEqualTo: id)
        .get();

    for (final doc in tasksSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete all star losses for this child
    final starLossesSnapshot = await _firestore
        .collection(_starLossesCollection)
        .where('childId', isEqualTo: id)
        .get();

    for (final doc in starLossesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Task operations
  Future<void> createTask(Task task) async {
    await _firestore
        .collection(_tasksCollection)
        .doc(task.id)
        .set(task.toMap());
  }

  Future<List<Task>> getTasksByParentId(String parentId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_tasksCollection)
          .where('parentId', isEqualTo: parentId)
          .get();

      final tasks = querySnapshot.docs
          .map((doc) => Task.fromMap(doc.data()))
          .toList();

      // Trier par date de création décroissante
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return tasks;
    } catch (e) {
      debugPrint('Error getting tasks by parent: $e');
      return [];
    }
  }

  Future<List<Task>> getDailyTasksByParentId(String parentId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_tasksCollection)
          .where('parentId', isEqualTo: parentId)
          .where('isDaily', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .get();

      final tasks = querySnapshot.docs
          .map((doc) => Task.fromMap(doc.data()))
          .toList();

      // Trier par date de création décroissante
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return tasks;
    } catch (e) {
      debugPrint('Error getting daily tasks by parent: $e');
      return [];
    }
  }

  Future<List<Task>> getTasksByChildId(String childId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_tasksCollection)
          .where('childId', isEqualTo: childId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Task.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting tasks: $e');
      return [];
    }
  }

  Future<List<Task>> getTodayTasksByChildId(String childId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection(_tasksCollection)
          .where('childId', isEqualTo: childId)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('createdAt',
              isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Task.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting today tasks: $e');
      return [];
    }
  }

  Future<void> updateTask(Task task) async {
    await _firestore
        .collection(_tasksCollection)
        .doc(task.id)
        .update(task.toMap());
  }

  Future<void> deleteTask(String id) async {
    await _firestore
        .collection(_tasksCollection)
        .doc(id)
        .delete();
  }

  // Star Loss operations
  Future<void> createStarLoss(StarLoss starLoss) async {
    await _firestore
        .collection(_starLossesCollection)
        .doc(starLoss.id)
        .set(starLoss.toMap());
  }

  Future<List<StarLoss>> getStarLossesByChildId(String childId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_starLossesCollection)
          .where('childId', isEqualTo: childId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => StarLoss.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting star losses: $e');
      return [];
    }
  }

  // Stream methods for real-time updates
  Stream<List<Child>> getChildrenStreamByParentId(String parentId) {
    return _firestore
        .collection(_childrenCollection)
        .where('parentId', isEqualTo: parentId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Child.fromMap(doc.data()))
            .toList());
  }

  Stream<List<Task>> getTasksStreamByChildId(String childId) {
    return _firestore
        .collection(_tasksCollection)
        .where('childId', isEqualTo: childId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromMap(doc.data()))
            .toList());
  }

  Stream<List<StarLoss>> getStarLossesStreamByChildId(String childId) {
    return _firestore
        .collection(_starLossesCollection)
        .where('childId', isEqualTo: childId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StarLoss.fromMap(doc.data()))
            .toList());
  }

  // Reward operations
  Future<void> createReward(Reward reward) async {
    final docRef = await _firestore
        .collection(_rewardsCollection)
        .add(reward.toMap());
    await docRef.update({'id': docRef.id});
  }

  Future<List<Reward>> getRewardsByParentId(String parentId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_rewardsCollection)
          .where('parentId', isEqualTo: parentId)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Reward.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting rewards: $e');
      return [];
    }
  }

  Future<void> updateReward(Reward reward) async {
    await _firestore
        .collection(_rewardsCollection)
        .doc(reward.id)
        .update(reward.toMap());
  }

  Future<void> deleteReward(String id) async {
    await _firestore
        .collection(_rewardsCollection)
        .doc(id)
        .delete();
  }

  Stream<List<Reward>> getRewardsStreamByParentId(String parentId) {
    return _firestore
        .collection(_rewardsCollection)
        .where('parentId', isEqualTo: parentId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Reward.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Sanction operations
  Future<void> createSanction(Sanction sanction) async {
    final docRef = await _firestore
        .collection(_sanctionsCollection)
        .add(sanction.toMap());
    await docRef.update({'id': docRef.id});
  }

  Future<List<Sanction>> getSanctionsByParentId(String parentId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_sanctionsCollection)
          .where('parentId', isEqualTo: parentId)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Sanction.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting sanctions: $e');
      return [];
    }
  }

  Future<void> updateSanction(Sanction sanction) async {
    await _firestore
        .collection(_sanctionsCollection)
        .doc(sanction.id)
        .update(sanction.toMap());
  }

  Future<void> deleteSanction(String id) async {
    await _firestore
        .collection(_sanctionsCollection)
        .doc(id)
        .delete();
  }

  Stream<List<Sanction>> getSanctionsStreamByParentId(String parentId) {
    return _firestore
        .collection(_sanctionsCollection)
        .where('parentId', isEqualTo: parentId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Sanction.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Reward Exchange operations
  Future<void> createRewardExchange(RewardExchange exchange) async {
    final docRef = await _firestore
        .collection(_rewardExchangesCollection)
        .add(exchange.toMap());
    await docRef.update({'id': docRef.id});
  }

  Future<List<RewardExchange>> getRewardExchangesByChildId(String childId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_rewardExchangesCollection)
          .where('childId', isEqualTo: childId)
          .orderBy('exchangedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => RewardExchange.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting reward exchanges: $e');
      return [];
    }
  }

  Future<void> markRewardExchangeCompleted(String exchangeId) async {
    await _firestore
        .collection(_rewardExchangesCollection)
        .doc(exchangeId)
        .update({'isCompleted': true});
  }

  Stream<List<RewardExchange>> getRewardExchangesStreamByChildId(String childId) {
    return _firestore
        .collection(_rewardExchangesCollection)
        .where('childId', isEqualTo: childId)
        .orderBy('exchangedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RewardExchange.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Sanction Applied operations
  Future<void> createSanctionApplied(SanctionApplied sanction) async {
    final docRef = await _firestore
        .collection(_sanctionsAppliedCollection)
        .add(sanction.toMap());
    await docRef.update({'id': docRef.id});
  }

  Future<List<SanctionApplied>> getSanctionsAppliedByChildId(String childId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_sanctionsAppliedCollection)
          .where('childId', isEqualTo: childId)
          .orderBy('appliedAt', descending: true)
          .get();

      final sanctions = querySnapshot.docs
          .map((doc) => SanctionApplied.fromMap(doc.data(), doc.id))
          .toList();

      // Vérifier automatiquement les sanctions expirées et les désactiver
      await _checkAndUpdateExpiredSanctions(sanctions);

      return sanctions;
    } catch (e) {
      debugPrint('Error getting sanctions applied: $e');
      return [];
    }
  }

  Future<void> _checkAndUpdateExpiredSanctions(List<SanctionApplied> sanctions) async {
    final now = DateTime.now();
    final batch = _firestore.batch();
    bool hasUpdates = false;

    for (final sanction in sanctions) {
      if (sanction.isActive && sanction.isExpired) {
        // La sanction est expirée mais toujours active, la désactiver
        batch.update(
          _firestore.collection(_sanctionsAppliedCollection).doc(sanction.id),
          {'isActive': false}
        );
        hasUpdates = true;
        debugPrint('Sanction expirée désactivée automatiquement: ${sanction.sanctionName}');
      }
    }

    if (hasUpdates) {
      await batch.commit();
      debugPrint('Mise à jour des sanctions expirées terminée');
    }
  }

  Future<void> deactivateSanctionApplied(String sanctionId) async {
    await _firestore
        .collection(_sanctionsAppliedCollection)
        .doc(sanctionId)
        .update({'isActive': false});
  }

  Stream<List<SanctionApplied>> getSanctionsAppliedStreamByChildId(String childId) {
    return _firestore
        .collection(_sanctionsAppliedCollection)
        .where('childId', isEqualTo: childId)
        .where('isActive', isEqualTo: true)
        .orderBy('appliedAt', descending: true)
        .orderBy('__name__', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SanctionApplied.fromMap(doc.data(), doc.id))
            .toList());
  }

  // History operations
  Future<List<HistoryItem>> getHistoryByChildId(String childId, {int limit = 20, DateTime? startAfter}) async {
    try {
      // Récupérer d'abord les informations de l'enfant pour obtenir le parentId
      final childDoc = await _firestore
          .collection(_childrenCollection)
          .doc(childId)
          .get();
      
      if (!childDoc.exists) {
        debugPrint('Child not found: $childId');
        return [];
      }
      
      final child = Child.fromMap(childDoc.data()!);
      final parentId = child.familyId; // Utiliser familyId au lieu de parentId
      
      // Récupérer toutes les tâches du parent, puis filtrer localement
      final allTasks = await getTasksByParentId(parentId);
      final tasks = allTasks
          .where((task) => task.childIds.contains(childId))
          .where((task) => startAfter == null || task.createdAt.isBefore(startAfter!))
          .take(limit)
          .map((task) => HistoryItem.fromTask(task))
          .toList();

      // Récupérer les pertes d'étoiles de l'enfant
      final starLossesQuery = _firestore
          .collection(_starLossesCollection)
          .where('childId', isEqualTo: childId)
          .orderBy('createdAt', descending: true);
      
      final starLossesSnapshot = startAfter != null
          ? await starLossesQuery.startAfter([Timestamp.fromDate(startAfter)]).limit(limit).get()
          : await starLossesQuery.limit(limit).get();
      
      final starLosses = starLossesSnapshot.docs
          .map((doc) => StarLoss.fromMap(doc.data()))
          .map((starLoss) => HistoryItem.fromStarLoss(starLoss))
          .toList();

      // Récupérer les échanges de récompenses de l'enfant
      final rewardExchangesQuery = _firestore
          .collection(_rewardExchangesCollection)
          .where('childId', isEqualTo: childId)
          .orderBy('exchangedAt', descending: true);
      
      final rewardExchangesSnapshot = startAfter != null
          ? await rewardExchangesQuery.startAfter([Timestamp.fromDate(startAfter)]).limit(limit).get()
          : await rewardExchangesQuery.limit(limit).get();
      
      final rewardExchanges = rewardExchangesSnapshot.docs
          .map((doc) => RewardExchange.fromMap(doc.data(), doc.id))
          .map((exchange) => HistoryItem.fromRewardExchange(exchange))
          .toList();

      // Récupérer les sanctions appliquées à l'enfant
      final sanctionsAppliedQuery = _firestore
          .collection(_sanctionsAppliedCollection)
          .where('childId', isEqualTo: childId)
          .orderBy('appliedAt', descending: true);
      
      final sanctionsAppliedSnapshot = startAfter != null
          ? await sanctionsAppliedQuery.startAfter([Timestamp.fromDate(startAfter)]).limit(limit).get()
          : await sanctionsAppliedQuery.limit(limit).get();
      
      final sanctionsApplied = sanctionsAppliedSnapshot.docs
          .map((doc) => SanctionApplied.fromMap(doc.data(), doc.id))
          .map((sanction) => HistoryItem.fromSanctionApplied(sanction))
          .toList();

      // Combiner tous les éléments d'historique
      final allHistoryItems = <HistoryItem>[
        ...tasks,
        ...starLosses,
        ...rewardExchanges,
        ...sanctionsApplied,
      ];

      // Trier par date décroissante
      allHistoryItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Limiter le nombre de résultats
      return allHistoryItems.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting history: $e');
      return [];
    }
  }

  Stream<List<HistoryItem>> getHistoryStreamByChildId(String childId) {
    // Créer un contrôleur de stream personnalisé
    final controller = StreamController<List<HistoryItem>>();
    
    // Écouter les changements dans chaque collection
    void updateHistory() async {
      final history = await getHistoryByChildId(childId, limit: 50);
      if (!controller.isClosed) {
        controller.add(history);
      }
    }
    
    // Récupérer d'abord les informations de l'enfant pour obtenir le parentId
    _firestore
        .collection(_childrenCollection)
        .doc(childId)
        .get()
        .then((childDoc) {
          if (!childDoc.exists) return;
          
          final child = Child.fromMap(childDoc.data()!);
          final parentId = child.familyId; // Utiliser familyId au lieu de parentId
          
          // Configurer les écouteurs pour chaque collection
          final tasksSubscription = _firestore
              .collection(_tasksCollection)
              .where('parentId', isEqualTo: parentId)
              .snapshots()
              .listen((_) => updateHistory());
              
          final starLossesSubscription = _firestore
              .collection(_starLossesCollection)
              .where('childId', isEqualTo: childId)
              .snapshots()
              .listen((_) => updateHistory());
              
          final rewardExchangesSubscription = _firestore
              .collection(_rewardExchangesCollection)
              .where('childId', isEqualTo: childId)
              .snapshots()
              .listen((_) => updateHistory());
              
          final sanctionsAppliedSubscription = _firestore
              .collection(_sanctionsAppliedCollection)
              .where('childId', isEqualTo: childId)
              .snapshots()
              .listen((_) => updateHistory());
          
          // Nettoyer les ressources lorsque le stream est fermé
          controller.onCancel = () {
            tasksSubscription.cancel();
            starLossesSubscription.cancel();
            rewardExchangesSubscription.cancel();
            sanctionsAppliedSubscription.cancel();
            controller.close();
          };
        })
        .catchError((e) {
          debugPrint('Error getting child for history stream: $e');
          controller.close();
        });
    
    // Charger les données initiales
    updateHistory();
    
    return controller.stream;
  }

  // Family operations
  Future<void> createFamily(Family family) async {
    await _firestore
        .collection(_familiesCollection)
        .doc(family.id)
        .set(family.toMap());
  }

  Future<Family?> getFamilyById(String id) async {
    try {
      final doc = await _firestore
          .collection(_familiesCollection)
          .doc(id)
          .get();

      if (doc.exists && doc.data() != null) {
        return Family.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting family by id: $e');
      return null;
    }
  }

  Future<List<Family>> getFamiliesByParentId(String parentId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_familiesCollection)
          .where('parentIds', arrayContains: parentId)
          .get();

      return querySnapshot.docs
          .map((doc) => Family.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting families by parent: $e');
      return [];
    }
  }

  Future<void> updateFamily(Family family) async {
    await _firestore
        .collection(_familiesCollection)
        .doc(family.id)
        .update(family.toMap());
  }

  Future<void> addParentToFamily(String familyId, String parentId) async {
    try {
      debugPrint('Ajout du parent $parentId à la famille $familyId');
      
      // Utiliser une transaction pour garantir la cohérence
      await _firestore.runTransaction((transaction) async {
        final familyDoc = await transaction.get(_firestore.collection(_familiesCollection).doc(familyId));
        
        if (!familyDoc.exists) {
          debugPrint('Famille non trouvée: $familyId');
          throw Exception('Famille non trouvée');
        }
        
        final familyData = familyDoc.data()!;
        final parentIds = List<String>.from(familyData['parentIds'] ?? []);
        
        // Vérifier si le parent est déjà dans la famille
        if (parentIds.contains(parentId)) {
          debugPrint('Le parent $parentId est déjà dans la famille $familyId');
          return; // Ne rien faire, le parent est déjà dans la famille
        }
        
        // Ajouter le parent à la famille
        parentIds.add(parentId);
        transaction.update(familyDoc.reference, {'parentIds': parentIds});
      });
      
      debugPrint('Parent $parentId ajouté avec succès à la famille $familyId');
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout du parent à la famille: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      rethrow; // Propager l'erreur pour la gérer au niveau supérieur
    }
  }

  Future<void> removeParentFromFamily(String familyId, String parentId) async {
    final family = await getFamilyById(familyId);
    if (family != null) {
      final updatedFamily = family.removeParent(parentId);
      await updateFamily(updatedFamily);
    }
  }

  Future<void> addChildToFamily(String familyId, String childId) async {
    final family = await getFamilyById(familyId);
    if (family != null) {
      final updatedFamily = family.addChild(childId);
      await updateFamily(updatedFamily);
    }
  }

  Future<void> removeChildFromFamily(String familyId, String childId) async {
    final family = await getFamilyById(familyId);
    if (family != null) {
      final updatedFamily = family.removeChild(childId);
      await updateFamily(updatedFamily);
    }
  }

  // Méthode pour créer une famille automatiquement lors de l'inscription
  Future<Family> createFamilyForParent(String parentId, String parentName) async {
    final familyId = DateTime.now().millisecondsSinceEpoch.toString();
    final family = Family(
      id: familyId,
      name: 'Famille de $parentName',
      parentIds: [parentId],
      childIds: [],
      createdBy: parentId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await createFamily(family);
    return family;
  }

  // Family Invitation operations
  
  // Créer une invitation de famille
  Future<void> createFamilyInvitation(FamilyInvitation invitation) async {
    await _firestore
        .collection(_familyInvitationsCollection)
        .doc(invitation.id)
        .set(invitation.toMap());
    debugPrint('Invitation de famille créée: ${invitation.id}');
  }

  // Obtenir une invitation par son ID
  Future<FamilyInvitation?> getFamilyInvitationById(String id) async {
    try {
      final doc = await _firestore
          .collection(_familyInvitationsCollection)
          .doc(id)
          .get();

      if (doc.exists && doc.data() != null) {
        return FamilyInvitation.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting family invitation by id: $e');
      return null;
    }
  }

  // Obtenir les invitations d'un utilisateur
  Future<List<FamilyInvitation>> getFamilyInvitationsByUserId(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_familyInvitationsCollection)
          .where('invitedUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => FamilyInvitation.fromMap(doc.data()))
          .where((invitation) => !invitation.isExpired)
          .toList();
    } catch (e) {
      debugPrint('Error getting family invitations by user: $e');
      return [];
    }
  }

  // Mettre à jour une invitation
  Future<void> updateFamilyInvitation(FamilyInvitation invitation) async {
    await _firestore
        .collection(_familyInvitationsCollection)
        .doc(invitation.id)
        .update(invitation.toMap());
    debugPrint('Invitation de famille mise à jour: ${invitation.id}');
  }

  // Accepter une invitation de famille
  Future<bool> acceptFamilyInvitation(String invitationId) async {
    try {
      debugPrint('Début de l\'acceptation de l\'invitation: $invitationId');
      
      // Vérifier d'abord si l'invitation existe et est active
      final invitation = await getFamilyInvitationById(invitationId);
      if (invitation == null) {
        debugPrint('Invitation non trouvée: $invitationId');
        return false;
      }
      
      if (!invitation.isActive) {
        debugPrint('Invitation inactive: $invitationId, statut: ${invitation.status.codeName}');
        return false;
      }

      // Mettre à jour le statut de l'invitation d'abord
      debugPrint('Mise à jour du statut de l\'invitation');
      final updatedInvitation = invitation.accept();
      await updateFamilyInvitation(updatedInvitation);

      // Essayer d'ajouter le parent à la famille sans vérifier d'abord si elle existe
      // La méthode addParentToFamily gérera elle-même les erreurs
      debugPrint('Ajout du parent à la famille: ${invitation.familyId}');
      try {
        await addParentToFamily(invitation.familyId, invitation.invitedUserId);
        debugPrint('Parent ajouté avec succès à la famille');
      } catch (e) {
        debugPrint('Erreur lors de l\'ajout du parent à la famille: $e');
        // L'invitation est acceptée mais l'ajout à la famille a échoué
        // L'utilisateur peut essayer de rejoindre manuellement plus tard
      }

      debugPrint('Invitation acceptée avec succès: $invitationId');
      return true;
    } catch (e) {
      debugPrint('Erreur lors de l\'acceptation de l\'invitation: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // Refuser une invitation de famille
  Future<bool> rejectFamilyInvitation(String invitationId) async {
    try {
      debugPrint('Début du refus de l\'invitation: $invitationId');
      
      // Vérifier d'abord si l'invitation existe et est active
      final invitation = await getFamilyInvitationById(invitationId);
      if (invitation == null) {
        debugPrint('Invitation non trouvée: $invitationId');
        return false;
      }
      
      if (!invitation.isActive) {
        debugPrint('Invitation inactive: $invitationId, statut: ${invitation.status.codeName}');
        return false;
      }

      // Mettre à jour le statut de l'invitation
      debugPrint('Mise à jour du statut de l\'invitation');
      final updatedInvitation = invitation.reject();
      await updateFamilyInvitation(updatedInvitation);

      debugPrint('Invitation refusée avec succès: $invitationId');
      return true;
    } catch (e) {
      debugPrint('Erreur lors du refus de l\'invitation: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // Vérifier si une invitation existe déjà pour un utilisateur et une famille
  Future<bool> hasPendingInvitation(String userId, String familyId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_familyInvitationsCollection)
          .where('invitedUserId', isEqualTo: userId)
          .where('familyId', isEqualTo: familyId)
          .where('status', isEqualTo: 'pending')
          .get();

      // Vérifier si une des invitations est encore active (non expirée)
      for (final doc in querySnapshot.docs) {
        final invitation = FamilyInvitation.fromMap(doc.data());
        if (!invitation.isExpired) {
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error checking pending invitation: $e');
      return false;
    }
  }

  // Nettoyer les invitations expirées
  Future<void> cleanupExpiredInvitations() async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection(_familyInvitationsCollection)
          .where('expiresAt', isLessThan: Timestamp.fromDate(now))
          .where('status', isEqualTo: 'pending')
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'status': 'expired'});
      }

      if (querySnapshot.docs.isNotEmpty) {
        await batch.commit();
        debugPrint('${querySnapshot.docs.length} invitations expirées marquées');
      }
    } catch (e) {
      debugPrint('Error cleaning up expired invitations: $e');
    }
  }

  // Stream pour les invitations d'un utilisateur
  Stream<List<FamilyInvitation>> getFamilyInvitationsStreamByUserId(String userId) {
    return _firestore
        .collection(_familyInvitationsCollection)
        .where('invitedUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FamilyInvitation.fromMap(doc.data()))
            .where((invitation) => !invitation.isExpired)
            .toList());
  }

  // Support Request operations
  Future<void> createSupportRequest(SupportRequest request) async {
    await _firestore
        .collection(_supportRequestsCollection)
        .doc(request.id)
        .set(request.toMap());
    debugPrint('Demande de support créée: ${request.id}');
  }

  Future<List<SupportRequest>> getSupportRequestsByUserId(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_supportRequestsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => SupportRequest.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting support requests: $e');
      return [];
    }
  }

  Future<void> updateSupportRequest(SupportRequest request) async {
    await _firestore
        .collection(_supportRequestsCollection)
        .doc(request.id)
        .update(request.toMap());
    debugPrint('Demande de support mise à jour: ${request.id}');
  }

  Stream<List<SupportRequest>> getSupportRequestsStreamByUserId(String userId) {
    return _firestore
        .collection(_supportRequestsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SupportRequest.fromMap(doc.data()))
            .toList());
    }
  
    // Tutorial State operations
    Future<void> createTutorialState(TutorialState tutorialState) async {
      await _firestore
          .collection(_tutorialStatesCollection)
          .doc(tutorialState.id)
          .set(tutorialState.toMap());
    }
  
    Future<TutorialState?> getTutorialStateByParentId(String parentId) async {
      try {
        final querySnapshot = await _firestore
            .collection(_tutorialStatesCollection)
            .where('parentId', isEqualTo: parentId)
            .limit(1)
            .get();
  
        if (querySnapshot.docs.isNotEmpty) {
          return TutorialState.fromMap(querySnapshot.docs.first.data());
        }
        return null;
      } catch (e) {
        debugPrint('Error getting tutorial state by parent id: $e');
        return null;
      }
    }
  
    Future<void> updateTutorialState(TutorialState tutorialState) async {
      await _firestore
          .collection(_tutorialStatesCollection)
          .doc(tutorialState.id)
          .update(tutorialState.toMap());
    }
  
    Future<TutorialState> initializeTutorialStateForParent(String parentId) async {
      // Vérifier si un état de tutoriel existe déjà pour ce parent
      TutorialState? existingState = await getTutorialStateByParentId(parentId);
      
      if (existingState != null) {
        return existingState;
      }
      
      // Créer un nouvel état de tutoriel
      final tutorialState = TutorialState(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        parentId: parentId,
        hasCompletedTutorial: false,
        currentStep: 0,
        hasAddedChildren: false,
        hasConfiguredTasks: false,
        hasConfiguredRewards: false,
        hasConfiguredSanctions: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await createTutorialState(tutorialState);
      return tutorialState;
    }
  
    Future<void> markTutorialStepCompleted(String parentId, int step) async {
      final tutorialState = await getTutorialStateByParentId(parentId);
      if (tutorialState != null) {
        final updatedState = tutorialState.markStepCompleted(step);
        await updateTutorialState(updatedState);
      }
    }
  
    Stream<TutorialState?> getTutorialStateStreamByParentId(String parentId) {
      return _firestore
          .collection(_tutorialStatesCollection)
          .where('parentId', isEqualTo: parentId)
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isNotEmpty) {
              return TutorialState.fromMap(snapshot.docs.first.data());
            }
            return null;
          });
    }
  }