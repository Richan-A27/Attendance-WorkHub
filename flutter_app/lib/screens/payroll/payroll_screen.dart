import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../models/pay_period.dart';
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
  PayPeriod? _selectedPeriod;
  String _calculationMode = 'INCLUDE_BREAKS';
  final _searchController = TextEditingController();
  String _statusFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Color _periodStatusColor(String status) {
    switch (status) {
      case 'PAID':
        return AppTheme.primaryGreen;
      case 'FINALIZED':
        return const Color(0xFF2E769B);
      case 'PROCESSING':
        return const Color(0xFFBF8A2A);
      default:
        return AppTheme.mutedText;
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _generatePayroll(BuildContext context) async {
    if (_selectedPeriod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pay period first')),
      );
      return;
    }
    try {
      await ref.read(payrollRepositoryProvider).generatePayroll(
            payPeriodId: _selectedPeriod!.id,
            calculationMode: _calculationMode,
          );
      // Refresh the period payroll data
      ref.invalidate(periodPayrollProvider(_selectedPeriod!.id));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Payroll generated (${_calculationMode == 'INCLUDE_BREAKS' ? 'Including' : 'Excluding'} breaks)'),
          ),
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

  Future<void> _createPayPeriod(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => _CreatePayPeriodDialog(
        onCreated: (period) {
          ref.invalidate(openPayPeriodsProvider);
          ref.invalidate(allPayPeriodsProvider);
          setState(() => _selectedPeriod = period);
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final openPeriodsAsync = ref.watch(openPayPeriodsProvider);
    final currency = NumberFormat.currency(symbol: '₹');

    // Load payroll records only when a period is selected
    final payrollAsync = _selectedPeriod != null
        ? ref.watch(periodPayrollProvider(_selectedPeriod!.id))
        : const AsyncValue<List<PayrollRecord>>.data([]);

    return Scaffold(
      body: AppView(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Page Header ──────────────────────────────────────────────
              AppPageHeader(
                eyebrow: 'Payroll',
                title: 'Compensation operations',
                subtitle:
                    'Select a pay period, choose how breaks are calculated, then generate payroll records for review.',
                trailing: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    // Create Pay Period button
                    OutlinedButton.icon(
                      onPressed: () => _createPayPeriod(context),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('New period'),
                    ),
                    // Generate payroll button
                    ElevatedButton.icon(
                      onPressed: _selectedPeriod != null
                          ? () => _generatePayroll(context)
                          : null,
                      icon: const Icon(Icons.calculate_rounded),
                      label: const Text('Run payroll'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Pay Period Selector + Mode Toggle ────────────────────────
              _PayPeriodControls(
                openPeriodsAsync: openPeriodsAsync,
                selectedPeriod: _selectedPeriod,
                calculationMode: _calculationMode,
                periodStatusColor: _periodStatusColor,
                onPeriodChanged: (p) => setState(() {
                  _selectedPeriod = p;
                  _searchController.clear();
                  _statusFilter = 'All';
                }),
                onModeChanged: (m) => setState(() => _calculationMode = m),
              ),
              const SizedBox(height: 24),

              // ── Metric Cards ─────────────────────────────────────────────
              payrollAsync.when(
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

                  final totalGross = records.fold<double>(
                      0, (sum, r) => sum + r.grossPay);
                  final totalNet =
                      records.fold<double>(0, (sum, r) => sum + r.netPay);
                  final totalPaidHours =
                      records.fold<double>(0, (sum, r) => sum + r.paidHours);
                  final totalOTHours =
                      records.fold<double>(0, (sum, r) => sum + r.overtimeHours);
                  final pendingCount =
                      records.where((r) => r.status != 'PAID').length;

                  final payrollDataSource =
                      PayrollDataSource(records: filteredRecords);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Metric cards grid
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
                        childAspectRatio:
                            ResponsiveLayout.isMobile(context) ? 2.5 : 1.8,
                        children: [
                          AppMetricCard(
                            title: 'Gross pay',
                            value: currency.format(totalGross),
                            caption: 'Total gross compensation for this period',
                            icon: Icons.payments_rounded,
                            accentColor: AppTheme.primaryGreen,
                            progress: records.isEmpty ? 0 : 1,
                            trend: _selectedPeriod?.name ?? '',
                          ),
                          AppMetricCard(
                            title: 'Net pay',
                            value: currency.format(totalNet),
                            caption: 'Net payroll after deductions',
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
                            title: 'Paid hours',
                            value: '${totalPaidHours.toStringAsFixed(1)}h',
                            caption:
                                _calculationMode == 'INCLUDE_BREAKS'
                                    ? 'Total hours (breaks included)'
                                    : 'Working hours (breaks excluded)',
                            icon: Icons.timer_rounded,
                            accentColor: const Color(0xFF2E769B),
                            progress: records.isEmpty ? 0 : 1,
                            trend: _calculationMode == 'INCLUDE_BREAKS'
                                ? 'Incl. Breaks'
                                : 'Excl. Breaks',
                          ),
                          AppMetricCard(
                            title: 'Overtime hours',
                            value: '${totalOTHours.toStringAsFixed(1)}h',
                            caption: 'Total overtime across all employees',
                            icon: Icons.more_time_rounded,
                            accentColor: const Color(0xFFBF8A2A),
                            progress: records.isEmpty
                                ? 0
                                : pendingCount / records.length,
                            trend: '$pendingCount pending',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Charts row
                      if (records.isNotEmpty) ...[
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
                      ],

                      // Payroll table
                      if (records.isEmpty)
                        AppEmptyState(
                          icon: Icons.account_balance_wallet_outlined,
                          title: _selectedPeriod == null
                              ? 'No pay period selected'
                              : 'No payroll records for ${_selectedPeriod!.name}',
                          description: _selectedPeriod == null
                              ? 'Create or select a pay period, then click Run payroll to generate compensation records.'
                              : 'Click Run payroll to generate compensation records for this period.',
                          actionLabel:
                              _selectedPeriod == null ? 'New period' : 'Run payroll',
                          onAction: _selectedPeriod == null
                              ? () => _createPayPeriod(context)
                              : () => _generatePayroll(context),
                        )
                      else
                        AppTableContainer(
                          title: 'Payroll register',
                          subtitle:
                              'Search by employee ID or status. Paid Hours reflects the selected calculation mode.',
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
                                      onTap: () => setState(
                                          () => _statusFilter = 'PENDING'),
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
                                      'Try a broader search or switch the status chip.',
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
                                      gridLinesVisibility:
                                          GridLinesVisibility.none,
                                      headerGridLinesVisibility:
                                          GridLinesVisibility.none,
                                      columns: <GridColumn>[
                                        _PayrollColumn(
                                            name: 'employeeId',
                                            title: 'Emp ID'),
                                        _PayrollColumn(
                                          name: 'paidHours',
                                          title: 'Paid hrs',
                                        ),
                                        _PayrollColumn(
                                          name: 'regularHours',
                                          title: 'Reg. hrs',
                                        ),
                                        _PayrollColumn(
                                          name: 'overtimeHours',
                                          title: 'OT hrs',
                                        ),
                                        _PayrollColumn(
                                          name: 'breakHours',
                                          title: 'Break hrs',
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
                  );
                },
                loading: () => const SingleChildScrollView(
                  child: Column(
                    children: [
                      AppSkeletonCard(height: 170),
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
                  onAction: () => ref
                      .invalidate(periodPayrollProvider(_selectedPeriod!.id)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pay Period Controls widget ───────────────────────────────────────────────

class _PayPeriodControls extends StatelessWidget {
  final AsyncValue<List<PayPeriod>> openPeriodsAsync;
  final PayPeriod? selectedPeriod;
  final String calculationMode;
  final Color Function(String) periodStatusColor;
  final ValueChanged<PayPeriod?> onPeriodChanged;
  final ValueChanged<String> onModeChanged;

  const _PayPeriodControls({
    required this.openPeriodsAsync,
    required this.selectedPeriod,
    required this.calculationMode,
    required this.periodStatusColor,
    required this.onPeriodChanged,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Pay period & calculation mode',
            subtitle:
                'Select the pay period to process, then choose how break time is handled in the payroll calculation.',
          ),
          const SizedBox(height: 20),
          openPeriodsAsync.when(
            data: (periods) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pay period dropdown
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pay Period',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.mist),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<PayPeriod>(
                            isExpanded: true,
                            hint: Text(
                              periods.isEmpty
                                  ? 'No open periods — create one first'
                                  : 'Select a pay period',
                              style: const TextStyle(color: AppTheme.mutedText),
                            ),
                            value: selectedPeriod,
                            items: periods
                                .map((p) => DropdownMenuItem(
                                      value: p,
                                      child: Row(
                                        children: [
                                          Expanded(child: Text(p.label)),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: periodStatusColor(p.status)
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              p.status,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color:
                                                    periodStatusColor(p.status),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                            onChanged: onPeriodChanged,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Calculation mode toggle
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Calculation Mode',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ModeToggle(
                      mode: calculationMode,
                      onChanged: onModeChanged,
                    ),
                  ],
                ),
              ],
            ),
            loading: () => const AppSkeletonCard(height: 60),
            error: (e, _) => Text('Failed to load periods: $e'),
          ),
        ],
      ),
    );
  }
}

// ── Calculation mode toggle ──────────────────────────────────────────────────

class _ModeToggle extends StatelessWidget {
  final String mode;
  final ValueChanged<String> onChanged;

  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ModeOption(
          label: 'Include Breaks',
          subtitle: 'Paid = Total hours (first → last punch)',
          value: 'INCLUDE_BREAKS',
          groupValue: mode,
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
        _ModeOption(
          label: 'Exclude Breaks',
          subtitle: 'Paid = Working hours (session time only)',
          value: 'EXCLUDE_BREAKS',
          groupValue: mode,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ModeOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  const _ModeOption({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryGreen.withValues(alpha: 0.08)
              : Colors.transparent,
          border: Border.all(
            color: selected ? AppTheme.primaryGreen : AppTheme.mist,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: (v) => onChanged(v!),
              activeColor: AppTheme.primaryGreen,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? AppTheme.primaryGreen : AppTheme.ink,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.mutedText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Create Pay Period Dialog ──────────────────────────────────────────────────

class _CreatePayPeriodDialog extends ConsumerStatefulWidget {
  final void Function(PayPeriod) onCreated;

  const _CreatePayPeriodDialog({required this.onCreated});

  @override
  ConsumerState<_CreatePayPeriodDialog> createState() =>
      _CreatePayPeriodDialogState();
}

class _CreatePayPeriodDialogState
    extends ConsumerState<_CreatePayPeriodDialog> {
  final _nameController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_nameController.text.isEmpty || _startDate == null || _endDate == null) {
      setState(() => _error = 'All fields are required');
      return;
    }
    if (!_endDate!.isAfter(_startDate!)) {
      setState(() => _error = 'End date must be after start date');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final fmt = DateFormat('yyyy-MM-dd');
      final period =
          await ref.read(payrollRepositoryProvider).createPayPeriod(
                name: _nameController.text.trim(),
                startDate: fmt.format(_startDate!),
                endDate: fmt.format(_endDate!),
              );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onCreated(period);
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM yyyy');
    return AlertDialog(
      title: const Text('New Pay Period'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Week 28 – Jul 7 to Jul 13',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(true),
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text(_startDate == null
                        ? 'Start date'
                        : fmt.format(_startDate!)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(false),
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text(
                        _endDate == null ? 'End date' : fmt.format(_endDate!)),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}

// ── Shared column helper ─────────────────────────────────────────────────────

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

// ── Payroll posture card ─────────────────────────────────────────────────────

class _PayrollStatusCard extends StatelessWidget {
  final List<PayrollRecord> records;

  const _PayrollStatusCard({required this.records});

  @override
  Widget build(BuildContext context) {
    final paid = records.where((r) => r.status == 'PAID').length;
    final pending = records.where((r) => r.status != 'PAID').length;
    final bonuses = records.fold<double>(0, (sum, r) => sum + r.bonuses);
    final deductions = records.fold<double>(0, (sum, r) => sum + r.deductions);
    final totalBreaks = records.fold<double>(0, (sum, r) => sum + r.breakHours);
    final currency = NumberFormat.currency(symbol: '₹');

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Payroll posture',
            subtitle:
                'Snapshot of payout status, bonuses, deductions, and break time for this period.',
          ),
          const SizedBox(height: 24),
          AppKeyValueRow(label: 'Paid records', value: '$paid'),
          const Divider(),
          AppKeyValueRow(label: 'Pending records', value: '$pending'),
          const Divider(),
          AppKeyValueRow(
              label: 'Total break hours',
              value: '${totalBreaks.toStringAsFixed(2)}h'),
          const Divider(),
          AppKeyValueRow(label: 'Bonuses', value: currency.format(bonuses)),
          const Divider(),
          AppKeyValueRow(
              label: 'Deductions', value: currency.format(deductions)),
        ],
      ),
    );
  }
}

// ── Top payouts chart ────────────────────────────────────────────────────────

class _TopPayrollChart extends ConsumerWidget {
  final List<PayrollRecord> records;

  const _TopPayrollChart({required this.records});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesProvider);
    final employees = employeesAsync.value ?? [];
    final employeeLookup = {for (final e in employees) e.id: e};

    final top = [...records]..sort((a, b) => b.netPay.compareTo(a.netPay));
    final series = top.take(5).toList();

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Top payouts',
            subtitle: 'Highest net payroll values in the selected period.',
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
                          .map((r) => r.netPay)
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
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
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
                          final name =
                              employeeLookup[empId]?.name ?? 'E$empId';
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
                            colors: [AppTheme.primaryGreen, AppTheme.accentGold],
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
