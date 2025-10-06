import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../models/parent.dart';
import '../../models/family_invitation.dart';
import '../../utils/app_colors.dart';

class AddParentScreen extends StatefulWidget {
  const AddParentScreen({super.key});

  @override
  State<AddParentScreen> createState() => _AddParentScreenState();
}

class _AddParentScreenState extends State<AddParentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  Parent? _foundParent;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _searchParent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _foundParent = null;
    });

    try {
      final firestoreService = FirestoreService();
      final parent = await firestoreService.getParentByEmail(_emailController.text.trim());
      
      setState(() {
        _foundParent = parent;
        _isLoading = false;
      });

      if (parent == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun compte trouvé avec cet email'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la recherche: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _inviteParentToFamily() async {
    if (_foundParent == null) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final familyProvider = Provider.of<FamilyProvider>(context, listen: false);
    final firestoreService = FirestoreService();
    final notificationService = NotificationService();
    final currentUser = authProvider.currentUser;

    try {
      // S'assurer que l'utilisateur est connecté
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Si l'utilisateur actuel n'a pas de famille, en créer une pour lui
      if (familyProvider.currentFamily == null) {
        await familyProvider.createFamilyForParent(currentUser.id, currentUser.name);
      }

      // À ce stade, la famille doit exister. Si ce n'est pas le cas, il y a une erreur.
      final family = familyProvider.currentFamily;
      if (family == null) {
        throw Exception('Impossible de trouver ou de créer une famille');
      }

      // Vérifier si le parent est déjà dans la famille
      if (family.hasParent(_foundParent!.id)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ce parent fait déjà partie de la famille'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return; // Sortir de la fonction car il n'y a rien à faire
      }

      // Vérifier si une invitation est déjà en cours
      final hasPendingInvitation = await firestoreService.hasPendingInvitation(
        _foundParent!.id,
        family.id,
      );

      if (hasPendingInvitation) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Une invitation a déjà été envoyée à ce parent'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Créer l'invitation
      final invitation = FamilyInvitation.create(
        familyId: family.id,
        familyName: family.name,
        invitedUserId: _foundParent!.id,
        invitedUserEmail: _foundParent!.email,
        invitedUserName: _foundParent!.name,
        invitedByUserId: currentUser.id,
        invitedByUserName: currentUser.name,
      );

      await firestoreService.createFamilyInvitation(invitation);

      // Envoyer une notification d'invitation
      await notificationService.sendFamilyInvitationNotification(
        invitedUserId: _foundParent!.id,
        familyId: family.id,
        familyName: family.name,
        invitedByUserName: currentUser.name,
        invitationId: invitation.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invitation envoyée à ${_foundParent!.name}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inviter un parent'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Entrez l\'email du parent que vous souhaitez inviter à rejoindre votre famille. Le parent doit déjà avoir un compte et recevra une notification d\'invitation.',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Champ email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email du parent',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                  hintText: 'exemple@email.com',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez saisir un email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                    return 'Veuillez saisir un email valide';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _searchParent(),
              ),
              const SizedBox(height: 16),

              // Bouton de recherche
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _searchParent,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.search),
                label: Text(_isLoading ? 'Recherche...' : 'Rechercher'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

              const SizedBox(height: 24),

              // Résultat de la recherche
              if (_foundParent != null) ...[
                const Text(
                  'Parent trouvé:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          color: Colors.green[700],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _foundParent!.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _foundParent!.email,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[700],
                        size: 24,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Bouton d'invitation
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _inviteParentToFamily,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.mail),
                  label: Text(_isLoading ? 'Envoi...' : 'Inviter à rejoindre la famille'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],

              // Message d'erreur
              if (_foundParent == null && _emailController.text.isNotEmpty && !_isLoading) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Aucun parent trouvé avec cet email. Vérifiez que l\'email est correct et que le parent a déjà créé un compte.',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}