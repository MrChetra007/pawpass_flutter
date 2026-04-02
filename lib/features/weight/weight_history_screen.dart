import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme_data.dart';
import '../../data/models/weight_log_model.dart';
import '../../shared/providers/weight_provider.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/paw_card.dart';
import '../../shared/widgets/skeleton_loader.dart';
import 'add_weight_bottom_sheet.dart';

class WeightHistoryScreen extends ConsumerStatefulWidget {
  final String petId;
  final String petName;

  const WeightHistoryScreen({
    super.key,
    required this.petId,
    required this.petName,
  });

  @override
  ConsumerState<WeightHistoryScreen> createState() => _WeightHistoryScreenState();
}

class _WeightHistoryScreenState extends ConsumerState<WeightHistoryScreen> {
  bool _showChart = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(weightNotifierProvider.notifier).loadWeightLogs(petId: widget.petId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(weightNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.petName}\'s Weight'),
        actions: [
          IconButton(
            icon: Icon(_showChart ? Icons.list : Icons.show_chart),
            onPressed: () => setState(() => _showChart = !_showChart),
          ),
        ],
      ),
      body: logsAsync.when(
        loading: () => _buildLoadingState(),
        error: (e, _) => _buildErrorState(e.toString()),
        data: (logs) {
          final petLogs = logs.where((l) => l.petId == widget.petId).toList();
          
          if (petLogs.isEmpty) {
            return EmptyState(
              icon: Icons.monitor_weight,
              title: 'No weight records',
              subtitle: 'Start tracking your pet\'s weight over time',
              actionLabel: 'Log Weight',
              onAction: () => _showAddWeight(),
            );
          }

          return _showChart
              ? _buildChartView(petLogs)
              : _buildListView(petLogs);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddWeight(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: SkeletonCard(),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.read(weightNotifierProvider.notifier).loadWeightLogs(petId: widget.petId),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildChartView(List<WeightLog> logs) {
    final theme = Theme.of(context);
    final sortedLogs = List<WeightLog>.from(logs)..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    
    if (sortedLogs.length < 2) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Add at least 2 weight records to see the chart',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final spots = sortedLogs.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weightKg);
    }).toList();

    final minWeight = sortedLogs.map((l) => l.weightKg).reduce((a, b) => a < b ? a : b);
    final maxWeight = sortedLogs.map((l) => l.weightKg).reduce((a, b) => a > b ? a : b);
    final padding = (maxWeight - minWeight) * 0.1;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          PawCard(
            child: SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.dividerTheme.color ?? Colors.grey.withValues(alpha: 0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toStringAsFixed(1)} kg',
                            style: theme.textTheme.labelMedium,
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= sortedLogs.length) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('MMM d').format(sortedLogs[index].recordedAt),
                              style: theme.textTheme.labelMedium,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: minWeight - padding,
                  maxY: maxWeight + padding,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: theme.colorScheme.primary,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSummaryCard(sortedLogs),
          const SizedBox(height: 16),
          Expanded(child: _buildListView(logs)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(List<WeightLog> logs) {
    final theme = Theme.of(context);
    final sortedLogs = List<WeightLog>.from(logs)..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    
    final latest = sortedLogs.first;
    final first = sortedLogs.last;
    final weightChange = latest.weightKg - first.weightKg;

    return PawCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text('Current', style: theme.textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(
                '${latest.weightKg.toStringAsFixed(1)} kg',
                style: theme.textTheme.titleLarge,
              ),
              Text(
                DateFormat('MMM d').format(latest.recordedAt),
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
          Container(width: 1, height: 50, color: theme.dividerTheme.color),
          Column(
            children: [
              Text('Change', style: theme.textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(
                '${weightChange >= 0 ? '+' : ''}${weightChange.toStringAsFixed(1)} kg',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: weightChange >= 0 ? PawThemeData.successGreen : PawThemeData.alertRed,
                ),
              ),
              Text(
                'since ${DateFormat('MMM d').format(first.recordedAt)}',
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
          Container(width: 1, height: 50, color: theme.dividerTheme.color),
          Column(
            children: [
              Text('Records', style: theme.textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(
                '${sortedLogs.length}',
                style: theme.textTheme.titleLarge,
              ),
              Text(
                'total',
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<WeightLog> logs) {
    final sortedLogs = List<WeightLog>.from(logs)..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedLogs.length,
      itemBuilder: (context, index) {
        final log = sortedLogs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildWeightCard(log),
        );
      },
    );
  }

  Widget _buildWeightCard(WeightLog log) {
    final theme = Theme.of(context);

    return PawCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.monitor_weight,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${log.weightKg.toStringAsFixed(1)} kg',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMMM d, yyyy').format(log.recordedAt),
                  style: theme.textTheme.labelMedium,
                ),
                if (log.notes != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    log.notes!,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showDeleteConfirmation(log),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(WeightLog log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Weight Record?'),
        content: Text(
          'Delete the weight record of ${log.weightKg} kg from ${DateFormat('MMM d, yyyy').format(log.recordedAt)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(weightNotifierProvider.notifier).deleteWeightLog(log.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddWeight() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddWeightBottomSheet(petId: widget.petId),
    );
  }
}
