import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/children_provider.dart';
import '../../providers/family_provider.dart';
import '../../models/child.dart';
import '../../models/task.dart';
import '../../services/firestore_service.dart';
import '../../services/auto_ad_service.dart';
import '../../utils/app_colors.dart';
import '../children/child_profile_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<Task> _dailyTasks = [];
  bool _isLoadingTasks = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      // Notifier AutoAdService que nous sommes sur l'écran d'accueil
      AutoAdService().onScreenChanged('home');
    });
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
    final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      // Utiliser l'ID de la famille actuelle si disponible, sinon utiliser l'ID du parent
      String familyId = familyProvider.currentFamily?.id ?? authProvider.currentUser!.id;
      await childrenProvider.loadChildren(familyId);
      await _loadDailyTasks(authProvider.currentUser!.id);
    }
  }

  Future<void> _loadDailyTasks(String parentId) async {
    setState(() => _isLoadingTasks = true);
    try {
      // Utiliser la nouvelle méthode qui filtre automatiquement les tâches non complétées par tous les enfants
      final pendingTasks = await FirestoreService().getPendingDailyTasksByParentId(parentId);
      setState(() => _dailyTasks = pendingTasks);
    } catch (e) {
      debugPrint('Error loading daily tasks: $e');
    } finally {
      setState(() => _isLoadingTasks = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: Consumer2<AuthProvider, ChildrenProvider>(
        builder: (context, authProvider, childrenProvider, child) {
          if (childrenProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final children = childrenProvider.children;
          final totalStars = children.fold<int>(0, (sum, child) => sum + child.stars);

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header d'accueil sans AppBar
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkGradientHero
                          : AppColors.gradientHero,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkPrimary.withOpacity(0.3)
                            : AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '👋 Bonjour',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              authProvider.currentUser?.name ?? '',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${children.length} ${children.length <= 1 ? "enfant" : "enfants"} • $totalStars ⭐ au total',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Mes Enfants - Slider
                Text(
                  'Mes Enfants',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                if (children.isEmpty)
                  _buildEmptyChildrenState(context)
                else if (children.length <= 2)
                  Column(
                    children: children
                        .map((child) => _buildChildCard(child, context))
                        .toList(),
                  )
                else
                  SizedBox(
                    height: 200,
                    child: PageView.builder(
                      controller: PageController(viewportFraction: 0.85),
                      itemCount: children.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _buildChildCard(children[index], context),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 32),

                // Tâches quotidiennes
                Text(
                  'Tâches quotidiennes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                _isLoadingTasks
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : _dailyTasks.isEmpty
                        ? _buildEmptyDailyTasksState()
                        : _buildDailyTasksList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyChildrenState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkGradientPrimary.map((c) => c.withOpacity(0.1)).toList()
              : AppColors.gradientPrimary.map((c) => c.withOpacity(0.1)).toList(),
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkPrimary.withOpacity(0.3)
              : AppColors.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.child_friendly, size: 48, color: AppColors.primary.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            'Aucun enfant ajouté',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Allez dans l\'onglet Enfants pour en ajouter',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildCard(Child child, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Theme.of(context).brightness == Brightness.dark
              ? [
                  AppColors.darkCard,
                  AppColors.darkSurface,
                ]
              : [
                  Colors.white,
                  AppColors.primary.withOpacity(0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? [AppColors.darkCardShadow]
            : [AppColors.cardShadow],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ChildProfileScreen(child: child),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkGradientHero
                          : AppColors.gradientHero,
                    ),
                    shape: BoxShape.circle,
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
                  child: Center(
                    child: Text(
                      child.avatar,
                      style: const TextStyle(fontSize: 36),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${child.age} ans',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Badge étoiles
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: child.stars < 0
                                ? [
                                    AppColors.starNegative.withOpacity(0.2),
                                    AppColors.starNegative.withOpacity(0.1),
                                  ]
                                : [
                                    AppColors.starPositiveBackgroundDark,
                                    AppColors.starPositiveBackgroundLight,
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 18,
                              color: child.stars < 0
                                  ? AppColors.starNegative
                                  : AppColors.starPositive,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${child.stars}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: child.stars < 0
                                    ? AppColors.starNegative
                                    : AppColors.starPositive,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Flèche
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkPrimary.withOpacity(0.1)
                        : AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkPrimary
                        : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyDailyTasksState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkGradientSecondary.map((c) => c.withOpacity(0.1)).toList()
              : AppColors.gradientSecondary.map((c) => c.withOpacity(0.1)).toList(),
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSecondary.withOpacity(0.3)
              : AppColors.secondary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy, size: 48, color: AppColors.secondary.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            'Pas de tâches quotidiennes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ajoutez des tâches quotidiennes dans l\'onglet Tâches',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTasksList() {
    return Column(
      children: _dailyTasks.map((task) => _buildDailyTaskCard(task)).toList(),
    );
  }

  Widget _buildDailyTaskCard(Task task) {
    final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);
    final List<Child> assignedChildren = task.childIds
        .map((childId) => childrenProvider.children.firstWhere(
              (child) => child.id == childId,
              orElse: () => childrenProvider.children.first,
            ))
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Theme.of(context).brightness == Brightness.dark
              ? [
                  AppColors.darkCard,
                  task.type == TaskType.positive
                      ? AppColors.darkTaskBackgroundPositive
                      : AppColors.darkTaskBackgroundNegative,
                ]
              : [
                  Colors.white,
                  task.type == TaskType.positive
                      ? Colors.green.withOpacity(0.05)
                      : Colors.red.withOpacity(0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: task.type == TaskType.positive
              ? (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTaskPositive.withOpacity(0.2)
                  : Colors.green.withOpacity(0.2))
              : (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTaskNegative.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2)),
        ),
      ),
      child: InkWell(
        onTap: () => _showTaskCompletionDialog(task, assignedChildren),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: task.type == TaskType.positive
                    ? (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTaskPositive.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1))
                    : (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTaskNegative.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                task.type == TaskType.positive
                    ? Icons.add_circle
                    : Icons.remove_circle,
                color: task.type == TaskType.positive
                    ? (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTaskPositive
                        : Colors.green)
                    : (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTaskNegative
                        : Colors.red),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${task.type == TaskType.positive ? "+" : "-"}${task.stars} ⭐',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: task.type == TaskType.positive
                          ? (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTaskPositive
                              : Colors.green)
                          : (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTaskNegative
                              : Colors.red),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Afficher les enfants assignés avec leur état de complétion
                  Row(
                    children: assignedChildren.map((child) {
                      final isCompleted = task.isCompletedTodayByChild(child.id);
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? (Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.darkTaskBackgroundPositive
                                  : Colors.green.withOpacity(0.1))
                              : AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCompleted
                                ? (Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.darkTaskPositive.withOpacity(0.3)
                                    : Colors.green.withOpacity(0.3))
                                : AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              child.avatar,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              child.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: isCompleted
                                    ? (Theme.of(context).brightness == Brightness.dark
                                        ? AppColors.darkTaskPositive
                                        : Colors.green)
                                    : AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (isCompleted) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.check_circle,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.darkTaskPositive
                                    : Colors.green,
                                size: 14,
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.check_circle_outline,
              color: AppColors.primary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskCompletionDialog(Task task, List<Child> assignedChildren) {
    if (assignedChildren.isEmpty) return;

    // Si un seul enfant, utiliser le dialogue simple
    if (assignedChildren.length == 1) {
      _showSingleChildDialog(task, assignedChildren.first);
      return;
    }

    // Si plusieurs enfants, utiliser le dialogue de sélection
    _showMultipleChildrenDialog(task, assignedChildren);
  }

  void _showSingleChildDialog(Task task, Child child) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône de question
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.gradientPrimary,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.help_outline,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Titre
                Text(
                  'Est-ce que ${child.name} a fait cette tâche ?',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                // Nom de la tâche
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: AppColors.primary.withOpacity(0.3),
                            ),
                          ),
                        ),
                        child: const Text(
                          'Non',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _completeTask(task, [child]);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Oui',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMultipleChildrenDialog(Task task, List<Child> assignedChildren) {
    // Créer une liste pour suivre quels enfants ont complété la tâche
    // Initialiser avec l'état actuel de complétion pour chaque enfant
    final Map<String, bool> childrenCompletion = {};
    for (final child in assignedChildren) {
      childrenCompletion[child.id] = task.isCompletedTodayByChild(child.id);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icône de question
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: AppColors.gradientPrimary,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.group,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Titre
                    const Text(
                      'Qui a fait cette tâche ?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    
                    // Nom de la tâche
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    
                    // Liste des enfants avec cases à cocher
                    ...assignedChildren.map((child) {
                      final isAlreadyCompleted = task.isCompletedTodayByChild(child.id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: childrenCompletion[child.id] == true
                                ? Colors.green.withOpacity(0.1)
                                : isAlreadyCompleted
                                    ? Colors.grey.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: childrenCompletion[child.id] == true
                                  ? Colors.green.withOpacity(0.3)
                                  : isAlreadyCompleted
                                      ? Colors.grey.withOpacity(0.3)
                                      : Colors.grey.withOpacity(0.2),
                            ),
                          ),
                          child: CheckboxListTile(
                            title: Row(
                              children: [
                                Text(
                                  child.avatar,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    child.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (isAlreadyCompleted)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Déjà fait',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            value: childrenCompletion[child.id],
                            onChanged: (bool? value) {
                              setState(() {
                                childrenCompletion[child.id] = value ?? false;
                              });
                            },
                            activeColor: AppColors.primary,
                            checkColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          ),
                        ),
                      );
                    }).toList(),
                    
                    const SizedBox(height: 16),
                    
                    // Boutons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: AppColors.primary.withOpacity(0.3),
                                ),
                              ),
                            ),
                            child: const Text(
                              'Annuler',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              // Filtrer les enfants qui ont complété la tâche
                              final completedChildren = assignedChildren
                                  .where((child) => childrenCompletion[child.id] == true)
                                  .toList();
                              
                              if (completedChildren.isNotEmpty) {
                                _completeTask(task, completedChildren);
                              } else {
                                // Aucun enfant sélectionné, afficher un message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Veuillez sélectionner au moins un enfant'),
                                    backgroundColor: AppColors.primary,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(12)),
                                    ),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Valider',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _completeTask(Task task, List<Child> completedChildren) async {
    final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.currentUser == null || completedChildren.isEmpty) return;

    // Mettre à jour les étoiles pour chaque enfant qui a complété la tâche
    for (final child in completedChildren) {
      final updatedChild = child.copyWith(
        stars: child.stars + task.starChange,
        updatedAt: DateTime.now(),
      );
      
      // Mettre à jour l'enfant dans Firestore
      await FirestoreService().updateChild(updatedChild);
      
      // Mettre à jour le provider
      childrenProvider.updateChild(updatedChild);
      
      // Enregistrer la tâche dans l'historique
      await FirestoreService().recordTaskApplication(task.id, child.id);
    }

    // Si c'est une tâche quotidienne, mettre à jour les complétions individuelles
    if (task.isDaily) {
      // Marquer la tâche comme complétée par chaque enfant
      for (final child in completedChildren) {
        await FirestoreService().markDailyTaskCompletedByChild(task.id, child.id);
      }
      
      // Recharger les tâches quotidiennes pour mettre à jour l'affichage
      await _loadDailyTasks(authProvider.currentUser!.id);
    }

    // Afficher une confirmation
    final childrenNames = completedChildren.map((child) => child.name).join(', ');
    final remainingChildren = task.getChildrenNotCompletedToday();
    final message = remainingChildren.isEmpty
        ? 'Tâche complétée par tous les enfants ! ${task.starChange > 0 ? "+" : ""}${task.starChange} étoile(s) ajoutée(s) à ${childrenNames} !'
        : '${task.starChange > 0 ? "+" : ""}${task.starChange} étoile(s) ajoutée(s) à ${childrenNames} ! ${remainingChildren.length} enfant(s) restant(s).';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final List<Color> gradient;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient.map((c) => c.withOpacity(0.1)).toList(),
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: gradient.first.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: gradient.first,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: gradient.first,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: gradient.first,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
