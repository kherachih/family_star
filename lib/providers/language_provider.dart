import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  static const String _languageKey = 'selected_language';
  Locale _currentLocale = const Locale('en'); // Langue par défaut
  bool _isInitialized = false;
  
  Locale get currentLocale => _currentLocale;
  
  // Liste des langues supportées
  static final List<Locale> supportedLocales = [
    const Locale('fr'), // Français
    const Locale('en'), // Anglais
    const Locale('ar'), // Arabe
    const Locale('es'), // Espagnol
    const Locale('de'), // Allemand
    const Locale('it'), // Italien
    const Locale('pt'), // Portugais
    const Locale('ja'), // Japonais
    const Locale('ko'), // Coréen
  ];
  
  // Noms des langues pour l'affichage
  static final Map<String, String> languageNames = {
    'fr': 'Français',
    'en': 'English',
    'ar': 'العربية',
    'es': 'Español',
    'de': 'Deutsch',
    'it': 'Italiano',
    'pt': 'Português',
    'ja': '日本語',
    'ko': '한국어',
  };
  
  // Initialiser le provider et charger la langue sauvegardée
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguageCode = prefs.getString(_languageKey);
      
      if (savedLanguageCode != null) {
        // Vérifier si la langue sauvegardée est supportée
        final savedLocale = supportedLocales.firstWhere(
          (locale) => locale.languageCode == savedLanguageCode,
          orElse: () => const Locale('en'), // Langue par défaut si non trouvée
        );
        
        _currentLocale = savedLocale;
      }
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      // En cas d'erreur, conserver la langue par défaut
      debugPrint('Erreur lors du chargement de la langue: $e');
      _isInitialized = true;
    }
  }
  
  // Changer la langue
  Future<void> changeLanguage(String languageCode, {BuildContext? context}) async {
    try {
      // Vérifier si la langue est supportée
      final newLocale = supportedLocales.firstWhere(
        (locale) => locale.languageCode == languageCode,
        orElse: () => _currentLocale, // Conserver la langue actuelle si non trouvée
      );
      
      // Ne faire le changement que si la langue est différente
      if (_currentLocale.languageCode == newLocale.languageCode) {
        return; // Pas besoin de changer si c'est la même langue
      }
      
      // Mettre à jour la locale dans EasyLocalization si le contexte est fourni
      if (context != null) {
        await context.setLocale(newLocale);
      }
      
      // Mettre à jour la locale actuelle
      _currentLocale = newLocale;
      
      // Sauvegarder la préférence
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      
      // Forcer la notification pour reconstruire l'interface
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors du changement de langue: $e');
    }
  }
  
  // Obtenir le nom de la langue actuelle
  String get currentLanguageName {
    return languageNames[_currentLocale.languageCode] ?? 'English';
  }
  
  // Obtenir le code de langue actuel
  String get currentLanguageCode {
    return _currentLocale.languageCode;
  }
  
  // Vérifier c'est la première utilisation (pas de langue sauvegardée)
  Future<bool> isFirstTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !prefs.containsKey(_languageKey);
    } catch (e) {
      debugPrint('Erreur lors de la vérification de première utilisation: $e');
      return false;
    }
  }
  
  // Marquer que l'utilisateur a choisi une langue (plus première fois)
  Future<void> setLanguageChosen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('language_chosen', true);
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde du choix de langue: $e');
    }
  }
  
  // Vérifier si l'utilisateur a déjà choisi une langue
  Future<bool> hasChosenLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('language_chosen') ?? false;
    } catch (e) {
      debugPrint('Erreur lors de la vérification du choix de langue: $e');
      return false;
    }
  }
}