import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/rewards_provider.dart';
import '../../providers/children_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/child.dart';
import '../../models/reward.dart';
import '../../utils/ad_helper.dart';

class RewardsCatalogScreen extends StatefulWidget {
  final Child child;

  const RewardsCatalogScreen({super.key, required this.child});

  @override
  State<RewardsCatalogScreen> createState() => _RewardsCatalogScreenState();
}

class _RewardsCatalogScreenState extends State<RewardsCatalogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final rewardsProvider = context.read<RewardsProvider>();
    // Pour l'instant, on utilise familyId comme parentId
    // Cela sera mis à jour avec le système de familles
    rewardsProvider.loadRewards(widget.child.familyId);
    rewardsProvider.loadRewardExchanges(widget.child.id);
  }

  @override
  Widget build(BuildContext context) {
    final rewardsProvider = context.watch<RewardsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalogue de Récompenses'),
        backgroundColor: Colors.amber,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Chip(
              avatar: const Icon(Icons.star, color: Colors.amber, size: 18),
              label: Text(
                '${widget.child.stars}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.white,
            ),
          ),
        ],
      ),
      body: rewardsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (rewardsProvider.rewardExchanges.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.amber.shade50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mes Récompenses en attente',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...rewardsProvider.rewardExchanges
                            .where((exchange) => !exchange.isCompleted)
                            .map((exchange) => Card(
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.card_giftcard,
                                      color: Colors.amber,
                                    ),
                                    title: Text(exchange.rewardName),
                                    subtitle: Text(
                                      'Échangée le ${_formatDate(exchange.exchangedAt)}',
                                    ),
                                    trailing: const Chip(
                                      label: Text('En attente'),
                                      backgroundColor: Colors.orange,
                                      labelStyle: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                )),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                ],
                Expanded(
                  child: rewardsProvider.rewards.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.card_giftcard, size: 80, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'Aucune récompense disponible',
                                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Demande à tes parents d\'ajouter des récompenses',
                                style: TextStyle(color: Colors.grey[500]),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: rewardsProvider.rewards.length,
                          itemBuilder: (context, index) {
                            final reward = rewardsProvider.rewards[index];
                            final canAfford = widget.child.stars >= reward.starsCost;

                            return Card(
                              elevation: 4,
                              child: InkWell(
                                onTap: canAfford
                                    ? () => _confirmExchange(reward)
                                    : null,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.card_giftcard,
                                              size: 48,
                                              color: canAfford ? Colors.amber : Colors.grey,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              reward.name,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: canAfford ? Colors.black : Colors.grey,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        reward.description,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: canAfford ? Colors.grey[700] : Colors.grey,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: canAfford ? Colors.amber : Colors.grey,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${reward.starsCost}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _confirmExchange(Reward reward) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Échanger une récompense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voulez-vous échanger ${reward.starsCost} étoiles contre:'),
            const SizedBox(height: 8),
            Text(
              reward.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(reward.description),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Vos étoiles actuelles: '),
                const Icon(Icons.star, size: 16, color: Colors.amber),
                Text(
                  '${widget.child.stars}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Row(
              children: [
                const Text('Après échange: '),
                const Icon(Icons.star, size: 16, color: Colors.amber),
                Text(
                  '${widget.child.stars - reward.starsCost}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final rewardsProvider = context.read<RewardsProvider>();
              final childrenProvider = context.read<ChildrenProvider>();

              final success = await rewardsProvider.exchangeReward(
                widget.child,
                reward,
                (updatedChild) async {
                  await childrenProvider.updateChild(updatedChild);
                },
              );

              Navigator.pop(context);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Récompense "${reward.name}" échangée avec succès!'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadData();
                
                // Afficher une publicité après un échange de récompense réussi
                final authProvider = context.read<AuthProvider>();
                if (authProvider.currentUser != null) {
                  // Attendre un peu pour que le SnackBar soit visible
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) {
                      AdHelper.showAdIfAvailable(context, authProvider.currentUser!.id);
                    }
                  });
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(rewardsProvider.error ?? 'Erreur lors de l\'échange'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('Échanger'),
          ),
        ],
      ),
    );
  }
}