import 'package:flutter/material.dart';
import '../../services/admob_service.dart';
import '../../utils/admob_helper.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdTestScreen extends StatefulWidget {
  const AdTestScreen({Key? key}) : super(key: key);

  @override
  _AdTestScreenState createState() => _AdTestScreenState();
}

class _AdTestScreenState extends State<AdTestScreen> {
  bool _isLoading = false;
  int _adViewsToday = 0;
  bool _canShowAd = false;

  @override
  void initState() {
    super.initState();
    _loadAdStatus();
  }

  Future<void> _loadAdStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser != null) {
      final userId = authProvider.currentUser!.id;
      
      // Vérifier le statut de la publicité
      final canShow = await AdMobService().canShowAd(userId);
      
      // Récupérer le nombre de vues aujourd'hui
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayKey = 'ad_views_${today.year}_${today.month}_${today.day}';
      final adViews = prefs.getInt(todayKey) ?? 0;
      
      setState(() {
        _canShowAd = canShow;
        _adViewsToday = adViews;
      });
    }
  }

  Future<void> _showAd() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser != null) {
      setState(() {
        _isLoading = true;
      });

      final userId = authProvider.currentUser!.id;
      
      // Afficher la publicité AdMob réelle
      await AdMobHelper.showInterstitialAd(context, userId);
      
      // Recharger le statut après un délai
      Future.delayed(const Duration(seconds: 2), () {
        _loadAdStatus();
      });

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetAdCounter() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = 'ad_views_${today.year}_${today.month}_${today.day}';
    
    await prefs.remove(todayKey);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Compteur de publicités réinitialisé'),
        backgroundColor: Colors.green,
      ),
    );
    
    _loadAdStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test des publicités'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Statut des publicités',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          _canShowAd ? Icons.check_circle : Icons.block,
                          color: _canShowAd ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _canShowAd 
                              ? 'Publicités disponibles' 
                              : 'Limite atteinte',
                          style: TextStyle(
                            color: _canShowAd ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Publicités vues aujourd\'hui: $_adViewsToday/2',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _canShowAd && !_isLoading ? _showAd : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Afficher une publicité',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _resetAdCounter,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Réinitialiser le compteur (test)',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Limite de 2 publicités par jour\n'
                      '• Les publicités s\'affichent en plein écran\n'
                      '• Bouton de fermeture après 5 secondes\n'
                      '• Message explicatif en bas de l\'écran',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}