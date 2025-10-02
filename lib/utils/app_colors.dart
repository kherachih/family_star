import 'package:flutter/material.dart';

class AppColors {
  // Couleurs principales - Palette familiale chaleureuse
  static const Color primary = Color(0xFFFF6B6B); // Rouge corail chaleureux
  static const Color secondary = Color(0xFFFFD93D); // Jaune doré
  static const Color tertiary = Color(0xFF6BCB77); // Vert doux
  static const Color accent = Color(0xFF4D96FF); // Bleu ciel

  // Couleurs de fond
  static const Color background = Color(0xFFFFF9F0); // Crème chaleureux
  static const Color surface = Colors.white;

  // Couleurs pour les étoiles
  static const Color starPositive = Color(0xFFFFD93D); // Jaune doré
  static const Color starNegative = Color(0xFFFF6B6B); // Rouge
  
  // Couleurs de fond pour les badges d'étoiles
  static const Color starPositiveBackgroundDark = Color(0xFF4A4A4A); // Gris foncé pour étoiles positives
  static const Color starPositiveBackgroundLight = Color(0xFF6A6A6A); // Gris clair pour étoiles positives

  // Couleurs pour les tâches
  static const Color taskPositive = Color(0xFF6BCB77); // Vert
  static const Color taskNegative = Color(0xFFFF6B6B); // Rouge

  // Dégradés
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

  // Couleurs de texte
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textLight = Color(0xFFB2BEC3);

  // Ombres
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
}