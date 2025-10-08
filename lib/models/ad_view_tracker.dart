class AdViewTracker {
  final String userId;
  final DateTime date;
  final int viewCount;

  AdViewTracker({
    required this.userId,
    required this.date,
    required this.viewCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': date.toIso8601String(),
      'viewCount': viewCount,
    };
  }

  factory AdViewTracker.fromMap(Map<String, dynamic> map) {
    return AdViewTracker(
      userId: map['userId'] ?? '',
      date: DateTime.parse(map['date']),
      viewCount: map['viewCount'] ?? 0,
    );
  }

  // Pour la compatibilité avec le code existant
  factory AdViewTracker.fromDocument(Map<String, dynamic> data) {
    return AdViewTracker.fromMap(data);
  }

  AdViewTracker copyWith({
    String? userId,
    DateTime? date,
    int? viewCount,
  }) {
    return AdViewTracker(
      userId: userId ?? this.userId,
      date: date ?? this.date,
      viewCount: viewCount ?? this.viewCount,
    );
  }
}