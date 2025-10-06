import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/children_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../../utils/app_colors.dart';
import '../children/add_child_screen.dart';

class TutorialChildrenStep extends StatefulWidget {
  final VoidCallback onStepCompleted;

  const TutorialChildrenStep({
    super.key,
    required this.onStepCompleted,
  });

  @override
  State<TutorialChildrenStep> createState() => _TutorialChildrenStepState();
}

class _TutorialChildrenStepState extends State<TutorialChildrenStep> {
  @override
  void initState() {
    super.initState();
    // Charger les enfants existants
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChildren();
    });
  }

  Future<void> _loadChildren() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);
    final familyProvider = Provider.of<FamilyProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      await childrenProvider.loadChildren(
        familyProvider.currentFamily?.id ?? authProvider.currentUser!.id,
      );
    }
  }

  void _navigateToAddChild() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const AddChildScreen(),
      ),
    );

    // Si un enfant a été ajouté, recharger la liste
    if (result == true) {
      await _loadChildren();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChildrenProvider>(
      builder: (context, childrenProvider, child) {
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
                    colors: AppColors.gradientTertiary,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.tertiary.withOpacity(0.3),
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
                            Icons.child_care,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Ajoutez vos enfants',
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
                      'Commencez par ajouter vos enfants à votre famille. Vous pourrez configurer leurs tâches, récompenses et sanctions personnalisées.',
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
              
              // Liste des enfants existants
              if (childrenProvider.children.isNotEmpty) ...[
                Text(
                  'Vos enfants (${childrenProvider.children.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: childrenProvider.children.length,
                    itemBuilder: (context, index) {
                      final child = childrenProvider.children[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.tertiary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                child.avatar,
                                style: const TextStyle(fontSize: 32),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    child.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${child.age} ans',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.tertiary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: AppColors.tertiary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${child.stars}',
                                    style: const TextStyle(
                                      color: AppColors.tertiary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ] else ...[
                // Message si aucun enfant
                Container(
                  constraints: const BoxConstraints(minHeight: 200),
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.tertiary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.child_care,
                              size: 60,
                              color: AppColors.tertiary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun enfant ajouté',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ajoutez votre premier enfant pour commencer',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              
              // Bouton d'ajout
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _navigateToAddChild,
                  icon: const Icon(Icons.add),
                  label: Text(
                    childrenProvider.children.isEmpty 
                        ? 'Ajouter mon premier enfant' 
                        : 'Ajouter un autre enfant',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tertiary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              // Message pour continuer si au moins un enfant est ajouté
              if (childrenProvider.children.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.tertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.tertiary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.tertiary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Parfait ! Vous pouvez maintenant passer à l\'étape suivante.',
                          style: TextStyle(
                            color: AppColors.tertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}