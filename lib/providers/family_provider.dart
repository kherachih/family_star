import 'package:flutter/foundation.dart';
import '../models/family.dart';
import '../models/parent.dart';
import '../services/firestore_service.dart';

class FamilyProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  Family? _currentFamily;
  List<Family> _families = [];
  List<Parent> _familyParents = [];
  bool _isLoading = false;
  String? _errorMessage;

  Family? get currentFamily => _currentFamily;
  List<Family> get families => _families;
  List<Parent> get familyParents => _familyParents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadFamiliesByParentId(String parentId) async {
    _setLoading(true);
    try {
      _families = await _firestoreService.getFamiliesByParentId(parentId);
      if (_families.isNotEmpty) {
        _currentFamily = _families.first; // Prendre la première famille par défaut
      } else {
        // Vérifier si le parent a des enfants existants
        final children = await _firestoreService.getChildrenByFamilyOrParentId(parentId);
        if (children.isNotEmpty) {
          // Créer une famille automatiquement pour les parents avec des enfants existants
          print('👨‍👩‍👧‍👦 Création automatique d\'une famille pour le parent avec enfants existants');
          final parent = await _firestoreService.getParentById(parentId);
          if (parent != null) {
            final newFamily = await createFamilyForParent(parentId, parent.name);
            
            // Mettre à jour tous les enfants existants pour les lier à la nouvelle famille
            for (final child in children) {
              print('🔄 Migration de l\'enfant ${child.name} vers la famille ${newFamily.id}');
              
              // Mettre à jour l'enfant avec le familyId
              final updatedChild = child.copyWith(
                familyId: newFamily.id,
                updatedAt: DateTime.now(),
              );
              await _firestoreService.updateChild(updatedChild);
              
              // Ajouter l'enfant à la famille
              await addChildToFamily(newFamily.id, child.id);
            }
            
            print('✅ Migration terminée: ${children.length} enfant(s) migré(s) vers la famille ${newFamily.id}');
          }
        }
      }
      _clearError();
    } catch (e) {
      _setError('Erreur lors du chargement des familles: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadFamilyById(String familyId) async {
    _setLoading(true);
    try {
      _currentFamily = await _firestoreService.getFamilyById(familyId);
      _clearError();
    } catch (e) {
      _setError('Erreur lors du chargement de la famille: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<Family> createFamilyForParent(String parentId, String parentName) async {
    _setLoading(true);
    try {
      final family = await _firestoreService.createFamilyForParent(parentId, parentName);
      _families.add(family);
      _currentFamily = family;
      _clearError();
      notifyListeners();
      return family;
    } catch (e) {
      _setError('Erreur lors de la création de la famille: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addParentToFamily(String familyId, String parentId) async {
    _setLoading(true);
    try {
      await _firestoreService.addParentToFamily(familyId, parentId);
      
      // Mettre à jour la famille locale
      if (_currentFamily?.id == familyId) {
        _currentFamily = _currentFamily!.addParent(parentId);
        notifyListeners();
      }
      
      // Mettre à jour la liste des familles
      final familyIndex = _families.indexWhere((f) => f.id == familyId);
      if (familyIndex != -1) {
        _families[familyIndex] = _families[familyIndex].addParent(parentId);
      }
      
      _clearError();
      return true;
    } catch (e) {
      _setError('Erreur lors de l\'ajout du parent à la famille: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> removeParentFromFamily(String familyId, String parentId) async {
    _setLoading(true);
    try {
      await _firestoreService.removeParentFromFamily(familyId, parentId);
      
      // Mettre à jour la famille locale
      if (_currentFamily?.id == familyId) {
        _currentFamily = _currentFamily!.removeParent(parentId);
        notifyListeners();
      }
      
      // Mettre à jour la liste des familles
      final familyIndex = _families.indexWhere((f) => f.id == familyId);
      if (familyIndex != -1) {
        _families[familyIndex] = _families[familyIndex].removeParent(parentId);
      }
      
      _clearError();
      return true;
    } catch (e) {
      _setError('Erreur lors du retrait du parent de la famille: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addChildToFamily(String familyId, String childId) async {
    _setLoading(true);
    try {
      await _firestoreService.addChildToFamily(familyId, childId);
      
      // Mettre à jour la famille locale
      if (_currentFamily?.id == familyId) {
        _currentFamily = _currentFamily!.addChild(childId);
        notifyListeners();
      }
      
      // Mettre à jour la liste des familles
      final familyIndex = _families.indexWhere((f) => f.id == familyId);
      if (familyIndex != -1) {
        _families[familyIndex] = _families[familyIndex].addChild(childId);
      }
      
      _clearError();
      return true;
    } catch (e) {
      _setError('Erreur lors de l\'ajout de l\'enfant à la famille: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> removeChildFromFamily(String familyId, String childId) async {
    _setLoading(true);
    try {
      await _firestoreService.removeChildFromFamily(familyId, childId);
      
      // Mettre à jour la famille locale
      if (_currentFamily?.id == familyId) {
        _currentFamily = _currentFamily!.removeChild(childId);
        notifyListeners();
      }
      
      // Mettre à jour la liste des familles
      final familyIndex = _families.indexWhere((f) => f.id == familyId);
      if (familyIndex != -1) {
        _families[familyIndex] = _families[familyIndex].removeChild(childId);
      }
      
      _clearError();
      return true;
    } catch (e) {
      _setError('Erreur lors du retrait de l\'enfant de la famille: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateFamilyName(String familyId, String newName) async {
    _setLoading(true);
    try {
      if (_currentFamily?.id == familyId) {
        _currentFamily = _currentFamily!.copyWith(
          name: newName,
          updatedAt: DateTime.now(),
        );
        await _firestoreService.updateFamily(_currentFamily!);
        
        // Mettre à jour la liste des familles
        final familyIndex = _families.indexWhere((f) => f.id == familyId);
        if (familyIndex != -1) {
          _families[familyIndex] = _currentFamily!;
        }
        
        notifyListeners();
      }
      
      _clearError();
      return true;
    } catch (e) {
      _setError('Erreur lors de la mise à jour du nom de la famille: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void setCurrentFamily(Family family) {
    _currentFamily = family;
    notifyListeners();
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