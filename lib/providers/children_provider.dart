import 'package:flutter/foundation.dart';
import '../models/child.dart';
import '../services/firestore_service.dart';

class ChildrenProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<Child> _children = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Child> get children => _children;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadChildren(String parentId) async {
    _setLoading(true);
    try {
      print('🔍 Chargement des enfants pour le parent: $parentId');
      _children = await _firestoreService.getChildrenByParentId(parentId);
      print('✅ ${_children.length} enfant(s) chargé(s)');
      for (var child in _children) {
        print('   - ${child.name} (${child.totalStars} étoiles)');
      }
      _clearError();
    } catch (e) {
      print('❌ Erreur chargement enfants: $e');
      _setError('Erreur lors du chargement des enfants: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addChild({
    required String parentId,
    required String name,
    required int age,
    DateTime? birthDate,
    String? photoUrl,
    String gender = 'boy',
    int avatarIndex = 0,
    int birthdayStars = 10,
    List<String> objectives = const [],
  }) async {
    _setLoading(true);
    try {
      print('➕ Ajout enfant: $name pour parent: $parentId');
      final child = Child(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        parentId: parentId,
        name: name,
        age: age,
        birthDate: birthDate,
        photoUrl: photoUrl,
        gender: gender,
        avatarIndex: avatarIndex,
        birthdayStars: birthdayStars,
        objectives: objectives,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.createChild(child);
      print('✅ Enfant ajouté dans Firestore avec avatar: ${child.avatar}');
      _children.add(child);
      _clearError();
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Erreur ajout enfant: $e');
      _setError('Erreur lors de l\'ajout de l\'enfant: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateChild(Child child) async {
    _setLoading(true);
    try {
      final updatedChild = child.copyWith(updatedAt: DateTime.now());
      await _firestoreService.updateChild(updatedChild);

      final index = _children.indexWhere((c) => c.id == child.id);
      if (index != -1) {
        _children[index] = updatedChild;
      }
      _clearError();
      return true;
    } catch (e) {
      _setError('Erreur lors de la mise à jour de l\'enfant: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteChild(String childId) async {
    _setLoading(true);
    try {
      await _firestoreService.deleteChild(childId);
      _children.removeWhere((child) => child.id == childId);
      _clearError();
      return true;
    } catch (e) {
      _setError('Erreur lors de la suppression de l\'enfant: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateChildStars(String childId, int starChange) async {
    try {
      final childIndex = _children.indexWhere((c) => c.id == childId);
      if (childIndex == -1) return false;

      final currentChild = _children[childIndex];
      final newStarCount = currentChild.totalStars + starChange;

      final updatedChild = currentChild.copyWith(
        totalStars: newStarCount,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateChild(updatedChild);
      _children[childIndex] = updatedChild;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur lors de la mise à jour des étoiles: ${e.toString()}');
      return false;
    }
  }

  Child? getChildById(String childId) {
    try {
      return _children.firstWhere((child) => child.id == childId);
    } catch (e) {
      return null;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}