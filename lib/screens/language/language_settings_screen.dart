import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/app_colors.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('language.change_language'.tr()),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [
                    AppColors.darkPrimary.withOpacity(0.1),
                    AppColors.darkBackground,
                  ]
                : [
                    AppColors.primary.withOpacity(0.1),
                    Colors.white,
                  ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              
              // En-tête
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkGradientPrimary
                        : AppColors.gradientPrimary,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkPrimary.withOpacity(0.3)
                          : AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.language_outlined,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'language.select_language'.tr(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'language.title'.tr(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
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

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkCard
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: isSelected
                                ? Border.all(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? AppColors.darkPrimary
                                        : AppColors.primary,
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
                                  // Mettre à jour le contexte EasyLocalization d'abord
                                  if (mounted) {
                                    await context.setLocale(locale);
                                  }
                                  
                                  // Changer la langue via le provider ensuite
                                  await languageProvider.changeLanguage(languageCode);

                                  if (mounted) {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                    
                                    // Afficher un message de confirmation
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('language.language_changed'.tr()),
                                        backgroundColor: Theme.of(context).brightness == Brightness.dark
                                            ? AppColors.darkPrimary
                                            : AppColors.primary,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                    
                                    // Retourner à l'écran précédent
                                    Navigator.of(context).pop();
                                  }
                                } catch (e) {
                                  debugPrint('Erreur lors du changement de langue: $e');
                                  if (mounted) {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Erreur lors du changement de langue'),
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
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
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? (Theme.of(context).brightness == Brightness.dark
                                                ? AppColors.darkPrimary.withOpacity(0.1)
                                                : AppColors.primary.withOpacity(0.1))
                                            : Colors.grey.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _getLanguageFlag(languageCode),
                                          style: const TextStyle(fontSize: 28),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),

                                    // Nom de la langue
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            languageName,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              color: isSelected
                                                  ? (Theme.of(context).brightness == Brightness.dark
                                                      ? AppColors.darkPrimary
                                                      : AppColors.primary)
                                                  : Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _getLanguageNativeName(languageCode),
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Icône de sélection
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle,
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? AppColors.darkPrimary
                                            : AppColors.primary,
                                        size: 24,
                                      )
                                    else
                                      Icon(
                                        Icons.radio_button_unchecked,
                                        color: Colors.grey[400],
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

              if (_isLoading)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ),
            ],
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

  String _getLanguageNativeName(String languageCode) {
    switch (languageCode) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      case 'es':
        return 'Español';
      case 'de':
        return 'Deutsch';
      case 'it':
        return 'Italiano';
      case 'pt':
        return 'Português';
      case 'ja':
        return '日本語';
      case 'ko':
        return '한국어';
      default:
        return languageCode;
    }
  }
}