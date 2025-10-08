import 'package:flutter/material.dart';
import '../screens/ads/simple_ad_screen.dart';
import '../services/admob_service.dart';

class AdHelper {
  static void showCustomInterstitialAd(BuildContext context, String userId) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return SimpleAdScreen(
            userId: userId,
            onAdClosed: () {
              Navigator.of(context).pop();
            },
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        barrierDismissible: false,
        opaque: false,
      ),
    );
  }

  static Future<bool> showAdIfAvailable(BuildContext context, String userId) async {
    print('Checking if ad can be shown for user: $userId');
    
    // Vérifier si l'utilisateur peut voir une publicité
    final canShowAd = await AdMobService().canShowAd(userId);
    
    print('Can show ad: $canShowAd');
    
    if (canShowAd) {
      print('Showing custom interstitial ad');
      showCustomInterstitialAd(context, userId);
      return true;
    } else {
      print('Ad cannot be shown - limit reached or error');
    }
    
    return false;
  }
}