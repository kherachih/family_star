import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rewards_provider.dart';
import '../../models/reward.dart';
import 'add_reward_screen.dart';

class RewardsManagementScreen extends StatefulWidget {
  const RewardsManagementScreen({super.key});

  @override
  State<RewardsManagementScreen> createState() => _RewardsManagementScreenState();
}

class _RewardsManagementScreenState extends State<RewardsManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRewards();
    });
  }

  void _loadRewards() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser != null) {
      context.read<RewardsProvider>().loadRewards(authProvider.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final rewardsProvider = context.watch<RewardsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Récompenses'),
        backgroundColor: Colors.amber,
      ),
      body: rewardsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : rewardsProvider.rewards.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.card_giftcard, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune récompense',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ajoutez des récompenses pour motiver vos enfants',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: rewardsProvider.rewards.length,
                  itemBuilder: (context, index) {
                    final reward = rewardsProvider.rewards[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.amber,
                          child: const Icon(Icons.card_giftcard, color: Colors.white),
                        ),
                        title: Text(
                          reward.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(reward.description),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star, size: 16, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  '${reward.starsCost} étoiles',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('Modifier'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _navigateToAddRewardScreen(reward: reward);
                            } else if (value == 'delete') {
                              _confirmDelete(reward);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddRewardScreen(),
        backgroundColor: Colors.amber,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter une récompense'),
      ),
    );
  }

  void _navigateToAddRewardScreen({Reward? reward}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRewardScreen(reward: reward),
      ),
    ).then((_) {
      // Recharger les récompenses après le retour de l'écran d'ajout/modification
      _loadRewards();
    });
  }

  void _confirmDelete(Reward reward) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer la récompense "${reward.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authProvider = context.read<AuthProvider>();
              final rewardsProvider = context.read<RewardsProvider>();

              try {
                await rewardsProvider.deleteReward(
                  reward.id!,
                  authProvider.currentUser!.id,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Récompense supprimée')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
