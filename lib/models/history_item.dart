import 'package:cloud_firestore/cloud_firestore.dart';
import 'task.dart';
import 'star_loss.dart';
import 'reward_exchange.dart';
import 'sanction_applied.dart';

enum HistoryItemType {
  task('Tâche'),
  starLoss('Perte d\'étoiles'),
  rewardExchange('Récompense'),
  sanctionApplied('Sanction');

  const HistoryItemType(this.displayName);
  final String displayName;
}

class HistoryItem {
  final String id;
  final HistoryItemType type;
  final DateTime timestamp;
  final String title;
  final String? description;
  final int starChange; // Positif pour gain, négatif pour perte
  final Map<String, dynamic> data; // Données originales pour référence

  HistoryItem({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.title,
    this.description,
    required this.starChange,
    required this.data,
  });

  // Factory pour créer un HistoryItem à partir d'une tâche
  factory HistoryItem.fromTask(Task task) {
    return HistoryItem(
      id: task.id,
      type: HistoryItemType.task,
      timestamp: task.createdAt,
      title: task.title,
      description: task.description,
      starChange: task.starChange,
      data: task.toMap(),
    );
  }

  // Factory pour créer un HistoryItem à partir d'une perte d'étoiles
  factory HistoryItem.fromStarLoss(StarLoss starLoss) {
    return HistoryItem(
      id: starLoss.id,
      type: HistoryItemType.starLoss,
      timestamp: starLoss.createdAt,
      title: starLoss.type.displayName,
      description: starLoss.reason,
      starChange: -starLoss.starsCost,
      data: starLoss.toMap(),
    );
  }

  // Factory pour créer un HistoryItem à partir d'un échange de récompense
  factory HistoryItem.fromRewardExchange(RewardExchange exchange) {
    return HistoryItem(
      id: exchange.id ?? '',
      type: HistoryItemType.rewardExchange,
      timestamp: exchange.exchangedAt,
      title: exchange.rewardName,
      description: 'Récompense échangée',
      starChange: -exchange.starsCost,
      data: exchange.toMap(),
    );
  }

  // Factory pour créer un HistoryItem à partir d'une sanction appliquée
  factory HistoryItem.fromSanctionApplied(SanctionApplied sanction) {
    return HistoryItem(
      id: sanction.id ?? '',
      type: HistoryItemType.sanctionApplied,
      timestamp: sanction.appliedAt,
      title: sanction.sanctionName,
      description: sanction.durationText != null 
          ? 'Durée: ${sanction.durationText}' 
          : 'Sanction appliquée',
      starChange: sanction.starsCost, // Positif car ça ajoute des étoiles (réduit le négatif)
      data: sanction.toMap(),
    );
  }

  // Méthode pour déterminer si c'est un gain ou une perte
  bool get isGain => starChange > 0;
  bool get isLoss => starChange < 0;

  // Méthode pour obtenir une représentation textuelle du changement d'étoiles
  String get starChangeText {
    if (starChange == 0) return '0 ⭐';
    final sign = isGain ? '+' : '';
    return '$sign$starChange ⭐';
  }

  // Méthode pour obtenir la couleur en fonction du type d'élément
  String get colorType {
    switch (type) {
      case HistoryItemType.task:
        return isGain ? 'green' : 'red';
      case HistoryItemType.starLoss:
        return 'red';
      case HistoryItemType.rewardExchange:
        return 'orange';
      case HistoryItemType.sanctionApplied:
        return 'purple';
    }
  }

  // Méthode pour formater la date
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return "À l'instant";
        }
        return "Il y a ${difference.inMinutes} min";
      }
      return "Il y a ${difference.inHours}h";
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}