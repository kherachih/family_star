import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admob_config.dart';

class AdMobConfigService {
  static final AdMobConfigService _instance = AdMobConfigService._internal();
  factory AdMobConfigService() => _instance;
  AdMobConfigService._internal();

  final CollectionReference _configCollection = 
      FirebaseFirestore.instance.collection('config');

  // Obtenir la configuration AdMob
  Future<AdMobConfig?> getAdMobConfig() async {
    try {
      final docSnapshot = await _configCollection.doc('admob').get();
      
      if (docSnapshot.exists) {
        return AdMobConfig.fromMap(docSnapshot.data() as Map<String, dynamic>);
      }
      
      return null;
    } catch (e) {
      print('Error getting AdMob config: $e');
      return null;
    }
  }

  // Mettre à jour la configuration AdMob
  Future<bool> updateAdMobConfig({
    required String interstitialAdUnitId,
    required int maxAdsPerDay,
  }) async {
    try {
      final config = AdMobConfig(
        interstitialAdUnitId: interstitialAdUnitId,
        maxAdsPerDay: maxAdsPerDay,
        updatedAt: DateTime.now(),
      );

      await _configCollection.doc('admob').set(config.toMap());
      print('AdMob config updated successfully');
      return true;
    } catch (e) {
      print('Error updating AdMob config: $e');
      return false;
    }
  }

  // Créer la configuration par défaut si elle n'existe pas
  Future<void> createDefaultConfig() async {
    try {
      final existingConfig = await getAdMobConfig();
      
      if (existingConfig == null) {
        // Utiliser l'ID de test par défaut pour la première configuration
        final defaultConfig = AdMobConfig(
          interstitialAdUnitId: 'ca-app-pub-3940256099942544/1033173712', // ID de test Android
          maxAdsPerDay: 4,
          updatedAt: DateTime.now(),
        );

        await _configCollection.doc('admob').set(defaultConfig.toMap());
        print('Default AdMob config created with TEST ID');
      }
    } catch (e) {
      print('Error creating default AdMob config: $e');
    }
  }

  // Créer une configuration avec les IDs de test
  Future<void> createTestConfig() async {
    try {
      final testConfig = AdMobConfig(
        interstitialAdUnitId: 'ca-app-pub-3940256099942544/1033173712', // ID de test Android
        maxAdsPerDay: 4,
        updatedAt: DateTime.now(),
      );

      await _configCollection.doc('admob').set(testConfig.toMap());
      print('Test AdMob config created');
    } catch (e) {
      print('Error creating test AdMob config: $e');
    }
  }

  // Créer une configuration avec les IDs de production
  Future<void> createProductionConfig() async {
    try {
      final productionConfig = AdMobConfig(
        interstitialAdUnitId: 'ca-app-pub-3888359147915052/1138981644', // Votre ID de production
        maxAdsPerDay: 4,
        updatedAt: DateTime.now(),
      );

      await _configCollection.doc('admob').set(productionConfig.toMap());
      print('Production AdMob config created');
    } catch (e) {
      print('Error creating production AdMob config: $e');
    }
  }

  // Supprimer la configuration (pour les tests)
  Future<bool> deleteConfig() async {
    try {
      await _configCollection.doc('admob').delete();
      print('AdMob config deleted');
      return true;
    } catch (e) {
      print('Error deleting AdMob config: $e');
      return false;
    }
  }
}