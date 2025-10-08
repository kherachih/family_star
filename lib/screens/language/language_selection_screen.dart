import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/app_colors.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkGradientHero
                : const [
                    Color(0xFFFF6B6B),
                    Color(0xFFFFD93D),
                  ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/logo.png',
                  height: 150,
                ),
                const SizedBox(height: 32),

                // Titre
                Text(
                  'language.title'.tr(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Sous-titre
                Text(
                  'language.first_time_language'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Liste des langues
                Expanded(
                  child: Consumer<LanguageProvider>(
                    builder: (context, languageProvider, child) {
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: LanguageProvider.supportedLocales.length,
                        itemBuilder: (context, index) {
                          final locale = LanguageProvider.supportedLocales[index];
                          final languageCode = locale.languageCode;
                          final languageName = LanguageProvider.languageNames[languageCode] ?? languageCode;
                          final isSelected = languageProvider.currentLanguageCode == languageCode;

                          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDarkMode ? AppColors.darkCard : Colors.white)
                                  : (isDarkMode ? AppColors.darkCard.withOpacity(0.8) : Colors.white.withOpacity(0.9)),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                                  blurRadius: isDarkMode ? 12 : 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: isSelected
                                  ? Border.all(
                                      color: isDarkMode ? AppColors.darkPrimary : const Color(0xFFFF6B6B),
                                      width: 2)
                                  : null,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isLoading ? null : () async {
                                  if (_isLoading) return;
                                  
                                  setState(() {
                                    _isLoading = true;
                                  });

                                  try {
                                    // Changer la langue via le provider (qui gère aussi le contexte EasyLocalization)
                                    await languageProvider.changeLanguage(languageCode, context: context);
                                    
                                    // Marquer que l'utilisateur a choisi une langue
                                    await languageProvider.setLanguageChosen();

                                    if (mounted) {
                                      // Forcer une reconstruction complète
                                      setState(() {
                                        _isLoading = false;
                                      });
                                      
                                      // Naviguer vers l'écran de connexion
                                      Navigator.of(context).pushReplacementNamed('/login');
                                    }
                                  } catch (e) {
                                    debugPrint('Erreur lors du changement de langue: $e');
                                    if (mounted) {
                                      setState(() {
                                        _isLoading = false;
                                      });
                                    }
                                  }
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      // Drapeau ou icône de langue
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? (isDarkMode ? AppColors.darkPrimary.withOpacity(0.2) : const Color(0xFFFF6B6B).withOpacity(0.1))
                                              : (isDarkMode ? Colors.grey.withOpacity(0.2) : Colors.grey.withOpacity(0.1)),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Text(
                                            _getLanguageFlag(languageCode),
                                            style: const TextStyle(fontSize: 24),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),

                                      // Nom de la langue
                                      Expanded(
                                        child: Text(
                                          languageName,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isSelected
                                                ? (isDarkMode ? AppColors.darkPrimary : const Color(0xFFFF6B6B))
                                                : (isDarkMode ? AppColors.darkTextPrimary : Colors.black87),
                                          ),
                                        ),
                                      ),

                                      // Icône de sélection
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle,
                                          color: isDarkMode ? AppColors.darkPrimary : const Color(0xFFFF6B6B),
                                          size: 24,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Bouton continuer
                if (_isLoading)
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                else
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.5)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // Utiliser la langue actuelle et continuer
                          Navigator.of(context).pushReplacementNamed('/login');
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'language.continue'.tr(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getLanguageFlag(String languageCode) {
    switch (languageCode) {
      case 'fr':
        return '🇫🇷';
      case 'en':
        return '🇬🇧';
      case 'ar':
        return '🇸🇦';
      case 'es':
        return '🇪🇸';
      case 'de':
        return '🇩🇪';
      case 'it':
        return '🇮🇹';
      case 'pt':
        return '🇧🇷';
      case 'ja':
        return '🇯🇵';
      case 'ko':
        return '🇰🇷';
      default:
        return '🌐';
    }
  }
}