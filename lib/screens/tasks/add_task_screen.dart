import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/children_provider.dart';
import '../../models/task.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_colors.dart';

class AddTaskScreen extends StatefulWidget {
  final Task? task; // Tâche à modifier (optionnel)
  
  const AddTaskScreen({super.key, this.task});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _starsController = TextEditingController(text: '5');

  TaskType _selectedType = TaskType.positive;
  Set<String> _selectedChildIds = {};
  bool _isDaily = false;
  bool _isLoading = false;
  bool _isEditMode = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.task != null;
    
    // Initialiser les animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    // Démarrer l'animation
    _animationController.forward();
    
    if (_isEditMode) {
      // Remplir les champs avec les données de la tâche existante
      _titleController.text = widget.task!.title;
      _starsController.text = widget.task!.stars.toString();
      _selectedType = widget.task!.type;
      _selectedChildIds = Set<String>.from(widget.task!.childIds);
      _isDaily = widget.task!.isDaily;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _starsController.dispose();
    _animationController.dispose();
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
      Task task;
      
      if (_isEditMode) {
        // Mode édition : mettre à jour la tâche existante
        task = widget.task!.copyWith(
          title: _titleController.text.trim(),
          type: _selectedType,
          stars: int.parse(_starsController.text),
          childIds: _selectedChildIds.toList(),
          isDaily: _isDaily,
          updatedAt: DateTime.now(),
        );
        
        await FirestoreService().updateTask(task);
      } else {
        // Mode création : créer une nouvelle tâche
        task = Task(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          parentId: authProvider.currentUser!.id,
          childIds: _selectedChildIds.toList(),
          title: _titleController.text.trim(),
          description: null,
          type: _selectedType,
          stars: int.parse(_starsController.text),
          isDaily: _isDaily,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await FirestoreService().createTask(task);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode
                ? 'Tâche "${task.title}" modifiée avec succès'
                : 'Tâche "${task.title}" ajoutée avec succès'),
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
        title: Text(_isEditMode ? 'Modifier une tâche' : 'Ajouter une tâche'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
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
                : Text(
                    _isEditMode ? 'METTRE À JOUR' : 'SAUVEGARDER',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Container(
        color: AppColors.background,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Type de tâche (Positive/Négative)
                    Card(
                      elevation: 4,
                      shadowColor: AppColors.cardShadow.color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.category,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Type de tâche',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        setState(() => _selectedType = TaskType.positive);
                                      },
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: _selectedType == TaskType.positive
                                            ? AppColors.taskPositive.withValues(alpha: 0.15)
                                            : null,
                                        side: BorderSide(
                                          color: _selectedType == TaskType.positive
                                              ? AppColors.taskPositive
                                              : Colors.grey.shade300,
                                          width: 2.5,
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        elevation: _selectedType == TaskType.positive ? 2 : 0,
                                        shadowColor: _selectedType == TaskType.positive
                                            ? AppColors.taskPositive.withValues(alpha: 0.3)
                                            : Colors.transparent,
                                      ),
                                      icon: Icon(
                                        Icons.add_circle,
                                        color: _selectedType == TaskType.positive
                                            ? AppColors.taskPositive
                                            : Colors.grey.shade500,
                                        size: 28,
                                      ),
                                      label: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Positive',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: _selectedType == TaskType.positive
                                                  ? AppColors.taskPositive
                                                  : Colors.grey.shade700,
                                              fontWeight: _selectedType == TaskType.positive
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.star,
                                            color: _selectedType == TaskType.positive
                                                ? AppColors.taskPositive
                                                : Colors.grey.shade500,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        setState(() => _selectedType = TaskType.negative);
                                      },
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: _selectedType == TaskType.negative
                                            ? AppColors.taskNegative.withValues(alpha: 0.15)
                                            : null,
                                        side: BorderSide(
                                          color: _selectedType == TaskType.negative
                                              ? AppColors.taskNegative
                                              : Colors.grey.shade300,
                                          width: 2.5,
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        elevation: _selectedType == TaskType.negative ? 2 : 0,
                                        shadowColor: _selectedType == TaskType.negative
                                            ? AppColors.taskNegative.withValues(alpha: 0.3)
                                            : Colors.transparent,
                                      ),
                                      icon: Icon(
                                        Icons.remove_circle,
                                        color: _selectedType == TaskType.negative
                                            ? AppColors.taskNegative
                                            : Colors.grey.shade500,
                                        size: 28,
                                      ),
                                      label: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Négative',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: _selectedType == TaskType.negative
                                                  ? AppColors.taskNegative
                                                  : Colors.grey.shade700,
                                              fontWeight: _selectedType == TaskType.negative
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.star_border,
                                            color: _selectedType == TaskType.negative
                                                ? AppColors.taskNegative
                                                : Colors.grey.shade500,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Indicateur visuel du type sélectionné
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _selectedType == TaskType.positive
                                    ? AppColors.taskPositive.withValues(alpha: 0.1)
                                    : AppColors.taskNegative.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedType == TaskType.positive
                                      ? AppColors.taskPositive
                                      : AppColors.taskNegative,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _selectedType == TaskType.positive
                                        ? Icons.info
                                        : Icons.info_outline,
                                    color: _selectedType == TaskType.positive
                                        ? AppColors.taskPositive
                                        : AppColors.taskNegative,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _selectedType == TaskType.positive
                                          ? 'Les tâches positives donnent des étoiles à l\'enfant lorsqu\'il les accomplit.'
                                          : 'Les tâches négatives enlèvent des étoiles à l\'enfant lorsqu\'il ne respecte pas les règles.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _selectedType == TaskType.positive
                                            ? AppColors.taskPositive
                                            : AppColors.taskNegative,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Sélection de l'enfant
                    Card(
                      elevation: 4,
                      shadowColor: AppColors.cardShadow.color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.child_care,
                                    color: AppColors.accent,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Assigner à',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_selectedChildIds.isNotEmpty)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.accent.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: AppColors.accent,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_selectedChildIds.length} enfant(s) sélectionné(s)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 16),
                            if (children.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.info_outline, color: Colors.grey),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'Aucun enfant disponible. Ajoutez d\'abord un enfant.',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ...children.map((child) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: _selectedChildIds.contains(child.id)
                                          ? AppColors.accent.withValues(alpha: 0.1)
                                          : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _selectedChildIds.contains(child.id)
                                            ? AppColors.accent
                                            : Colors.grey.shade300,
                                        width: _selectedChildIds.contains(child.id) ? 2 : 1,
                                      ),
                                      boxShadow: _selectedChildIds.contains(child.id)
                                          ? [
                                              BoxShadow(
                                                color: AppColors.accent.withValues(alpha: 0.2),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: CheckboxListTile(
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
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: AppColors.secondary.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(child.avatar, style: const TextStyle(fontSize: 26)),
                                          ),
                                          const SizedBox(width: 14),
                                          Text(
                                            child.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      activeColor: AppColors.accent,
                                      controlAffinity: ListTileControlAffinity.leading,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    ),
                                  )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Titre
                    Card(
                      elevation: 4,
                      shadowColor: AppColors.cardShadow.color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: _selectedType == TaskType.positive
                                        ? AppColors.taskPositive.withValues(alpha: 0.1)
                                        : AppColors.taskNegative.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.title,
                                    color: _selectedType == TaskType.positive
                                        ? AppColors.taskPositive
                                        : AppColors.taskNegative,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _selectedType == TaskType.positive
                                      ? 'Titre de la tâche positive'
                                      : 'Titre de l\'action négative',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _titleController,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: _selectedType == TaskType.positive
                                        ? AppColors.taskPositive
                                        : AppColors.taskNegative,
                                    width: 2.5,
                                  ),
                                ),
                                hintText: _selectedType == TaskType.positive
                                    ? 'Ex: Ranger sa chambre'
                                    : 'Ex: Ne pas faire son lit',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 15,
                                ),
                                prefixIcon: Icon(
                                  _selectedType == TaskType.positive
                                      ? Icons.task_alt
                                      : Icons.gpp_bad,
                                  color: _selectedType == TaskType.positive
                                      ? AppColors.taskPositive
                                      : AppColors.taskNegative,
                                  size: 24,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Veuillez saisir un titre';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tâche quotidienne (uniquement pour les tâches positives)
                    if (_selectedType == TaskType.positive)
                      Card(
                        elevation: 4,
                        shadowColor: AppColors.cardShadow.color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.repeat,
                                      color: AppColors.accent,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Tâche quotidienne',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          setState(() => _isDaily = false);
                                        },
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: !_isDaily
                                              ? Colors.grey.shade100
                                              : null,
                                          side: BorderSide(
                                            color: !_isDaily
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade300,
                                            width: 2.5,
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 20),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          elevation: !_isDaily ? 2 : 0,
                                          shadowColor: !_isDaily
                                              ? Colors.grey.withValues(alpha: 0.2)
                                              : Colors.transparent,
                                        ),
                                        icon: Icon(
                                          Icons.event_busy,
                                          color: !_isDaily ? Colors.grey.shade700 : Colors.grey.shade500,
                                          size: 28,
                                        ),
                                        label: Text(
                                          'Non',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: !_isDaily ? Colors.grey.shade700 : Colors.grey.shade500,
                                            fontWeight: !_isDaily ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          setState(() => _isDaily = true);
                                        },
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: _isDaily
                                              ? AppColors.accent.withValues(alpha: 0.15)
                                              : null,
                                          side: BorderSide(
                                            color: _isDaily
                                                ? AppColors.accent
                                                : Colors.grey.shade300,
                                            width: 2.5,
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 20),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          elevation: _isDaily ? 2 : 0,
                                          shadowColor: _isDaily
                                              ? AppColors.accent.withValues(alpha: 0.3)
                                              : Colors.transparent,
                                        ),
                                        icon: Icon(
                                          Icons.event_repeat,
                                          color: _isDaily ? AppColors.accent : Colors.grey.shade500,
                                          size: 28,
                                        ),
                                        label: Text(
                                          'Oui',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: _isDaily ? AppColors.accent : Colors.grey.shade500,
                                            fontWeight: _isDaily ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _isDaily ? AppColors.accent.withValues(alpha: 0.1) : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _isDaily ? AppColors.accent.withValues(alpha: 0.3) : Colors.grey.shade300,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _isDaily ? Icons.info : Icons.info_outline,
                                      color: _isDaily ? AppColors.accent : Colors.grey.shade600,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _isDaily
                                            ? 'Cette tâche se répètera chaque jour et pourra être marquée comme complétée quotidiennement.'
                                            : 'Cette tâche est ponctuelle et ne se répètera pas.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: _isDaily ? AppColors.accent : Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Nombre d'étoiles
                    Card(
                      elevation: 4,
                      shadowColor: AppColors.cardShadow.color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.starPositive.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.star,
                                    color: AppColors.starPositive,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Nombre d\'étoiles',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _starsController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: _selectedType == TaskType.positive
                                        ? AppColors.taskPositive
                                        : AppColors.taskNegative,
                                    width: 2.5,
                                  ),
                                ),
                                prefixIcon: Icon(
                                  _selectedType == TaskType.positive
                                      ? Icons.add_circle
                                      : Icons.remove_circle,
                                  color: _selectedType == TaskType.positive
                                      ? AppColors.taskPositive
                                      : AppColors.taskNegative,
                                  size: 24,
                                ),
                                suffixText: '⭐',
                                suffixStyle: TextStyle(
                                  color: _selectedType == TaskType.positive
                                      ? AppColors.taskPositive
                                      : AppColors.taskNegative,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
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
                            const SizedBox(height: 16),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _selectedType == TaskType.positive
                                    ? AppColors.taskPositive.withValues(alpha: 0.1)
                                    : AppColors.taskNegative.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedType == TaskType.positive
                                      ? AppColors.taskPositive.withValues(alpha: 0.3)
                                      : AppColors.taskNegative.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _selectedType == TaskType.positive
                                        ? Icons.info
                                        : Icons.info_outline,
                                    color: _selectedType == TaskType.positive
                                        ? AppColors.taskPositive
                                        : AppColors.taskNegative,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _selectedType == TaskType.positive
                                          ? 'Étoiles gagnées en faisant cette tâche'
                                          : 'Étoiles perdues pour cette action',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _selectedType == TaskType.positive
                                            ? AppColors.taskPositive
                                            : AppColors.taskNegative,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bouton d'ajout
                    Container(
                      margin: const EdgeInsets.only(top: 16, bottom: 40),
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handleSubmit,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Icon(
                                _isEditMode ? Icons.update : Icons.add,
                                size: 24,
                              ),
                        label: Text(
                          _isEditMode ? 'Mettre à jour la tâche' : 'Ajouter la tâche',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 6,
                          shadowColor: AppColors.buttonShadow.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}