import 'duration_unit.dart';

class SanctionApplied {
  final String? id;
  final String childId;
  final String sanctionId;
  final String sanctionName;
  final int starsCost;
  final int? durationValue;
  final DurationUnit? durationUnit;
  final DateTime appliedAt;
  final DateTime? endsAt;
  final bool isActive;

  SanctionApplied({
    this.id,
    required this.childId,
    required this.sanctionId,
    required this.sanctionName,
    required this.starsCost,
    this.durationValue,
    this.durationUnit,
    DateTime? appliedAt,
    this.endsAt,
    this.isActive = true,
  }) : appliedAt = appliedAt ?? DateTime.now();

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

  // Calculer le temps restant avant la fin de la sanction
  Duration? get timeRemaining {
    if (!isActive || endsAt == null) return null;
    
    final now = DateTime.now();
    if (now.isAfter(endsAt!)) return Duration.zero;
    
    return endsAt!.difference(now);
  }

  // Vérifier si la sanction est expirée
  bool get isExpired {
    if (!isActive || endsAt == null) return false;
    return DateTime.now().isAfter(endsAt!);
  }

  // Formater le temps restant en texte lisible
  String? get timeRemainingText {
    final remaining = timeRemaining;
    if (remaining == null) return null;
    
    if (remaining.inDays > 0) {
      final days = remaining.inDays;
      final hours = remaining.inHours % 24;
      return '$days jour${days > 1 ? 's' : ''} $hours heure${hours > 1 ? 's' : ''}';
    } else if (remaining.inHours > 0) {
      final hours = remaining.inHours;
      final minutes = remaining.inMinutes % 60;
      return '$hours heure${hours > 1 ? 's' : ''} $minutes minute${minutes > 1 ? 's' : ''}';
    } else {
      final minutes = remaining.inMinutes;
      return '$minutes minute${minutes > 1 ? 's' : ''}';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'childId': childId,
      'sanctionId': sanctionId,
      'sanctionName': sanctionName,
      'starsCost': starsCost,
      'durationValue': durationValue,
      'durationUnit': durationUnit?.name,
      'appliedAt': appliedAt.toIso8601String(),
      'endsAt': endsAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory SanctionApplied.fromMap(Map<String, dynamic> map, String id) {
    DurationUnit? unit;
    if (map['durationUnit'] != null) {
      unit = DurationUnit.values.firstWhere(
        (e) => e.name == map['durationUnit'],
        orElse: () => DurationUnit.days,
      );
    }

    return SanctionApplied(
      id: id,
      childId: map['childId'] ?? '',
      sanctionId: map['sanctionId'] ?? '',
      sanctionName: map['sanctionName'] ?? '',
      starsCost: map['starsCost'] ?? 0,
      durationValue: map['durationValue'],
      durationUnit: unit,
      appliedAt: DateTime.parse(map['appliedAt']),
      endsAt: map['endsAt'] != null ? DateTime.parse(map['endsAt']) : null,
      isActive: map['isActive'] ?? true,
    );
  }
}
