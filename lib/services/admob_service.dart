import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ad_view_tracker.dart';

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  bool _isConfigLoaded = false;
  bool _isAdLoading = false; // Pour éviter les chargements multiples
  int _retryAttempt = 0; // Pour le backoff exponentiel
  
  String? _remoteInterstitialAdUnitId; // ID chargé depuis Firebase
  int _maxAdsPerDay = 4;

  // Obtenir l'ID d'annonce interstitielle approprié
  String get _interstitialAdUnitId {
    // Priorité 1: L'ID configuré à distance depuis Firebase
    if (_remoteInterstitialAdUnitId != null && _remoteInterstitialAdUnitId!.isNotEmpty) {
      return _remoteInterstitialAdUnitId!;
    }

    // Priorité 2: L'ID de test si en mode debug
    if (kDebugMode) {
      print('⚠️ AdMob config not found or invalid in Firebase. Using fallback TEST ad unit ID.');
      return 'ca-app-pub-3940256099942544/1033173712'; // ID de test Android
    }

    // Priorité 3: L'ID de production comme dernier recours
    print('⚠️ AdMob config not found or invalid in Firebase. Using fallback PRODUCTION ad unit ID.');
    return 'ca-app-pub-3888359147915052/1138981644'; // ID de production
  }
  
  // Initialiser le service AdMob
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    
    // Charger la configuration depuis Firebase
    await _loadAdConfigFromFirebase();
    
    // Charger la première annonce
    _loadInterstitialAd();
  }
  
  // Charger la configuration AdMob depuis Firebase
  Future<void> _loadAdConfigFromFirebase() async {
    try {
      final docRef = FirebaseFirestore.instance.collection('config').doc('admob');
      final docSnapshot = await docRef.get();
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        _remoteInterstitialAdUnitId = data['interstitialAdUnitId'] as String?;
        _maxAdsPerDay = data['maxAdsPerDay'] as int? ?? 4;
        
        if (_remoteInterstitialAdUnitId != null && _remoteInterstitialAdUnitId!.isNotEmpty) {
          print('✅ Loaded AdMob config from Firebase: $_remoteInterstitialAdUnitId');
        } else {
          print('⚠️ Invalid AdMob config in Firebase, will use fallback ID.');
        }
      } else {
        print('⚠️ AdMob config doc does not exist in Firebase, will use fallback ID.');
      }
      
      _isConfigLoaded = true;
    } catch (e) {
      print('❌ Error loading AdMob config from Firebase: $e');
      print('Will use fallback AdMob ID.');
      _isConfigLoaded = true;
    }
  }
  
  // Recharger la configuration depuis Firebase (pour les changements dynamiques)
  Future<void> reloadAdConfig() async {
    _isConfigLoaded = false;
    await _loadAdConfigFromFirebase();
    
    // Recharger l'annonce si l'ID a changé
    if (_isAdLoaded) {
      _isAdLoaded = false;
      _interstitialAd?.dispose();
      _interstitialAd = null;
      _loadInterstitialAd();
    }
  }
  
  // Charger une annonce interstitielle avec une stratégie de backoff exponentiel
  void _loadInterstitialAd() {
    if (_isAdLoading || _isAdLoaded) {
      // Si une annonce est déjà en cours de chargement ou est déjà chargée, ne rien faire.
      return;
    }

    _isAdLoading = true;
    final adUnitId = _interstitialAdUnitId;
    print('Loading ad with unit ID: $adUnitId (Attempt: ${_retryAttempt + 1})');

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print('✅ Ad was loaded successfully.');
          _interstitialAd = ad;
          _isAdLoaded = true;
          _isAdLoading = false;
          _retryAttempt = 0; // Réinitialiser le compteur de tentatives

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              print('✅ Ad showed full screen content.');
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('❌ Ad failed to show full screen content: $error');
              _isAdLoaded = false;
              _isAdLoading = false;
              ad.dispose();
              _loadInterstitialAd(); // Tenter de recharger
            },
            onAdDismissedFullScreenContent: (ad) {
              print('✅ Ad was dismissed.');
              _isAdLoaded = false;
              _isAdLoading = false;
              ad.dispose();
              _loadInterstitialAd(); // Pré-charger la prochaine annonce
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('❌ Ad failed to load: $error');
          _isAdLoaded = false;
          _isAdLoading = false;
          _retryAttempt++;

          // Calculer le délai de backoff exponentiel
          final delayInSeconds = min(30 * pow(2, _retryAttempt), 3600); // Max 1 heure
          final retryDelay = Duration(seconds: delayInSeconds.toInt());

          print('Retrying to load ad in ${retryDelay.inSeconds} seconds...');
          Timer(retryDelay, () => _loadInterstitialAd());
        },
      ),
    );
  }
  
  // Vérifier si l'utilisateur peut voir une publicité
  Future<bool> canShowAd(String userId) async {
    try {
      // Vérifier d'abord en local avec SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayKey = 'ad_views_${today.year}_${today.month}_${today.day}';
      final adViewsToday = prefs.getInt(todayKey) ?? 0;
      
      print('Ad views today from local storage: $adViewsToday (max: $_maxAdsPerDay)');
      
      if (adViewsToday >= _maxAdsPerDay) {
        print('Daily ad limit reached locally: $adViewsToday >= $_maxAdsPerDay');
        return false;
      }
      
      // Vérifier également dans Firestore pour la synchronisation entre appareils
      // Si Firestore échoue, on se fie au stockage local
      try {
        final docRef = FirebaseFirestore.instance
            .collection('ad_view_trackers')
            .doc('${userId}_${today.year}_${today.month}_${today.day}');
        
        final docSnapshot = await docRef.get();
        
        if (docSnapshot.exists) {
          final tracker = AdViewTracker.fromMap(docSnapshot.data()!);
          print('Ad views from Firestore: ${tracker.viewCount} (max: $_maxAdsPerDay)');
          return tracker.viewCount < _maxAdsPerDay;
        }
      } catch (firestoreError) {
        print('Firestore error, using local storage only: $firestoreError');
        // Continuer avec uniquement le stockage local
      }
      
      return true;
    } catch (e) {
      print('Error checking if ad can be shown: $e');
      return false;
    }
  }
  
  // Enregistrer la vue d'une publicité
  Future<void> recordAdView(String userId) async {
    try {
      final today = DateTime.now();
      final todayKey = 'ad_views_${today.year}_${today.month}_${today.day}';
      
      // Mettre à jour localement
      final prefs = await SharedPreferences.getInstance();
      final currentViews = prefs.getInt(todayKey) ?? 0;
      await prefs.setInt(todayKey, currentViews + 1);
      print('Ad view recorded locally: ${currentViews + 1}');
      
      // Mettre à jour dans Firestore (sans bloquer si erreur)
      try {
        final docRef = FirebaseFirestore.instance
            .collection('ad_view_trackers')
            .doc('${userId}_${today.year}_${today.month}_${today.day}');
        
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final docSnapshot = await transaction.get(docRef);
          
          if (docSnapshot.exists) {
            final tracker = AdViewTracker.fromMap(docSnapshot.data()!);
            transaction.update(docRef, {
              'viewCount': tracker.viewCount + 1,
            });
            print('Ad view updated in Firestore: ${tracker.viewCount + 1}');
          } else {
            final newTracker = AdViewTracker(
              userId: userId,
              date: today,
              viewCount: 1,
            );
            transaction.set(docRef, newTracker.toMap());
            print('New ad view tracker created in Firestore');
          }
        });
      } catch (firestoreError) {
        print('Firestore error when recording ad view (using local only): $firestoreError');
        // Ne pas bloquer l'opération si Firestore échoue
      }
    } catch (e) {
      print('Error recording ad view: $e');
    }
  }
  
  // Afficher une publicité interstitielle (avec vérification de limite)
  Future<bool> showInterstitialAd(String userId) async {
    if (!_isAdLoaded || _interstitialAd == null) {
      print('No ad loaded to show');
      return false;
    }
    
    // Vérifier si l'utilisateur peut voir une publicité
    final canShow = await canShowAd(userId);
    if (!canShow) {
      print('User has reached daily ad limit');
      return false;
    }
    
    try {
      print('Attempting to show PRODUCTION interstitial ad...');
      await _interstitialAd!.show();
      
      // Enregistrer la vue de la publicité
      await recordAdView(userId);
      
      return true;
    } catch (e) {
      print('Error showing interstitial ad: $e');
      return false;
    }
  }
  
  // Afficher une publicité interstitielle sans vérification de limite (pour la page "Nous aider")
  Future<bool> showInterstitialAdWithoutLimit(String userId) async {
    if (!_isAdLoaded || _interstitialAd == null) {
      print('No ad loaded to show (without limit)');
      return false;
    }
    
    try {
      print('Attempting to show interstitial ad without limit...');
      await _interstitialAd!.show();
      
      // Enregistrer la vue de la publicité
      await recordAdView(userId);
      
      return true;
    } catch (e) {
      print('Error showing interstitial ad without limit: $e');
      return false;
    }
  }
  
  // Forcer le rechargement d'une annonce (pour les tests)
  void forceLoadAd() {
    if (kDebugMode) {
      print('🔄 Forcing ad reload...');
    }
    _isAdLoaded = false;
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _loadInterstitialAd();
  }
  
  // Libérer les ressources
  void dispose() {
    _interstitialAd?.dispose();
  }
}