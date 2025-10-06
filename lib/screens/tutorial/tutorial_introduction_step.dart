import 'package:flutter/material.dart';
import 'package:family_star/utils/app_colors.dart';

class TutorialIntroductionStep extends StatelessWidget {
  final VoidCallback? onNextPressed;

  const TutorialIntroductionStep({
    Key? key,
    this.onNextPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          // Titre principal
          const Text(
            'Bienvenue sur Family Star !',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Image d'illustration
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.star,
                size: 60,
                color: AppColors.primary,
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Description du principe
          const Text(
            'Le principe est simple :',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 15),
          
          // Points clés
          _buildPrinciplePoint(
            icon: Icons.task_alt,
            title: 'Tâches quotidiennes',
            description: 'Vos enfants gagnent des étoiles en accomplissant leurs tâches quotidiennes.',
          ),
          
          const SizedBox(height: 15),
          
          _buildPrinciplePoint(
            icon: Icons.card_giftcard,
            title: 'Récompenses',
            description: 'Les étoiles gagnées peuvent être échangées contre des récompenses que vous définissez.',
          ),
          
          const SizedBox(height: 15),
          
          _buildPrinciplePoint(
            icon: Icons.gavel,
            title: 'Sanctions éducatives',
            description: 'En cas de non-respect des règles, des sanctions adaptées peuvent être appliquées.',
          ),
          
          const SizedBox(height: 15),
          
          _buildPrinciplePoint(
            icon: Icons.family_restroom,
            title: 'Famille unie',
            description: 'Un système motivant qui renforce la communication et la responsabilité au sein de la famille.',
          ),
          
          const SizedBox(height: 30),
          
          // Message de motivation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.accent.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: AppColors.accent,
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Family Star transforme les tâches ménagères en un jeu motivant pour toute la famille !',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Bouton pour commencer
          Center(
            child: ElevatedButton(
              onPressed: onNextPressed ?? () {
                // Naviguer vers la page d'ajout des enfants
                Navigator.of(context).pushReplacementNamed('/tutorial/children');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 3,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Commencer',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPrinciplePoint({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}