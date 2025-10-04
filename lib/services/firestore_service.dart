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
    final family = await getFamilyById(familyId);
    if (family != null) {
      final updatedFamily = family.addParent(parentId);
      await updateFamily(updatedFamily);
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
}