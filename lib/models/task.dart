import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskType {
  positive('Positive', '+'), // Donne des étoiles
  negative('Negative', '-'); // Enlève des étoiles

  const TaskType(this.displayName, this.symbol);
  final String displayName;
  final String symbol;
}

class Task {
  final String id;
  final String parentId; // ID du parent qui a créé la tâche
  final List<String> childIds; // IDs des enfants assignés (peut être plusieurs)
  final String title; // Ex: "Ranger sa chambre" ou "Ne pas faire son lit"
  final String? description; // Description optionnelle
  final TaskType type; // Positif (+) ou Négatif (-)
  final int stars; // Nombre d'étoiles (toujours positif)
  final bool isActive; // Si la tâche est active ou archivée
  final bool isDaily; // Si la tâche est quotidienne
  final DateTime? lastCompletedAt; // Date de dernière complétion (pour les tâches quotidiennes) - gardé pour compatibilité
  final Map<String, DateTime>? dailyCompletions; // Suivi des complétions quotidiennes par enfant (childId -> date de complétion)
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.parentId,
    required this.childIds,
    required this.title,
    this.description,
    required this.type,
    required this.stars,
    this.isActive = true,
    this.isDaily = false,
    this.lastCompletedAt,
    this.dailyCompletions,
    required this.createdAt,
    required this.updatedAt,
  });

  // Compatibilité avec l'ancien système (childId unique)
  String get childId => childIds.isNotEmpty ? childIds.first : '';

  /// Retourne le changement d'étoiles (positif ou négatif)
  int get starChange => type == TaskType.positive ? stars : -stars;
  
  /// Vérifie si un enfant spécifique a complété la tâche aujourd'hui
  bool isCompletedTodayByChild(String childId) {
    if (!isDaily || dailyCompletions == null || !dailyCompletions!.containsKey(childId)) {
      return false;
    }
    
    final completionDate = dailyCompletions![childId]!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final completionDay = DateTime(completionDate.year, completionDate.month, completionDate.day);
    
    return completionDay == today;
  }
  
  /// Vérifie si tous les enfants assignés ont complété la tâche aujourd'hui
  bool isCompletedTodayByAllChildren() {
    if (!isDaily || childIds.isEmpty) return false;
    
    // Si aucune complétion enregistrée, retourner false
    if (dailyCompletions == null || dailyCompletions!.isEmpty) return false;
    
    // Vérifier si tous les enfants assignés ont complété la tâche aujourd'hui
    for (final childId in childIds) {
      if (!isCompletedTodayByChild(childId)) {
        return false;
      }
    }
    
    return true;
  }
  
  /// Retourne la liste des enfants qui ont complété la tâche aujourd'hui
  List<String> getChildrenCompletedToday() {
    if (!isDaily || dailyCompletions == null) return [];
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return dailyCompletions!.entries.where((entry) {
      final completionDate = entry.value;
      final completionDay = DateTime(completionDate.year, completionDate.month, completionDate.day);
      return completionDay == today;
    }).map((entry) => entry.key).toList();
  }
  
  /// Retourne la liste des enfants qui n'ont pas encore complété la tâche aujourd'hui
  List<String> getChildrenNotCompletedToday() {
    return childIds.where((childId) => !isCompletedTodayByChild(childId)).toList();
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    // Support ancien format avec childId unique
    List<String> childIds;
    if (map['childIds'] != null) {
      childIds = List<String>.from(map['childIds']);
    } else if (map['childId'] != null) {
      childIds = [map['childId'] as String];
    } else {
      childIds = [];
    }
    
    // Gérer les complétions quotidiennes par enfant
    Map<String, DateTime>? dailyCompletions;
    if (map['dailyCompletions'] != null) {
      dailyCompletions = {};
      final completionsMap = map['dailyCompletions'] as Map<String, dynamic>;
      completionsMap.forEach((childId, completionDate) {
        if (completionDate is String) {
          dailyCompletions![childId] = DateTime.parse(completionDate);
        } else if (completionDate is Timestamp) {
          dailyCompletions![childId] = completionDate.toDate();
        }
      });
    }

    return Task(
      id: map['id'] as String,
      parentId: map['parentId'] as String,
      childIds: childIds,
      title: map['title'] as String,
      description: map['description'] as String?,
      type: TaskType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TaskType.positive,
      ),
      stars: map['stars'] as int,
      isActive: map['isActive'] as bool? ?? true,
      isDaily: map['isDaily'] as bool? ?? false,
      lastCompletedAt: map['lastCompletedAt'] != null
          ? map['lastCompletedAt'] is String
              ? DateTime.parse(map['lastCompletedAt'] as String)
              : (map['lastCompletedAt'] as Timestamp).toDate()
          : null,
      dailyCompletions: dailyCompletions,
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
      'childIds': childIds,
      'title': title,
      'description': description,
      'type': type.name,
      'stars': stars,
      'isActive': isActive,
      'isDaily': isDaily,
      'lastCompletedAt': lastCompletedAt?.toIso8601String(),
      'dailyCompletions': dailyCompletions?.map((key, value) => MapEntry(key, value.toIso8601String())),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Task copyWith({
    String? id,
    String? parentId,
    List<String>? childIds,
    String? title,
    String? description,
    TaskType? type,
    int? stars,
    bool? isActive,
    bool? isDaily,
    DateTime? lastCompletedAt,
    Map<String, DateTime>? dailyCompletions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      childIds: childIds ?? this.childIds,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      stars: stars ?? this.stars,
      isActive: isActive ?? this.isActive,
      isDaily: isDaily ?? this.isDaily,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      dailyCompletions: dailyCompletions ?? this.dailyCompletions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  /// Marque la tâche comme complétée par un enfant spécifique aujourd'hui
  Task markCompletedByChild(String childId) {
    final now = DateTime.now();
    final updatedCompletions = Map<String, DateTime>.from(dailyCompletions ?? {});
    updatedCompletions[childId] = now;
    
    return copyWith(
      dailyCompletions: updatedCompletions,
      updatedAt: now,
    );
  }
}