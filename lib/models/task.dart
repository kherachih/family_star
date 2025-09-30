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
    required this.createdAt,
    required this.updatedAt,
  });

  // Compatibilité avec l'ancien système (childId unique)
  String get childId => childIds.isNotEmpty ? childIds.first : '';

  /// Retourne le changement d'étoiles (positif ou négatif)
  int get starChange => type == TaskType.positive ? stars : -stars;

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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}