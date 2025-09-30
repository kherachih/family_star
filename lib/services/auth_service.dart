import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/parent.dart';
import 'database_service.dart';

class AuthService {
  static const String _currentUserKey = 'current_user_id';
  static const String _rememberMeKey = 'remember_me';

  final DatabaseService _databaseService = DatabaseService();

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<Parent?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Vérifier si l'email existe déjà
      final existingParent = await _databaseService.getParentByEmail(email);
      if (existingParent != null) {
        throw Exception('Un compte avec cet email existe déjà');
      }

      // Créer le nouveau parent
      final parent = Parent(
        id: _generateId(),
        name: name,
        email: email,
        passwordHash: _hashPassword(password),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Sauvegarder dans la base de données
      await _databaseService.insertParent(parent);

      // Connecter automatiquement l'utilisateur
      await _saveCurrentUser(parent.id, false);

      return parent;
    } catch (e) {
      throw Exception('Erreur lors de la création du compte: ${e.toString()}');
    }
  }

  Future<Parent?> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      // Rechercher le parent par email
      final parent = await _databaseService.getParentByEmail(email);
      if (parent == null) {
        throw Exception('Email ou mot de passe incorrect');
      }

      // Vérifier le mot de passe
      if (parent.passwordHash != _hashPassword(password)) {
        throw Exception('Email ou mot de passe incorrect');
      }

      // Sauvegarder la session
      await _saveCurrentUser(parent.id, rememberMe);

      return parent;
    } catch (e) {
      throw Exception('Erreur lors de la connexion: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
    await prefs.remove(_rememberMeKey);
  }

  Future<Parent?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_currentUserKey);

      if (userId == null) return null;

      return await _databaseService.getParentById(userId);
    } catch (e) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final currentUser = await getCurrentUser();
    return currentUser != null;
  }

  Future<void> _saveCurrentUser(String userId, bool rememberMe) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, userId);
    await prefs.setBool(_rememberMeKey, rememberMe);
  }

  Future<bool> shouldRememberUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }

  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? photoUrl,
  }) async {
    try {
      final currentUser = await _databaseService.getParentById(userId);
      if (currentUser == null) {
        throw Exception('Utilisateur non trouvé');
      }

      final updatedUser = currentUser.copyWith(
        name: name ?? currentUser.name,
        photoUrl: photoUrl ?? currentUser.photoUrl,
        updatedAt: DateTime.now(),
      );

      await _databaseService.updateParent(updatedUser);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du profil: ${e.toString()}');
    }
  }

  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final parent = await _databaseService.getParentById(userId);
      if (parent == null) {
        throw Exception('Utilisateur non trouvé');
      }

      // Vérifier le mot de passe actuel
      if (parent.passwordHash != _hashPassword(currentPassword)) {
        throw Exception('Mot de passe actuel incorrect');
      }

      // Mettre à jour avec le nouveau mot de passe
      final updatedParent = parent.copyWith(
        passwordHash: _hashPassword(newPassword),
        updatedAt: DateTime.now(),
      );

      await _databaseService.updateParent(updatedParent);
    } catch (e) {
      throw Exception('Erreur lors du changement de mot de passe: ${e.toString()}');
    }
  }
}