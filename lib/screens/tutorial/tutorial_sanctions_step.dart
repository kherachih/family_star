import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/children_provider.dart';
import '../../providers/rewards_provider.dart';
import '../../providers/tutorial_selections_provider.dart';
import '../../utils/app_colors.dart';
import '../rewards/add_sanction_screen.dart';
import '../../models/sanction.dart';
import '../../models/task.dart';
import '../../models/reward.dart';
import '../../models/duration_unit.dart';
import '../../services/firestore_service.dart';

class TutorialSanctionsStep extends StatefulWidget {
  final VoidCallback onStepCompleted;

  const TutorialSanctionsStep({
    super.key,
    required this.onStepCompleted,
  });

  @override
  State<TutorialSanctionsStep> createState() => _TutorialSanctionsStepState();
}

class _TutorialSanctionsStepState extends State<TutorialSanctionsStep> {
  List<Sanction> _suggestedSanctions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeSuggestedSanctions();
  }

  void _initializeSuggestedSanctions() {
    setState(() {
      _isLoading = true;
    });

    // Sanctions suggérées pour les enfants
    _suggestedSanctions = [
      Sanction(
        id: 'suggested_1',
        parentId: 'suggested',
        name: 'Pas de tablette',
        description: 'Interdiction d\'utiliser la tablette',
        starsCost: 5,
        durationValue: 1,
        durationUnit: DurationUnit.days,
      ),
      Sanction(
        id: 'suggested_2',
        parentId: 'suggested',
        name: 'Pas de téléphone',
        description: 'Interdiction d\'utiliser le téléphone',
        starsCost: 5,
        durationValue: 1,
        durationUnit: DurationUnit.days,
      ),
      Sanction(
        id: 'suggested_3',
        parentId: 'suggested',
        name: 'Pas de jeux vidéo',
        description: 'Interdiction de jouer aux jeux vidéo',
        starsCost: 3,
        durationValue: 1,
        durationUnit: DurationUnit.days,
      ),
      Sanction(
        id: 'suggested_4',
        parentId: 'suggested',
        name: 'Pas de sortie',
        description: 'Interdiction de sortir avec les amis',
        starsCost: 8,
        durationValue: 1,
        durationUnit: DurationUnit.weeks,
      ),
      Sanction(
        id: 'suggested_5',
        parentId: 'suggested',
        name: 'Coucher plus tôt',
        description: 'Heure de coucher avancée de 30 minutes',
        starsCost: 3,
        durationValue: 3,
        durationUnit: DurationUnit.days,
      ),
      Sanction(
        id: 'suggested_6',
        parentId: 'suggested',
        name: 'Pas de télévision',
        description: 'Interdiction de regarder la télévision',
        starsCost: 4,
        durationValue: 1,
        durationUnit: DurationUnit.days,
      ),
      Sanction(
        id: 'suggested_7',
        parentId: 'suggested',
        name: 'Tâches supplémentaires',
        description: 'Tâches ménagères supplémentaires',
        starsCost: 6,
        durationValue: null,
        durationUnit: null,
      ),
      Sanction(
        id: 'suggested_8',
        parentId: 'suggested',
        name: 'Privation de dessert',
        description: 'Pas de dessert après le repas',
        starsCost: 2,
        durationValue: 1,
        durationUnit: DurationUnit.days,
      ),
    ];

    setState(() {
      _isLoading = false;
    });
    
    // Stocker les sanctions dans le provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectionsProvider = Provider.of<TutorialSelectionsProvider>(context, listen: false);
      selectionsProvider.setSanctions(_suggestedSanctions);
    });
  }

  void _toggleSanctionSelection(String sanctionId) {
    final selectionsProvider = Provider.of<TutorialSelectionsProvider>(context, listen: false);
    selectionsProvider.toggleSanctionSelection(sanctionId);
  }

  void _navigateToAddSanction() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const AddSanctionScreen(),
      ),
    );

    // Si une sanction a été ajoutée, on pourrait recharger les sanctions ici
    if (result == true) {
      // Recharger les sanctions si nécessaire
    }
  }

  Future<void> _saveAllSelections() async {
    final selectionsProvider = Provider.of<TutorialSelectionsProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);

    if (authProvider.currentUser == null || childrenProvider.children.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Sauvegarder toutes les sélections
      final selectedTasks = selectionsProvider.getSelectedTasks();
      final selectedRewards = selectionsProvider.getSelectedRewards();
      final selectedSanctions = selectionsProvider.getSelectedSanctions();

      // Créer les tâches
      for (Task task in selectedTasks) {
        final newTask = Task(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_${task.id}',
          parentId: authProvider.currentUser!.id,
          childIds: childrenProvider.children.map((child) => child.id).toList(),
          title: task.title,
          description: task.description,
          type: task.type,
          stars: task.stars,
          isDaily: task.isDaily,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await FirestoreService().createTask(newTask);
      }

      // Créer les récompenses
      for (Reward reward in selectedRewards) {
        final newReward = Reward(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_${reward.id}',
          parentId: authProvider.currentUser!.id,
          name: reward.name,
          description: reward.description,
          starsCost: reward.starsCost,
        );

        await FirestoreService().createReward(newReward);
      }

      // Créer les sanctions
      for (Sanction sanction in selectedSanctions) {
        final newSanction = Sanction(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_${sanction.id}',
          parentId: authProvider.currentUser!.id,
          name: sanction.name,
          description: sanction.description,
          starsCost: sanction.starsCost,
          durationValue: sanction.durationValue,
          durationUnit: sanction.durationUnit,
        );

        await FirestoreService().createSanction(newSanction);
      }
      
      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Configuration terminée : ${selectedTasks.length} tâche(s), ${selectedRewards.length} récompense(s) et ${selectedSanctions.length} sanction(s) ajoutée(s)'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Attendre un peu pour que le message s'affiche
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Passer à l'étape suivante
      widget.onStepCompleted();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildSanctionItem(Sanction sanction) {
    final selectionsProvider = Provider.of<TutorialSelectionsProvider>(context);
    final isSelected = selectionsProvider.selections.selectedSanctionIds.contains(sanction.id);
    
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
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.warning,
            color: Colors.red,
          ),
        ),
        title: Text(
          sanction.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.blue : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sanction.description,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? Colors.blue.shade700 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Durée: ${_formatDuration(sanction)}',
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.blue.shade600 : Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_border,
                size: 14,
                color: Colors.red,
              ),
              const SizedBox(width: 2),
              Text(
                '${sanction.starsCost}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
        onTap: () => _toggleSanctionSelection(sanction.id!),
      ),
    );
  }

  String _formatDuration(Sanction sanction) {
    if (sanction.durationValue == null || sanction.durationUnit == null) {
      return 'Permanent';
    }
    
    String unit = '';
    switch (sanction.durationUnit) {
      case DurationUnit.hours:
        unit = sanction.durationValue == 1 ? 'heure' : 'heures';
        break;
      case DurationUnit.days:
        unit = sanction.durationValue == 1 ? 'jour' : 'jours';
        break;
      case DurationUnit.weeks:
        unit = sanction.durationValue == 1 ? 'semaine' : 'semaines';
        break;
      default:
        unit = '';
        break;
    }
    
    return '${sanction.durationValue} $unit';
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
                  Color(0xFFEF5350),
                  Color(0xFFE53935),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
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
                        Icons.gavel,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Configurez les sanctions',
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
                  'Définissez les sanctions appropriées en cas de non-respect des règles. Les sanctions doivent être éducatives et proportionnelles.',
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
          
          // Sanctions suggérées
          if (_isLoading) ...[
            const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ] else ...[
            Text(
              'Sanctions suggérées',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sélectionnez les sanctions qui conviennent à votre famille',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: _suggestedSanctions.length,
                itemBuilder: (context, index) {
                  return _buildSanctionItem(_suggestedSanctions[index]);
                },
              ),
            ),
          ],
          
          // Boutons d'action
          const SizedBox(height: 16),
          Consumer<TutorialSelectionsProvider>(
            builder: (context, selectionsProvider, child) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveAllSelections,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(_isLoading
                      ? 'Enregistrement...'
                      : 'Terminer et sauvegarder tout (${selectionsProvider.selections.selectedSanctionIds.length} sanctions, ${selectionsProvider.selections.selectedRewardIds.length} récompenses, ${selectionsProvider.selections.selectedTaskIds.length} tâches)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Astuce : Sélectionnez plusieurs sanctions puis validez en une seule fois !',
                    style: TextStyle(
                      color: Colors.red,
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