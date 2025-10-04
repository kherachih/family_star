import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/child.dart';
import '../../models/history_item.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/history_item_widget.dart';

class HistoryScreen extends StatefulWidget {
  final Child child;

  const HistoryScreen({
    super.key,
    required this.child,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryItem> _historyItems = [];
  bool _isLoading = false;
  bool _hasMoreHistory = true;
  final int _pageSize = 15;
  final ScrollController _scrollController = ScrollController();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
        if (_hasMoreHistory && !_isLoading) {
          _loadHistory();
        }
      }
    });
  }

  Future<void> _loadHistory({bool refresh = false}) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      if (refresh) {
        _historyItems.clear();
        _hasMoreHistory = true;
      }
    });

    try {
      final newItems = await _firestoreService.getHistoryByChildId(
        widget.child.id,
        limit: _pageSize,
        startAfter: _historyItems.isNotEmpty ? _historyItems.last.timestamp : null,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _historyItems = newItems;
          } else {
            _historyItems.addAll(newItems);
          }
          _hasMoreHistory = newItems.length == _pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement de l\'historique: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historique de ${widget.child.name}'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _loadHistory(refresh: true),
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadHistory(refresh: true),
        child: _historyItems.isEmpty
            ? _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _buildEmptyState()
            : Column(
                children: [
                  // En-tête avec statistiques
                  _buildStatsHeader(),
                  
                  // Liste des éléments d'historique
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _historyItems.length + (_hasMoreHistory ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _historyItems.length) {
                          return _isLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : const SizedBox.shrink();
                        }
                        
                        return HistoryItemWidget(
                          historyItem: _historyItems[index],
                        );
                      },
                    ),
                  ),
                  
                  // Message de fin d'historique
                  if (!_hasMoreHistory && _historyItems.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: const Center(
                        child: Text(
                          'Fin de l\'historique',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun historique disponible',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les activités de ${widget.child.name} apparaîtront ici',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _loadHistory(refresh: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Actualiser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    int totalGains = 0;
    int totalLosses = 0;
    int taskCount = 0;
    int rewardCount = 0;
    int sanctionCount = 0;

    for (final item in _historyItems) {
      if (item.isGain) {
        totalGains += item.starChange;
      } else {
        totalLosses += item.starChange.abs();
      }

      switch (item.type) {
        case HistoryItemType.task:
          taskCount++;
          break;
        case HistoryItemType.rewardExchange:
          rewardCount++;
          break;
        case HistoryItemType.sanctionApplied:
          sanctionCount++;
          break;
        case HistoryItemType.starLoss:
          // Les pertes d'étoiles sont comptées dans les pertes totales
          break;
      }
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6A5ACD), // Bleu violet
            Color(0xFF483D8B), // Bleu foncé
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Statistiques',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Gains',
                '+$totalGains ⭐',
                AppColors.starPositive,
              ),
              _buildStatItem(
                'Pertes',
                '-$totalLosses ⭐',
                AppColors.starNegative,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Tâches',
                '$taskCount',
                Colors.blue,
              ),
              _buildStatItem(
                'Récompenses',
                '$rewardCount',
                Colors.orange,
              ),
              _buildStatItem(
                'Sanctions',
                '$sanctionCount',
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}