class Sanction {
  final String? id;
  final String parentId;
  final String name;
  final String description;
  final int starsCost; // Nombre d'étoiles négatives nécessaires (valeur positive, ex: 10 pour -10 étoiles)
  final String? duration; // Ex: "1 semaine", "3 jours"
  final bool isActive;
  final DateTime createdAt;

  Sanction({
    this.id,
    required this.parentId,
    required this.name,
    required this.description,
    required this.starsCost,
    this.duration,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'parentId': parentId,
      'name': name,
      'description': description,
      'starsCost': starsCost,
      'duration': duration,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Sanction.fromMap(Map<String, dynamic> map, String id) {
    return Sanction(
      id: id,
      parentId: map['parentId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      starsCost: map['starsCost'] ?? 0,
      duration: map['duration'],
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Sanction copyWith({
    String? id,
    String? parentId,
    String? name,
    String? description,
    int? starsCost,
    String? duration,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Sanction(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      description: description ?? this.description,
      starsCost: starsCost ?? this.starsCost,
      duration: duration ?? this.duration,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
