import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/children_provider.dart';
import '../../models/child.dart';
import '../../utils/app_colors.dart';
import 'add_child_screen.dart';
import 'child_profile_screen.dart';

class ChildrenTab extends StatefulWidget {
  const ChildrenTab({super.key});

  @override
  State<ChildrenTab> createState() => _ChildrenTabState();
}

class _ChildrenTabState extends State<ChildrenTab> {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Consumer<ChildrenProvider>(
          builder: (context, childrenProvider, child) {
            if (childrenProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final children = childrenProvider.children;

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // AppBar avec dégradé
                SliverAppBar(
                  expandedHeight: 150,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: AppColors.gradientTertiary,
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 60),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.people_rounded,
                              size: 40,
                              color: Colors.white,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Mes Enfants',
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
                ),

                // Liste des enfants
                if (children.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: AppColors.gradientPrimary,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person_add_rounded,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Aucun enfant',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Commencez par ajouter votre premier enfant',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddChildScreen(),
                                ),
                              );
                              if (result == true) {
                                _loadData();
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Ajouter un enfant'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _buildChildCard(children[index]);
                        },
                        childCount: children.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: Consumer<ChildrenProvider>(
        builder: (context, childrenProvider, child) {
          if (childrenProvider.children.isEmpty) return const SizedBox();

          return Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.gradientPrimary,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddChildScreen(),
                    ),
                  );
                  if (result == true) {
                    _loadData();
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Ajouter',
                        style: TextStyle(
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
        },
      ),
    );
  }

  Widget _buildChildCard(Child child) {
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
                // Avatar avec cercle dégradé
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

                // Infos enfant
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
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
}
