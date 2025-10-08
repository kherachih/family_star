import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
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
            content: Text('common.error'.tr() + ': ${e.toString()}'),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'ui.family_management.leave_confirm_title'.tr(),
          style: TextStyle(
            color: isDarkMode ? AppColors.darkTextPrimary : Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ui.family_management.leave_confirm_message'.tr(),
              style: TextStyle(
                color: isDarkMode ? AppColors.darkTextPrimary : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ui.family_management.leave_warning'.tr(args: [family?.name ?? '']),
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? AppColors.darkTextSecondary : Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'common.cancel'.tr(),
              style: TextStyle(
                color: isDarkMode ? AppColors.darkTextSecondary : Colors.black,
              ),
            ),
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
            child: Text('ui.family_management.leave_family'.tr()),
          ),
        ],
      ),
    );
  }

  void _showDeleteFamilyDialog() {
    final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
    final family = familyProvider.currentFamily;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'ui.family_management.delete_confirm_title'.tr(),
          style: TextStyle(
            color: isDarkMode ? AppColors.darkTextPrimary : Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ui.family_management.delete_owner_message'.tr(),
              style: TextStyle(
                color: isDarkMode ? AppColors.darkTextPrimary : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ui.family_management.delete_warning'.tr(args: [family?.name ?? '']),
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? AppColors.darkTextSecondary : Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ui.family_management.delete_data_warning'.tr(),
              style: TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'common.cancel'.tr(),
              style: TextStyle(
                color: isDarkMode ? AppColors.darkTextSecondary : Colors.black,
              ),
            ),
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
            child: Text('ui.family_management.delete_family'.tr()),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'ui.family_management.transfer_confirm_title'.tr(),
          style: TextStyle(
            color: isDarkMode ? AppColors.darkTextPrimary : Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ui.family_management.transfer_owner_message'.tr(),
              style: TextStyle(
                color: isDarkMode ? AppColors.darkTextPrimary : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ui.family_management.transfer_warning'.tr(args: [family?.name ?? '']),
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? AppColors.darkTextSecondary : Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ui.family_management.select_new_owner'.tr(),
              style: TextStyle(
                color: isDarkMode ? AppColors.darkTextPrimary : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            // Liste des autres parents
            ..._parents
                .where((parent) => parent.id != currentUser?.id)
                .map((parent) => ListTile(
                      title: Text(
                        parent.name,
                        style: TextStyle(
                          color: isDarkMode ? AppColors.darkTextPrimary : Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        parent.email,
                        style: TextStyle(
                          color: isDarkMode ? AppColors.darkTextSecondary : Colors.grey,
                        ),
                      ),
                      leading: Icon(
                        Icons.person,
                        color: isDarkMode ? AppColors.darkTextPrimary : Colors.black,
                      ),
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
            child: Text(
              'common.cancel'.tr(),
              style: TextStyle(
                color: isDarkMode ? AppColors.darkTextSecondary : Colors.black,
              ),
            ),
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
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('ui.family_management.leaving_family'.tr()),
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
            SnackBar(
              content: Text('ui.family_management.family_left_success'.tr()),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Retour à l'écran précédent
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ui.family_management.error_leaving_family'.tr()),
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
            content: Text('common.error'.tr() + ': ${e.toString()}'),
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
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('ui.family_management.deleting_family'.tr()),
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
            SnackBar(
              content: Text('ui.family_management.family_deleted_success'.tr()),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Retour à l'écran précédent
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ui.family_management.error_deleting_family'.tr()),
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
            content: Text('common.error'.tr() + ': ${e.toString()}'),
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
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('ui.family_management.transferring_ownership'.tr()),
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
          SnackBar(
            content: Text('ui.family_management.ownership_transferred_success'.tr()),
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
            content: Text('common.error'.tr() + ': ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteChildDialog(Child child) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkSurface
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'ui.family_management.delete_child_title'.tr(),
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTextPrimary
                : Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ui.family_management.delete_child_message'.tr(args: [child.name]),
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextPrimary
                    : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ui.family_management.delete_child_warning'.tr(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'common.cancel'.tr(),
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextSecondary
                    : Colors.black,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('ui.family_management.delete_child'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // Afficher un indicateur de chargement
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('ui.family_management.deleting_child'.tr()),
              ],
            ),
          ),
        );

        // Supprimer l'enfant
        await _firestoreService.deleteChild(child.id);
        
        Navigator.pop(context); // Fermer le dialogue de chargement
        
        // Recharger les membres de la famille
        await _loadFamilyMembers();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ui.family_management.child_deleted_success'.tr(args: [child.name])),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        Navigator.pop(context); // Fermer le dialogue de chargement en cas d'erreur
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('common.error'.tr() + ': ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
        title: Text('ui.family_management.title'.tr()),
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
              ? Center(
                  child: Text(
                    'ui.family_management.no_family_found'.tr(),
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextSecondary
                          : Colors.grey,
                    ),
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
                              'ui.family_management.created_on'.tr(args: [
                                family.createdAt.day.toString(),
                                family.createdAt.month.toString(),
                                family.createdAt.year.toString()
                              ]),
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
                                child: Text(
                                  'ui.family_management.owner'.tr(),
                                  style: const TextStyle(
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
                      Text(
                        'ui.family_management.parents'.tr(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _parents.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.darkCard
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? AppColors.darkTextSecondary
                                        : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'ui.family_management.no_parent_in_family'.tr(),
                                    style: TextStyle(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? AppColors.darkTextSecondary
                                          : Colors.grey[600],
                                    ),
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
                      Text(
                        'ui.family_management.children'.tr(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _children.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.darkCard
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.child_care,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? AppColors.darkTextSecondary
                                        : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'ui.family_management.no_child_in_family'.tr(),
                                    style: TextStyle(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? AppColors.darkTextSecondary
                                          : Colors.grey[600],
                                    ),
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
                                return _ChildMemberCard(
                                  child: child,
                                  onDelete: () => _showDeleteChildDialog(child),
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
                                ? 'ui.family_management.leave_and_delete'.tr()
                                : 'ui.family_management.leave_family'.tr(),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
            blurRadius: isDarkMode ? 15 : 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isOwner
                  ? (isDarkMode ? Colors.amber[800] : Colors.amber[100])
                  : (isDarkMode ? Colors.blue[800] : Colors.blue[100]),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isOwner
                  ? (isDarkMode ? Colors.amber[200] : Colors.amber[700])
                  : (isDarkMode ? Colors.blue[200] : Colors.blue[700]),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.green[800] : Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ui.family_management.you'.tr(),
                          style: TextStyle(
                            color: isDarkMode ? Colors.green[200] : Colors.green[700],
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
                    color: isDarkMode ? AppColors.darkTextSecondary : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (isOwner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.amber[800] : Colors.amber[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star,
                    color: isDarkMode ? Colors.amber[200] : Colors.amber[700],
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'ui.family_management.owner'.tr(),
                    style: TextStyle(
                      color: isDarkMode ? Colors.amber[200] : Colors.amber[700],
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

class _ChildMemberCard extends StatelessWidget {
  final Child child;
  final VoidCallback onDelete;

  const _ChildMemberCard({
    required this.child,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
            blurRadius: isDarkMode ? 15 : 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.blue[800] : Colors.blue[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.child_care,
              color: isDarkMode ? Colors.blue[200] : Colors.blue[700],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ui.family_management.age'.tr(args: [child.age.toString()]),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? AppColors.darkTextSecondary : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(
              Icons.delete,
              color: Colors.red,
            ),
            tooltip: 'ui.family_management.delete_child'.tr(),
          ),
        ],
      ),
    );
  }
}