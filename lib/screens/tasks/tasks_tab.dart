import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rewards_provider.dart';
import '../../utils/app_colors.dart';
import '../../models/task.dart';
import '../../models/reward.dart';
import '../../models/sanction.dart';
import '../../services/firestore_service.dart';
import 'add_task_screen.dart';
import '../rewards/add_reward_screen.dart';
import '../rewards/add_sanction_screen.dart';

class TasksTab extends StatefulWidget {
  const TasksTab({super.key});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Task> _tasks = [];
  bool _isLoadingTasks = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _loadTasks();
    await _loadRewardsAndSanctions();
  }

  Future<void> _loadTasks() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser == null) return;

    setState(() => _isLoadingTasks = true);
    try {
      final tasks = await FirestoreService().getTasksByParentId(authProvider.currentUser!.id);
      setState(() {
        _tasks = tasks;
        _isLoadingTasks = false;
      });
    } catch (e) {
      setState(() => _isLoadingTasks = false);
    }
  }

  Future<void> _loadRewardsAndSanctions() async {
    final authProvider = context.read<AuthProvider>();
    final rewardsProvider = context.read<RewardsProvider>();

    if (authProvider.currentUser != null) {
      await rewardsProvider.loadRewards(authProvider.currentUser!.id);
      await rewardsProvider.loadSanctions(authProvider.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header Tâches sans AppBar
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.gradientSecondary,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.task_alt_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gestion',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Tâches, récompenses et sanctions',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // TabBar personnalisé amélioré
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.95),
                              Colors.white.withOpacity(0.85),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        labelColor: AppColors.textPrimary, // Couleur plus foncée pour meilleure lisibilité
                        unselectedLabelColor: Colors.white, // Blanc pur pour les onglets non sélectionnés
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent, // Supprime le trait sous les onglets
                        tabs: const [
                          Tab(
                            icon: Icon(Icons.task_alt_rounded, size: 20),
                            text: 'Tâches',
                            iconMargin: EdgeInsets.only(bottom: 4),
                          ),
                          Tab(
                            icon: Icon(Icons.card_giftcard_rounded, size: 20),
                            text: 'Récompenses',
                            iconMargin: EdgeInsets.only(bottom: 4),
                          ),
                          Tab(
                            icon: Icon(Icons.block_rounded, size: 20),
                            text: 'Sanctions',
                            iconMargin: EdgeInsets.only(bottom: 4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Contenu des onglets avec animation
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.1),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        )),
                        child: child,
                      ),
                    );
                  },
                  child: _buildTasksSection(),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.1),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        )),
                        child: child,
                      ),
                    );
                  },
                  child: _buildRewardsSection(),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.1),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        )),
                        child: child,
                      ),
                    );
                  },
                  child: _buildSanctionsSection(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksSection() {
    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: _isLoadingTasks
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? _buildEmptyState(
                  icon: Icons.task_alt_rounded,
                  title: 'Aucune tâche',
                  subtitle: 'Créez des tâches pour vos enfants',
                  buttonText: 'Créer une tâche',
                  onPressed: () => _navigateToAddTask(),
                  color: AppColors.taskPositive,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tasks.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _tasks.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: _buildAddButton(
                          label: 'Créer une tâche',
                          icon: Icons.add,
                          gradient: AppColors.gradientTertiary,
                          onTap: () => _navigateToAddTask(),
                        ),
                      );
                    }
                    return _buildTaskCard(_tasks[index]);
                  },
                ),
    );
  }

  Widget _buildRewardsSection() {
    return Consumer<RewardsProvider>(
      builder: (context, rewardsProvider, child) {
        if (rewardsProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final rewards = rewardsProvider.rewards;

        if (rewards.isEmpty) {
          return _buildEmptyState(
            icon: Icons.card_giftcard,
            title: 'Aucune récompense',
            subtitle: 'Créez des récompenses pour motiver vos enfants',
            buttonText: 'Créer une récompense',
            onPressed: () => _navigateToAddRewardScreen(),
            color: Colors.amber,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rewards.length + 1,
          itemBuilder: (context, index) {
            if (index == rewards.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _buildAddButton(
                  label: 'Créer une récompense',
                  icon: Icons.add,
                  gradient: [Colors.amber[600]!, Colors.amber[400]!],
                  onTap: () => _navigateToAddRewardScreen(),
                ),
              );
            }
            return _buildRewardCard(rewards[index]);
          },
        );
      },
    );
  }

  Widget _buildSanctionsSection() {
    return Consumer<RewardsProvider>(
      builder: (context, rewardsProvider, child) {
        if (rewardsProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final sanctions = rewardsProvider.sanctions;

        if (sanctions.isEmpty) {
          return _buildEmptyState(
            icon: Icons.block,
            title: 'Aucune sanction',
            subtitle: 'Créez des sanctions pour les étoiles négatives',
            buttonText: 'Créer une sanction',
            onPressed: () => _navigateToAddSanctionScreen(),
            color: Colors.red,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sanctions.length + 1,
          itemBuilder: (context, index) {
            if (index == sanctions.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _buildAddButton(
                  label: 'Créer une sanction',
                  icon: Icons.add,
                  gradient: AppColors.gradientPrimary,
                  onTap: () => _navigateToAddSanctionScreen(),
                ),
              );
            }
            return _buildSanctionCard(sanctions[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animation de l'icône
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.15),
                          color.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(icon, size: 64, color: color),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            // Titre avec animation
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            // Sous-titre avec animation
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            // Bouton avec animation et dégradé
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.9 + (0.1 * value),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color,
                          color.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onPressed,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                buttonText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton({
    required String label,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: gradient.last.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: 22),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskCard(Task task) {
    // Vérifier si la tâche quotidienne a été complétée par tous les enfants aujourd'hui
    bool isCompletedToday = task.isDaily ? task.isCompletedTodayByAllChildren() : false;
    
    // Animation pour l'effet de survol
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: isCompletedToday
            ? LinearGradient(
                colors: [Colors.grey[100]!, Colors.grey[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [Colors.white, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: [
          BoxShadow(
            color: isCompletedToday
                ? Colors.grey.withOpacity(0.2)
                : (task.type == TaskType.positive
                    ? AppColors.taskPositive.withOpacity(0.15)
                    : AppColors.taskNegative.withOpacity(0.15)),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isCompletedToday
              ? Colors.grey[300]!
              : (task.type == TaskType.positive
                  ? AppColors.taskPositive.withOpacity(0.3)
                  : AppColors.taskNegative.withOpacity(0.3)),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isCompletedToday ? null : () => _showTaskDetails(task),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icône améliorée avec animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isCompletedToday
                          ? [Colors.grey[300]!, Colors.grey[400]!]
                          : (task.type == TaskType.positive
                              ? [AppColors.taskPositive.withOpacity(0.8), AppColors.taskPositive]
                              : [AppColors.taskNegative.withOpacity(0.8), AppColors.taskNegative]),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: isCompletedToday
                            ? Colors.grey.withOpacity(0.3)
                            : (task.type == TaskType.positive
                                ? AppColors.taskPositive.withOpacity(0.3)
                                : AppColors.taskNegative.withOpacity(0.3)),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    task.type == TaskType.positive ? Icons.add_circle_rounded : Icons.remove_circle_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Contenu principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isCompletedToday ? Colors.grey[600] : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          // Badge d'étoiles
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: task.type == TaskType.positive
                                    ? [AppColors.starPositive, AppColors.starPositive.withOpacity(0.8)]
                                    : [AppColors.starNegative, AppColors.starNegative.withOpacity(0.8)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${task.type == TaskType.positive ? "+" : "-"}${task.stars}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (task.description != null)
                        Text(
                          task.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: isCompletedToday ? Colors.grey[500] : AppColors.textSecondary,
                          ),
                        ),
                      if (task.isDaily) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCompletedToday ? Colors.grey[200] : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Tâche quotidienne',
                            style: TextStyle(
                              fontSize: 11,
                              color: isCompletedToday ? Colors.grey[600] : Colors.blue[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (task.childIds.length > 1) ...[
                          const SizedBox(height: 4),
                          // Afficher l'état de complétion pour les tâches multi-enfants
                          Builder(
                            builder: (context) {
                              final completedCount = task.getChildrenCompletedToday().length;
                              final totalCount = task.childIds.length;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: completedCount == totalCount
                                      ? Colors.green.withOpacity(0.1)
                                      : (completedCount > 0 ? Colors.orange.withOpacity(0.1) : Colors.grey.withOpacity(0.1)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Progression: $completedCount/$totalCount',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: completedCount == totalCount
                                        ? Colors.green[700]
                                        : (completedCount > 0 ? Colors.orange[700] : Colors.grey[600]),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                          ),
                        ] else if (task.childIds.isNotEmpty && task.isCompletedTodayByChild(task.childIds.first))
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Complétée aujourd\'hui',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                // Menu d'options
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: isCompletedToday ? Colors.grey[400] : AppColors.textSecondary),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await _navigateToEditTask(task);
                    } else if (value == 'delete') {
                      await _deleteTask(task);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20, color: AppColors.textSecondary),
                          const SizedBox(width: 12),
                          const Text('Modifier'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 20, color: AppColors.taskNegative),
                          const SizedBox(width: 12),
                          Text('Supprimer', style: TextStyle(color: AppColors.taskNegative)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTaskDetails(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null) ...[
              Text(task.description!),
              const SizedBox(height: 16),
            ],
            Text(
              'Type: ${task.type == TaskType.positive ? 'Positif' : 'Négatif'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Étoiles: ${task.type == TaskType.positive ? "+" : "-"}${task.stars}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (task.isDaily)
              Text(
                'Tâche quotidienne: Oui',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToEditTask(Task task) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTaskScreen(task: task),
      ),
    );
    if (result == true) {
      _loadTasks();
    }
  }

  Future<void> _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer la tâche "${task.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirestoreService().deleteTask(task.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tâche supprimée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          _loadTasks();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildRewardCard(Reward reward) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.white, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.starPositive.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppColors.starPositive.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToAddRewardScreen(reward: reward),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icône améliorée avec animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.starPositive.withOpacity(0.8), AppColors.starPositive],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.starPositive.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.card_giftcard_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Contenu principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              reward.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          // Badge d'étoiles
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.starPositive, AppColors.starPositive.withOpacity(0.8)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${reward.starsCost} ⭐',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        reward.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Menu d'options
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await _navigateToAddRewardScreen(reward: reward);
                    } else if (value == 'delete') {
                      // Implémenter la suppression si nécessaire
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20, color: AppColors.textSecondary),
                          const SizedBox(width: 12),
                          const Text('Modifier'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSanctionCard(Sanction sanction) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.white, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.taskNegative.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppColors.taskNegative.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToAddSanctionScreen(sanction: sanction),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icône améliorée avec animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.taskNegative.withOpacity(0.8), AppColors.taskNegative],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.taskNegative.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.block_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Contenu principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              sanction.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          // Badge d'étoiles
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.taskNegative, AppColors.taskNegative.withOpacity(0.8)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '-${sanction.starsCost} ⭐',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sanction.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (sanction.durationText != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.taskNegative.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Durée: ${sanction.durationText}',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.taskNegative,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Menu d'options
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await _navigateToAddSanctionScreen(sanction: sanction);
                    } else if (value == 'delete') {
                      // Implémenter la suppression si nécessaire
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20, color: AppColors.textSecondary),
                          const SizedBox(width: 12),
                          const Text('Modifier'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToAddTask() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTaskScreen()),
    );
    if (result == true) {
      _loadTasks();
    }
  }

  Future<void> _navigateToAddRewardScreen({Reward? reward}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRewardScreen(reward: reward),
      ),
    );
    if (result == true) {
      _loadRewardsAndSanctions();
    }
  }

  Future<void> _navigateToAddSanctionScreen({Sanction? sanction}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddSanctionScreen(sanction: sanction),
      ),
    );
    if (result == true) {
      _loadRewardsAndSanctions();
    }
  }
}
