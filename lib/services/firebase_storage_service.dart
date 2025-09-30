import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Compresse et upload une image vers Firebase Storage
  /// Retourne l'URL de téléchargement ou null en cas d'erreur
  static Future<String?> uploadChildPhoto({
    required String childId,
    required String imagePath,
  }) async {
    try {
      // Lire le fichier image
      final File imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw Exception('Le fichier image n\'existe pas');
      }

      // Lire les bytes de l'image
      final Uint8List originalBytes = await imageFile.readAsBytes();

      // Compresser l'image
      final Uint8List compressedBytes = await _compressImage(originalBytes);

      // Créer une référence unique pour l'image
      final String fileName = 'child_$childId.jpg';
      final Reference ref = _storage.ref().child('children').child(fileName);

      // Metadata pour optimiser le stockage
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'childId': childId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Upload l'image compressée
      final UploadTask uploadTask = ref.putData(compressedBytes, metadata);
      final TaskSnapshot snapshot = await uploadTask;

      // Obtenir l'URL de téléchargement
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('Image uploadée avec succès: $downloadUrl');
      return downloadUrl;

    } catch (e) {
      debugPrint('Erreur lors de l\'upload de l\'image: $e');
      return null;
    }
  }

  /// Compresse une image en réduisant sa taille et qualité
  static Future<Uint8List> _compressImage(Uint8List originalBytes) async {
    try {
      // Décoder l'image
      img.Image? image = img.decodeImage(originalBytes);
      if (image == null) {
        throw Exception('Impossible de décoder l\'image');
      }

      // Redimensionner l'image (max 400x400)
      const int maxSize = 400;
      if (image.width > maxSize || image.height > maxSize) {
        // Calculer les nouvelles dimensions en gardant le ratio
        double ratio = image.width / image.height;
        int newWidth, newHeight;

        if (image.width > image.height) {
          newWidth = maxSize;
          newHeight = (maxSize / ratio).round();
        } else {
          newHeight = maxSize;
          newWidth = (maxSize * ratio).round();
        }

        image = img.copyResize(image, width: newWidth, height: newHeight);
      }

      // Encoder en JPEG avec compression (qualité 85%)
      final Uint8List compressedBytes = Uint8List.fromList(
        img.encodeJpg(image, quality: 85)
      );

      debugPrint('Image compressée: ${originalBytes.length} -> ${compressedBytes.length} bytes');
      return compressedBytes;

    } catch (e) {
      debugPrint('Erreur lors de la compression: $e');
      // En cas d'erreur, retourner l'image originale
      return originalBytes;
    }
  }

  /// Supprime l'image d'un enfant
  static Future<bool> deleteChildPhoto(String childId) async {
    try {
      final String fileName = 'child_$childId.jpg';
      final Reference ref = _storage.ref().child('children').child(fileName);
      await ref.delete();
      debugPrint('Image supprimée avec succès pour l\'enfant: $childId');
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la suppression de l\'image: $e');
      return false;
    }
  }

  /// Met à jour la photo d'un enfant (supprime l'ancienne et upload la nouvelle)
  static Future<String?> updateChildPhoto({
    required String childId,
    required String newImagePath,
  }) async {
    try {
      // Supprimer l'ancienne image (optionnel, ne pas échouer si elle n'existe pas)
      await deleteChildPhoto(childId);

      // Upload la nouvelle image
      return await uploadChildPhoto(
        childId: childId,
        imagePath: newImagePath,
      );
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de l\'image: $e');
      return null;
    }
  }

  /// Obtient la taille totale utilisée par les images d'enfants
  static Future<int> getTotalStorageUsed() async {
    try {
      final ListResult result = await _storage.ref().child('children').listAll();
      int totalSize = 0;

      for (Reference ref in result.items) {
        final FullMetadata metadata = await ref.getMetadata();
        totalSize += metadata.size ?? 0;
      }

      return totalSize;
    } catch (e) {
      debugPrint('Erreur lors du calcul de l\'espace utilisé: $e');
      return 0;
    }
  }
}