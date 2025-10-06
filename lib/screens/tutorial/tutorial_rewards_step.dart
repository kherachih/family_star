import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rewards_provider.dart';
import '../../providers/tutorial_selections_provider.dart';
import '../../utils/app_colors.dart';
import '../rewards/add_reward_screen.dart';
import '../../models/reward.dart';
import '../../services/firestore_service.dart';

class TutorialRewardsStep extends StatefulWidget {
  final VoidCallback onStepCompleted;

  const TutorialRewardsStep({
    super.key,
    required this.onStepCompleted,
  });

  @override
  State<TutorialRewardsStep> createState() => _TutorialRewardsStepState();
}

class _TutorialRewardsStepState extends State<TutorialRewardsStep> {
  List<Reward> _suggestedRewards = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeSuggestedRewards();
  }

  void _initializeSuggestedRewards() {
    setState(() {
      _isLoading = true;
    });

    // Récompenses suggérées pour les enfants
    _suggestedRewards = [
      Reward(
        id: 'suggested_1',
        parentId: 'suggested',
        name: 'Une heure de tablette',
        description: 'Utilisation de la tablette pendant une heure',
        starsCost: 10,
      ),
      Reward(
        id: 'suggested_2',
        parentId: 'suggested',
        name: 'Sortie au parc',
        description: 'Une sortie au parc avec les parents',
        starsCost: 15,
      ),
      Reward(
        id: 'suggested_3',
        parentId: 'suggested',
        name: 'Film au cinéma',
        description: 'Un billet pour le film de son choix',
        starsCost: 25,
      ),
      Reward(
        id: 'suggested_4',
        parentId: 'suggested',
        name: 'Glace préférée',
        description: 'Une glace à son parfum préféré',
        starsCost: 8,
      ),
      Reward(
        id: 'suggested_5',
        parentId: 'suggested',
        name: 'Jeu vidéo',
        description: 'Une heure de jeu vidéo',
        starsCost: 12,
      ),
      Reward(
        id: 'suggested_6',
        parentId: 'suggested',
        name: 'Livraison pizza',
        description: 'Soirée pizza à la maison',
        starsCost: 30,
      ),
      Reward(
        id: 'suggested_7',
        parentId: 'suggested',
        name: 'Achat de jouet',
        description: 'Un jouet de son choix (budget limité)',
        starsCost: 40,
      ),
      Reward(
        id: 'suggested_8',
        parentId: 'suggested',
        name: 'Pique-nique',
        description: 'Un pique-nique en famille',
        starsCost: 20,
      ),
    ];

    setState(() {
      _isLoading = false;
    });
    
    // Stocker les récompenses dans le provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectionsProvider = Provider.of<TutorialSelectionsProvider>(context, listen: false);
      selectionsProvider.setRewards(_suggestedRewards);
    });
  }

  void _toggleRewardSelection(String rewardId) {
    final selectionsProvider = Provider.of<TutorialSelectionsProvider>(context, listen: false);
    selectionsProvider.toggleRewardSelection(rewardId);
  }

  void _navigateToAddReward() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const AddRewardScreen(),
      ),
    );

    // Si une récompense a été ajoutée, on pourrait recharger les récompenses ici
    if (result == true) {
      // Recharger les récompenses si nécessaire
    }
  }

  void _goToNextStep() {
    final selectionsProvider = Provider.of<TutorialSelectionsProvider>(context, listen: false);
    
    if (!selectionsProvider.selections.hasSelectedRewards) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins une récompense'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Passer à l'étape suivante
    widget.onStepCompleted();
  }

  Widget _buildRewardItem(Reward reward) {
    final selectionsProvider = Provider.of<TutorialSelectionsProvider>(context);
    final isSelected = selectionsProvider.selections.selectedRewardIds.contains(reward.id);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.card_giftcard,
            color: Colors.orange,
          ),
        ),
        title: Text(
          reward.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.blue : null,
          ),
        ),
        subtitle: Text(
          reward.description,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.blue.shade700 : Colors.grey[600],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star,
                size: 14,
                color: Colors.orange,
              ),
              const SizedBox(width: 2),
              Text(
                '${reward.starsCost}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ),
        onTap: () => _toggleRewardSelection(reward.id!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de l'étape
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFB74D),
                  Color(0xFFFF9800),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.card_giftcard,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Définissez les récompenses',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Configurez les récompenses que vos enfants peuvent obtenir en échange de leurs étoiles. Vous pouvez utiliser nos suggestions ou créer vos propres récompenses.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Récompenses suggérées
          if (_isLoading) ...[
            const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ] else ...[
            Text(
              'Récompenses suggérées',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sélectionnez les récompenses qui conviennent à votre famille',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: _suggestedRewards.length,
                itemBuilder: (context, index) {
                  return _buildRewardItem(_suggestedRewards[index]);
                },
              ),
            ),
          ],
          
          // Boutons d'action
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Consumer<TutorialSelectionsProvider>(
              builder: (context, selectionsProvider, child) {
                return ElevatedButton.icon(
                  onPressed: _goToNextStep,
                  icon: const Icon(Icons.check),
                  label: Text('Valider les récompenses sélectionnées (${selectionsProvider.selections.selectedRewardIds.length})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Astuce : Sélectionnez plusieurs récompenses puis validez en une seule fois !',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
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