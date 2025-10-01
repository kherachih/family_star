import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/child.dart';
import '../../models/task.dart';
import '../../models/sanction.dart';
import '../../providers/children_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rewards_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_colors.dart';
import '../rewards/rewards_catalog_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.child.name);
    _ageController = TextEditingController(text: widget.child.age.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedChild = widget.child.copyWith(
      name: _nameController.text.trim(),
      age: int.parse(_ageController.text),
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
      await childrenProvider.updateChildStars(widget.child.id, task.starChange);

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
                  // Photo de profil (Avatar) avec dégradé
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
                        currentChild.avatar,
                        style: const TextStyle(fontSize: 70),
                      ),
                    ),
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

                  // Informations du profil
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

                          // Âge
                          TextFormField(
                            controller: _ageController,
                            enabled: _isEditing,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Âge',
                              prefixIcon: Icon(Icons.cake),
                              border: OutlineInputBorder(),
                              suffixText: 'ans',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Veuillez saisir l\'âge';
                              }
                              final age = int.tryParse(value);
                              if (age == null || age < 3 || age > 12) {
                                return 'L\'âge doit être entre 3 et 12 ans';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

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
    await rewardsProvider.loadSanctions(child.parentId);

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
                      if (sanction.duration != null)
                        Text(
                          'Durée: ${sanction.duration}',
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
}
