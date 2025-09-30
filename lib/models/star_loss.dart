import 'package:cloud_firestore/cloud_firestore.dart';

enum StarLossType {
  tantrum('Colère/Crise'),
  disobedience('Désobéissance'),
  badBehavior('Mauvais comportement'),
  refusalToCooperate('Refus de coopérer'),
  badHabit('Mauvaise habitude'),
  other('Autre');

  const StarLossType(this.displayName);
  final String displayName;
}

class StarLoss {
  final String id;
  final String childId;
  final StarLossType type;
  final String description;
  final int starsCost;
  final String reason;
  final DateTime createdAt;

  StarLoss({
    required this.id,
    required this.childId,
    required this.type,
    required this.description,
    required this.starsCost,
    required this.reason,
    required this.createdAt,
  });

  factory StarLoss.fromMap(Map<String, dynamic> map) {
    return StarLoss(
      id: map['id'] as String,
      childId: map['childId'] as String,
      type: StarLossType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => StarLossType.other,
      ),
      description: map['description'] as String,
      starsCost: map['starsCost'] as int,
      reason: map['reason'] as String,
      createdAt: map['createdAt'] is String
          ? DateTime.parse(map['createdAt'] as String)
          : (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'childId': childId,
      'type': type.name,
      'description': description,
      'starsCost': starsCost,
      'reason': reason,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  StarLoss copyWith({
    String? id,
    String? childId,
    StarLossType? type,
    String? description,
    int? starsCost,
    String? reason,
    DateTime? createdAt,
  }) {
    return StarLoss(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      type: type ?? this.type,
      description: description ?? this.description,
      starsCost: starsCost ?? this.starsCost,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}