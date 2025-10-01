class RewardExchange {
  final String? id;
  final String childId;
  final String rewardId;
  final String rewardName;
  final int starsCost;
  final DateTime exchangedAt;
  final bool isCompleted; // Si le parent a validé la récompense

  RewardExchange({
    this.id,
    required this.childId,
    required this.rewardId,
    required this.rewardName,
    required this.starsCost,
    DateTime? exchangedAt,
    this.isCompleted = false,
  }) : exchangedAt = exchangedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'childId': childId,
      'rewardId': rewardId,
      'rewardName': rewardName,
      'starsCost': starsCost,
      'exchangedAt': exchangedAt.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory RewardExchange.fromMap(Map<String, dynamic> map, String id) {
    return RewardExchange(
      id: id,
      childId: map['childId'] ?? '',
      rewardId: map['rewardId'] ?? '',
      rewardName: map['rewardName'] ?? '',
      starsCost: map['starsCost'] ?? 0,
      exchangedAt: DateTime.parse(map['exchangedAt']),
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}
