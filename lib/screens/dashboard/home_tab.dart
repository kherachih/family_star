import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/children_provider.dart';
import '../../models/child.dart';
import '../../models/task.dart';
import '../../services/firestore_service.dart';
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
    });
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      await childrenProvider.loadChildren(authProvider.currentUser!.id);
      await _loadDailyTasks(authProvider.currentUser!.id);
    }
  }

  Future<void> _loadDailyTasks(String parentId) async {
    setState(() => _isLoadingTasks = true);
    try {
      final dailyTasks = await FirestoreService().getDailyTasksByParentId(parentId);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Filtrer les tâches quotidiennes pour n'afficher que celles non complétées aujourd'hui
      final filteredTasks = dailyTasks.where((task) {
        if (task.lastCompletedAt == null) return true;
        
        final lastCompletedDate = DateTime(
          task.lastCompletedAt!.year,
          task.lastCompletedAt!.month,
          task.lastCompletedAt!.day,
        );
        
        // Si la tâche a été complétée aujourd'hui, ne pas l'afficher
        return lastCompletedDate.isBefore(today);
      }).toList();
      
      setState(() => _dailyTasks = filteredTasks);
    } catch (e) {
      debugPrint('Error loading daily tasks: $e');
    } finally {
      setState(() => _isLoadingTasks = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Consumer2<AuthProvider, ChildrenProvider>(
          builder: (context, authProvider, childrenProvider, child) {
            if (childrenProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final children = childrenProvider.children;
            final totalStars = children.fold<int>(0, (sum, child) => sum + child.stars);

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // AppBar moderne
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: AppColors.gradientHero,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 60),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
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
                                fontSize: 28,
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
                    ),
                  ),
                ),

                // Contenu
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Mes Enfants - Slider
                        const Text(
                          'Mes Enfants',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
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
                        const Text(
                          'Tâches quotidiennes',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
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
                  ),
                ),
              ],
            );
          },
        ),
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
          colors: AppColors.gradientPrimary.map((c) => c.withOpacity(0.1)).toList(),
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.child_friendly, size: 48, color: AppColors.primary.withOpacity(0.5)),
          const SizedBox(height: 12),
          const Text(
            'Aucun enfant ajouté',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Allez dans l\'onglet Enfants pour en ajouter',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
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
          colors: [
            Colors.white,
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [AppColors.cardShadow],
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
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.gradientHero,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${child.age} ans',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
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
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppColors.primary,
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
          colors: AppColors.gradientSecondary.map((c) => c.withOpacity(0.1)).toList(),
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy, size: 48, color: AppColors.secondary.withOpacity(0.5)),
          const SizedBox(height: 12),
          const Text(
            'Pas de tâches quotidiennes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ajoutez des tâches quotidiennes dans l\'onglet Tâches',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
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
          colors: [
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
              ? Colors.green.withOpacity(0.2)
              : Colors.red.withOpacity(0.2),
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
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                task.type == TaskType.positive
                    ? Icons.add_circle
                    : Icons.remove_circle,
                color: task.type == TaskType.positive
                    ? Colors.green
                    : Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${task.type == TaskType.positive ? "+" : "-"}${task.stars} ⭐',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: task.type == TaskType.positive
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Afficher les enfants assignés
                  Row(
                    children: assignedChildren.map((child) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
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
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
                  assignedChildren.length == 1
                      ? 'Est-ce que ${assignedChildren.first.name} a fait cette tâche ?'
                      : 'Est-ce que les enfants ont fait cette tâche ?',
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
                          _completeTask(task, assignedChildren);
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

  Future<void> _completeTask(Task task, List<Child> assignedChildren) async {
    final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.currentUser == null) return;

    // Mettre à jour les étoiles pour chaque enfant assigné
    for (final child in assignedChildren) {
      final updatedChild = child.copyWith(
        stars: child.stars + task.starChange,
        updatedAt: DateTime.now(),
      );
      
      // Mettre à jour l'enfant dans Firestore
      await FirestoreService().updateChild(updatedChild);
      
      // Mettre à jour le provider
      childrenProvider.updateChild(updatedChild);
    }

    // Si c'est une tâche quotidienne, mettre à jour la date de dernière complétion
    if (task.isDaily) {
      final updatedTask = task.copyWith(
        lastCompletedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Mettre à jour la tâche dans Firestore
      await FirestoreService().updateTask(updatedTask);
      
      // Recharger les tâches quotidiennes pour masquer celle qui vient d'être complétée
      await _loadDailyTasks(authProvider.currentUser!.id);
    }

    // Afficher une confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          assignedChildren.length == 1
              ? '${task.starChange > 0 ? "+" : ""}${task.starChange} étoile(s) ajoutée(s) à ${assignedChildren.first.name} !'
              : '${task.starChange > 0 ? "+" : ""}${task.starChange} étoile(s) ajoutée(s) aux enfants !',
        ),
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
