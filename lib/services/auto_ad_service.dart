import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../providers/auth_provider.dart';
import 'admob_service.dart';
import '../utils/admob_helper.dart';

class AutoAdService {
  static final AutoAdService _instance = AutoAdService._internal();
  factory AutoAdService() => _instance;
  AutoAdService._internal();

  Timer? _navigationTimer;
  int _navigationCount = 0;
  final int _navigationThreshold = 1; // Réduit à 1 navigation pour les tests
  final int _minSecondsBetweenAds = 30; // Réduit à 30 secondes pour les tests
  DateTime? _lastAdShownTime;
  bool _isInitialized = false;
  AuthProvider? _authProvider;

  // Initialiser le service
  void initialize(AuthProvider authProvider) {
    _authProvider = authProvider;
    _isInitialized = true;
    if (kDebugMode) {
      print('AutoAdService initialized with AuthProvider');
    }
  }

  // Appeler cette méthode lors de la navigation entre les écrans
  void onScreenChanged(String screenName, {bool showAdImmediately = false}) {
    if (!_isInitialized) {
      if (kDebugMode) {
        print('AutoAdService not initialized, skipping navigation tracking');
      }
      return;
    }
    
    _navigationCount++;
    
    if (kDebugMode) {
      print('Navigation to: $screenName (count: $_navigationCount)');
    }

    // Vérifier si on doit afficher une pub
    if (showAdImmediately || _shouldShowAd()) {
      _showAdWithDelay();
    }

    // Redémarrer le timer
    _restartNavigationTimer();
  }

  // Vérifier si une pub doit être affichée
  bool _shouldShowAd() {
    if (kDebugMode) {
      print('Checking if ad should be shown:');
      print('  - Navigation count: $_navigationCount (threshold: $_navigationThreshold)');
      print('  - Last ad shown: $_lastAdShownTime');
    }
    
    // Vérifier si le nombre de navigations est suffisant
    if (_navigationCount < _navigationThreshold) {
      if (kDebugMode) {
        print('  - Not enough navigations yet');
      }
      return false;
    }

    // Vérifier si le temps minimum s'est écoulé depuis la dernière pub
    if (_lastAdShownTime != null) {
      final timeSinceLastAd = DateTime.now().difference(_lastAdShownTime!);
      if (timeSinceLastAd.inSeconds < _minSecondsBetweenAds) {
        if (kDebugMode) {
          print('  - Too soon since last ad: ${timeSinceLastAd.inSeconds}s < $_minSecondsBetweenAds}s');
        }
        return false;
      }
    }

    if (kDebugMode) {
      print('  - Ad should be shown!');
    }
    return true;
  }

  // Afficher une pub après un délai aléatoire
  void _showAdWithDelay() {
    final randomDelay = Random().nextInt(3) + 2; // Délai aléatoire entre 2 et 5 secondes pour les tests
    
    if (kDebugMode) {
      print('Will show ad in $randomDelay seconds');
    }

    Timer(Duration(seconds: randomDelay), () {
      _tryShowAd();
    });
  }

  // Essayer d'afficher une pub
  Future<void> _tryShowAd() async {
    try {
      if (_authProvider == null) {
        if (kDebugMode) {
          print('❌ No AuthProvider available, skipping ad');
        }
        return;
      }
      
      // Obtenir l'utilisateur actuel via le AuthProvider stocké
      if (_authProvider!.currentUser == null) {
        if (kDebugMode) {
          print('❌ No user logged in, skipping ad');
        }
        return;
      }

      final userId = _authProvider!.currentUser!.id;

      if (kDebugMode) {
        print('🔄 Trying to show auto ad for user: $userId');
      }

      // Vérifier si l'utilisateur peut voir une pub
      final canShow = await AdMobService().canShowAd(userId);
      if (!canShow) {
        if (kDebugMode) {
          print('❌ User has reached daily ad limit');
        }
        return;
      }

      // Afficher la pub
      final success = await AdMobService().showInterstitialAd(userId);
      if (success) {
        _lastAdShownTime = DateTime.now();
        _navigationCount = 0; // Réinitialiser le compteur
        
        if (kDebugMode) {
          print('✅ Auto ad shown successfully');
        }
      } else {
        if (kDebugMode) {
          print('❌ Failed to show auto ad - trying to force load a new ad');
          // En mode debug, essayer de forcer le chargement d'une nouvelle pub
          AdMobService().forceLoadAd();
          // Réessayer après un court délai
          Timer(const Duration(seconds: 3), () async {
            final retrySuccess = await AdMobService().showInterstitialAd(userId);
            if (retrySuccess) {
              _lastAdShownTime = DateTime.now();
              _navigationCount = 0;
              print('✅ Auto ad shown successfully on retry');
            } else {
              print('❌ Still failed to show auto ad after retry');
            }
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in auto ad service: $e');
      }
    }
  }

  // Redémarrer le timer de navigation
  void _restartNavigationTimer() {
    _navigationTimer?.cancel();
    
    // Si aucune navigation après 30 secondes, réinitialiser le compteur
    _navigationTimer = Timer(const Duration(seconds: 30), () {
      _navigationCount = 0;
      if (kDebugMode) {
        print('Navigation count reset due to inactivity');
      }
    });
  }

  // Libérer les ressources
  void dispose() {
    _navigationTimer?.cancel();
    if (kDebugMode) {
      print('AutoAdService disposed');
    }
  }
}