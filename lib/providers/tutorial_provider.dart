import 'package:flutter/foundation.dart';
import '../models/tutorial_state.dart';
import '../services/firestore_service.dart';

class TutorialProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  TutorialState? _tutorialState;
  bool _isLoading = false;
  String? _errorMessage;

  TutorialState? get tutorialState => _tutorialState;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  bool get needsTutorial => _tutorialState != null && !_tutorialState!.hasCompletedTutorial;
  int get currentStep => _tutorialState?.currentStep ?? 0;
  double get progress => _tutorialState?.progress ?? 0.0;
  String get stepTitle => _tutorialState?.stepTitle ?? '';
  String get stepDescription => _tutorialState?.stepDescription ?? '';

  Future<void> initializeTutorialState(String parentId) async {
    _setLoading(true);
    try {
      _tutorialState = await _firestoreService.initializeTutorialStateForParent(parentId);
      _clearError();
    } catch (e) {
      _setError('Erreur lors de l\'initialisation du tutoriel: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadTutorialState(String parentId) async {
    _setLoading(true);
    try {
      _tutorialState = await _firestoreService.getTutorialStateByParentId(parentId);
      _clearError();
    } catch (e) {
      _setError('Erreur lors du chargement du tutoriel: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> completeCurrentStep() async {
    if (_tutorialState == null) return;
    
    _setLoading(true);
    try {
      final updatedState = _tutorialState!.markStepCompleted(_tutorialState!.currentStep);
      await _firestoreService.updateTutorialState(updatedState);
      _tutorialState = updatedState;
      _clearError();
    } catch (e) {
      _setError('Erreur lors de la mise à jour du tutoriel: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  void setCurrentStep(int step) {
    if (_tutorialState == null) return;
    
    _tutorialState = _tutorialState!.copyWith(
      currentStep: step,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  Future<void> skipTutorial() async {
    if (_tutorialState == null) return;
    
    _setLoading(true);
    try {
      final completedState = _tutorialState!.copyWith(
        hasCompletedTutorial: true,
        currentStep: 5,
        updatedAt: DateTime.now(),
      );
      await _firestoreService.updateTutorialState(completedState);
      _tutorialState = completedState;
      _clearError();
    } catch (e) {
      _setError('Erreur lors du saut du tutoriel: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetTutorial() async {
    if (_tutorialState == null) return;
    
    _setLoading(true);
    try {
      final resetState = TutorialState(
        id: _tutorialState!.id,
        parentId: _tutorialState!.parentId,
        hasCompletedTutorial: false,
        currentStep: 0,
        hasCompletedIntroduction: false,
        hasAddedChildren: false,
        hasConfiguredTasks: false,
        hasConfiguredRewards: false,
        hasConfiguredSanctions: false,
        createdAt: _tutorialState!.createdAt,
        updatedAt: DateTime.now(),
      );
      await _firestoreService.updateTutorialState(resetState);
      _tutorialState = resetState;
      _clearError();
    } catch (e) {
      _setError('Erreur lors de la réinitialisation du tutoriel: ${e.toString()}');
    } finally {
      _setLoading(false);
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
}