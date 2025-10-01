class Reward {
  final String? id;
  final String parentId;
  final String name;
  final String description;
  final int starsCost; // Nombre d'étoiles positives nécessaires
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;

  Reward({
    this.id,
    required this.parentId,
    required this.name,
    required this.description,
    required this.starsCost,
    this.imageUrl,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'parentId': parentId,
      'name': name,
      'description': description,
      'starsCost': starsCost,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Reward.fromMap(Map<String, dynamic> map, String id) {
    return Reward(
      id: id,
      parentId: map['parentId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      starsCost: map['starsCost'] ?? 0,
      imageUrl: map['imageUrl'],
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Reward copyWith({
    String? id,
    String? parentId,
    String? name,
    String? description,
    int? starsCost,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Reward(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      description: description ?? this.description,
      starsCost: starsCost ?? this.starsCost,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
