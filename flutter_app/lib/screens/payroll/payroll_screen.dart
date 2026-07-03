import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../models/payroll_record.dart';
import '../../repositories/payroll_repository.dart';
import '../../repositories/employee_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/responsive_layout.dart';
import 'payroll_data_source.dart';

class PayrollScreen extends ConsumerStatefulWidget {
  const PayrollScreen({super.key});

  @override
  ConsumerState<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends ConsumerState<PayrollScreen> {
  DateTime _selectedDate = DateTime.now();
  final _searchController = TextEditingController();
  String _statusFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickMonth(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _processPayroll(BuildContext context) async {
    try {
      await ref
          .read(payrollRepositoryProvider)
          .processAllPayroll(_selectedDate.month, _selectedDate.year);
      ref.invalidate(monthlyPayrollProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payroll calculated successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final payrollAsyncValue = ref.watch(monthlyPayrollProvider(_selectedDate));
    final currency = NumberFormat.currency(symbol: '\$');
    final monthLabel = DateFormat('MMMM yyyy').format(_selectedDate);

    return Scaffold(
      body: AppView(
        child: payrollAsyncValue.when(
          data: (records) {
            final query = _searchController.text.trim().toLowerCase();
            final filteredRecords = records.where((record) {
              final matchesQuery = query.isEmpty ||
                  record.employeeId.toString().contains(query) ||
                  record.status.toLowerCase().contains(query);
              final matchesStatus =
                  _statusFilter == 'All' || record.status == _statusFilter;
              return matchesQuery && matchesStatus;
            }).toList();

            final totalGross =
                records.fold<double>(0, (sum, record) => sum + record.grossPay);
            final totalNet =
                records.fold<double>(0, (sum, record) => sum + record.netPay);
            final pendingCount =
                records.where((record) => record.status != 'PAID').length;
            final avgNet = records.isEmpty ? 0 : totalNet / records.length;

            final payrollDataSource =
                PayrollDataSource(records: filteredRecords);

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppPageHeader(
                    eyebrow: 'Payroll',
                    title: 'Compensation operations',
                    subtitle:
                        'Review payroll output for $monthLabel, calculate current records, and track payout posture without touching processing rules.',
                    trailing: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _pickMonth(context),
                          icon: const Icon(Icons.calendar_month_rounded),
                          label: Text(monthLabel),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _processPayroll(context),
                          icon: const Icon(Icons.calculate_rounded),
                          label: const Text('Run payroll'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  GridView.count(
                    crossAxisCount: ResponsiveLayout.adaptiveColumns(
                      context,
                      mobile: 1,
                      tablet: 2,
                      desktop: 4,
                    ),
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: ResponsiveLayout.isMobile(context) ? 2.5 : 1.8,
                    children: [
                      AppMetricCard(
                        title: 'Monthly gross',
                        value: currency.format(totalGross),
                        caption:
                            'Total gross compensation processed this month',
                        icon: Icons.payments_rounded,
                        accentColor: AppTheme.primaryGreen,
                        progress: records.isEmpty ? 0 : 1,
                        trend: monthLabel.split(' ').first,
                      ),
                      AppMetricCard(
                        title: 'Monthly net',
                        value: currency.format(totalNet),
                        caption: 'Net payroll exposure after deductions',
                        icon: Icons.account_balance_wallet_rounded,
                        accentColor: AppTheme.olive,
                        progress: totalGross == 0
                            ? 0
                            : (totalNet / totalGross).clamp(0.0, 1.0),
                        trend: totalGross == 0
                            ? '0%'
                            : '${((totalNet / totalGross) * 100).round()}%',
                      ),
                      AppMetricCard(
                        title: 'Pending payroll',
                        value: '$pendingCount',
                        caption: 'Records not yet marked as paid',
                        icon: Icons.pending_actions_rounded,
                        accentColor: const Color(0xFFBF8A2A),
                        progress:
                            records.isEmpty ? 0 : pendingCount / records.length,
                        trend:
                            '${records.isEmpty ? 0 : ((pendingCount / records.length) * 100).round()}%',
                      ),
                      AppMetricCard(
                        title: 'Average net pay',
                        value: currency.format(avgNet),
                        caption: 'Average payout per employee record',
                        icon: Icons.query_stats_rounded,
                        accentColor: const Color(0xFF2E769B),
                        progress: avgNet == 0 ? 0 : 1,
                        trend: 'Benchmark',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  GridView.count(
                    crossAxisCount: ResponsiveLayout.adaptiveColumns(
                      context,
                      mobile: 1,
                      tablet: 1,
                      desktop: 2,
                    ),
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio:
                        ResponsiveLayout.isDesktop(context) ? 1.38 : 1.05,
                    children: [
                      _PayrollStatusCard(records: records),
                      _TopPayrollChart(records: records),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (records.isEmpty)
                    AppEmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'No payroll records for $monthLabel',
                      description:
                          'Run payroll for the selected month to generate compensation records for review.',
                      actionLabel: 'Run payroll',
                      onAction: () => _processPayroll(context),
                    )
                  else
                    AppTableContainer(
                      title: 'Payroll register',
                      subtitle:
                          'Search by employee ID or status, then review hours, compensation, and payout state in one place.',
                      toolbar: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: AppSearchField(
                                  controller: _searchController,
                                  hintText: 'Search employee IDs or statuses',
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: () => setState(() {
                                  _searchController.clear();
                                  _statusFilter = 'All';
                                }),
                                icon: const Icon(Icons.restart_alt_rounded),
                                label: const Text('Reset'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              children: [
                                AppFilterPill(
                                  label: 'All',
                                  selected: _statusFilter == 'All',
                                  onTap: () =>
                                      setState(() => _statusFilter = 'All'),
                                ),
                                AppFilterPill(
                                  label: 'PAID',
                                  selected: _statusFilter == 'PAID',
                                  onTap: () =>
                                      setState(() => _statusFilter = 'PAID'),
                                ),
                                AppFilterPill(
                                  label: 'PENDING',
                                  selected: _statusFilter == 'PENDING',
                                  onTap: () =>
                                      setState(() => _statusFilter = 'PENDING'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      child: filteredRecords.isEmpty
                          ? const AppEmptyState(
                              icon: Icons.search_off_rounded,
                              title: 'No payroll matches these filters',
                              description:
                                  'Try a broader search or switch the status chip to inspect more payroll records.',
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: SizedBox(
                                height: 560,
                                child: SfDataGrid(
                                  source: payrollDataSource,
                                  columnWidthMode: ColumnWidthMode.fill,
                                  allowSorting: true,
                                  allowFiltering: true,
                                  headerRowHeight: 58,
                                  rowHeight: 74,
                                  gridLinesVisibility: GridLinesVisibility.none,
                                  headerGridLinesVisibility:
                                      GridLinesVisibility.none,
                                  columns: <GridColumn>[
                                    _PayrollColumn(
                                        name: 'employeeId', title: 'Emp ID'),
                                    _PayrollColumn(
                                      name: 'regularHours',
                                      title: 'Reg. hours',
                                    ),
                                    _PayrollColumn(
                                      name: 'overtimeHours',
                                      title: 'OT hours',
                                    ),
                                    _PayrollColumn(
                                      name: 'grossPay',
                                      title: 'Gross pay',
                                    ),
                                    _PayrollColumn(
                                      name: 'netPay',
                                      title: 'Net pay',
                                    ),
                                    _PayrollColumn(
                                      name: 'status',
                                      title: 'Status',
                                      alignment: Alignment.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                ],
              ),
            );
          },
          loading: () => const SingleChildScrollView(
            child: Column(
              children: [
                AppSkeletonCard(height: 170),
                SizedBox(height: 24),
                AppSkeletonCard(height: 180),
                SizedBox(height: 24),
                AppSkeletonCard(height: 320),
              ],
            ),
          ),
          error: (error, stack) => AppEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Unable to load payroll',
            description: error.toString(),
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(monthlyPayrollProvider),
          ),
        ),
      ),
    );
  }
}

class _PayrollColumn extends GridColumn {
  _PayrollColumn({
    required String name,
    required String title,
    Alignment alignment = Alignment.centerLeft,
  }) : super(
          columnName: name,
          label: Container(
            alignment: alignment,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: const BoxDecoration(color: Color(0xFFF5EEDF)),
            child: Text(
              title,
              style: const TextStyle(
                color: AppTheme.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
}

class _PayrollStatusCard extends StatelessWidget {
  final List<PayrollRecord> records;

  const _PayrollStatusCard({required this.records});

  @override
  Widget build(BuildContext context) {
    final paid = records.where((record) => record.status == 'PAID').length;
    final pending = records.where((record) => record.status != 'PAID').length;
    final bonuses =
        records.fold<double>(0, (sum, record) => sum + record.bonuses);
    final deductions =
        records.fold<double>(0, (sum, record) => sum + record.deductions);
    final currency = NumberFormat.currency(symbol: '\$');

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Payroll posture',
            subtitle:
                'A snapshot of payout status, bonus load, and deduction impact.',
          ),
          const SizedBox(height: 24),
          AppKeyValueRow(label: 'Paid records', value: '$paid'),
          const Divider(),
          AppKeyValueRow(label: 'Pending records', value: '$pending'),
          const Divider(),
          AppKeyValueRow(label: 'Bonuses', value: currency.format(bonuses)),
          const Divider(),
          AppKeyValueRow(
            label: 'Deductions',
            value: currency.format(deductions),
          ),
        ],
      ),
    );
  }
}

class _TopPayrollChart extends ConsumerWidget {
  final List<PayrollRecord> records;

  const _TopPayrollChart({required this.records});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesProvider);
    final employees = employeesAsync.value ?? [];
    final employeeLookup = {
      for (final e in employees) e.id: e,
    };

    final top = [...records]..sort((a, b) => b.netPay.compareTo(a.netPay));
    final series = top.take(5).toList();

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Top payouts',
            subtitle: 'Highest net payroll values in the selected month.',
          ),
          const SizedBox(height: 24),
          if (series.isEmpty)
            const Expanded(
              child: Center(
                child: Text('No payroll values available yet'),
              ),
            )
          else
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: series
                          .map((record) => record.netPay)
                          .reduce((a, b) => a > b ? a : b) +
                      100,
                  minY: 0,
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
                          if (index < 0 || index >= series.length) {
                            return const SizedBox.shrink();
                          }
                          final empId = series[index].employeeId;
                          final name = employeeLookup[empId]?.name ?? 'E$empId';
                          final displayName = name.split(' ').first;

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
                  barGroups: List.generate(series.length, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: series[index].netPay,
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
