import 'duration_unit.dart';

class Sanction {
  final String? id;
  final String parentId;
  final String name;
  final String description;
  final int starsCost; // Nombre d'étoiles négatives nécessaires (valeur positive, ex: 10 pour -10 étoiles)
  final int? durationValue; // Valeur numérique de la durée (ex: 1, 3, 7)
  final DurationUnit? durationUnit; // Unité de durée (heures, jours, semaines)
  final bool isActive;
  final DateTime createdAt;

  Sanction({
    this.id,
    required this.parentId,
    required this.name,
    required this.description,
    required this.starsCost,
    this.durationValue,
    this.durationUnit,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Getter pour formater la durée en texte lisible
  String? get durationText {
    if (durationValue == null || durationUnit == null) return null;
    
    String unitText;
    switch (durationUnit!) {
      case DurationUnit.hours:
        unitText = durationValue == 1 ? 'heure' : 'heures';
        break;
      case DurationUnit.days:
        unitText = durationValue == 1 ? 'jour' : 'jours';
        break;
      case DurationUnit.weeks:
        unitText = durationValue == 1 ? 'semaine' : 'semaines';
        break;
    }
    
    return '$durationValue $unitText';
  }

  // Calculer la durée en heures
  int? get durationInHours {
    if (durationValue == null || durationUnit == null) return null;
    
    switch (durationUnit!) {
      case DurationUnit.hours:
        return durationValue;
      case DurationUnit.days:
        return durationValue! * 24;
      case DurationUnit.weeks:
        return durationValue! * 24 * 7;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'parentId': parentId,
      'name': name,
      'description': description,
      'starsCost': starsCost,
      'durationValue': durationValue,
      'durationUnit': durationUnit?.name,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Sanction.fromMap(Map<String, dynamic> map, String id) {
    DurationUnit? unit;
    if (map['durationUnit'] != null) {
      unit = DurationUnit.values.firstWhere(
        (e) => e.name == map['durationUnit'],
        orElse: () => DurationUnit.days,
      );
    }

    return Sanction(
      id: id,
      parentId: map['parentId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      starsCost: map['starsCost'] ?? 0,
      durationValue: map['durationValue'],
      durationUnit: unit,
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
    int? durationValue,
    DurationUnit? durationUnit,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Sanction(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      description: description ?? this.description,
      starsCost: starsCost ?? this.starsCost,
      durationValue: durationValue ?? this.durationValue,
      durationUnit: durationUnit ?? this.durationUnit,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
