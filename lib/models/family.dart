import 'package:cloud_firestore/cloud_firestore.dart';

class Family {
  final String id;
  final String name;
  final List<String> parentIds;
  final List<String> childIds;
  final String createdBy; // ID du parent qui a créé la famille
  final DateTime createdAt;
  final DateTime updatedAt;

  Family({
    required this.id,
    required this.name,
    required this.parentIds,
    required this.childIds,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Family.fromMap(Map<String, dynamic> map) {
    return Family(
      id: map['id'] as String,
      name: map['name'] as String,
      parentIds: List<String>.from(map['parentIds'] ?? []),
      childIds: List<String>.from(map['childIds'] ?? []),
      createdBy: map['createdBy'] as String,
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
      'name': name,
      'parentIds': parentIds,
      'childIds': childIds,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Family copyWith({
    String? id,
    String? name,
    List<String>? parentIds,
    List<String>? childIds,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Family(
      id: id ?? this.id,
      name: name ?? this.name,
      parentIds: parentIds ?? this.parentIds,
      childIds: childIds ?? this.childIds,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Vérifie si un parent fait partie de cette famille
  bool hasParent(String parentId) {
    return parentIds.contains(parentId);
  }

  /// Ajoute un parent à la famille
  Family addParent(String parentId) {
    if (parentIds.contains(parentId)) return this;
    
    final newParentIds = List<String>.from(parentIds)..add(parentId);
    return copyWith(
      parentIds: newParentIds,
      updatedAt: DateTime.now(),
    );
  }

  /// Retire un parent de la famille
  Family removeParent(String parentId) {
    if (!parentIds.contains(parentId)) return this;
    
    final newParentIds = List<String>.from(parentIds)..remove(parentId);
    return copyWith(
      parentIds: newParentIds,
      updatedAt: DateTime.now(),
    );
  }

  /// Ajoute un enfant à la famille
  Family addChild(String childId) {
    if (childIds.contains(childId)) return this;
    
    final newChildIds = List<String>.from(childIds)..add(childId);
    return copyWith(
      childIds: newChildIds,
      updatedAt: DateTime.now(),
    );
  }

  /// Retire un enfant de la famille
  Family removeChild(String childId) {
    if (!childIds.contains(childId)) return this;
    
    final newChildIds = List<String>.from(childIds)..remove(childId);
    return copyWith(
      childIds: newChildIds,
      updatedAt: DateTime.now(),
    );
  }
}