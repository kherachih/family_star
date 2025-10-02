import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rewards_provider.dart';
import '../../models/sanction.dart';
import 'add_sanction_screen.dart';

class SanctionsManagementScreen extends StatefulWidget {
  const SanctionsManagementScreen({super.key});

  @override
  State<SanctionsManagementScreen> createState() => _SanctionsManagementScreenState();
}

class _SanctionsManagementScreenState extends State<SanctionsManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSanctions();
    });
  }

  void _loadSanctions() {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser != null) {
      context.read<RewardsProvider>().loadSanctions(authProvider.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final rewardsProvider = context.watch<RewardsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Sanctions'),
        backgroundColor: Colors.red,
      ),
      body: rewardsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : rewardsProvider.sanctions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.block, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune sanction',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ajoutez des sanctions pour les étoiles négatives',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: rewardsProvider.sanctions.length,
                  itemBuilder: (context, index) {
                    final sanction = rewardsProvider.sanctions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red,
                          child: const Icon(Icons.block, color: Colors.white),
                        ),
                        title: Text(
                          sanction.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sanction.description),
                            const SizedBox(height: 4),
                            if (sanction.durationText != null)
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    sanction.durationText!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star, size: 16, color: Colors.red),
                                const SizedBox(width: 4),
                                Text(
                                  '-${sanction.starsCost} étoiles',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
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
                              _navigateToAddSanctionScreen(sanction: sanction);
                            } else if (value == 'delete') {
                              _confirmDelete(sanction);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddSanctionScreen(),
        backgroundColor: Colors.red,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter une sanction'),
      ),
    );
  }

  void _navigateToAddSanctionScreen({Sanction? sanction}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddSanctionScreen(sanction: sanction),
      ),
    ).then((_) {
      // Recharger les sanctions après le retour de l'écran d'ajout/modification
      _loadSanctions();
    });
  }

  void _confirmDelete(Sanction sanction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer la sanction "${sanction.name}" ?'),
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
                await rewardsProvider.deleteSanction(
                  sanction.id!,
                  authProvider.currentUser!.id,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sanction supprimée')),
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
