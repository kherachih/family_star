import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../utils/app_colors.dart';
import '../../services/admob_service.dart';

class CustomInterstitialAdScreen extends StatefulWidget {
  final String userId;
  final VoidCallback onAdClosed;

  const CustomInterstitialAdScreen({
    Key? key,
    required this.userId,
    required this.onAdClosed,
  }) : super(key: key);

  @override
  _CustomInterstitialAdScreenState createState() => _CustomInterstitialAdScreenState();
}

class _CustomInterstitialAdScreenState extends State<CustomInterstitialAdScreen> {
  bool _canCloseAd = false;
  int _secondsRemaining = 5;
  Timer? _timer;
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _loadAd();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsRemaining--;
        if (_secondsRemaining <= 0) {
          _canCloseAd = true;
          timer.cancel();
        }
      });
    });
  }

  void _loadAd() {
    // Utiliser l'ID de test pour Android en développement
    final adUnitId = 'ca-app-pub-3940256099942544/1033173712';
    
    print('Loading interstitial ad with unit ID: $adUnitId');
    
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(
        nonPersonalizedAds: false,
      ),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print('Interstitial ad loaded successfully in custom screen');
          setState(() {
            _interstitialAd = ad;
            _isAdLoaded = true;
          });
          
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              print('Interstitial ad dismissed in custom screen');
              ad.dispose();
              _closeAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('Failed to show interstitial ad in custom screen: $error');
              ad.dispose();
              _closeAd();
            },
            onAdImpression: (ad) {
              print('Interstitial ad impression recorded in custom screen');
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('Failed to load interstitial ad in custom screen: ${error.message}, code: ${error.code}');
          // Continuer même si la pub ne charge pas
          setState(() {
            _isAdLoaded = false;
          });
        },
      ),
    );
  }

  void _closeAd() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
    
    // Enregistrer la vue de la publicité
    AdMobService().recordAdView(widget.userId);
    
    widget.onAdClosed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _interstitialAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: Stack(
        children: [
          // Contenu principal
          Center(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Titre
                  Text(
                    'ads.advertisement'.tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Espace pour la publicité AdMob
                  Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _isAdLoaded && _interstitialAd != null
                        ? Center(
                            child: ElevatedButton(
                              onPressed: () async {
                                await _interstitialAd?.show();
                              },
                              child: Text('ads.show_ad'.tr()),
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.ads_click,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'ads.loading_ad'.tr(),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Message explicatif
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ads.ad_explanation'.tr(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bouton de fermeture (apparaît après 5 secondes)
          if (_canCloseAd)
            Positioned(
              top: 50,
              right: 20,
              child: GestureDetector(
                onTap: _closeAd,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          
          // Compte à rebours
          if (!_canCloseAd)
            Positioned(
              top: 50,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$_secondsRemaining',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}