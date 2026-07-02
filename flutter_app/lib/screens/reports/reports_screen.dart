import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repositories/reports_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_ui.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppPageHeader(
              eyebrow: 'Reporting',
              title: 'Performance and payroll reporting',
              subtitle:
                  'Switch between weekly and monthly views to review statistics, employee summaries, and operational rollups.',
              trailing: OutlinedButton.icon(
                onPressed: () {
                  ref.invalidate(currentWeeklyReportProvider);
                  ref.invalidate(currentMonthlyReportProvider);
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh reports'),
              ),
            ),
            const SizedBox(height: 24),
            AppSurfaceCard(
              padding: const EdgeInsets.all(10),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(18),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.ink,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.calendar_view_week_rounded),
                    text: 'Weekly',
                  ),
                  Tab(
                    icon: Icon(Icons.calendar_month_rounded),
                    text: 'Monthly',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _WeeklyReportTab(),
                  _MonthlyReportTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyReportTab extends ConsumerWidget {
  const _WeeklyReportTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(currentWeeklyReportProvider);
    return reportAsync.when(
      data: (data) => _ReportView(data: data, label: 'Weekly'),
      loading: () => const SingleChildScrollView(
        child: Column(
          children: [
            AppSkeletonCard(height: 180),
            SizedBox(height: 24),
            AppSkeletonCard(height: 340),
          ],
        ),
      ),
      error: (e, _) => AppEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Unable to load weekly report',
        description: e.toString(),
        actionLabel: 'Retry',
        onAction: () => ref.invalidate(currentWeeklyReportProvider),
      ),
    );
  }
}

class _MonthlyReportTab extends ConsumerWidget {
  const _MonthlyReportTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(currentMonthlyReportProvider);
    return reportAsync.when(
      data: (data) => _ReportView(data: data, label: 'Monthly'),
      loading: () => const SingleChildScrollView(
        child: Column(
          children: [
            AppSkeletonCard(height: 180),
            SizedBox(height: 24),
            AppSkeletonCard(height: 340),
          ],
        ),
      ),
      error: (e, _) => AppEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Unable to load monthly report',
        description: e.toString(),
        actionLabel: 'Retry',
        onAction: () => ref.invalidate(currentMonthlyReportProvider),
      ),
    );
  }
}

class _ReportView extends StatelessWidget {
  final Map<String, dynamic> data;
  final String label;

  const _ReportView({required this.data, required this.label});

  @override
  Widget build(BuildContext context) {
    final stats = data['statistics'] as Map<String, dynamic>? ?? data;
    final numericEntries = stats.entries
        .where((entry) => entry.value is num)
        .map((entry) => MapEntry(entry.key, (entry.value as num).toDouble()))
        .toList();
    final listEntries =
        stats.entries.where((entry) => entry.value is List).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: numericEntries.length >= 4
                ? 4
                : numericEntries.length.clamp(1, 4),
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.2,
            children: numericEntries.take(4).map((entry) {
              return AppMetricCard(
                title: _formatKey(entry.key),
                value: entry.value % 1 == 0
                    ? entry.value.toInt().toString()
                    : entry.value.toStringAsFixed(1),
                caption: '$label reporting statistic',
                icon: Icons.analytics_rounded,
                accentColor: AppTheme.primaryGreen,
                progress: 1,
                trend: label,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.35,
            children: [
              _ReportChartCard(entries: numericEntries, label: label),
              _ReportHighlightsCard(stats: stats, label: label),
            ],
          ),
          const SizedBox(height: 24),
          if (listEntries.isNotEmpty)
            AppSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSectionHeader(
                    title: '$label detail views',
                    subtitle:
                        'Expanded report lists and employee-level breakdowns surfaced from the current data payload.',
                  ),
                  const SizedBox(height: 24),
                  ...listEntries.map((entry) {
                    final items = entry.value as List;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatKey(entry.key),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          if (items.isEmpty)
                            const Text('No data available')
                          else
                            ...items.take(6).map((item) {
                              if (item is Map) {
                                final title =
                                    item['employeeName']?.toString() ??
                                        'Employee ${item['employeeId'] ?? ''}';
                                final subtitle = item.entries
                                    .where(
                                        (field) => field.key != 'employeeName')
                                    .take(3)
                                    .map((field) =>
                                        '${_formatKey(field.key)}: ${field.value}')
                                    .join(' • ');
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: AppSurfaceCard(
                                    color: const Color(0xFFF8F3E8),
                                    padding: const EdgeInsets.all(18),
                                    child: AppInfoTile(
                                      icon: Icons.description_outlined,
                                      title: title,
                                      subtitle: subtitle,
                                      trailing: const SizedBox.shrink(),
                                    ),
                                  ),
                                );
                              }
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: AppSurfaceCard(
                                  color: const Color(0xFFF8F3E8),
                                  padding: const EdgeInsets.all(18),
                                  child: Text(item.toString()),
                                ),
                              );
                            }),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .replaceAll('_', ' ')
        .trim();
  }
}

class _ReportChartCard extends StatelessWidget {
  final List<MapEntry<String, double>> entries;
  final String label;

  const _ReportChartCard({
    required this.entries,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final visible = entries.take(5).toList();

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: '$label statistics chart',
            subtitle:
                'Visual comparison of the strongest numeric metrics in this report.',
          ),
          const SizedBox(height: 24),
          Expanded(
            child: visible.isEmpty
                ? const Center(child: Text('No numeric report data available'))
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceBetween,
                      maxY: visible
                              .map((entry) => entry.value)
                              .reduce((a, b) => a > b ? a : b) +
                          2,
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => const FlLine(
                          color: AppTheme.mist,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= visible.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  visible[index].key.substring(
                                        0,
                                        visible[index].key.length > 6
                                            ? 6
                                            : visible[index].key.length,
                                      ),
                                  style: const TextStyle(
                                    color: AppTheme.mutedText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(visible.length, (index) {
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: visible[index].value,
                              width: 18,
                              borderRadius: BorderRadius.circular(8),
                              gradient: const LinearGradient(
                                colors: [
                                  AppTheme.primaryGreen,
                                  AppTheme.accentGold
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReportHighlightsCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  final String label;

  const _ReportHighlightsCard({
    required this.stats,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final highlights = stats.entries.take(6).toList();

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: '$label highlights',
            subtitle:
                'Readable key-value summary for the current reporting period.',
          ),
          const SizedBox(height: 24),
          ...highlights.map((entry) {
            return Column(
              children: [
                AppKeyValueRow(
                  label: entry.key,
                  value: entry.value.toString(),
                ),
                if (entry != highlights.last) const Divider(),
              ],
            );
          }),
        ],
      ),
    );
  }
}
