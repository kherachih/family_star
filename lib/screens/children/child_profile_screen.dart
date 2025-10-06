import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/child.dart';
import '../../models/task.dart';
import '../../models/sanction.dart';
import '../../models/sanction_applied.dart';
import '../../providers/children_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rewards_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/avatars.dart';
import '../rewards/rewards_catalog_screen.dart';
import 'history_screen.dart';
import 'sanctions_applied_screen.dart';

class ChildProfileScreen extends StatefulWidget {
  final Child child;

  const ChildProfileScreen({super.key, required this.child});

  @override
  State<ChildProfileScreen> createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends State<ChildProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  bool _isEditing = false;
  Timer? _timer;
  List<SanctionApplied> _activeSanctions = [];
  String _selectedGender = 'boy';
  int _selectedAvatarIndex = 0;
  DateTime? _selectedBirthDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.child.name);
    _ageController = TextEditingController(text: widget.child.age.toString());
    _selectedGender = widget.child.gender;
    _selectedAvatarIndex = widget.child.avatarIndex;
    _selectedBirthDate = widget.child.birthDate;
    _loadActiveSanctions();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    // Vérifier que la date de naissance est sélectionnée
    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une date de naissance'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Calculer l'âge à partir de la date de naissance
    final calculatedAge = _calculateAge(_selectedBirthDate);

    // Vérifier que l'âge est dans la plage valide (3-12 ans)
    if (calculatedAge < 3 || calculatedAge > 18) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('L\'âge doit être entre 3 et 18 ans'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final updatedChild = widget.child.copyWith(
      name: _nameController.text.trim(),
      age: calculatedAge,
      birthDate: _selectedBirthDate,
      gender: _selectedGender,
      avatarIndex: _selectedAvatarIndex,
    );

    final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);
    final success = await childrenProvider.updateChild(updatedChild);

    if (success && mounted) {
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Annuler les modifications
        _nameController.text = widget.child.name;
        _ageController.text = widget.child.age.toString();
        _selectedGender = widget.child.gender;
        _selectedAvatarIndex = widget.child.avatarIndex;
        _selectedBirthDate = widget.child.birthDate;
      }
    });
  }

  void _checkForExpiredSanctions(List<SanctionApplied> previousSanctions) {
    // Vérifier si des sanctions viennent d'expirer (étaient actives avant mais ne le sont plus)
    final now = DateTime.now();
    final currentSanctionIds = _activeSanctions.map((s) => s.id).toSet();
    
    final recentlyExpired = previousSanctions.where((previousSanction) {
      // Si la sanction était dans la liste précédente mais n'y est plus
      // ou si elle est encore active mais expirée selon le temps
      return !currentSanctionIds.contains(previousSanction.id) ||
             (previousSanction.isActive && 
              previousSanction.endsAt != null && 
              now.isAfter(previousSanction.endsAt!));
    }).toList();
    
    if (recentlyExpired.isNotEmpty) {
      // Afficher une célébration pour chaque sanction expirée
      for (final sanction in recentlyExpired) {
        _showCelebrationDialog(sanction);
      }
    }
  }

  void _showCelebrationDialog(SanctionApplied sanction) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 30)),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Sanction terminée !',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🎊',
              style: TextStyle(fontSize: 60),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Félicitations ! La sanction "${sanction.sanctionName}" de ${widget.child.name} est maintenant terminée !',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'C\'est la fête ! 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Recharger les sanctions pour mettre à jour l'interface
              _loadActiveSanctions();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Super ! 🎊'),
          ),
        ],
      ),
    );
  }

  void _loadActiveSanctions() async {
    final rewardsProvider = Provider.of<RewardsProvider>(context, listen: false);
    await rewardsProvider.loadSanctionsApplied(widget.child.id);
    
    // Mettre à jour la liste des sanctions actives après le chargement
    if (mounted) {
      final previousSanctions = List<SanctionApplied>.from(_activeSanctions);
      setState(() {
        _activeSanctions = rewardsProvider.sanctionsApplied
            .where((s) => s.isActive && !s.isExpired)
            .toList();
      });
      
      // Vérifier si des sanctions viennent d'expirer et afficher une célébration
      _checkForExpiredSanctions(previousSanctions);
    }
  }

  void _startTimer() {
    // Mettre à jour l'interface toutes les minutes pour le compte à rebours
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        // Recharger les sanctions pour vérifier si certaines ont expiré
        _loadActiveSanctions();
      }
    });
  }

  Future<void> _showTaskSelectionDialog(TaskType type) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) return;

    // Charger les tâches du parent filtrées par type et assignées à cet enfant
    final allTasks = await FirestoreService().getTasksByParentId(authProvider.currentUser!.id);
    final tasks = allTasks
        .where((task) => task.type == type && task.childIds.contains(widget.child.id))
        .toList();

    if (!mounted) return;

    if (tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            type == TaskType.positive
                ? 'Aucune tâche positive assignée à ${widget.child.name}'
                : 'Aucune tâche négative assignée à ${widget.child.name}',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedTask = await showDialog<Task>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          type == TaskType.positive
              ? 'Tâches positives pour ${widget.child.name}'
              : 'Actions négatives pour ${widget.child.name}',
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: type == TaskType.positive
                        ? Colors.green[100]
                        : Colors.red[100],
                    child: Icon(
                      type == TaskType.positive
                          ? Icons.add_circle
                          : Icons.remove_circle,
                      color: type == TaskType.positive
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  title: Text(task.title),
                  subtitle: task.description != null
                      ? Text(task.description!)
                      : null,
                  trailing: Text(
                    '${type == TaskType.positive ? "+" : "-"}${task.stars} ⭐',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: type == TaskType.positive
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, task),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );

    if (selectedTask != null && mounted) {
      await _applyTask(selectedTask);
    }
  }

  Future<void> _applyTask(Task task) async {
    final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);

    try {
      await childrenProvider.updateChildStars(widget.child.id, task.starChange, taskId: task.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              task.type == TaskType.positive
                  ? '${widget.child.name} a gagné ${task.stars} ⭐'
                  : '${widget.child.name} a perdu ${task.stars} ⭐',
            ),
            backgroundColor: Colors.green,
          ),
        );
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChildrenProvider>(
      builder: (context, childrenProvider, child) {
        final currentChild = childrenProvider.getChildById(widget.child.id) ?? widget.child;

        return Scaffold(
          appBar: AppBar(
            title: Text(_isEditing ? 'Modifier le profil' : currentChild.name),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            actions: [
              if (_isEditing)
                TextButton(
                  onPressed: childrenProvider.isLoading ? null : _handleSave,
                  child: const Text(
                    'SAUVEGARDER',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _toggleEdit,
                  tooltip: 'Modifier',
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Photo de profil (Avatar) avec dégradé et bouton d'historique
                  Stack(
                    children: [
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: AppColors.gradientHero,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _isEditing ? ChildAvatars.getAvatar(_selectedGender, _selectedAvatarIndex) : currentChild.avatar,
                            style: const TextStyle(fontSize: 70),
                          ),
                        ),
                      ),
                      // Bouton d'historique en haut à droite
                      Positioned(
                        top: 0,
                        right: _isEditing ? -50 : 0, // Déplace le bouton hors de l'écran en mode édition
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HistoryScreen(child: currentChild),
                                ),
                              );
                            },
                            icon: const Icon(Icons.history, color: Colors.white),
                            tooltip: 'Voir l\'historique',
                            iconSize: 20,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                          ),
                        ),
                      ),
                      // Bouton pour modifier l'avatar en mode édition
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.deepPurple,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: () {
                                _showAvatarSelectionDialog(
                                  context,
                                  setState,
                                  _selectedGender,
                                  _selectedAvatarIndex,
                                  (gender) => setState(() => _selectedGender = gender),
                                  (index) => setState(() => _selectedAvatarIndex = index),
                                );
                              },
                              icon: const Icon(Icons.edit, color: Colors.white),
                              tooltip: 'Modifier l\'avatar',
                              iconSize: 20,
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Compteur d'étoiles avec dégradé
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: currentChild.stars < 0
                            ? [
                                AppColors.starNegative.withOpacity(0.2),
                                AppColors.starNegative.withOpacity(0.1),
                              ]
                            : [
                                AppColors.starPositive.withOpacity(0.2),
                                AppColors.starPositive.withOpacity(0.1),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: currentChild.stars < 0
                            ? AppColors.starNegative.withOpacity(0.3)
                            : AppColors.starPositive.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (currentChild.stars < 0
                                    ? AppColors.starNegative
                                    : AppColors.starPositive)
                                .withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.star_rounded,
                            color: currentChild.stars < 0
                                ? AppColors.starNegative
                                : AppColors.starPositive,
                            size: 36,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${currentChild.stars}',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: currentChild.stars < 0
                                    ? AppColors.starNegative
                                    : AppColors.starPositive,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              currentChild.stars.abs() <= 1 ? 'étoile' : 'étoiles',
                              style: TextStyle(
                                fontSize: 14,
                                color: currentChild.stars < 0
                                    ? AppColors.starNegative
                                    : AppColors.starPositive,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Section des sanctions actives
                  if (_activeSanctions.isNotEmpty) ...[
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.red, width: 2),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.red.withOpacity(0.05),
                              Colors.red.withOpacity(0.02),
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // En-tête de la section
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning, color: Colors.white, size: 24),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Sanctions actives',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_activeSanctions.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Liste des sanctions actives
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: _activeSanctions.map((sanction) {
                                  return _buildActiveSanctionCard(sanction);
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  const SizedBox(height: 32),

                  // Informations du profil - affiché uniquement en mode édition
                  if (_isEditing) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Informations',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),

                            // Nom
                            TextFormField(
                              controller: _nameController,
                              enabled: _isEditing,
                              decoration: const InputDecoration(
                                labelText: 'Nom',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Veuillez saisir le nom de l\'enfant';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Date de naissance
                            GestureDetector(
                              onTap: _selectBirthDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.cake, color: Colors.grey),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _selectedBirthDate != null
                                            ? '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
                                            : 'Sélectionner la date de naissance',
                                        style: TextStyle(
                                          color: _selectedBirthDate != null ? Colors.black : Colors.grey,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.calendar_today, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Âge calculé: ${_calculateAge(_selectedBirthDate)} ans',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Message d'erreur
                  if (childrenProvider.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[300]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              childrenProvider.errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_isEditing) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _toggleEdit,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: childrenProvider.isLoading ? null : _handleSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: childrenProvider.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Sauvegarder'),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Actions rapides
                  if (!_isEditing) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Actions rapides',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),

                            // Bouton vert - Tâches positives
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: AppColors.gradientTertiary,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.taskPositive.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _showTaskSelectionDialog(TaskType.positive),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.3),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.add_circle_rounded,
                                            size: 24,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: Text(
                                            'Ajouter des étoiles',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 18,
                                          color: Colors.white70,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Bouton rouge - Tâches négatives
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: AppColors.gradientPrimary,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.taskNegative.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _showTaskSelectionDialog(TaskType.negative),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.3),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.remove_circle_rounded,
                                            size: 24,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: Text(
                                            'Enlever des étoiles',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 18,
                                          color: Colors.white70,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Bouton Récompenses
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RewardsCatalogScreen(child: currentChild),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.card_giftcard),
                              label: const Text('Voir les récompenses'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Bouton Sanctions (si étoiles négatives)
                            if (currentChild.stars < 0)
                              ElevatedButton.icon(
                                onPressed: () {
                                  _showSanctionsDialog(currentChild);
                                },
                                icon: const Icon(Icons.block),
                                label: const Text('Appliquer une sanction'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),

                            const SizedBox(height: 12),

                            // Bouton pour voir les sanctions actives - affiché uniquement s'il y a des sanctions actives
                            if (_activeSanctions.isNotEmpty)
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SanctionsAppliedScreen(child: currentChild),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.history),
                                label: const Text('Voir les sanctions actives'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSanctionsDialog(Child child) async {
    final rewardsProvider = Provider.of<RewardsProvider>(context, listen: false);
    // Pour l'instant, on utilise familyId comme parentId
    // Cela sera mis à jour avec le système de familles
    await rewardsProvider.loadSanctions(child.familyId);

    if (!mounted) return;

    final sanctions = rewardsProvider.sanctions
        .where((s) => child.stars <= -s.starsCost)
        .toList();

    if (sanctions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune sanction disponible pour ce niveau d\'étoiles'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedSanction = await showDialog<Sanction>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appliquer une sanction'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sanctions.length,
            itemBuilder: (context, index) {
              final sanction = sanctions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Icon(Icons.block, color: Colors.white),
                  ),
                  title: Text(sanction.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sanction.description),
                      if (sanction.durationText != null)
                        Text(
                          'Durée: ${sanction.durationText}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  trailing: Text(
                    '-${sanction.starsCost} ⭐',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, sanction),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );

    if (selectedSanction != null && mounted) {
      await _applySanction(child, selectedSanction);
    }
  }

  Future<void> _applySanction(Child child, Sanction sanction) async {
    final rewardsProvider = Provider.of<RewardsProvider>(context, listen: false);
    final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);

    final success = await rewardsProvider.applySanction(
      child,
      sanction,
      (updatedChild) async {
        await childrenProvider.updateChild(updatedChild);
      },
    );

    if (mounted) {
      if (success) {
        // Attendre un peu que Firestore mette à jour les données
        await Future.delayed(const Duration(milliseconds: 1000));
        
        // Recharger les sanctions depuis Firestore
        await rewardsProvider.loadSanctionsApplied(widget.child.id);
        
        // Mettre à jour la liste des sanctions actives
        setState(() {
          _activeSanctions = rewardsProvider.sanctionsApplied
              .where((s) => s.isActive && !s.isExpired)
              .toList();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sanction "${sanction.name}" appliquée. Étoiles remises à 0.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(rewardsProvider.error ?? 'Erreur lors de l\'application de la sanction'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildActiveSanctionCard(SanctionApplied sanction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: sanction.timeRemaining != null && sanction.timeRemaining!.inHours < 24
              ? Colors.red
              : Colors.orange,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // En-tête avec nom de la sanction
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.block, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sanction.sanctionName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '-${sanction.starsCost} ⭐',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenu avec compte à rebours
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compte à rebours
                if (sanction.timeRemaining != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getTimeRemainingColor(sanction.timeRemaining!).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _getTimeRemainingColor(sanction.timeRemaining!),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Temps restant:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sanction.timeRemainingText ?? 'Terminé',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _getTimeRemainingColor(sanction.timeRemaining!),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

                // Bouton pour terminer la sanction
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmEndSanction(sanction),
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: const Text('Terminer', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTimeRemainingColor(Duration remaining) {
    if (remaining.inHours < 1) {
      return Colors.red;
    } else if (remaining.inHours < 24) {
      return Colors.orange;
    } else {
      return Colors.blue;
    }
  }

  void _confirmEndSanction(SanctionApplied sanction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminer la sanction'),
        content: Text(
          'Voulez-vous vraiment terminer la sanction "${sanction.sanctionName}" avant la fin prévue ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _endSanction(sanction);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }

  int _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 0;
    
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    
    // Vérifier si l'anniversaire n'est pas encore passé cette année
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now().subtract(const Duration(days: 365 * 5)), // Par défaut 5 ans
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // Maximum 18 ans
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );
    
    if (picked != null && mounted) {
      setState(() {
        _selectedBirthDate = picked;
        // Mettre à jour le champ âge pour la validation
        _ageController.text = _calculateAge(picked).toString();
      });
    }
  }

  Future<void> _endSanction(SanctionApplied sanction) async {
    try {
      final rewardsProvider = Provider.of<RewardsProvider>(context, listen: false);
      await rewardsProvider.deactivateSanction(sanction.id!);
      
      // Attendre un peu que Firestore mette à jour les données
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Recharger les sanctions depuis Firestore
      await rewardsProvider.loadSanctionsApplied(widget.child.id);
      
      if (mounted) {
        // Mettre à jour la liste des sanctions actives
        setState(() {
          _activeSanctions = rewardsProvider.sanctionsApplied
              .where((s) => s.isActive && !s.isExpired)
              .toList();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sanction terminée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
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
    }
  }
  
  void _showAvatarSelectionDialog(BuildContext context, StateSetter setState, String selectedGender, int selectedAvatarIndex, Function(String) onGenderChanged, Function(int) onAvatarIndexChanged) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir un avatar'),
        content: StatefulBuilder(
          builder: (context, dialogSetState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sélection du genre
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('Garçon'),
                      selected: selectedGender == 'boy',
                      onSelected: (selected) {
                        if (selected) {
                          dialogSetState(() {
                            onGenderChanged('boy');
                            onAvatarIndexChanged(0);
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    ChoiceChip(
                      label: const Text('Fille'),
                      selected: selectedGender == 'girl',
                      onSelected: (selected) {
                        if (selected) {
                          dialogSetState(() {
                            onGenderChanged('girl');
                            onAvatarIndexChanged(0);
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Grille d'avatars
                GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: ChildAvatars.getAvatarsByGender(selectedGender).length,
                  itemBuilder: (context, index) {
                    final avatar = ChildAvatars.getAvatar(selectedGender, index);
                    final isSelected = index == selectedAvatarIndex;
                    
                    return GestureDetector(
                      onTap: () {
                        dialogSetState(() {
                          onAvatarIndexChanged(index);
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.deepPurple.withOpacity(0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? Colors.deepPurple : Colors.grey.withOpacity(0.3),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            avatar,
                            style: const TextStyle(fontSize: 30),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }
}
