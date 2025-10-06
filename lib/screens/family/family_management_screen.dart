import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../models/parent.dart';
import '../../models/child.dart';
import '../../utils/app_colors.dart';

class FamilyManagementScreen extends StatefulWidget {
  const FamilyManagementScreen({super.key});

  @override
  State<FamilyManagementScreen> createState() => _FamilyManagementScreenState();
}

class _FamilyManagementScreenState extends State<FamilyManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  List<Parent> _parents = [];
  List<Child> _children = [];

  @override
  void initState() {
    super.initState();
    _loadFamilyMembers();
  }

  Future<void> _loadFamilyMembers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
      final family = familyProvider.currentFamily;
      
      if (family != null) {
        // Charger les parents
        final parents = <Parent>[];
        for (final parentId in family.parentIds) {
          final parent = await _firestoreService.getParentById(parentId);
          if (parent != null) {
            parents.add(parent);
          }
        }
        
        // Charger les enfants
        final children = await _firestoreService.getChildrenByFamilyId(family.id);
        
        setState(() {
          _parents = parents;
          _children = children;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _leaveFamily() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    final family = familyProvider.currentFamily;
    
    if (currentUser == null || family == null) return;

    // Vérifier si l'utilisateur est le créateur de la famille
    if (family.createdBy == currentUser.id) {
      // Vérifier s'il reste d'autres parents dans la famille
      if (family.parentIds.length > 1) {
        // Demander de transférer la propriété
        _showTransferOwnershipDialog();
      } else {
        // Demander confirmation pour supprimer la famille
        _showDeleteFamilyDialog();
      }
      return;
    }

    // Demander confirmation pour quitter la famille
    _showLeaveFamilyDialog();
  }

  void _showLeaveFamilyDialog() {
    final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
    final family = familyProvider.currentFamily;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Quitter la famille'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Êtes-vous sûr de vouloir quitter cette famille ?'),
            const SizedBox(height: 16),
            Text(
              'Vous ne pourrez plus voir les enfants et les tâches de la famille "${family?.name}".',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
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
              Navigator.pop(context);
              await _confirmLeaveFamily();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }

  void _showDeleteFamilyDialog() {
    final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
    final family = familyProvider.currentFamily;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer la famille'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Vous êtes le seul membre de cette famille.'),
            const SizedBox(height: 8),
            Text(
              'Si vous partez, la famille "${family?.name}" sera supprimée définitivement.',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Toutes les données associées (enfants, tâches, etc.) seront perdues.',
              style: TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.w500),
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
              Navigator.pop(context);
              await _confirmDeleteFamily();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showTransferOwnershipDialog() {
    final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
    final family = familyProvider.currentFamily;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Transférer la propriété'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Vous êtes le créateur de cette famille.'),
            const SizedBox(height: 8),
            Text(
              'Avant de quitter la famille "${family?.name}", vous devez transférer la propriété à un autre parent.',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text('Sélectionnez un nouveau propriétaire :'),
            const SizedBox(height: 8),
            // Liste des autres parents
            ..._parents
                .where((parent) => parent.id != currentUser?.id)
                .map((parent) => ListTile(
                      title: Text(parent.name),
                      subtitle: Text(parent.email),
                      leading: const Icon(Icons.person),
                      onTap: () {
                        Navigator.pop(context);
                        _transferOwnership(parent.id);
                      },
                    ))
                .toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLeaveFamily() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      final family = familyProvider.currentFamily;
      
      if (currentUser == null || family == null) return;

      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Quitter la famille...'),
            ],
          ),
        ),
      );

      // Retirer le parent de la famille
      final success = await familyProvider.removeParentFromFamily(family.id, currentUser.id);
      
      Navigator.pop(context); // Fermer le dialogue de chargement

      if (success) {
        // Recharger les familles de l'utilisateur
        await familyProvider.loadFamiliesByParentId(currentUser.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vous avez quitté la famille'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Retour à l'écran précédent
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors du départ de la famille'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      Navigator.pop(context); // Fermer le dialogue de chargement en cas d'erreur
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteFamily() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      final family = familyProvider.currentFamily;
      
      if (currentUser == null || family == null) return;

      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Suppression de la famille...'),
            ],
          ),
        ),
      );

      // Supprimer la famille (cela devrait être implémenté dans FirestoreService)
      // Pour l'instant, nous allons simplement retirer le parent
      final success = await familyProvider.removeParentFromFamily(family.id, currentUser.id);
      
      Navigator.pop(context); // Fermer le dialogue de chargement

      if (success) {
        // Recharger les familles de l'utilisateur
        await familyProvider.loadFamiliesByParentId(currentUser.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La famille a été supprimée'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Retour à l'écran précédent
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la suppression de la famille'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      Navigator.pop(context); // Fermer le dialogue de chargement en cas d'erreur
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _transferOwnership(String newOwnerId) async {
    try {
      final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
      final family = familyProvider.currentFamily;
      
      if (family == null) return;

      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Transfert de la propriété...'),
            ],
          ),
        ),
      );

      // Mettre à jour le créateur de la famille
      final updatedFamily = family.copyWith(createdBy: newOwnerId);
      await _firestoreService.updateFamily(updatedFamily);
      
      // Mettre à jour la famille locale
      familyProvider.setCurrentFamily(updatedFamily);
      
      Navigator.pop(context); // Fermer le dialogue de chargement

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La propriété a été transférée'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Maintenant, quitter la famille
        _confirmLeaveFamily();
      }
    } catch (e) {
      Navigator.pop(context); // Fermer le dialogue de chargement en cas d'erreur
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
    final family = familyProvider.currentFamily;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion de la famille'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.gradientPrimary,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : family == null
              ? const Center(
                  child: Text(
                    'Aucune famille trouvée',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Informations de la famille
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: AppColors.gradientPrimary,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.family_restroom,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    family.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Créée le ${family.createdAt.day}/${family.createdAt.month}/${family.createdAt.year}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            if (family.createdBy == currentUser?.id)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Propriétaire',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Liste des parents
                      const Text(
                        'Parents',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _parents.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.person_outline, color: Colors.grey[600]),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Aucun parent dans la famille',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _parents.length,
                              itemBuilder: (context, index) {
                                final parent = _parents[index];
                                return _MemberCard(
                                  name: parent.name,
                                  email: parent.email,
                                  isOwner: family.createdBy == parent.id,
                                  isCurrentUser: currentUser?.id == parent.id,
                                  icon: Icons.person,
                                );
                              },
                            ),
                      const SizedBox(height: 24),

                      // Liste des enfants
                      const Text(
                        'Enfants',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _children.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.child_care, color: Colors.grey[600]),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Aucun enfant dans la famille',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _children.length,
                              itemBuilder: (context, index) {
                                final child = _children[index];
                                return _MemberCard(
                                  name: child.name,
                                  email: 'Âge: ${child.age} ans',
                                  isOwner: false,
                                  isCurrentUser: false,
                                  icon: Icons.child_care,
                                );
                              },
                            ),
                      const SizedBox(height: 32),

                      // Bouton pour quitter la famille
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _leaveFamily,
                          icon: const Icon(Icons.exit_to_app),
                          label: Text(
                            family.createdBy == currentUser?.id
                                ? 'Quitter et supprimer la famille'
                                : 'Quitter la famille',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final String name;
  final String email;
  final bool isOwner;
  final bool isCurrentUser;
  final IconData icon;

  const _MemberCard({
    required this.name,
    required this.email,
    required this.isOwner,
    required this.isCurrentUser,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isOwner ? Colors.amber[100] : Colors.blue[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isOwner ? Colors.amber[700] : Colors.blue[700],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Vous',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (isOwner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.amber[700],
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Propriétaire',
                    style: TextStyle(
                      color: Colors.amber[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}