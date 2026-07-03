import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../repositories/reports_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/responsive_layout.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  DateTime _selectedWeeklyDate = DateTime.now();
  DateTime _selectedMonthlyDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTime _getWeekStart(DateTime d) {
    return d.subtract(Duration(days: d.weekday - 1));
  }

  Future<void> _pickWeeklyDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedWeeklyDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedWeeklyDate = date);
    }
  }

  Future<void> _pickMonthlyDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedMonthlyDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedMonthlyDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeekly = _tabController.index == 0;
    final weekStart = _getWeekStart(_selectedWeeklyDate);
    final weekLabel = "Week of ${DateFormat('MMM dd, yyyy').format(weekStart)}";
    final monthLabel = DateFormat('MMMM yyyy').format(_selectedMonthlyDate);

    return Scaffold(
      body: AppView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppPageHeader(
              eyebrow: 'Reporting',
              title: 'Reports',
              subtitle:
                  'Switch between weekly and monthly rollups to review trends, totals, and employee-level details.',
              trailing: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => isWeekly ? _pickWeeklyDate(context) : _pickMonthlyDate(context),
                    icon: const Icon(Icons.calendar_month_rounded),
                    label: Text(isWeekly ? weekLabel : monthLabel),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      if (isWeekly) {
                        ref.invalidate(weeklyReportProvider(_selectedWeeklyDate));
                      } else {
                        ref.invalidate(monthlyReportProvider(_selectedMonthlyDate));
                      }
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: AppSurfaceCard(
                  padding: const EdgeInsets.all(6),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppTheme.ink,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    tabs: const [
                      Tab(text: 'Weekly'),
                      Tab(text: 'Monthly'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _WeeklyReportTab(selectedDate: _selectedWeeklyDate),
                  _MonthlyReportTab(selectedDate: _selectedMonthlyDate),
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
  final DateTime selectedDate;
  const _WeeklyReportTab({required this.selectedDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(weeklyReportProvider(selectedDate));
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
        onAction: () => ref.invalidate(weeklyReportProvider(selectedDate)),
      ),
    );
  }
}

class _MonthlyReportTab extends ConsumerWidget {
  final DateTime selectedDate;
  const _MonthlyReportTab({required this.selectedDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(monthlyReportProvider(selectedDate));
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
        onAction: () => ref.invalidate(monthlyReportProvider(selectedDate)),
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
    final summaryEntries = numericEntries.take(4).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summaryEntries.isNotEmpty)
            _ResponsiveWrap(
              minItemWidth: 220,
              spacing: 14,
              runSpacing: 14,
              children: summaryEntries.map((entry) {
                return _ReportStatTile(
                  title: _formatReportKey(entry.key),
                  value: _formatValue(entry.key, entry.value),
                  label: label,
                );
              }).toList(),
            ),
          if (summaryEntries.isNotEmpty) const SizedBox(height: 18),
          _ResponsiveWrap(
            minItemWidth: 360,
            spacing: 16,
            runSpacing: 16,
            children: [
              _ReportChartCard(entries: numericEntries, label: label),
              _ReportHighlightsCard(stats: stats, label: label),
            ],
          ),
          const SizedBox(height: 18),
          if (listEntries.isNotEmpty)
            AppSurfaceCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSectionHeader(
                    title: '$label details',
                    subtitle:
                        'Expanded employee and record lists from the current payload.',
                  ),
                  const SizedBox(height: 18),
                  ...listEntries.map((entry) {
                    final rawList = entry.value as List;
                    final items = rawList.expand((e) => e is List ? e : [e]).toList();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatReportKey(entry.key),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
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
                                
                                // Filter out metadata and complex maps/lists
                                final otherEntries = item.entries.where((field) => 
                                    field.key != 'employeeName' && 
                                    field.key != 'employeeId' &&
                                    field.value is! Map &&
                                    field.value is! List);
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: AppSurfaceCard(
                                    color: Colors.white,
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const CircleAvatar(
                                              backgroundColor: AppTheme.mist,
                                              child: Icon(Icons.person_rounded, color: AppTheme.darkGreenSidebar),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              title,
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.darkGreenSidebar,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Wrap(
                                          spacing: 12,
                                          runSpacing: 12,
                                          children: otherEntries.map((field) {
                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF8F3E8),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    _formatReportKey(field.key),
                                                    style: const TextStyle(
                                                      fontSize: 11.5,
                                                      color: AppTheme.mutedText,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    _formatValue(field.key, field.value),
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w800,
                                                      color: AppTheme.darkGreenSidebar,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: AppSurfaceCard(
                                  color: const Color(0xFFF8F3E8),
                                  padding: const EdgeInsets.all(14),
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
    final chartHeight = ResponsiveLayout.isMobile(context) ? 220.0 : 250.0;

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: '$label chart',
            subtitle: 'Quick comparison of the main numeric metrics.',
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: chartHeight,
            child: visible.isEmpty
                ? const Center(child: Text('No numeric report data available'))
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
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
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= visible.length) {
                                  return const SizedBox.shrink();
                              }
                              final formattedKey = _formatReportKey(visible[index].key);
                              final displayName = formattedKey.split(' ').first;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  displayName,
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
    final highlights = stats.entries
        .where((e) => e.value is! List && e.value is! Map)
        .take(6)
        .toList();

    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: '$label highlights',
            subtitle: 'Key values for the current reporting period.',
          ),
          const SizedBox(height: 16),
          Expanded(
            flex: 0,
            child: SingleChildScrollView(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = constraints.maxWidth < 560
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 12) / 2;

                  return Wrap(
                     spacing: 12,
                    runSpacing: 12,
                    children: highlights.map((entry) {
                      return SizedBox(
                        width: itemWidth,
                        child: AppSurfaceCard(
                          color: const Color(0xFFF8F3E8),
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatReportKey(entry.key),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontSize: 12.5,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatValue(entry.key, entry.value),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportStatTile extends StatelessWidget {
  final String title;
  final String value;
  final String label;

  const _ReportStatTile({
    required this.title,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      gradient: LinearGradient(
        colors: [
          Colors.white,
          AppTheme.sage.withValues(alpha: 0.35),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: AppTheme.primaryGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.ink,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.olive,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _ResponsiveWrap extends StatelessWidget {
  final List<Widget> children;
  final double minItemWidth;
  final double spacing;
  final double runSpacing;

  const _ResponsiveWrap({
    required this.children,
    required this.minItemWidth,
    this.spacing = 16,
    this.runSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final columns = availableWidth >= (minItemWidth * 2 + spacing) ? 2 : 1;
        final itemWidth =
            columns == 1 ? availableWidth : (availableWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children
              .map(
                (child) => SizedBox(
                  width: itemWidth,
                  child: child,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

String _formatReportKey(String key) {
  if (key.isEmpty) return '';
  final spaced = key
      .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
      .replaceAll('_', ' ')
      .trim();
  return spaced.split(' ').map((word) {
    if (word.isEmpty) return '';
    return word[0].toUpperCase() + word.substring(1);
  }).join(' ');
}

String _formatValue(String key, dynamic val) {
  if (val == null) return '—';
  final valStr = val.toString();
  
  final numVal = num.tryParse(valStr);
  
  if (key.toLowerCase().contains('percentage')) {
    if (numVal != null) {
      return '${numVal.toStringAsFixed(1)}%';
    }
    return '$valStr%';
  }
  
  if (key.toLowerCase().contains('pay') || 
      key.toLowerCase().contains('rate') || 
      key.toLowerCase().contains('bonus') || 
      key.toLowerCase().contains('deduction')) {
    if (numVal != null) {
      return '\$${numVal.toStringAsFixed(2)}';
    }
  }
  
  if (key.toLowerCase().contains('hours')) {
    if (numVal != null) {
      return '${numVal.toStringAsFixed(1)}h';
    }
  }

  if (key.toLowerCase().contains('date') || key.endsWith('At')) {
    final parsed = DateTime.tryParse(valStr);
    if (parsed != null) {
      return DateFormat('yyyy-MM-dd HH:mm').format(parsed);
    }
  }
  
  return valStr;
}
