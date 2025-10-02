import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/child.dart';
import '../../models/sanction_applied.dart';
import '../../providers/rewards_provider.dart';

class SanctionsAppliedScreen extends StatefulWidget {
  final Child child;

  const SanctionsAppliedScreen({super.key, required this.child});

  @override
  State<SanctionsAppliedScreen> createState() => _SanctionsAppliedScreenState();
}

class _SanctionsAppliedScreenState extends State<SanctionsAppliedScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadSanctionsApplied();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _loadSanctionsApplied() {
    final rewardsProvider = Provider.of<RewardsProvider>(context, listen: false);
    rewardsProvider.loadSanctionsApplied(widget.child.id);
  }

  void _startTimer() {
    // Mettre à jour l'interface toutes les minutes pour le compte à rebours
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RewardsProvider>(
      builder: (context, rewardsProvider, child) {
        final activeSanctions = rewardsProvider.sanctionsApplied
            .where((s) => s.isActive && !s.isExpired)
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: Text('Sanctions actives - ${widget.child.name}'),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          body: activeSanctions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 80, color: Colors.green[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune sanction active',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.child.name} n\'a aucune sanction en cours',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    _loadSanctionsApplied();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: activeSanctions.length,
                    itemBuilder: (context, index) {
                      final sanction = activeSanctions[index];
                      return _buildSanctionCard(sanction, rewardsProvider);
                    },
                  ),
                ),
        );
      },
    );
  }

  Widget _buildSanctionCard(SanctionApplied sanction, RewardsProvider rewardsProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: sanction.timeRemaining != null && sanction.timeRemaining!.inHours < 24
              ? Colors.red
              : Colors.orange,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // En-tête avec nom de la sanction
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.block, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    sanction.sanctionName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '-${sanction.starsCost} ⭐',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenu avec compte à rebours
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Durée de la sanction
                if (sanction.durationText != null)
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Durée: ${sanction.durationText}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 12),

                // Date d'application
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Appliquée le: ${_formatDate(sanction.appliedAt)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Compte à rebours
                if (sanction.timeRemaining != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getTimeRemainingColor(sanction.timeRemaining!).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getTimeRemainingColor(sanction.timeRemaining!),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Temps restant:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sanction.timeRemainingText ?? 'Terminé',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getTimeRemainingColor(sanction.timeRemaining!),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Bouton pour terminer la sanction
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmEndSanction(sanction, rewardsProvider),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Terminer la sanction'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTimeRemainingColor(Duration remaining) {
    if (remaining.inHours < 1) {
      return Colors.red;
    } else if (remaining.inHours < 24) {
      return Colors.orange;
    } else {
      return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _confirmEndSanction(SanctionApplied sanction, RewardsProvider rewardsProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminer la sanction'),
        content: Text(
          'Voulez-vous vraiment terminer la sanction "${sanction.sanctionName}" avant la fin prévue ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _endSanction(sanction, rewardsProvider);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }

  Future<void> _endSanction(SanctionApplied sanction, RewardsProvider rewardsProvider) async {
    try {
      await rewardsProvider.deactivateSanction(sanction.id!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sanction terminée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        _loadSanctionsApplied();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}