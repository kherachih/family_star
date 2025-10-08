import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/auto_ad_service.dart';
import '../../utils/app_colors.dart';
import '../family/add_parent_screen.dart';
import '../family/family_management_screen.dart';
import 'edit_profile_screen.dart';
import '../notifications/notifications_screen.dart';
import 'support_screen.dart';
import '../language/language_settings_screen.dart';
import '../support/support_us_screen.dart';
import '../admin/admob_config_screen.dart';
import 'package:flutter/foundation.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'auth.logout'.tr(),
          style: TextStyle(
            color: isDarkMode ? AppColors.darkTextPrimary : Colors.black,
          ),
        ),
        content: Text(
          'profile.logout_confirm'.tr(),
          style: TextStyle(
            color: isDarkMode ? AppColors.darkTextPrimary : Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'profile.cancel_button'.tr(),
              style: TextStyle(
                color: isDarkMode ? AppColors.darkTextSecondary : Colors.black,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('profile.logout_confirm_button'.tr()),
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
    // Notifier AutoAdService que nous sommes sur l'écran de profil
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AutoAdService().onScreenChanged('profile');
    });
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header profil sans AppBar
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkGradientSecondary
                    : AppColors.gradientSecondary,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkSecondary.withOpacity(0.3)
                      : AppColors.secondary.withOpacity(0.3),
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
          Text(
            'profile.title'.tr(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

                  // Carte Profil
                  _SettingsCard(
                    icon: Icons.person_outline_rounded,
                    title: 'profile.my_profile'.tr(),
                    subtitle: 'profile.edit_profile'.tr(),
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
                        title: 'profile.family_management'.tr(),
                        subtitle: familyProvider.currentFamily != null
                            ? 'profile.view_members'.tr()
                            : 'profile.no_family'.tr(),
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
                              SnackBar(
                                content: Text('profile.create_family_first'.tr()),
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
                        title: 'profile.invite_parents'.tr(),
                        subtitle: familyProvider.currentFamily != null
                            ? 'profile.add_member'.tr()
                            : 'profile.create_family_first'.tr(),
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
                              SnackBar(
                                content: Text('profile.create_family_first'.tr()),
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
                        title: 'profile.notifications'.tr(),
                        subtitle: notificationProvider.unreadCount! > 0
                            ? 'profile.unread_notifications'.tr(args: [notificationProvider.unreadCount.toString(), notificationProvider.unreadCount! > 1 ? 's' : ''])
                            : 'profile.manage_notifications'.tr(),
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

                  // Carte Langue
                  Consumer<LanguageProvider>(
                    builder: (context, languageProvider, child) {
                      return _SettingsCard(
                        icon: Icons.language_outlined,
                        title: 'profile.language'.tr(),
                        subtitle: languageProvider.currentLanguageName,
                        gradient: AppColors.gradientPrimary,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LanguageSettingsScreen(),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Carte Mode sombre
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return _SettingsCard(
                        icon: Icons.dark_mode_outlined,
                        title: 'profile.dark_mode'.tr(),
                        subtitle: themeProvider.isDarkMode
                            ? 'profile.dark_mode_enabled'.tr()
                            : 'profile.dark_mode_disabled'.tr(),
                        gradient: AppColors.gradientSecondary,
                        onTap: () {
                          themeProvider.toggleTheme();
                        },
                        trailing: Switch(
                          value: themeProvider.isDarkMode,
                          onChanged: (value) {
                            themeProvider.setDarkMode(value);
                          },
                          activeColor: AppColors.primary,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'profile.help_support'.tr(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Carte Aide
                  _SettingsCard(
                    icon: Icons.help_outline_rounded,
                    title: 'profile.help_support'.tr(),
                    subtitle: 'profile.help_center'.tr(),
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

                  // Carte Nous aider
                  _SettingsCard(
                    icon: Icons.favorite_rounded,
                    title: 'support_us.title'.tr(),
                    subtitle: 'support_us.subtitle'.tr(),
                    gradient: AppColors.gradientPrimary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SupportUsScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Carte À propos
                  _SettingsCard(
                    icon: Icons.info_outline_rounded,
                    title: 'profile.about'.tr(),
                    subtitle: 'profile.version'.tr(),
                    gradient: AppColors.gradientSecondary,
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'app_title'.tr(),
                        applicationVersion: '1.0.0',
                        applicationIcon: GestureDetector(
                          onLongPress: () {
                            // Accès caché à l'écran d'administration AdMob
                            // Seulement en mode debug ou pour les administrateurs
                            if (kDebugMode) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AdMobConfigScreen(),
                                ),
                              );
                            }
                          },
                          child: Container(
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
                        ),
                        children: [
                          Text('profile.family_reward_system'.tr()),
                          if (kDebugMode)
                            const Text('\n(Appuyez long sur le logo pour accéder à l\'administration AdMob)'),
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
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.logout_rounded, color: Colors.white),
                              const SizedBox(width: 12),
                              Text(
                                'auth.logout'.tr(),
                                style: const TextStyle(
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
  final Widget? trailing;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkCard
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? [AppColors.darkCardShadow]
            : [AppColors.cardShadow],
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing ??
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
