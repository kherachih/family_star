import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/parent.dart' as app_models;
import 'firestore_service.dart';

class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }


  Future<app_models.Parent?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Vérifier si l'email existe déjà
      final existingParent = await _firestoreService.getParentByEmail(email);
      if (existingParent != null) {
        throw Exception('Un compte avec cet email existe déjà');
      }

      // Créer le compte Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Erreur lors de la création du compte');
      }

      // Mettre à jour le profil utilisateur
      await credential.user!.updateDisplayName(name);

      // Créer le parent dans Firestore
      final parent = app_models.Parent(
        id: credential.user!.uid,
        name: name,
        email: email,
        passwordHash: _hashPassword(password),
        photoUrl: credential.user!.photoURL,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.createParent(parent);

      return parent;
    } on FirebaseAuthException catch (e) {
      String message = 'Erreur lors de la création du compte';
      switch (e.code) {
        case 'weak-password':
          message = 'Le mot de passe est trop faible';
          break;
        case 'email-already-in-use':
          message = 'Un compte avec cet email existe déjà';
          break;
        case 'invalid-email':
          message = 'Email invalide';
          break;
      }
      throw Exception(message);
    } catch (e) {
      throw Exception('Erreur lors de la création du compte: ${e.toString()}');
    }
  }

  Future<app_models.Parent?> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      // Connecter avec Firebase Auth
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Email ou mot de passe incorrect');
      }

      // Récupérer les données du parent depuis Firestore
      final parent = await _firestoreService.getParentById(credential.user!.uid);
      if (parent == null) {
        throw Exception('Utilisateur non trouvé');
      }

      return parent;
    } on FirebaseAuthException catch (e) {
      String message = 'Email ou mot de passe incorrect';
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Email ou mot de passe incorrect';
          break;
        case 'too-many-requests':
          message = 'Trop de tentatives. Réessayez plus tard';
          break;
        case 'user-disabled':
          message = 'Ce compte a été désactivé';
          break;
      }
      throw Exception(message);
    } catch (e) {
      throw Exception('Erreur lors de la connexion: ${e.toString()}');
    }
  }

  Future<app_models.Parent?> signInWithGoogle() async {
    try {
      // Démarrer le processus de connexion Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // L'utilisateur a annulé la connexion
      }

      // Obtenir les détails d'authentification
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Créer une nouvelle credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Se connecter à Firebase avec la credential Google
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw Exception('Erreur lors de la connexion Google');
      }

      final user = userCredential.user!;

      // Vérifier si le parent existe déjà dans Firestore
      app_models.Parent? parent = await _firestoreService.getParentById(user.uid);

      if (parent == null) {
        // Créer un nouveau parent
        parent = app_models.Parent(
          id: user.uid,
          name: user.displayName ?? 'Utilisateur Google',
          email: user.email!,
          passwordHash: '', // Pas de mot de passe pour Google Sign-In
          photoUrl: user.photoURL,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestoreService.createParent(parent);
      } else {
        // Mettre à jour les informations si nécessaire
        final updatedParent = parent.copyWith(
          photoUrl: user.photoURL ?? parent.photoUrl,
          updatedAt: DateTime.now(),
        );

        if (updatedParent.photoUrl != parent.photoUrl) {
          await _firestoreService.updateParent(updatedParent);
          parent = updatedParent;
        }
      }

      return parent;
    } catch (e) {
      throw Exception('Erreur lors de la connexion Google: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      throw Exception('Erreur lors de la déconnexion: ${e.toString()}');
    }
  }

  Future<app_models.Parent?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      return await _firestoreService.getParentById(user.uid);
    } catch (e) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }

  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? photoUrl,
  }) async {
    try {
      final currentUser = await _firestoreService.getParentById(userId);
      if (currentUser == null) {
        throw Exception('Utilisateur non trouvé');
      }

      // Mettre à jour Firebase Auth si nécessaire
      final user = _auth.currentUser;
      if (user != null && name != null) {
        await user.updateDisplayName(name);
      }

      // Mettre à jour Firestore
      final updatedUser = currentUser.copyWith(
        name: name ?? currentUser.name,
        photoUrl: photoUrl ?? currentUser.photoUrl,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateParent(updatedUser);
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
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Ré-authentifier l'utilisateur
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Changer le mot de passe
      await user.updatePassword(newPassword);

      // Mettre à jour le hash dans Firestore
      final parent = await _firestoreService.getParentById(userId);
      if (parent != null) {
        final updatedParent = parent.copyWith(
          passwordHash: _hashPassword(newPassword),
          updatedAt: DateTime.now(),
        );
        await _firestoreService.updateParent(updatedParent);
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Erreur lors du changement de mot de passe';
      switch (e.code) {
        case 'wrong-password':
          message = 'Mot de passe actuel incorrect';
          break;
        case 'weak-password':
          message = 'Le nouveau mot de passe est trop faible';
          break;
        case 'requires-recent-login':
          message = 'Reconnectez-vous avant de changer votre mot de passe';
          break;
      }
      throw Exception(message);
    } catch (e) {
      throw Exception('Erreur lors du changement de mot de passe: ${e.toString()}');
    }
  }

  // Stream pour écouter les changements d'état d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}