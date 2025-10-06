import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/children_provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/tutorial_selections_provider.dart';
import '../../utils/app_colors.dart';
import '../tasks/add_task_screen.dart';
import '../../models/task.dart';
import '../../services/firestore_service.dart';

class TutorialTasksStep extends StatefulWidget {
  final VoidCallback onStepCompleted;

  const TutorialTasksStep({
    super.key,
    required this.onStepCompleted,
  });

  @override
  State<TutorialTasksStep> createState() => _TutorialTasksStepState();
}

class _TutorialTasksStepState extends State<TutorialTasksStep> {
  List<Task> _suggestedTasks = [];
  List<Task> _positiveTasks = [];
  List<Task> _negativeTasks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeSuggestedTasks();
  }

  void _initializeSuggestedTasks() {
    setState(() {
      _isLoading = true;
    });

    // Tâches suggérées pour les enfants
    _suggestedTasks = [
      Task(
        id: 'suggested_1',
        parentId: 'suggested',
        childIds: [], // Sera rempli plus tard
        title: 'Ranger sa chambre',
        description: null,
        type: TaskType.positive,
        stars: 3,
        isDaily: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Task(
        id: 'suggested_2',
        parentId: 'suggested',
        childIds: [],
        title: 'Brosser les dents',
        description: null,
        type: TaskType.positive,
        stars: 2,
        isDaily: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Task(
        id: 'suggested_3',
        parentId: 'suggested',
        childIds: [],
        title: 'Faire ses devoirs',
        description: null,
        type: TaskType.positive,
        stars: 5,
        isDaily: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Task(
        id: 'suggested_4',
        parentId: 'suggested',
        childIds: [],
        title: 'Mettre la table',
        description: null,
        type: TaskType.positive,
        stars: 2,
        isDaily: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Task(
        id: 'suggested_5',
        parentId: 'suggested',
        childIds: [],
        title: 'Aider à la cuisine',
        description: null,
        type: TaskType.positive,
        stars: 3,
        isDaily: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Task(
        id: 'suggested_6',
        parentId: 'suggested',
        childIds: [],
        title: 'Ne pas faire de bruit',
        description: null,
        type: TaskType.negative,
        stars: 2,
        isDaily: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Task(
        id: 'suggested_7',
        parentId: 'suggested',
        childIds: [],
        title: 'Respecter les heures de coucher',
        description: null,
        type: TaskType.positive,
        stars: 3,
        isDaily: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Task(
        id: 'suggested_8',
        parentId: 'suggested',
        childIds: [],
        title: 'Ranger ses jouets',
        description: null,
        type: TaskType.positive,
        stars: 2,
        isDaily: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    // Séparer les tâches positives et négatives
    _positiveTasks = _suggestedTasks.where((task) => task.type == TaskType.positive).toList();
    _negativeTasks = _suggestedTasks.where((task) => task.type == TaskType.negative).toList();

    // Stocker les tâches dans le provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectionsProvider = Provider.of<TutorialSelectionsProvider>(context, listen: false);
      selectionsProvider.setTasks(_suggestedTasks);
    });

    setState(() {
      _isLoading = false;
    });
  }

  void _toggleTaskSelection(String taskId) {
    final selectionsProvider = Provider.of<TutorialSelectionsProvider>(context, listen: false);
    selectionsProvider.toggleTaskSelection(taskId);
  }

  void _navigateToAddTask() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const AddTaskScreen(),
      ),
    );

    // Si une tâche a été ajoutée, on pourrait recharger les tâches ici
    if (result == true) {
      // Recharger les tâches si nécessaire
    }
  }

  void _goToNextStep() {
    final selectionsProvider = Provider.of<TutorialSelectionsProvider>(context, listen: false);
    
    if (!selectionsProvider.selections.hasSelectedTasks) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins une tâche'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Passer à l'étape suivante
    widget.onStepCompleted();
  }

  Widget _buildTaskItem(Task task) {
    final selectionsProvider = Provider.of<TutorialSelectionsProvider>(context);
    final isSelected = selectionsProvider.selections.selectedTaskIds.contains(task.id);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: task.type == TaskType.positive
                ? AppColors.taskPositive.withOpacity(0.1)
                : AppColors.taskNegative.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            task.type == TaskType.positive
                ? Icons.add_circle
                : Icons.remove_circle,
            color: task.type == TaskType.positive
                ? AppColors.taskPositive
                : AppColors.taskNegative,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.blue : null,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(
              task.isDaily ? Icons.repeat : Icons.event,
              size: 14,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              task.isDaily ? 'Quotidienne' : 'Ponctuelle',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: task.type == TaskType.positive
                ? AppColors.taskPositive.withOpacity(0.1)
                : AppColors.taskNegative.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star,
                size: 14,
                color: task.type == TaskType.positive
                    ? AppColors.taskPositive
                    : AppColors.taskNegative,
              ),
              const SizedBox(width: 2),
              Text(
                '${task.stars}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: task.type == TaskType.positive
                      ? AppColors.taskPositive
                      : AppColors.taskNegative,
                ),
              ),
            ],
          ),
        ),
        onTap: () => _toggleTaskSelection(task.id!),
      ),
    );
  }

  Widget _buildTaskSection(String title, List<Task> tasks, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sélectionnez les tâches qui vous conviennent',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              return _buildTaskItem(tasks[index]);
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChildrenProvider>(
      builder: (context, childrenProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête de l'étape
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.gradientSecondary,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.task_alt,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Configurez les tâches quotidiennes',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Définissez les tâches que vos enfants doivent accomplir chaque jour. Vous pouvez utiliser nos suggestions ou créer vos propres tâches personnalisées.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Tâches suggérées
              if (_isLoading) ...[
                const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ] else ...[
                // Section des tâches positives
                _buildTaskSection(
                  'Tâches qui font gagner des étoiles',
                  _positiveTasks,
                  AppColors.taskPositive,
                ),
                
                const SizedBox(height: 24),
                
                // Section des tâches négatives
                _buildTaskSection(
                  'Tâches qui font perdre des étoiles',
                  _negativeTasks,
                  AppColors.taskNegative,
                ),
              ],
              
              // Boutons d'action
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: Consumer<TutorialSelectionsProvider>(
                  builder: (context, selectionsProvider, child) {
                    return ElevatedButton.icon(
                      onPressed: _goToNextStep,
                      icon: const Icon(Icons.check),
                      label: Text('Valider les tâches sélectionnées (${selectionsProvider.selections.selectedTaskIds.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.secondary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Astuce : Sélectionnez plusieurs tâches puis validez en une seule fois !',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}