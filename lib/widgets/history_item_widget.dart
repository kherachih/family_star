import 'package:flutter/material.dart';
import '../models/history_item.dart';
import '../utils/app_colors.dart';

class HistoryItemWidget extends StatelessWidget {
  final HistoryItem historyItem;

  const HistoryItemWidget({
    super.key,
    required this.historyItem,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getBackgroundColor().withOpacity(0.05),
              _getBackgroundColor().withOpacity(0.02),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icône et cercle de couleur
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getBackgroundColor().withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    _getIcon(),
                    color: _getBackgroundColor(),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Contenu principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre et type
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            historyItem.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getBackgroundColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            historyItem.type.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getBackgroundColor(),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Description
                    if (historyItem.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        historyItem.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    // Date et changement d'étoiles
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          historyItem.formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: historyItem.isGain
                                ? AppColors.starPositive.withOpacity(0.1)
                                : AppColors.starNegative.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            historyItem.starChangeText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: historyItem.isGain
                                  ? AppColors.starPositive
                                  : AppColors.starNegative,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (historyItem.type) {
      case HistoryItemType.task:
        return historyItem.isGain ? AppColors.taskPositive : AppColors.taskNegative;
      case HistoryItemType.starLoss:
        return AppColors.taskNegative;
      case HistoryItemType.rewardExchange:
        return Colors.orange;
      case HistoryItemType.sanctionApplied:
        return Colors.purple;
    }
  }

  IconData _getIcon() {
    switch (historyItem.type) {
      case HistoryItemType.task:
        return historyItem.isGain ? Icons.add_circle : Icons.remove_circle;
      case HistoryItemType.starLoss:
        return Icons.star_border;
      case HistoryItemType.rewardExchange:
        return Icons.card_giftcard;
      case HistoryItemType.sanctionApplied:
        return Icons.block;
    }
  }
}