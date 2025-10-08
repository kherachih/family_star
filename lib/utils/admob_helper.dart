import 'package:flutter/material.dart';
import '../services/admob_service.dart';

class AdMobHelper {
  // Afficher une publicité avec vérification de limite (pour les autres parties de l'app)
  static Future<bool> showInterstitialAd(BuildContext context, String userId) async {
    print('Checking if ad can be shown for user: $userId');
    
    // Vérifier si l'utilisateur peut voir une publicité
    final canShowAd = await AdMobService().canShowAd(userId);
    
    print('Can show ad: $canShowAd');
    
    if (canShowAd) {
      print('Showing interstitial ad');
      final success = await AdMobService().showInterstitialAd(userId);
      
      if (success) {
        // La publicité a été affichée avec succès
        // Attendre un peu que la pub se ferme puis afficher le popup de remerciement
        Future.delayed(const Duration(seconds: 1), () {
          if (context.mounted) {
            _showThankYouPopup(context);
          }
        });
        return true;
      } else {
        print('Failed to show interstitial ad');
        // Afficher un message à l'utilisateur si la publicité n'a pas pu être chargée
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La publicité n\'a pas pu être chargée. Veuillez réessayer plus tard.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return false;
      }
    } else {
      print('Ad cannot be shown - limit reached or error');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Limite de publicités atteinte pour aujourd\'hui.'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    }
    
    return false;
  }
  
  // Afficher une publicité sans vérification de limite (pour la page "Nous aider")
  static Future<bool> showInterstitialAdWithoutLimit(BuildContext context, String userId) async {
    print('Showing interstitial ad without limit for user: $userId');
    
    final success = await AdMobService().showInterstitialAdWithoutLimit(userId);
    
    if (success) {
      // La publicité a été affichée avec succès
      // Attendre un peu que la pub se ferme puis afficher le popup de remerciement
      Future.delayed(const Duration(seconds: 1), () {
        if (context.mounted) {
          _showThankYouPopup(context);
        }
      });
      return true;
    } else {
      print('Failed to show interstitial ad without limit');
      // Afficher un message à l'utilisateur si la publicité n'a pas pu être chargée
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La publicité n\'a pas pu être chargée. Veuillez réessayer plus tard.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return false;
    }
  }

  static void _showThankYouPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.pink.withOpacity(0.1),
                  Colors.purple.withOpacity(0.1),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône de cœur animé
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    size: 40,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Titre
                const Text(
                  'Merci pour votre soutien !',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                // Message
                const Text(
                  'Votre aide nous permet de continuer à développer Family Star pour toute la famille.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                const Text(
                  'Chaque publicité regardée fait une réelle différence !',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Bouton
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Continuer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}