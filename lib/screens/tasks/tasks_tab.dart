import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rewards_provider.dart';
import '../../utils/app_colors.dart';
import '../../models/task.dart';
import '../../models/reward.dart';
import '../../models/sanction.dart';
import '../../services/firestore_service.dart';
import '../../services/auto_ad_service.dart';
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
    
    // Écouter les changements d'onglets pour les publicités automatiques
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final tabNames = ['Tâches', 'Récompenses', 'Sanctions'];
        AutoAdService().onScreenChanged('Tâches - ${tabNames[_tabController.index]}');
      }
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      // Notifier l'ouverture de l'écran des tâches
      AutoAdService().onScreenChanged('Tâches - Tâches');
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
    // Récupérer la taille de l'écran pour le responsive design
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final isTablet = screenSize.width > 600;
    
    return Scaffold(
      body: Column(
        children: [
          // Header Tâches sans AppBar
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkGradientSecondary
                    : AppColors.gradientSecondary,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 10.0 : 12.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.task_alt_rounded,
                            size: isSmallScreen ? 28.0 : 32.0,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 10.0 : 12.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gestion',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 18.0 : 20.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Tâches, récompenses et sanctions',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 11.0 : 12.0,
                                  color: Colors.white70,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 12.0 : 16.0),
                    // TabBar personnalisé amélioré
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(isSmallScreen ? 12.0 : 16.0),
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
                          borderRadius: BorderRadius.circular(isSmallScreen ? 8.0 : 12.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        labelColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black // Texte noir pour mode sombre
                            : AppColors.textPrimary, // Couleur plus foncée pour meilleure lisibilité
                        unselectedLabelColor: Colors.white, // Blanc pur pour les onglets non sélectionnés
                        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmallScreen ? 11.0 : 13.0),
                        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: isSmallScreen ? 11.0 : 13.0),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent, // Supprime le trait sous les onglets
                        tabs: [
                          Tab(
                            icon: Icon(Icons.task_alt_rounded, size: isSmallScreen ? 18.0 : 20.0),
                            text: 'Tâches',
                            iconMargin: EdgeInsets.only(bottom: isSmallScreen ? 2.0 : 4.0),
                          ),
                          Tab(
                            icon: Icon(Icons.card_giftcard_rounded, size: isSmallScreen ? 18.0 : 20.0),
                            text: 'Récompenses',
                            iconMargin: EdgeInsets.only(bottom: isSmallScreen ? 2.0 : 4.0),
                          ),
                          Tab(
                            icon: Icon(Icons.block_rounded, size: isSmallScreen ? 18.0 : 20.0),
                            text: 'Sanctions',
                            iconMargin: EdgeInsets.only(bottom: isSmallScreen ? 2.0 : 4.0),
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
                  child: _buildTasksSection(isSmallScreen, isTablet),
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
                  child: _buildRewardsSection(isSmallScreen, isTablet),
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
                  child: _buildSanctionsSection(isSmallScreen, isTablet),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksSection(bool isSmallScreen, bool isTablet) {
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
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTaskPositive
                      : AppColors.taskPositive,
                  isSmallScreen: isSmallScreen,
                  isTablet: isTablet,
                )
              : ListView.builder(
                  padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                  itemCount: _tasks.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _tasks.length) {
                      return Padding(
                        padding: EdgeInsets.only(top: isSmallScreen ? 12.0 : 16.0),
                        child: _buildAddButton(
                          label: 'Créer une tâche',
                          icon: Icons.add,
                          gradient: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkGradientTertiary
                              : AppColors.gradientTertiary,
                          onTap: () => _navigateToAddTask(),
                          isSmallScreen: isSmallScreen,
                          isTablet: isTablet,
                        ),
                      );
                    }
                    return _buildTaskCard(_tasks[index], isSmallScreen, isTablet);
                  },
                ),
    );
  }

  Widget _buildRewardsSection(bool isSmallScreen, bool isTablet) {
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
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkSecondary
                : Colors.amber,
            isSmallScreen: isSmallScreen,
            isTablet: isTablet,
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
          itemCount: rewards.length + 1,
          itemBuilder: (context, index) {
            if (index == rewards.length) {
              return Padding(
                padding: EdgeInsets.only(top: isSmallScreen ? 12.0 : 16.0),
                child: _buildAddButton(
                  label: 'Créer une récompense',
                  icon: Icons.add,
                  gradient: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkGradientSecondary
                      : [Colors.amber[600]!, Colors.amber[400]!],
                  onTap: () => _navigateToAddRewardScreen(),
                  isSmallScreen: isSmallScreen,
                  isTablet: isTablet,
                ),
              );
            }
            return _buildRewardCard(rewards[index], isSmallScreen, isTablet);
          },
        );
      },
    );
  }

  Widget _buildSanctionsSection(bool isSmallScreen, bool isTablet) {
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
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTaskNegative
                : Colors.red,
            isSmallScreen: isSmallScreen,
            isTablet: isTablet,
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
          itemCount: sanctions.length + 1,
          itemBuilder: (context, index) {
            if (index == sanctions.length) {
              return Padding(
                padding: EdgeInsets.only(top: isSmallScreen ? 12.0 : 16.0),
                child: _buildAddButton(
                  label: 'Créer une sanction',
                  icon: Icons.add,
                  gradient: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkGradientPrimary
                      : AppColors.gradientPrimary,
                  onTap: () => _navigateToAddSanctionScreen(),
                  isSmallScreen: isSmallScreen,
                  isTablet: isTablet,
                ),
              );
            }
            return _buildSanctionCard(sanctions[index], isSmallScreen, isTablet);
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
    required bool isSmallScreen,
    required bool isTablet,
  }) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 24.0 : 32.0),
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
                      padding: EdgeInsets.all(isSmallScreen ? 24.0 : 32.0),
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
                      child: Icon(icon, size: isSmallScreen ? 48.0 : 64.0, color: color),
                    ),
                  );
                },
              ),
              SizedBox(height: isSmallScreen ? 24.0 : 32.0),
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
                        style: TextStyle(
                          fontSize: isSmallScreen ? 22.0 : 26.0,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextPrimary // Texte principal pour mode sombre
                              : AppColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: isSmallScreen ? 8.0 : 12.0),
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
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14.0 : 16.0,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextSecondary // Texte secondaire pour mode sombre
                              : AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: isSmallScreen ? 24.0 : 32.0),
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
                        borderRadius: BorderRadius.circular(isSmallScreen ? 12.0 : 16.0),
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
                          borderRadius: BorderRadius.circular(isSmallScreen ? 12.0 : 16.0),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 24.0 : 32.0,
                              vertical: isSmallScreen ? 12.0 : 16.0
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_rounded, color: Colors.white, size: isSmallScreen ? 18.0 : 20.0),
                                SizedBox(width: isSmallScreen ? 6.0 : 8.0),
                                Text(
                                  buttonText,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmallScreen ? 14.0 : 16.0,
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
      ),
    );
  }

  Widget _buildAddButton({
    required String label,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
    required bool isSmallScreen,
    required bool isTablet,
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
              borderRadius: BorderRadius.circular(isSmallScreen ? 12.0 : 16.0),
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
                borderRadius: BorderRadius.circular(isSmallScreen ? 12.0 : 16.0),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 14.0 : 18.0,
                    horizontal: isTablet ? 24.0 : 16.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: isSmallScreen ? 20.0 : 22.0),
                      SizedBox(width: isSmallScreen ? 10.0 : 12.0),
                      Flexible(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 14.0 : 16.0,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
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

  Widget _buildTaskCard(Task task, bool isSmallScreen, bool isTablet) {
    // Vérifier si la tâche quotidienne a été complétée par tous les enfants aujourd'hui
    bool isCompletedToday = task.isDaily ? task.isCompletedTodayByAllChildren() : false;
    
    // Animation pour l'effet de survol
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12.0 : 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isSmallScreen ? 12.0 : 16.0),
        gradient: isCompletedToday
            ? LinearGradient(
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [AppColors.darkCard, AppColors.darkSurface]
                    : [Colors.grey[100]!, Colors.grey[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [AppColors.darkCard, AppColors.darkCard]
                    : [Colors.white, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: [
          BoxShadow(
            color: isCompletedToday
                ? Colors.grey.withOpacity(0.2)
                : (task.type == TaskType.positive
                    ? (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTaskPositive.withOpacity(0.15)
                        : AppColors.taskPositive.withOpacity(0.15))
                    : (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTaskNegative.withOpacity(0.15)
                        : AppColors.taskNegative.withOpacity(0.15))),
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
                  ? (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTaskPositive.withOpacity(0.3)
                      : AppColors.taskPositive.withOpacity(0.3))
                  : (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTaskNegative.withOpacity(0.3)
                      : AppColors.taskNegative.withOpacity(0.3))),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(isSmallScreen ? 12.0 : 16.0),
          onTap: isCompletedToday ? null : () => _showTaskDetails(task),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
            child: Row(
              children: [
                // Icône améliorée avec animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: EdgeInsets.all(isSmallScreen ? 10.0 : 12.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isCompletedToday
                          ? [Colors.grey[300]!, Colors.grey[400]!]
                          : (task.type == TaskType.positive
                              ? (Theme.of(context).brightness == Brightness.dark
                                  ? [AppColors.darkTaskPositive.withOpacity(0.8), AppColors.darkTaskPositive]
                                  : [AppColors.taskPositive.withOpacity(0.8), AppColors.taskPositive])
                              : (Theme.of(context).brightness == Brightness.dark
                                  ? [AppColors.darkTaskNegative.withOpacity(0.8), AppColors.darkTaskNegative]
                                  : [AppColors.taskNegative.withOpacity(0.8), AppColors.taskNegative])),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(isSmallScreen ? 8.0 : 12.0),
                    boxShadow: [
                      BoxShadow(
                        color: isCompletedToday
                            ? Colors.grey.withOpacity(0.3)
                            : (task.type == TaskType.positive
                                ? (Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.darkTaskPositive.withOpacity(0.3)
                                    : AppColors.taskPositive.withOpacity(0.3))
                                : (Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.darkTaskNegative.withOpacity(0.3)
                                    : AppColors.taskNegative.withOpacity(0.3))),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    task.type == TaskType.positive ? Icons.add_circle_rounded : Icons.remove_circle_rounded,
                    color: Colors.white,
                    size: isSmallScreen ? 20.0 : 24.0,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12.0 : 16.0),
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
                                fontSize: isSmallScreen ? 14.0 : 16.0,
                                fontWeight: FontWeight.bold,
                                color: isCompletedToday
                                    ? (Theme.of(context).brightness == Brightness.dark
                                        ? AppColors.darkTextLight
                                        : Colors.grey[600])
                                    : (Theme.of(context).brightness == Brightness.dark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.textPrimary),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: isSmallScreen ? 1 : 2,
                            ),
                          ),
                          // Badge d'étoiles
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 6.0 : 8.0,
                              vertical: isSmallScreen ? 2.0 : 4.0
                            ),
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
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallScreen ? 10.0 : 12.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 6.0 : 8.0),
                      if (task.description != null)
                        Text(
                          task.description!,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12.0 : 14.0,
                            color: isCompletedToday
                                ? (Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.darkTextLight
                                    : Colors.grey[500])
                                : (Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: isSmallScreen ? 2 : 3,
                        ),
                      if (task.isDaily) ...[
                        SizedBox(height: isSmallScreen ? 6.0 : 8.0),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 6.0 : 8.0,
                            vertical: isSmallScreen ? 2.0 : 4.0
                          ),
                          decoration: BoxDecoration(
                            color: isCompletedToday
                                ? (Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.darkTextLight.withOpacity(0.2)
                                    : Colors.grey[200])
                                : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Tâche quotidienne',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 9.0 : 11.0,
                              color: isCompletedToday
                                  ? (Theme.of(context).brightness == Brightness.dark
                                      ? AppColors.darkTextLight
                                      : Colors.grey[600])
                                  : Colors.blue[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (task.childIds.length > 1) ...[
                          SizedBox(height: isSmallScreen ? 2.0 : 4.0),
                          // Afficher l'état de complétion pour les tâches multi-enfants
                          Builder(
                            builder: (context) {
                              final completedCount = task.getChildrenCompletedToday().length;
                              final totalCount = task.childIds.length;
                              return Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 6.0 : 8.0,
                                  vertical: isSmallScreen ? 2.0 : 4.0
                                ),
                                decoration: BoxDecoration(
                                  color: completedCount == totalCount
                                      ? (Theme.of(context).brightness == Brightness.dark
                                          ? AppColors.darkTaskBackgroundPositive
                                          : Colors.green.withOpacity(0.1))
                                      : (completedCount > 0
                                          ? Colors.orange.withOpacity(0.1)
                                          : (Theme.of(context).brightness == Brightness.dark
                                              ? AppColors.darkCard
                                              : Colors.grey.withOpacity(0.1))),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Progression: $completedCount/$totalCount',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 9.0 : 11.0,
                                    color: completedCount == totalCount
                                        ? (Theme.of(context).brightness == Brightness.dark
                                            ? AppColors.darkTaskPositive
                                            : Colors.green[700])
                                        : (completedCount > 0
                                            ? Colors.orange[700]
                                            : (Theme.of(context).brightness == Brightness.dark
                                                ? AppColors.darkTextLight
                                                : Colors.grey[600])),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                          ),
                        ] else if (task.childIds.isNotEmpty && task.isCompletedTodayByChild(task.childIds.first))
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 6.0 : 8.0,
                              vertical: isSmallScreen ? 2.0 : 4.0
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.darkTaskBackgroundPositive
                                  : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Complétée aujourd\'hui',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 9.0 : 11.0,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.darkTaskPositive
                                    : Colors.green[700],
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
                  icon: Icon(
                    Icons.more_vert,
                    color: isCompletedToday
                        ? (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextLight
                            : Colors.grey[400])
                        : (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary),
                    size: isSmallScreen ? 20.0 : 24.0,
                  ),
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
                          Icon(
                            Icons.edit_outlined,
                            size: isSmallScreen ? 18.0 : 20.0,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                          SizedBox(width: isSmallScreen ? 8.0 : 12.0),
                          const Text('Modifier'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: isSmallScreen ? 18.0 : 20.0,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkTaskNegative
                                : AppColors.taskNegative,
                          ),
                          SizedBox(width: isSmallScreen ? 8.0 : 12.0),
                          Text(
                            'Supprimer',
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.darkTaskNegative
                                  : AppColors.taskNegative,
                            ),
                          ),
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

  Widget _buildRewardCard(Reward reward, bool isSmallScreen, bool isTablet) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12.0 : 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isSmallScreen ? 12.0 : 16.0),
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? [AppColors.darkCard, AppColors.darkCard]
              : [Colors.white, Colors.white],
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
          borderRadius: BorderRadius.circular(isSmallScreen ? 12.0 : 16.0),
          onTap: () => _navigateToAddRewardScreen(reward: reward),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
            child: Row(
              children: [
                // Icône améliorée avec animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: EdgeInsets.all(isSmallScreen ? 10.0 : 12.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.starPositive.withOpacity(0.8), AppColors.starPositive],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(isSmallScreen ? 8.0 : 12.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.starPositive.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.card_giftcard_rounded,
                    color: Colors.white,
                    size: isSmallScreen ? 20.0 : 24.0,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12.0 : 16.0),
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
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14.0 : 16.0,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: isSmallScreen ? 1 : 2,
                            ),
                          ),
                          // Badge d'étoiles
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 6.0 : 8.0,
                              vertical: isSmallScreen ? 2.0 : 4.0
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: Theme.of(context).brightness == Brightness.dark
                                    ? [AppColors.starPositive, AppColors.starPositive.withOpacity(0.8)]
                                    : [AppColors.starPositive, AppColors.starPositive.withOpacity(0.8)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${reward.starsCost} ⭐',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallScreen ? 10.0 : 12.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 6.0 : 8.0),
                      Text(
                        reward.description,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12.0 : 14.0,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: isSmallScreen ? 2 : 3,
                      ),
                    ],
                  ),
                ),
                // Menu d'options
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                    size: isSmallScreen ? 20.0 : 24.0,
                  ),
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
                          Icon(
                            Icons.edit_outlined,
                            size: isSmallScreen ? 18.0 : 20.0,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                          SizedBox(width: isSmallScreen ? 8.0 : 12.0),
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

  Widget _buildSanctionCard(Sanction sanction, bool isSmallScreen, bool isTablet) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12.0 : 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isSmallScreen ? 12.0 : 16.0),
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? [AppColors.darkCard, AppColors.darkCard]
              : [Colors.white, Colors.white],
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
          borderRadius: BorderRadius.circular(isSmallScreen ? 12.0 : 16.0),
          onTap: () => _navigateToAddSanctionScreen(sanction: sanction),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
            child: Row(
              children: [
                // Icône améliorée avec animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: EdgeInsets.all(isSmallScreen ? 10.0 : 12.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.taskNegative.withOpacity(0.8), AppColors.taskNegative],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(isSmallScreen ? 8.0 : 12.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.taskNegative.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.block_rounded,
                    color: Colors.white,
                    size: isSmallScreen ? 20.0 : 24.0,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12.0 : 16.0),
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
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14.0 : 16.0,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: isSmallScreen ? 1 : 2,
                            ),
                          ),
                          // Badge d'étoiles
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 6.0 : 8.0,
                              vertical: isSmallScreen ? 2.0 : 4.0
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: Theme.of(context).brightness == Brightness.dark
                                    ? [AppColors.darkTaskNegative, AppColors.darkTaskNegative.withOpacity(0.8)]
                                    : [AppColors.taskNegative, AppColors.taskNegative.withOpacity(0.8)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '-${sanction.starsCost} ⭐',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallScreen ? 10.0 : 12.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 6.0 : 8.0),
                      Text(
                        sanction.description,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12.0 : 14.0,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: isSmallScreen ? 2 : 3,
                      ),
                      if (sanction.durationText != null) ...[
                        SizedBox(height: isSmallScreen ? 6.0 : 8.0),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 6.0 : 8.0,
                            vertical: isSmallScreen ? 2.0 : 4.0
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkTaskBackgroundNegative
                                : AppColors.taskNegative.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Durée: ${sanction.durationText}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 9.0 : 11.0,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.darkTaskNegative
                                  : AppColors.taskNegative,
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
                  icon: Icon(
                    Icons.more_vert,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                    size: isSmallScreen ? 20.0 : 24.0,
                  ),
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
                          Icon(
                            Icons.edit_outlined,
                            size: isSmallScreen ? 18.0 : 20.0,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                          SizedBox(width: isSmallScreen ? 8.0 : 12.0),
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
