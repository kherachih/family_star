import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/children_provider.dart';
import '../../models/task.dart';
import '../../models/child.dart';
import '../../services/firestore_service.dart';
import 'add_task_screen.dart';

class TasksListScreen extends StatefulWidget {
  const TasksListScreen({super.key});

  @override
  State<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends State<TasksListScreen> {
  List<Task> _tasks = [];
  bool _isLoading = true;
  String? _selectedChildId; // null = toutes les tâches

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.currentUser == null) return;

      // Charger toutes les tâches du parent
      final tasks = await FirestoreService().getTasksByParentId(authProvider.currentUser!.id);

      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });

      print('Tâches chargées: ${tasks.length}');
    } catch (e) {
      print('Erreur chargement tâches: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Task> get _filteredTasks {
    if (_selectedChildId == null) {
      return _tasks;
    }
    return _tasks.where((task) => task.childIds.contains(_selectedChildId)).toList();
  }

  Future<void> _deleteTask(Task task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la tâche'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${task.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirestoreService().deleteTask(task.id);
        await _loadTasks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tâche supprimée'),
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
  }

  Future<void> _showApplyTaskDialog(Task task, List<Child> assignedChildren) async {
    if (assignedChildren.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun enfant assigné à cette tâche'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Si un seul enfant, appliquer directement
    if (assignedChildren.length == 1) {
      await _applyTaskToChild(task, assignedChildren.first);
      return;
    }

    // Si plusieurs enfants, demander lesquels sélectionner
    final selectedChildren = await showDialog<List<Child>>(
      context: context,
      builder: (context) => _ApplyTaskDialog(
        task: task,
        children: assignedChildren,
      ),
    );

    if (selectedChildren != null && selectedChildren.isNotEmpty) {
      final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);

      try {
        // Appliquer la tâche à tous les enfants sélectionnés
        for (final child in selectedChildren) {
          await childrenProvider.updateChildStars(child.id, task.starChange);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                task.type == TaskType.positive
                    ? '${selectedChildren.length} enfant(s) ont gagné ${task.stars} ⭐'
                    : '${selectedChildren.length} enfant(s) ont perdu ${task.stars} ⭐',
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
  }

  Future<void> _applyTaskToChild(Task task, Child child) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.type == TaskType.positive
            ? 'Appliquer la tâche'
            : 'Appliquer l\'action'),
        content: Text(
          task.type == TaskType.positive
              ? '${child.name} va gagner ${task.stars} ⭐'
              : '${child.name} va perdre ${task.stars} ⭐',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: task.type == TaskType.positive
                  ? Colors.green
                  : Colors.red,
            ),
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);
        await childrenProvider.updateChildStars(child.id, task.starChange);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                task.type == TaskType.positive
                    ? '${child.name} a gagné ${task.stars} ⭐'
                    : '${child.name} a perdu ${task.stars} ⭐',
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
  }

  @override
  Widget build(BuildContext context) {
    final childrenProvider = Provider.of<ChildrenProvider>(context);
    final children = childrenProvider.children;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tâches et Actions'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filtre par enfant
          if (children.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Tous'),
                      selected: _selectedChildId == null,
                      onSelected: (selected) {
                        setState(() => _selectedChildId = null);
                      },
                      selectedColor: Colors.deepPurple[100],
                    ),
                    const SizedBox(width: 8),
                    ...children.map((child) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(child.avatar),
                                const SizedBox(width: 4),
                                Text(child.name),
                              ],
                            ),
                            selected: _selectedChildId == child.id,
                            onSelected: (selected) {
                              setState(() {
                                _selectedChildId = selected ? child.id : null;
                              });
                            },
                            selectedColor: Colors.deepPurple[100],
                          ),
                        )),
                  ],
                ),
              ),
            ),

          // Liste des tâches
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.task_alt, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune tâche',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Ajoutez des tâches pour vos enfants',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTasks,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = _filteredTasks[index];
                            // Récupérer tous les enfants assignés à cette tâche
                            final assignedChildren = children
                                .where((c) => task.childIds.contains(c.id))
                                .toList();

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: task.type == TaskType.positive
                                      ? Colors.green[100]
                                      : Colors.red[100],
                                  child: Icon(
                                    task.type == TaskType.positive
                                        ? Icons.add_circle
                                        : Icons.remove_circle,
                                    color: task.type == TaskType.positive
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                title: Text(
                                  task.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Afficher tous les enfants assignés
                                    if (assignedChildren.isNotEmpty)
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: assignedChildren.map((child) => Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.deepPurple[50],
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.deepPurple[200]!),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(child.avatar, style: const TextStyle(fontSize: 14)),
                                              const SizedBox(width: 4),
                                              Text(
                                                child.name,
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        )).toList(),
                                      ),
                                    if (task.description != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        task.description!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${task.type == TaskType.positive ? "+" : "-"}${task.stars} ⭐',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: task.type == TaskType.positive
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'apply') {
                                          _showApplyTaskDialog(task, assignedChildren);
                                        } else if (value == 'delete') {
                                          _deleteTask(task);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'apply',
                                          child: Row(
                                            children: [
                                              Icon(Icons.check_circle, color: Colors.green),
                                              SizedBox(width: 8),
                                              Text('Appliquer'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Supprimer'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTaskScreen()),
          );
          if (result == true) {
            _loadTasks();
          }
        },
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle tâche'),
      ),
    );
  }
}

// Dialog pour sélectionner les enfants à qui appliquer la tâche
class _ApplyTaskDialog extends StatefulWidget {
  final Task task;
  final List<Child> children;

  const _ApplyTaskDialog({
    required this.task,
    required this.children,
  });

  @override
  State<_ApplyTaskDialog> createState() => _ApplyTaskDialogState();
}

class _ApplyTaskDialogState extends State<_ApplyTaskDialog> {
  late Set<String> _selectedChildIds;

  @override
  void initState() {
    super.initState();
    // Sélectionner tous les enfants par défaut
    _selectedChildIds = widget.children.map((c) => c.id).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.task.type == TaskType.positive
            ? 'Appliquer la tâche'
            : 'Appliquer l\'action',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sélectionnez les enfants:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          ...widget.children.map((child) {
            final isSelected = _selectedChildIds.contains(child.id);
            return CheckboxListTile(
              value: isSelected,
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _selectedChildIds.add(child.id);
                  } else {
                    _selectedChildIds.remove(child.id);
                  }
                });
              },
              title: Row(
                children: [
                  Text(child.avatar, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(child.name),
                ],
              ),
              subtitle: Text(
                widget.task.type == TaskType.positive
                    ? '+${widget.task.stars} ⭐'
                    : '-${widget.task.stars} ⭐',
                style: TextStyle(
                  color: widget.task.type == TaskType.positive
                      ? Colors.green
                      : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              activeColor: Colors.deepPurple,
              controlAffinity: ListTileControlAffinity.leading,
            );
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: _selectedChildIds.isEmpty
              ? null
              : () {
                  final selectedChildren = widget.children
                      .where((c) => _selectedChildIds.contains(c.id))
                      .toList();
                  Navigator.pop(context, selectedChildren);
                },
          style: TextButton.styleFrom(
            foregroundColor: widget.task.type == TaskType.positive
                ? Colors.green
                : Colors.red,
          ),
          child: Text(
            'Appliquer (${_selectedChildIds.length})',
          ),
        ),
      ],
    );
  }
}