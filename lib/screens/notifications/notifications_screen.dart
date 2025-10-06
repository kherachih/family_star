import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../models/notification.dart' as model;
import '../../models/family_invitation.dart';
import '../../utils/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Initialiser le provider avec l'ID de l'utilisateur actuel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      
      if (authProvider.currentUser != null) {
        notificationProvider.initialize(authProvider.currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
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
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              if (provider.unreadCount > 0) {
                return TextButton(
                  onPressed: () => _markAllAsRead(context),
                  child: const Text(
                    'Tout marquer comme lu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de chargement',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.clearError();
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      if (authProvider.currentUser != null) {
                        provider.initialize(authProvider.currentUser!.id);
                      }
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune notification',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vous n\'avez aucune notification pour le moment',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // En-tête avec le nombre de notifications non lues
              if (provider.unreadCount > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.gradientPrimary,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notifications_active_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Vous avez ${provider.unreadCount} notification${provider.unreadCount > 1 ? 's' : ''} non lue${provider.unreadCount > 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Liste des notifications
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    if (authProvider.currentUser != null) {
                      await Provider.of<NotificationProvider>(context, listen: false)
                          .loadNotifications();
                    }
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: provider.notifications.length,
                    itemBuilder: (context, index) {
                      final notification = provider.notifications[index];
                      return _NotificationCard(
                        notification: notification,
                        onTap: () => _handleNotificationTap(context, notification),
                        onMarkAsRead: () => _markAsRead(context, notification.id),
                        onDelete: () => _deleteNotification(context, notification.id),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleNotificationTap(BuildContext context, model.AppNotification notification) async {
    // Marquer comme lue si ce n'est pas déjà fait
    if (!notification.isRead) {
      _markAsRead(context, notification.id);
    }

    // Gérer les notifications d'invitation de famille
    if (notification.type == model.NotificationType.family &&
        notification.data != null &&
        notification.data!['type'] == 'family_invitation') {
      // Vérifier si l'invitation est expirée
      final invitationId = notification.data!['invitationId'] as String?;
      if (invitationId != null) {
        final firestoreService = FirestoreService();
        final invitation = await firestoreService.getFamilyInvitationById(invitationId);
        if (invitation != null && invitation.isExpired) {
          // Ne pas afficher le dialogue pour les invitations expirées
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cette invitation a expiré'),
              backgroundColor: Colors.grey,
            ),
          );
          return;
        }
      }
      _showFamilyInvitationDialog(context, notification);
      return;
    }

    // TODO: Naviguer vers la page appropriée en fonction du type de notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notification: ${notification.title}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showFamilyInvitationDialog(BuildContext context, model.AppNotification notification) {
    final data = notification.data!;
    final familyId = data['familyId'] as String;
    final familyName = data['familyName'] as String;
    final invitedByUserName = data['invitedByUserName'] as String;
    final invitationId = data['invitationId'] as String;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.family_restroom, color: Colors.teal[700]),
            ),
            const SizedBox(width: 12),
            const Text('Invitation de famille'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$invitedByUserName vous a invité à rejoindre la famille "$familyName"',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Voulez-vous accepter cette invitation ?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _rejectFamilyInvitation(context, invitationId, familyId, familyName);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
            child: const Text('Refuser'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _acceptFamilyInvitation(context, invitationId, familyId, familyName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Accepter'),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptFamilyInvitation(
    BuildContext context,
    String invitationId,
    String familyId,
    String familyName,
  ) async {
    // Utiliser un Completer pour gérer la fermeture du dialogue
    final completer = Completer<void>();
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
      final notificationService = NotificationService();
      final firestoreService = FirestoreService();
      
      if (authProvider.currentUser == null) return;
      
      // Afficher un indicateur de chargement et garder une référence
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              const Text('Acceptation de l\'invitation...'),
            ],
          ),
        ),
      ).then((_) => completer.complete()); // Se déclenche quand le dialogue est fermé

      // Accepter l'invitation avec un timeout pour éviter les boucles infinies
      final success = await firestoreService.acceptFamilyInvitation(invitationId)
          .timeout(const Duration(seconds: 30));
      
      // Fermer le dialogue de chargement
      if (context.mounted) {
        Navigator.of(context).pop();
        // Attendre que le dialogue soit complètement fermé
        await completer.future.timeout(const Duration(seconds: 2));
      }

      if (success) {
        try {
          // Envoyer une notification d'acceptation
          await notificationService.sendFamilyInvitationAcceptedNotification(
            familyId: familyId,
            familyName: familyName,
            acceptedUserName: authProvider.currentUser!.name,
            excludeUserId: authProvider.currentUser!.id,
          ).timeout(const Duration(seconds: 10));

          // Recharger les familles de l'utilisateur
          await familyProvider.loadFamiliesByParentId(authProvider.currentUser!.id)
              .timeout(const Duration(seconds: 10));
        } catch (e) {
          debugPrint('Erreur lors des opérations post-acceptation: $e');
          // Continuer même si ces opérations échouent
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vous avez rejoint la famille "$familyName"'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Vérifier si l'invitation a déjà été acceptée
        final invitation = await firestoreService.getFamilyInvitationById(invitationId);
        if (invitation != null && invitation.status.codeName == 'accepted') {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Vous avez déjà rejoint la famille "$familyName"'),
                backgroundColor: Colors.blue,
              ),
            );
          }
          
          // Recharger les familles de l'utilisateur pour s'assurer qu'elles sont à jour
          try {
            await familyProvider.loadFamiliesByParentId(authProvider.currentUser!.id)
                .timeout(const Duration(seconds: 10));
          } catch (e) {
            debugPrint('Erreur lors du rechargement des familles: $e');
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Erreur lors de l\'acceptation de l\'invitation'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'acceptation de l\'invitation: $e');
      
      // Fermer le dialogue de chargement si toujours affiché
      if (context.mounted) {
        Navigator.of(context).pop();
        await completer.future.timeout(const Duration(seconds: 2));
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectFamilyInvitation(
    BuildContext context,
    String invitationId,
    String familyId,
    String familyName,
  ) async {
    // État pour suivre si le dialogue est toujours affiché
    bool dialogShown = true;
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final notificationService = NotificationService();
      final firestoreService = FirestoreService();
      
      if (authProvider.currentUser == null) return;
      
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Refus de l\'invitation...'),
            ],
          ),
        ),
      );

      // Refuser l'invitation avec un timeout pour éviter les boucles infinies
      final success = await firestoreService.rejectFamilyInvitation(invitationId)
          .timeout(const Duration(seconds: 30));
      
      // Fermer le dialogue de chargement si toujours affiché
      if (dialogShown && context.mounted) {
        Navigator.pop(context);
        dialogShown = false;
      }

      if (success) {
        try {
          // Envoyer une notification de refus
          await notificationService.sendFamilyInvitationRejectedNotification(
            familyId: familyId,
            familyName: familyName,
            rejectedUserName: authProvider.currentUser!.name,
          ).timeout(const Duration(seconds: 10));
        } catch (e) {
          debugPrint('Erreur lors de l\'envoi de la notification de refus: $e');
          // Continuer même si cette opération échoue
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vous avez refusé l\'invitation'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Vérifier si l'invitation a déjà été traitée
        final invitation = await firestoreService.getFamilyInvitationById(invitationId);
        if (invitation != null) {
          String message = '';
          Color color = Colors.red;
          
          switch (invitation.status.codeName) {
            case 'accepted':
              message = 'Vous avez déjà accepté l\'invitation à la famille "$familyName"';
              color = Colors.blue;
              break;
            case 'rejected':
              message = 'Vous avez déjà refusé l\'invitation à la famille "$familyName"';
              color = Colors.orange;
              break;
            case 'expired':
              message = 'L\'invitation à la famille "$familyName" a expiré';
              color = Colors.grey;
              break;
            default:
              message = 'Erreur lors du refus de l\'invitation';
          }
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: color,
              ),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Erreur lors du refus de l\'invitation'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du refus de l\'invitation: $e');
      
      // Fermer le dialogue de chargement si toujours affiché
      if (dialogShown && context.mounted) {
        Navigator.pop(context);
        dialogShown = false;
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _markAsRead(BuildContext context, String notificationId) {
    Provider.of<NotificationProvider>(context, listen: false)
        .markAsRead(notificationId);
  }

  void _markAllAsRead(BuildContext context) {
    Provider.of<NotificationProvider>(context, listen: false)
        .markAllAsRead();
  }

  void _deleteNotification(BuildContext context, String notificationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer la notification'),
        content: const Text('Voulez-vous vraiment supprimer cette notification ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<NotificationProvider>(context, listen: false)
                  .deleteNotification(notificationId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final model.AppNotification notification;
  final Future<void> Function() onTap;
  final VoidCallback onMarkAsRead;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onMarkAsRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Vérifier si c'est une notification d'invitation expirée
    bool isExpired = false;
    if (notification.type == model.NotificationType.family &&
        notification.data != null &&
        notification.data!['type'] == 'family_invitation') {
      final invitationId = notification.data!['invitationId'] as String?;
      if (invitationId != null) {
        // Pour les invitations, on va vérifier l'état de manière asynchrone
        return FutureBuilder<FamilyInvitation?>(
          future: FirestoreService().getFamilyInvitationById(invitationId),
          builder: (context, snapshot) {
            isExpired = snapshot.hasData && snapshot.data!.isExpired;
            return _buildNotificationCard(context, isExpired);
          },
        );
      }
    }
    
    return _buildNotificationCard(context, isExpired);
  }

  Widget _buildNotificationCard(BuildContext context, bool isExpired) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isExpired
            ? Colors.grey[100]
            : notification.isRead
                ? Colors.white
                : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpired
              ? Colors.grey[300]!
              : notification.isRead
                  ? Colors.grey[300]!
                  : AppColors.primary.withOpacity(0.3),
          width: notification.isRead || isExpired ? 1 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isExpired ? 0.02 : 0.05),
            blurRadius: isExpired ? 5 : 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isExpired ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icône de la notification
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isExpired
                          ? [Colors.grey[400]!, Colors.grey[300]!]
                          : _getNotificationColors(notification.type),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    notification.icon,
                    style: TextStyle(
                      fontSize: 20,
                      color: isExpired ? Colors.grey[600] : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Contenu de la notification
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title + (isExpired ? ' (Expirée)' : ''),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: (notification.isRead || isExpired)
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                color: isExpired
                                    ? Colors.grey[600]
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (!notification.isRead && !isExpired)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (notification.description != null)
                        Text(
                          notification.description! + (isExpired ? '\nCette invitation a expiré.' : ''),
                          style: TextStyle(
                            fontSize: 14,
                            color: isExpired
                                ? Colors.grey[500]
                                : AppColors.textSecondary,
                            fontWeight: (notification.isRead || isExpired)
                                ? FontWeight.normal
                                : FontWeight.w500,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        notification.formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: isExpired ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Boutons d'action
                if (!isExpired)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'mark_as_read':
                          onMarkAsRead();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (!notification.isRead)
                        const PopupMenuItem(
                          value: 'mark_as_read',
                          child: Row(
                            children: [
                              Icon(Icons.done_rounded, size: 20),
                              SizedBox(width: 8),
                              Text('Marquer comme lu'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_rounded, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Supprimer', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    child: Icon(
                      Icons.more_vert_rounded,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _getNotificationColors(model.NotificationType type) {
    switch (type) {
      case model.NotificationType.task:
        return [Colors.green, Colors.green.shade300];
      case model.NotificationType.reward:
        return [Colors.blue, Colors.blue.shade300];
      case model.NotificationType.sanction:
        return [Colors.red, Colors.red.shade300];
      case model.NotificationType.starLoss:
        return [Colors.orange, Colors.orange.shade300];
      case model.NotificationType.system:
        return [Colors.purple, Colors.purple.shade300];
      case model.NotificationType.family:
        return [Colors.teal, Colors.teal.shade300];
    }
  }
}