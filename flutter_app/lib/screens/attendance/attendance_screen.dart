import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../repositories/attendance_repository.dart';
import '../../repositories/employee_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/responsive_layout.dart';
import 'attendance_data_source.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  final _searchController = TextEditingController();
  String _statusFilter = 'All';
  DateTime? _selectedDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attendanceAsyncValue = ref.watch(attendanceLogsProvider);
    final employeesAsyncValue = ref.watch(employeesProvider);

    if (attendanceAsyncValue.isLoading || employeesAsyncValue.isLoading) {
      return const Scaffold(
        body: AppView(
          child: SingleChildScrollView(
            child: Column(
              children: [
                AppSkeletonCard(height: 170),
                SizedBox(height: 24),
                AppSkeletonCard(height: 180),
                SizedBox(height: 24),
                AppSkeletonCard(height: 560),
              ],
            ),
          ),
        ),
      );
    }

    if (attendanceAsyncValue.hasError) {
      return Scaffold(
        body: AppView(
          child: AppEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Unable to load attendance',
            description: '${attendanceAsyncValue.error}',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(attendanceLogsProvider),
          ),
        ),
      );
    }

    final logs = attendanceAsyncValue.value ?? [];
    final employees = employeesAsyncValue.value ?? [];
    final employeeLookup = {
      for (final employee in employees) employee.id: employee,
    };
    final query = _searchController.text.trim().toLowerCase();

    final filteredLogs = logs.where((log) {
      final employee = employeeLookup[log.employeeId];
      final employeeName = employee?.name ?? 'Unknown';
      final matchesQuery = query.isEmpty ||
          employeeName.toLowerCase().contains(query) ||
          log.employeeId.toString().contains(query) ||
          (log.status ?? '').toLowerCase().contains(query);
      final matchesStatus = _statusFilter == 'All' ||
          (_statusFilter == 'Flagged' &&
              ((log.status ?? '').toLowerCase() != 'ok' &&
                  (log.status ?? '').toLowerCase() != 'present' &&
                  (log.status ?? '').isNotEmpty)) ||
          (_statusFilter == 'Normal' &&
              ((log.status ?? '').toLowerCase() == 'ok' ||
                  (log.status ?? '').toLowerCase() == 'present' ||
                  (log.status ?? '').isEmpty));

      final logDate = DateTime.tryParse(log.punchTime);
      final matchesDate = _selectedDate == null ||
          (logDate != null &&
              logDate.year == _selectedDate!.year &&
              logDate.month == _selectedDate!.month &&
              logDate.day == _selectedDate!.day);

      return matchesQuery && matchesStatus && matchesDate;
    }).toList();

    final uniqueEmployeeCount =
        logs.map((log) => log.employeeId).toSet().length;
    final flaggedCount = logs.where((log) {
      final status = (log.status ?? '').toLowerCase();
      return status.isNotEmpty && status != 'ok' && status != 'present';
    }).length;

    final attendanceDataSource =
        AttendanceDataSource(logs: filteredLogs, employees: employees);

    return Scaffold(
      body: AppView(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppPageHeader(
                eyebrow: 'Attendance',
                title: 'Live attendance intelligence',
                subtitle:
                    'Review daily punch behavior, search records quickly, and focus on exceptions without changing your sync pipeline.',
                trailing: OutlinedButton.icon(
                  onPressed: () => ref.invalidate(attendanceLogsProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh logs'),
                ),
              ),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: ResponsiveLayout.adaptiveColumns(
                  context,
                  mobile: 1,
                  tablet: 2,
                  desktop: 3,
                ),
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: ResponsiveLayout.isMobile(context)
                    ? 1.12
                    : (ResponsiveLayout.isTablet(context) ? 1.0 : 0.94),
                children: [
                  AppMetricCard(
                    title: 'Punch events',
                    value: '${logs.length}',
                    caption: 'Total attendance log entries in the current feed',
                    icon: Icons.fingerprint_rounded,
                    accentColor: AppTheme.primaryGreen,
                    progress: logs.isEmpty ? 0 : 1,
                    trend: 'Live',
                  ),
                  AppMetricCard(
                    title: 'People recorded',
                    value: '$uniqueEmployeeCount',
                    caption: 'Unique employees represented in these logs',
                    icon: Icons.groups_rounded,
                    accentColor: AppTheme.olive,
                    progress: uniqueEmployeeCount == 0 ? 0 : 1,
                    trend: 'Coverage',
                  ),
                  AppMetricCard(
                    title: 'Flagged entries',
                    value: '$flaggedCount',
                    caption: 'Records that may need human review',
                    icon: Icons.warning_amber_rounded,
                    accentColor: const Color(0xFFC45B4A),
                    progress: logs.isEmpty ? 0 : flaggedCount / logs.length,
                    trend: logs.isEmpty
                        ? '0%'
                        : '${((flaggedCount / logs.length) * 100).round()}%',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (logs.isEmpty)
                const AppEmptyState(
                  icon: Icons.event_busy_outlined,
                  title: 'No attendance logs yet',
                  description:
                      'Attendance records will appear here after the biometric device completes a sync.',
                )
              else
                AppTableContainer(
                  title: 'Attendance log',
                  subtitle:
                      'Search by person or device ID, narrow to a specific date, and inspect exception records cleanly.',
                  toolbar: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppSearchField(
                              controller: _searchController,
                              hintText:
                                  'Search by employee, device ID, or status',
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (picked != null) {
                                setState(() => _selectedDate = picked);
                              }
                            },
                            icon: const Icon(Icons.calendar_today_rounded),
                            label: Text(
                              _selectedDate == null
                                  ? 'Filter date'
                                  : DateFormat('dd MMM yyyy')
                                      .format(_selectedDate!),
                            ),
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
                              label: 'Normal',
                              selected: _statusFilter == 'Normal',
                              onTap: () =>
                                  setState(() => _statusFilter = 'Normal'),
                            ),
                            AppFilterPill(
                              label: 'Flagged',
                              selected: _statusFilter == 'Flagged',
                              onTap: () =>
                                  setState(() => _statusFilter = 'Flagged'),
                            ),
                            AppFilterPill(
                              label: 'Clear date',
                              selected: false,
                              onTap: () => setState(() => _selectedDate = null),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  child: filteredLogs.isEmpty
                      ? const AppEmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No logs match these filters',
                          description:
                              'Broaden the query or clear the selected date to inspect more attendance activity.',
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: SizedBox(
                            height: 560,
                            child: SfDataGrid(
                              source: attendanceDataSource,
                              columnWidthMode: ColumnWidthMode.fill,
                              allowSorting: true,
                              allowFiltering: true,
                              headerRowHeight: 58,
                              rowHeight: 74,
                              gridLinesVisibility: GridLinesVisibility.none,
                              headerGridLinesVisibility:
                                  GridLinesVisibility.none,
                              columns: <GridColumn>[
                                _AttendanceColumn(name: 'id', title: 'ID'),
                                _AttendanceColumn(
                                  name: 'employeeName',
                                  title: 'Employee',
                                ),
                                _AttendanceColumn(
                                  name: 'punchTime',
                                  title: 'Punch time',
                                ),
                                _AttendanceColumn(
                                  name: 'verifyMode',
                                  title: 'Verify mode',
                                ),
                                _AttendanceColumn(
                                  name: 'status',
                                  title: 'Status',
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendanceColumn extends GridColumn {
  _AttendanceColumn({
    required String name,
    required String title,
  }) : super(
          columnName: name,
          label: Container(
            alignment: Alignment.centerLeft,
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
