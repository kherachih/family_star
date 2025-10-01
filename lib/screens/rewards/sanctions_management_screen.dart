import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rewards_provider.dart';
import '../../models/sanction.dart';

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
                            if (sanction.duration != null)
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    sanction.duration!,
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
                              _showSanctionDialog(sanction: sanction);
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
        onPressed: () => _showSanctionDialog(),
        backgroundColor: Colors.red,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter une sanction'),
      ),
    );
  }

  void _showSanctionDialog({Sanction? sanction}) {
    final nameController = TextEditingController(text: sanction?.name ?? '');
    final descriptionController = TextEditingController(text: sanction?.description ?? '');
    final starsCostController = TextEditingController(
      text: sanction?.starsCost.toString() ?? '',
    );
    final durationController = TextEditingController(text: sanction?.duration ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(sanction == null ? 'Nouvelle Sanction' : 'Modifier la Sanction'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la sanction',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Pas de téléphone',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Confiscation du téléphone',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: starsCostController,
                decoration: const InputDecoration(
                  labelText: 'Nombre d\'étoiles négatives requises',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.star, color: Colors.red),
                  hintText: 'Ex: 10 pour -10 étoiles',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(
                  labelText: 'Durée (optionnel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                  hintText: 'Ex: 1 semaine, 3 jours',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  descriptionController.text.isEmpty ||
                  starsCostController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez remplir tous les champs requis')),
                );
                return;
              }

              final authProvider = context.read<AuthProvider>();
              final rewardsProvider = context.read<RewardsProvider>();

              final newSanction = Sanction(
                id: sanction?.id,
                parentId: authProvider.currentUser!.id,
                name: nameController.text,
                description: descriptionController.text,
                starsCost: int.parse(starsCostController.text),
                duration: durationController.text.isNotEmpty ? durationController.text : null,
              );

              try {
                if (sanction == null) {
                  await rewardsProvider.addSanction(newSanction);
                } else {
                  await rewardsProvider.updateSanction(newSanction);
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(sanction == null
                        ? 'Sanction ajoutée avec succès'
                        : 'Sanction modifiée avec succès'),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(sanction == null ? 'Ajouter' : 'Modifier'),
          ),
        ],
      ),
    );
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
