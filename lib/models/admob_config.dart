import 'package:cloud_firestore/cloud_firestore.dart';

class AdMobConfig {
  final String interstitialAdUnitId;
  final int maxAdsPerDay;
  final DateTime updatedAt;

  AdMobConfig({
    required this.interstitialAdUnitId,
    required this.maxAdsPerDay,
    required this.updatedAt,
  });

  // Créer une instance depuis un document Firestore
  factory AdMobConfig.fromMap(Map<String, dynamic> data) {
    return AdMobConfig(
      interstitialAdUnitId: data['interstitialAdUnitId'] ?? '',
      maxAdsPerDay: data['maxAdsPerDay'] ?? 4,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'interstitialAdUnitId': interstitialAdUnitId,
      'maxAdsPerDay': maxAdsPerDay,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Créer une copie avec des valeurs modifiées
  AdMobConfig copyWith({
    String? interstitialAdUnitId,
    int? maxAdsPerDay,
    DateTime? updatedAt,
  }) {
    return AdMobConfig(
      interstitialAdUnitId: interstitialAdUnitId ?? this.interstitialAdUnitId,
      maxAdsPerDay: maxAdsPerDay ?? this.maxAdsPerDay,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AdMobConfig(interstitialAdUnitId: $interstitialAdUnitId, maxAdsPerDay: $maxAdsPerDay, updatedAt: $updatedAt)';
  }
}