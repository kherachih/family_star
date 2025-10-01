class SanctionApplied {
  final String? id;
  final String childId;
  final String sanctionId;
  final String sanctionName;
  final int starsCost;
  final String? duration;
  final DateTime appliedAt;
  final DateTime? endsAt;
  final bool isActive;

  SanctionApplied({
    this.id,
    required this.childId,
    required this.sanctionId,
    required this.sanctionName,
    required this.starsCost,
    this.duration,
    DateTime? appliedAt,
    this.endsAt,
    this.isActive = true,
  }) : appliedAt = appliedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'childId': childId,
      'sanctionId': sanctionId,
      'sanctionName': sanctionName,
      'starsCost': starsCost,
      'duration': duration,
      'appliedAt': appliedAt.toIso8601String(),
      'endsAt': endsAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory SanctionApplied.fromMap(Map<String, dynamic> map, String id) {
    return SanctionApplied(
      id: id,
      childId: map['childId'] ?? '',
      sanctionId: map['sanctionId'] ?? '',
      sanctionName: map['sanctionName'] ?? '',
      starsCost: map['starsCost'] ?? 0,
      duration: map['duration'],
      appliedAt: DateTime.parse(map['appliedAt']),
      endsAt: map['endsAt'] != null ? DateTime.parse(map['endsAt']) : null,
      isActive: map['isActive'] ?? true,
    );
  }
}
