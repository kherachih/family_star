import 'package:flutter/foundation.dart';
import '../models/parent.dart';
import '../services/firebase_auth_service.dart';
import 'family_provider.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();
  Parent? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  Parent? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  Future<void> initializeAuth() async {
    _setLoading(true);
    try {
      _currentUser = await _authService.getCurrentUser();
      _clearError();
    } catch (e) {
      _setError('Erreur d\'initialisation: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    FamilyProvider? familyProvider,
  }) async {
    _setLoading(true);
    try {
      _currentUser = await _authService.register(
        name: name,
        email: email,
        password: password,
      );
      
      // Créer une famille pour le nouveau parent
      if (_currentUser != null && familyProvider != null) {
        await familyProvider.createFamilyForParent(_currentUser!.id, _currentUser!.name);
      }
      
      _clearError();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login({
    required String email,
    required String password,
    bool rememberMe = false,
    FamilyProvider? familyProvider,
  }) async {
    _setLoading(true);
    try {
      _currentUser = await _authService.login(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );
      
      // Charger les familles du parent
      if (_currentUser != null && familyProvider != null) {
        await familyProvider.loadFamiliesByParentId(_currentUser!.id);
        
        // Si le parent n'a pas de famille, en créer une automatiquement
        if (familyProvider.currentFamily == null) {
          await familyProvider.createFamilyForParent(_currentUser!.id, _currentUser!.name);
        }
      }
      
      _clearError();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
      _currentUser = null;
      _clearError();
    } catch (e) {
      _setError('Erreur lors de la déconnexion: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? photoUrl,
  }) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    try {
      await _authService.updateUserProfile(
        userId: _currentUser!.id,
        name: name,
        photoUrl: photoUrl,
      );

      // Recharger les données utilisateur
      _currentUser = await _authService.getCurrentUser();
      _clearError();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfilePhoto(String photoUrl) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    try {
      await _authService.updateUserProfile(
        userId: _currentUser!.id,
        photoUrl: photoUrl,
      );

      // Recharger les données utilisateur
      _currentUser = await _authService.getCurrentUser();
      _clearError();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    try {
      await _authService.changePassword(
        userId: _currentUser!.id,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _clearError();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
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

  Future<bool> signInWithGoogle({FamilyProvider? familyProvider}) async {
    _setLoading(true);
    try {
      _currentUser = await _authService.signInWithGoogle();
      if (_currentUser != null) {
        // Charger les familles du parent
        if (familyProvider != null) {
          await familyProvider.loadFamiliesByParentId(_currentUser!.id);
          
          // Si le parent n'a pas de famille, en créer une automatiquement
          if (familyProvider.currentFamily == null) {
            await familyProvider.createFamilyForParent(_currentUser!.id, _currentUser!.name);
          }
        }
        
        _clearError();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _clearError();
  }
}