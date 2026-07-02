import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../models/employee.dart';
import '../../models/work_schedule.dart';
import '../../repositories/employee_repository.dart';
import '../../repositories/schedule_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/responsive_layout.dart';
import 'employee_data_source.dart';

class EmployeeListScreen extends ConsumerStatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  ConsumerState<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends ConsumerState<EmployeeListScreen> {
  final _searchController = TextEditingController();
  String _statusFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employeesAsyncValue = ref.watch(employeesProvider);

    return Scaffold(
      body: AppView(
        child: employeesAsyncValue.when(
          data: (employees) {
            final query = _searchController.text.trim().toLowerCase();
            final filtered = employees.where((employee) {
              final matchesQuery = query.isEmpty ||
                  employee.name.toLowerCase().contains(query) ||
                  employee.id.toString().contains(query);
              final matchesStatus = _statusFilter == 'All' ||
                  (_statusFilter == 'Active' && employee.active) ||
                  (_statusFilter == 'Inactive' && !employee.active);
              return matchesQuery && matchesStatus;
            }).toList();

            final activeCount =
                employees.where((employee) => employee.active).length;
            final inactiveCount = employees.length - activeCount;

            final employeeDataSource =
                EmployeeDataSource(employeeData: filtered);

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppPageHeader(
                    eyebrow: 'Workforce',
                    title: 'Employee command center',
                    subtitle:
                        'Review synced identities, tune rates, and manage scheduling context without touching backend workflows.',
                    trailing: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Employee identities are synced from the biometric device. Select a row to update schedule and rate details.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.info_outline_rounded),
                      label: const Text('How editing works'),
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
                        title: 'Total employees',
                        value: '${employees.length}',
                        caption:
                            'Registered workforce records from device sync',
                        icon: Icons.groups_rounded,
                        accentColor: AppTheme.primaryGreen,
                        progress: employees.isEmpty ? 0 : 1,
                        trend: 'Live',
                      ),
                      AppMetricCard(
                        title: 'Active profiles',
                        value: '$activeCount',
                        caption: 'Employees currently active in the system',
                        icon: Icons.check_circle_outline_rounded,
                        accentColor: const Color(0xFF2F7A52),
                        progress: employees.isEmpty
                            ? 0
                            : activeCount / employees.length,
                        trend:
                            '${employees.isEmpty ? 0 : ((activeCount / employees.length) * 100).round()}%',
                      ),
                      AppMetricCard(
                        title: 'Inactive profiles',
                        value: '$inactiveCount',
                        caption: 'Records requiring review or deactivation',
                        icon: Icons.pause_circle_outline_rounded,
                        accentColor: const Color(0xFFBF8A2A),
                        progress: employees.isEmpty
                            ? 0
                            : inactiveCount / employees.length,
                        trend:
                            '${employees.isEmpty ? 0 : ((inactiveCount / employees.length) * 100).round()}%',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (employees.isEmpty)
                    const AppEmptyState(
                      icon: Icons.people_outline_rounded,
                      title: 'No employees synced yet',
                      description:
                          'Once biometric users are synchronized, this workspace will surface workforce records and schedule actions here.',
                    )
                  else
                    AppTableContainer(
                      title: 'Employee directory',
                      subtitle:
                          'Search by name, ID, or device mapping, then open a row to edit compensation and schedule details.',
                      toolbar: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: AppSearchField(
                                  controller: _searchController,
                                  hintText:
                                      'Search employees, device IDs, or internal IDs',
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
                                  label: 'Active',
                                  selected: _statusFilter == 'Active',
                                  onTap: () =>
                                      setState(() => _statusFilter = 'Active'),
                                ),
                                AppFilterPill(
                                  label: 'Inactive',
                                  selected: _statusFilter == 'Inactive',
                                  onTap: () => setState(
                                      () => _statusFilter = 'Inactive'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      child: filtered.isEmpty
                          ? const AppEmptyState(
                              icon: Icons.search_off_rounded,
                              title: 'No matching employees',
                              description:
                                  'Try broadening your search or switching the status filter to view more workforce records.',
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: SizedBox(
                                height: 560,
                                child: SfDataGrid(
                                  source: employeeDataSource,
                                  columnWidthMode: ColumnWidthMode.fill,
                                  allowSorting: true,
                                  allowFiltering: true,
                                  headerRowHeight: 58,
                                  rowHeight: 72,
                                  gridLinesVisibility: GridLinesVisibility.none,
                                  headerGridLinesVisibility:
                                      GridLinesVisibility.none,
                                  selectionMode: SelectionMode.single,
                                  onSelectionChanged: (addedRows, removedRows) {
                                    if (addedRows.isNotEmpty) {
                                      final employeeId = addedRows.first
                                          .getCells()
                                          .firstWhere(
                                              (cell) => cell.columnName == 'id')
                                          .value as int;
                                      final employee = filtered.firstWhere(
                                        (value) => value.id == employeeId,
                                      );
                                      _showEditEmployeeDialog(
                                          context, ref, employee);
                                    }
                                  },
                                  columns: <GridColumn>[
                                    _EmployeeColumn(name: 'id', title: 'Employee ID'),
                                    _EmployeeColumn(
                                        name: 'name', title: 'Employee'),
                                    _EmployeeColumn(
                                      name: 'hourlyRate',
                                      title: 'Hourly Rate',
                                      alignment: Alignment.centerRight,
                                    ),
                                    _EmployeeColumn(
                                      name: 'active',
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
                AppSkeletonCard(height: 560),
              ],
            ),
          ),
          error: (error, stack) => AppEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Unable to load employees',
            description: error.toString(),
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(employeesProvider),
          ),
        ),
      ),
    );
  }
}

class _EmployeeColumn extends GridColumn {
  _EmployeeColumn({
    required String name,
    required String title,
    Alignment alignment = Alignment.centerLeft,
  }) : super(
          columnName: name,
          label: Container(
            alignment: alignment,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: const BoxDecoration(
              color: Color(0xFFF5EEDF),
            ),
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

void _showEditEmployeeDialog(
    BuildContext context, WidgetRef ref, Employee employee) async {
  final hourlyRateCtrl =
      TextEditingController(text: employee.hourlyRate?.toString() ?? '');

  WorkSchedule? currentSchedule;
  TimeOfDay? selectedStartTime;
  TimeOfDay? selectedEndTime;

  try {
    final schedules =
        await ref.read(scheduleRepositoryProvider).getAllWorkSchedules();
    currentSchedule =
        schedules.where((s) => s.employeeId == employee.id).firstOrNull;
    if (currentSchedule != null) {
      selectedStartTime = currentSchedule.startTime;
      selectedEndTime = currentSchedule.endTime;
    } else {
      selectedStartTime = const TimeOfDay(hour: 9, minute: 0);
      selectedEndTime = const TimeOfDay(hour: 17, minute: 0);
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
            contentPadding: const EdgeInsets.fromLTRB(28, 20, 28, 8),
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit ${employee.name}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Update the synced worker schedule and compensation settings. Identity data remains device-managed.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSurfaceCard(
                      color: const Color(0xFFF6F0E4),
                      padding: const EdgeInsets.all(18),
                      child: AppInfoTile(
                        icon: Icons.badge_rounded,
                        title: employee.name,
                        subtitle:
                            'Employee ID ${employee.id} • Identity managed from the scanner sync',
                        trailing: AppStatusBadge(
                          label: employee.active ? 'Active' : 'Inactive',
                          color: employee.active
                              ? AppTheme.primaryGreen
                              : const Color(0xFFC45B4A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: hourlyRateCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Hourly rate',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Work schedule',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose the expected check-in and check-out times for payroll and attendance evaluation.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.access_time_rounded),
                            label: Text(selectedStartTime!.format(context)),
                            onPressed: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: selectedStartTime!,
                              );
                              if (time != null) {
                                setState(() => selectedStartTime = time);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.timer_off_outlined),
                            label: Text(selectedEndTime!.format(context)),
                            onPressed: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: selectedEndTime!,
                              );
                              if (time != null) {
                                setState(() => selectedEndTime = time);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final newSchedule = WorkSchedule(
                      id: currentSchedule?.id,
                      employeeId: employee.id,
                      startTime: selectedStartTime!,
                      endTime: selectedEndTime!,
                      workDays: const ['MON', 'TUE', 'WED', 'THU', 'FRI'],
                    );

                    await ref
                        .read(scheduleRepositoryProvider)
                        .saveWorkSchedule(newSchedule);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Employee updated successfully'),
                        ),
                      );
                      Navigator.of(context).pop();
                      ref.invalidate(employeesProvider);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error saving: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save changes'),
              ),
            ],
          );
        },
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }
}
