import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/children_provider.dart';
import '../../models/task.dart';
import '../../services/firestore_service.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _starsController = TextEditingController(text: '5');

  TaskType _selectedType = TaskType.positive;
  Set<String> _selectedChildIds = {};
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _starsController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedChildIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins un enfant'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      final task = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        parentId: authProvider.currentUser!.id,
        childIds: _selectedChildIds.toList(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        type: _selectedType,
        stars: int.parse(_starsController.text),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await FirestoreService().createTask(task);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tâche "${task.title}" ajoutée avec succès'),
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final childrenProvider = Provider.of<ChildrenProvider>(context);
    final children = childrenProvider.children;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter une tâche'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSubmit,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'SAUVEGARDER',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type de tâche (Positive/Négative)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Type de tâche',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() => _selectedType = TaskType.positive);
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: _selectedType == TaskType.positive
                                    ? Colors.green[50]
                                    : null,
                                side: BorderSide(
                                  color: _selectedType == TaskType.positive
                                      ? Colors.green
                                      : Colors.grey,
                                  width: 2,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              icon: const Icon(Icons.add_circle, color: Colors.green),
                              label: const Text(
                                'Positive\n(Donne des ⭐)',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() => _selectedType = TaskType.negative);
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: _selectedType == TaskType.negative
                                    ? Colors.red[50]
                                    : null,
                                side: BorderSide(
                                  color: _selectedType == TaskType.negative
                                      ? Colors.red
                                      : Colors.grey,
                                  width: 2,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              label: const Text(
                                'Négative\n(Enlève des ⭐)',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Sélection de l'enfant
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assigner à (sélection multiple)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_selectedChildIds.isNotEmpty)
                        Text(
                          '${_selectedChildIds.length} enfant(s) sélectionné(s)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.deepPurple[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      const SizedBox(height: 12),
                      if (children.isEmpty)
                        const Text(
                          'Aucun enfant disponible. Ajoutez d\'abord un enfant.',
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        ...children.map((child) => CheckboxListTile(
                              value: _selectedChildIds.contains(child.id),
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
                                  Text(child.avatar, style: const TextStyle(fontSize: 24)),
                                  const SizedBox(width: 8),
                                  Text(child.name),
                                ],
                              ),
                              activeColor: Colors.deepPurple,
                              controlAffinity: ListTileControlAffinity.leading,
                            )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Titre
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: _selectedType == TaskType.positive
                      ? 'Titre de la tâche positive'
                      : 'Titre de l\'action négative',
                  prefixIcon: const Icon(Icons.title),
                  border: const OutlineInputBorder(),
                  hintText: _selectedType == TaskType.positive
                      ? 'Ex: Ranger sa chambre'
                      : 'Ex: Ne pas faire son lit',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez saisir un titre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description (optionnelle)
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnel)',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                  hintText: 'Détails supplémentaires...',
                ),
              ),
              const SizedBox(height: 16),

              // Nombre d'étoiles
              TextFormField(
                controller: _starsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Nombre d\'étoiles',
                  prefixIcon: Icon(
                    _selectedType == TaskType.positive
                        ? Icons.add_circle
                        : Icons.remove_circle,
                    color: _selectedType == TaskType.positive
                        ? Colors.green
                        : Colors.red,
                  ),
                  border: const OutlineInputBorder(),
                  suffixText: '⭐',
                  helperText: _selectedType == TaskType.positive
                      ? 'Étoiles gagnées en faisant cette tâche'
                      : 'Étoiles perdues pour cette action',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez saisir le nombre d\'étoiles';
                  }
                  final stars = int.tryParse(value);
                  if (stars == null || stars < 1 || stars > 50) {
                    return 'Entre 1 et 50 étoiles';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Aperçu
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _selectedType == TaskType.positive
                      ? Colors.green[50]
                      : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedType == TaskType.positive
                        ? Colors.green[200]!
                        : Colors.red[200]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aperçu:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _titleController.text.isEmpty
                          ? 'Titre de la tâche...'
                          : _titleController.text,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_selectedType == TaskType.positive ? "+" : "-"}${_starsController.text} ⭐',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _selectedType == TaskType.positive
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Bouton d'ajout
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleSubmit,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.add),
                label: const Text('Ajouter la tâche'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}