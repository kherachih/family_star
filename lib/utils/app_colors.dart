import 'package:flutter/material.dart';

class AppColors {
  // Couleurs principales - Palette familiale chaleureuse
  static const Color primary = Color(0xFFFF6B6B); // Rouge corail chaleureux
  static const Color secondary = Color(0xFFFFD93D); // Jaune doré
  static const Color tertiary = Color(0xFF6BCB77); // Vert doux
  static const Color accent = Color(0xFF4D96FF); // Bleu ciel

  // Couleurs de fond - Mode clair
  static const Color background = Color(0xFFFFF9F0); // Crème chaleureux
  static const Color surface = Colors.white;
  
  // Couleurs de fond - Mode sombre (Nouvelle palette)
  static const Color darkBackground = Color(0xFF1E1E1E); // Gris charbon
  static const Color darkSurface = Color(0xFF2A2A2A); // Gris anthracite
  static const Color darkCard = Color(0xFF2A2A2A); // Gris anthracite pour les cartes
  
  // Couleurs principales - Mode sombre
  static const Color darkPrimary = Color(0xFFE84A5F); // Rouge corail foncé
  static const Color darkSecondary = Color(0xFFA6932D); // Jaune doré foncé (moins vif)
  static const Color darkTertiary = Color(0xFF3D6B4F); // Vert foncé (moins vif)
  static const Color darkAccent = Color(0xFF4DA3FF); // Bleu ciel doux
  
  // Couleurs pour les étoiles
  static const Color starPositive = Color(0xFFFFD93D); // Jaune doré
  static const Color starNegative = Color(0xFFFF6B6B); // Rouge
  
  // Couleurs de fond pour les badges d'étoiles
  static const Color starPositiveBackgroundDark = Color(0xFF4A4A4A); // Gris foncé pour étoiles positives
  static const Color starPositiveBackgroundLight = Color(0xFF6A6A6A); // Gris clair pour étoiles positives

  // Couleurs pour les tâches
  static const Color taskPositive = Color(0xFF6BCB77); // Vert
  static const Color taskNegative = Color(0xFFFF6B6B); // Rouge
  
  // Couleurs pour les tâches - Mode sombre
  static const Color darkTaskPositive = Color(0xFF3D6B4F); // Vert foncé (moins vif)
  static const Color darkTaskNegative = Color(0xFFE84A5F); // Rouge corail foncé
  static const Color darkTaskBackgroundPositive = Color(0xFF2A352E); // Fond vert foncé pour tâches réussies
  static const Color darkTaskBackgroundNegative = Color(0xFF3A2326); // Fond rouge pour tâches échouées

  // Dégradés - Mode clair
  static const List<Color> gradientPrimary = [
    Color(0xFFFF6B6B),
    Color(0xFFFF8E8E),
  ];

  static const List<Color> gradientSecondary = [
    Color(0xFFFFD93D),
    Color(0xFFFFE55D),
  ];

  static const List<Color> gradientTertiary = [
    Color(0xFF6BCB77),
    Color(0xFF8FDB94),
  ];

  static const List<Color> gradientHero = [
    Color(0xFFFF6B6B),
    Color(0xFFFFD93D),
  ];
  
  // Dégradés - Mode sombre (Nouvelle palette)
  static const List<Color> darkGradientPrimary = [
    Color(0xFFE84A5F), // Rouge corail foncé
    Color(0xFFFF6B6B), // Rouge corail clair
  ];

  static const List<Color> darkGradientSecondary = [
    Color(0xFFA6932D), // Jaune doré foncé (moins vif)
    Color(0xFFC4B032), // Jaune doré moyen
  ];

  static const List<Color> darkGradientTertiary = [
    Color(0xFF3D6B4F), // Vert foncé (moins vif)
    Color(0xFF4A825E), // Vert moyen
  ];

  static const List<Color> darkGradientHero = [
    Color(0xFFE84A5F), // Rouge corail foncé
    Color(0xFFA6932D), // Jaune doré foncé (moins vif)
  ];

  // Couleurs de texte - Mode clair
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textLight = Color(0xFFB2BEC3);
  
  // Couleurs de texte - Mode sombre (Nouvelle palette)
  static const Color darkTextPrimary = Color(0xFFECECEC); // Texte principal clair
  static const Color darkTextSecondary = Color(0xFFB0B0B0); // Sous-titres et descriptions
  static const Color darkTextLight = Color(0xFF757575); // Texte peu important

  // Couleurs spécifiques - Mode sombre
  static const Color white = Color(0xFFFFFFFF); // Pour icônes sur fonds colorés
  static const Color lightGray = Color(0xFFB0B0B0); // Bordures, éléments désactivés
  static const Color green = Color(0xFF57A773); // Succès, complétion
  static const Color red = Color(0xFFE84A5F); // Erreurs, alertes
  static const Color orange = Color(0xFFE6A157); // Avertissements

  // Ombres - Mode clair
  static BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withOpacity(0.08),
    blurRadius: 12,
    offset: const Offset(0, 4),
  );

  static BoxShadow buttonShadow = BoxShadow(
    color: primary.withOpacity(0.3),
    blurRadius: 8,
    offset: const Offset(0, 4),
  );
  
  // Ombres - Mode sombre (Nouvelle palette)
  static BoxShadow darkCardShadow = BoxShadow(
    color: Colors.black.withOpacity(0.5),
    blurRadius: 16,
    offset: const Offset(0, 4),
  );

  static BoxShadow darkButtonShadow = BoxShadow(
    color: Color(0xFFE84A5F).withOpacity(0.3), // Rouge corail foncé
    blurRadius: 8,
    offset: const Offset(0, 4),
  );
}