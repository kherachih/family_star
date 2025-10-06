import 'package:cloud_firestore/cloud_firestore.dart';

class TutorialState {
  final String id;
  final String parentId;
  final bool hasCompletedTutorial;
  final int currentStep;
  final bool hasCompletedIntroduction;
  final bool hasAddedChildren;
  final bool hasConfiguredTasks;
  final bool hasConfiguredRewards;
  final bool hasConfiguredSanctions;
  final DateTime createdAt;
  final DateTime updatedAt;

  TutorialState({
    required this.id,
    required this.parentId,
    required this.hasCompletedTutorial,
    this.currentStep = 0,
    this.hasCompletedIntroduction = false,
    this.hasAddedChildren = false,
    this.hasConfiguredTasks = false,
    this.hasConfiguredRewards = false,
    this.hasConfiguredSanctions = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TutorialState.fromMap(Map<String, dynamic> map) {
    return TutorialState(
      id: map['id'] as String,
      parentId: map['parentId'] as String,
      hasCompletedTutorial: map['hasCompletedTutorial'] as bool? ?? false,
      currentStep: map['currentStep'] as int? ?? 0,
      hasCompletedIntroduction: map['hasCompletedIntroduction'] as bool? ?? false,
      hasAddedChildren: map['hasAddedChildren'] as bool? ?? false,
      hasConfiguredTasks: map['hasConfiguredTasks'] as bool? ?? false,
      hasConfiguredRewards: map['hasConfiguredRewards'] as bool? ?? false,
      hasConfiguredSanctions: map['hasConfiguredSanctions'] as bool? ?? false,
      createdAt: map['createdAt'] is String
          ? DateTime.parse(map['createdAt'] as String)
          : (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] is String
          ? DateTime.parse(map['updatedAt'] as String)
          : (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parentId': parentId,
      'hasCompletedTutorial': hasCompletedTutorial,
      'currentStep': currentStep,
      'hasCompletedIntroduction': hasCompletedIntroduction,
      'hasAddedChildren': hasAddedChildren,
      'hasConfiguredTasks': hasConfiguredTasks,
      'hasConfiguredRewards': hasConfiguredRewards,
      'hasConfiguredSanctions': hasConfiguredSanctions,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  TutorialState copyWith({
    String? id,
    String? parentId,
    bool? hasCompletedTutorial,
    int? currentStep,
    bool? hasCompletedIntroduction,
    bool? hasAddedChildren,
    bool? hasConfiguredTasks,
    bool? hasConfiguredRewards,
    bool? hasConfiguredSanctions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TutorialState(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      hasCompletedTutorial: hasCompletedTutorial ?? this.hasCompletedTutorial,
      currentStep: currentStep ?? this.currentStep,
      hasCompletedIntroduction: hasCompletedIntroduction ?? this.hasCompletedIntroduction,
      hasAddedChildren: hasAddedChildren ?? this.hasAddedChildren,
      hasConfiguredTasks: hasConfiguredTasks ?? this.hasConfiguredTasks,
      hasConfiguredRewards: hasConfiguredRewards ?? this.hasConfiguredRewards,
      hasConfiguredSanctions: hasConfiguredSanctions ?? this.hasConfiguredSanctions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Méthodes utilitaires pour le tutoriel
  TutorialState markStepCompleted(int step) {
    TutorialState updated = copyWith(currentStep: step + 1, updatedAt: DateTime.now());
    
    // Marquer les étapes spécifiques comme complétées
    switch (step) {
      case 0: // Étape d'introduction
        updated = updated.copyWith(hasCompletedIntroduction: true);
        break;
      case 1: // Étape d'ajout d'enfants
        updated = updated.copyWith(hasAddedChildren: true);
        break;
      case 2: // Étape de configuration des tâches
        updated = updated.copyWith(hasConfiguredTasks: true);
        break;
      case 3: // Étape de configuration des récompenses
        updated = updated.copyWith(hasConfiguredRewards: true);
        break;
      case 4: // Étape de configuration des sanctions
        updated = updated.copyWith(hasConfiguredSanctions: true);
        break;
    }
    
    // Si c'est la dernière étape, marquer le tutoriel comme complété
    if (step >= 4) {
      updated = updated.copyWith(hasCompletedTutorial: true);
    }
    
    return updated;
  }

  bool get isOnboardingStep => !hasCompletedTutorial;
  
  int get totalSteps => 5; // Nombre total d'étapes du tutoriel
  
  double get progress => (currentStep / totalSteps).clamp(0.0, 1.0);
  
  String get stepTitle {
    switch (currentStep) {
      case 0:
        return 'Family Star';
      case 1:
        return 'Ajouter vos enfants';
      case 2:
        return 'Configurer les tâches';
      case 3:
        return 'Définir les récompenses';
      case 4:
        return 'Configurer les sanctions';
      default:
        return 'Configuration terminé';
    }
  }
  
  String get stepDescription {
    switch (currentStep) {
      case 0:
        return 'Découvrez le principe de l\'application Family Star';
      case 1:
        return 'Commencez par ajouter vos enfants à votre famille';
      case 2:
        return 'Configurez les tâches quotidiennes pour vos enfants';
      case 3:
        return 'Définissez les récompenses que vos enfants peuvent obtenir';
      case 4:
        return 'Configurez les sanctions en cas de non-respect des règles';
      default:
        return 'Félicitations ! Vous avez terminé le tutoriel';
    }
  }
}