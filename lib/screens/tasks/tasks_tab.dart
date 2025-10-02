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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.gradientSecondary,
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 24, right: 24, bottom: 60, top: 60),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.task_alt_rounded, size: 40, color: Colors.white),
                        SizedBox(height: 12),
                        Text(
                          'Gestion',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [
                  Tab(text: 'Tâches'),
                  Tab(text: 'Récompenses'),
                  Tab(text: 'Sanctions'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTasksSection(),
            _buildRewardsSection(),
            _buildSanctionsSection(),
          ],
        ),
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
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: color),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.add),
              label: Text(buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
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
    return Container(
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
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    // Vérifier si la tâche quotidienne a été complétée aujourd'hui
    bool isCompletedToday = false;
    if (task.isDaily && task.lastCompletedAt != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastCompletedDate = DateTime(
        task.lastCompletedAt!.year,
        task.lastCompletedAt!.month,
        task.lastCompletedAt!.day,
      );
      isCompletedToday = lastCompletedDate == today;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isCompletedToday ? Colors.grey[100] : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCompletedToday
              ? Colors.grey[300]
              : task.type == TaskType.positive ? Colors.green[100] : Colors.red[100],
          child: Icon(
            task.type == TaskType.positive ? Icons.add_circle : Icons.remove_circle,
            color: isCompletedToday
                ? Colors.grey[600]
                : task.type == TaskType.positive ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isCompletedToday ? Colors.grey[600] : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null)
              Text(
                task.description!,
                style: TextStyle(
                  color: isCompletedToday ? Colors.grey[500] : null,
                ),
              ),
            if (task.isDaily)
              Text(
                'Tâche quotidienne${isCompletedToday ? ' - Complétée aujourd\'hui' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: isCompletedToday ? Colors.grey[500] : Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              await _navigateToEditTask(task);
            } else if (value == 'delete') {
              await _deleteTask(task);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: isCompletedToday ? null : () => _showTaskDetails(task),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.amber,
          child: Icon(Icons.card_giftcard, color: Colors.white),
        ),
        title: Text(reward.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(reward.description),
        trailing: Text(
          '${reward.starsCost} ⭐',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.amber,
          ),
        ),
        onTap: () => _navigateToAddRewardScreen(reward: reward),
      ),
    );
  }

  Widget _buildSanctionCard(Sanction sanction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.red,
          child: Icon(Icons.block, color: Colors.white),
        ),
        title: Text(sanction.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sanction.description),
            if (sanction.durationText != null)
              Text(
                'Durée: ${sanction.durationText}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
          ],
        ),
        trailing: Text(
          '-${sanction.starsCost} ⭐',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        onTap: () => _navigateToAddSanctionScreen(sanction: sanction),
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
