import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/notification_provider.dart';
import '../../utils/app_colors.dart';
import '../family/add_parent_screen.dart';
import '../family/family_management_screen.dart';
import 'edit_profile_screen.dart';
import '../notifications/notifications_screen.dart';
import 'support_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      await authProvider.logout(notificationProvider: notificationProvider);
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header profil sans AppBar
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.gradientSecondary,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24.0),
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authProvider.currentUser?.name ?? 'Utilisateur',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            authProvider.currentUser?.email ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Paramètres',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

                  // Carte Profil
                  _SettingsCard(
                    icon: Icons.person_outline_rounded,
                    title: 'Mon profil',
                    subtitle: 'Modifier mes informations',
                    gradient: AppColors.gradientPrimary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Carte Gestion de la famille
                  Consumer<FamilyProvider>(
                    builder: (context, familyProvider, child) {
                      return _SettingsCard(
                        icon: Icons.people_outline_rounded,
                        title: 'Gestion de la famille',
                        subtitle: familyProvider.currentFamily != null
                            ? 'Voir les membres'
                            : 'Aucune famille',
                        gradient: AppColors.gradientTertiary,
                        onTap: () {
                          if (familyProvider.currentFamily != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FamilyManagementScreen(),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vous devez d\'abord créer ou rejoindre une famille'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Carte Inviter des parents
                  Consumer<FamilyProvider>(
                    builder: (context, familyProvider, child) {
                      return _SettingsCard(
                        icon: Icons.person_add_outlined,
                        title: 'Inviter des parents',
                        subtitle: familyProvider.currentFamily != null
                            ? 'Ajouter un membre à la famille'
                            : 'Créer une famille d\'abord',
                        gradient: AppColors.gradientPrimary,
                        onTap: () {
                          if (familyProvider.currentFamily != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddParentScreen(),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vous devez d\'abord créer ou rejoindre une famille'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Carte Notifications
                  Consumer<NotificationProvider>(
                    builder: (context, notificationProvider, child) {
                      return _SettingsCard(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        subtitle: notificationProvider.unreadCount! > 0
                            ? '${notificationProvider.unreadCount} non lue${notificationProvider.unreadCount! > 1 ? 's' : ''}'
                            : 'Gérer les notifications',
                        gradient: AppColors.gradientTertiary,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationsScreen(),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Carte Sécurité
                  _SettingsCard(
                    icon: Icons.lock_outline_rounded,
                    title: 'Sécurité',
                    subtitle: 'Mot de passe et sécurité',
                    gradient: AppColors.gradientSecondary,
                    onTap: () {
                      // TODO: Navigate to security settings
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bientôt disponible')),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'Support',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Carte Aide
                  _SettingsCard(
                    icon: Icons.help_outline_rounded,
                    title: 'Aide & Support',
                    subtitle: 'Centre d\'aide et FAQ',
                    gradient: AppColors.gradientTertiary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SupportScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Carte À propos
                  _SettingsCard(
                    icon: Icons.info_outline_rounded,
                    title: 'À propos',
                    subtitle: 'Version 1.0.0',
                    gradient: AppColors.gradientSecondary,
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Family Star',
                        applicationVersion: '1.0.0',
                        applicationIcon: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: AppColors.gradientHero,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        children: const [
                          Text('Système de récompenses familial'),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Bouton Déconnexion
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFF6B6B),
                          Color(0xFFFF8E8E),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _handleLogout(context),
                        borderRadius: BorderRadius.circular(16),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout_rounded, color: Colors.white),
                              SizedBox(width: 12),
                              Text(
                                'Déconnexion',
                                style: TextStyle(
                                  fontSize: 16,
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

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppColors.cardShadow],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient.map((c) => c.withOpacity(0.2)).toList(),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: gradient.first,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
