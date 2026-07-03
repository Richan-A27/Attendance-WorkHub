import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../repositories/attendance_repository.dart';
import '../../repositories/employee_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/responsive_layout.dart';
import '../../models/daily_attendance.dart';
import '../../models/attendance_break.dart';
import '../../models/attendance_session.dart';

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
    // Default to today if no date is picked
    final filterDate = _selectedDate ?? DateTime.now();
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(filterDate);

    final dailyAttendanceAsync = ref.watch(dailyAttendanceProvider(selectedDateStr));
    final employeesAsyncValue = ref.watch(employeesProvider);

    if (dailyAttendanceAsync.isLoading || employeesAsyncValue.isLoading) {
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

    if (dailyAttendanceAsync.hasError) {
      return Scaffold(
        body: AppView(
          child: AppEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Unable to load attendance intelligence',
            description: '${dailyAttendanceAsync.error}',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(dailyAttendanceProvider),
          ),
        ),
      );
    }

    final dailyRecords = dailyAttendanceAsync.value ?? [];
    final employees = employeesAsyncValue.value ?? [];
    final employeeLookup = {
      for (final employee in employees) employee.id: employee,
    };
    final query = _searchController.text.trim().toLowerCase();

    final filteredRecords = dailyRecords.where((record) {
      final employee = employeeLookup[record.employeeId];
      final employeeName = employee?.name ?? 'Unknown';
      
      final matchesQuery = query.isEmpty ||
          employeeName.toLowerCase().contains(query) ||
          record.employeeId.toString().contains(query) ||
          record.status.toLowerCase().contains(query);

      final statusLower = record.status.toLowerCase();
      final matchesStatus = _statusFilter == 'All' ||
          (_statusFilter == 'Flagged' && (statusLower == 'incomplete' || statusLower == 'absent' || statusLower == 'late')) ||
          (_statusFilter == 'Normal' && (statusLower == 'present' || statusLower == 'weekend' || statusLower == 'holiday'));

      return matchesQuery && matchesStatus;
    }).toList();

    // Stats
    final presentCount = dailyRecords.where((r) => r.status.toLowerCase() == 'present').length;
    final incompleteCount = dailyRecords.where((r) => r.status.toLowerCase() == 'incomplete').length;
    final lateCount = dailyRecords.where((r) => r.status.toLowerCase() == 'late').length;

    return Scaffold(
      body: AppView(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppPageHeader(
                eyebrow: 'Attendance Intelligence',
                title: 'Daily Shift & Break Analysis',
                subtitle:
                    'Analyze real-time working sessions, check-ins, check-outs, and precise break tracking calculated from raw punches.',
                trailing: OutlinedButton.icon(
                  onPressed: () {
                    ref.invalidate(dailyAttendanceProvider(selectedDateStr));
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh shift records'),
                ),
              ),
              const SizedBox(height: 24),
              
              // Metric cards
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
                    title: 'Active / Present',
                    value: '$presentCount',
                    caption: 'Employees completed shift normally',
                    icon: Icons.check_circle_outline_rounded,
                    accentColor: AppTheme.primaryGreen,
                    progress: dailyRecords.isEmpty ? 0 : presentCount / dailyRecords.length,
                    trend: 'On Track',
                  ),
                  AppMetricCard(
                    title: 'Late Arrivals',
                    value: '$lateCount',
                    caption: 'Clocked in past shift starting window',
                    icon: Icons.alarm_rounded,
                    accentColor: AppTheme.accentGold,
                    progress: dailyRecords.isEmpty ? 0 : lateCount / dailyRecords.length,
                    trend: 'Flagged',
                  ),
                  AppMetricCard(
                    title: 'Incomplete Shifts',
                    value: '$incompleteCount',
                    caption: 'Missing check-out punches',
                    icon: Icons.warning_amber_rounded,
                    accentColor: const Color(0xFFC45B4A),
                    progress: dailyRecords.isEmpty ? 0 : incompleteCount / dailyRecords.length,
                    trend: 'Action Required',
                  ),
                  AppMetricCard(
                    title: 'Wiped Clean Feed',
                    value: '${dailyRecords.length}',
                    caption: 'Total employee schedules processed today',
                    icon: Icons.groups_rounded,
                    accentColor: AppTheme.olive,
                    progress: 1.0,
                    trend: 'Live',
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Filter toolbar
              AppTableContainer(
                title: 'Intelligence Sheet',
                subtitle: 'Filter by date, name, or exception type to inspect breaks and sessions.',
                toolbar: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppSearchField(
                            controller: _searchController,
                            hintText: 'Search by employee or status...',
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: filterDate,
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
                            DateFormat('dd MMM yyyy').format(filterDate),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        children: [
                          AppFilterPill(
                            label: 'All',
                            selected: _statusFilter == 'All',
                            onTap: () => setState(() => _statusFilter = 'All'),
                          ),
                          AppFilterPill(
                            label: 'Normal',
                            selected: _statusFilter == 'Normal',
                            onTap: () => setState(() => _statusFilter = 'Normal'),
                          ),
                          AppFilterPill(
                            label: 'Flagged Exceptions',
                            selected: _statusFilter == 'Flagged',
                            onTap: () => setState(() => _statusFilter = 'Flagged'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                child: filteredRecords.isEmpty
                    ? const AppEmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No attendance records found',
                        description: 'Try changing your search query or selecting a different date.',
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredRecords.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        itemBuilder: (context, index) {
                          final record = filteredRecords[index];
                          final employee = employeeLookup[record.employeeId];
                          return _AttendanceCard(
                            record: record,
                            employeeName: employee?.name ?? 'Unknown Employee',
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendanceCard extends StatefulWidget {
  final DailyAttendance record;
  final String employeeName;

  const _AttendanceCard({
    required this.record,
    required this.employeeName,
  });

  @override
  State<_AttendanceCard> createState() => _AttendanceCardState();
}

class _AttendanceCardState extends State<_AttendanceCard> {
  bool _isExpanded = false;

  String _formatTime(String? timeStr) {
    if (timeStr == null) return '--:--';
    final parsed = DateTime.tryParse(timeStr);
    if (parsed == null) return timeStr;
    return DateFormat('hh:mm a').format(parsed);
  }

  String _formatDuration(int minutes) {
    if (minutes <= 0) return '0m';
    final h = (minutes / 60).floor();
    final m = minutes % 60;
    if (h > 0) {
      return '${h}h ${m}m';
    }
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.record.status);
    final recordDate = widget.record.attendanceDate;

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.sage.withValues(alpha: 0.3),
                          child: Text(
                            widget.employeeName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.employeeName,
                              style: const TextStyle(
                                color: AppTheme.ink,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ID: ${widget.record.employeeId}',
                              style: const TextStyle(
                                color: AppTheme.mutedText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        widget.record.status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetric('Check In', _formatTime(widget.record.firstPunch)),
                    _buildMetric('Check Out', widget.record.lastPunch != null ? _formatTime(widget.record.lastPunch) : (widget.record.status == 'INCOMPLETE' ? 'Missing' : 'Active')),
                    _buildMetric('Total Hours', _formatDuration(widget.record.totalMinutes)),
                    _buildMetric('Working Hours', _formatDuration(widget.record.workingMinutes)),
                    _buildMetric('Break Time', _formatDuration(widget.record.breakMinutes)),
                    _buildOvertimeMetric(widget.record.overtimeMinutes),
                    Icon(
                      _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.mutedText,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          _AttendanceDetailTimeline(
            employeeId: widget.record.employeeId,
            date: recordDate,
          ),
      ],
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppTheme.mutedText,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildOvertimeMetric(int overtimeMinutes) {
    final value = _formatDuration(overtimeMinutes);
    final hasOvertime = overtimeMinutes > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'OVERTIME',
          style: TextStyle(
            color: AppTheme.mutedText,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: hasOvertime ? AppTheme.accentGold : AppTheme.ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PRESENT':
        return AppTheme.primaryGreen;
      case 'LATE':
        return AppTheme.accentGold;
      case 'INCOMPLETE':
        return const Color(0xFFC45B4A);
      case 'ABSENT':
        return Colors.grey.shade600;
      case 'WEEKEND':
      case 'HOLIDAY':
        return AppTheme.olive;
      default:
        return AppTheme.ink;
    }
  }
}

class _AttendanceDetailTimeline extends ConsumerWidget {
  final int employeeId;
  final String date;

  const _AttendanceDetailTimeline({
    required this.employeeId,
    required this.date,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final param = '$employeeId/$date';
    final sessionsAsync = ref.watch(attendanceSessionsProvider(param));
    final breaksAsync = ref.watch(attendanceBreaksProvider(param));

    if (sessionsAsync.isLoading || breaksAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryGreen,
            strokeWidth: 3,
          ),
        ),
      );
    }

    if (sessionsAsync.hasError || breaksAsync.hasError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Text(
          'Error loading break timeline: ${sessionsAsync.error ?? breaksAsync.error}',
          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
        ),
      );
    }

    final sessions = sessionsAsync.value ?? [];
    final breaks = breaksAsync.value ?? [];

    if (sessions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'No punch sessions recorded for this day.',
            style: TextStyle(color: AppTheme.mutedText, fontSize: 13, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    // Build timeline events
    final List<_TimelineEvent> events = [];
    
    for (final s in sessions) {
      events.add(_TimelineEvent(
        isSession: true,
        start: s.punchIn,
        end: s.punchOut,
        durationMinutes: s.durationMinutes ?? 0,
        number: s.sessionNumber,
      ));
    }
    
    for (final b in breaks) {
      events.add(_TimelineEvent(
        isSession: false,
        start: b.breakStart,
        end: b.breakEnd,
        durationMinutes: b.durationMinutes,
        number: b.breakNumber,
      ));
    }

    events.sort((a, b) => a.start.compareTo(b.start));

    return Container(
      width: double.infinity,
      color: const Color(0xFFFBFBF9),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TIMELINE & BREAK INTELLIGENCE',
            style: TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 18),
          ...events.map((e) => _buildTimelineNode(e)),
        ],
      ),
    );
  }

  Widget _buildTimelineNode(_TimelineEvent e) {
    final startLocal = DateTime.tryParse(e.start);
    final endLocal = e.end != null ? DateTime.tryParse(e.end!) : null;
    final timeFormat = DateFormat('hh:mm a');
    
    final startStr = startLocal != null ? timeFormat.format(startLocal) : e.start;
    final endStr = endLocal != null ? timeFormat.format(endLocal) : (e.end ?? 'Active');

    final color = e.isSession ? AppTheme.primaryGreen : AppTheme.accentGold;
    final title = e.isSession ? 'Session ${e.number}' : 'Break ${e.number}';
    final subtitle = '$startStr → $endStr';
    
    final h = (e.durationMinutes / 60).floor();
    final m = e.durationMinutes % 60;
    final durationStr = e.isSession 
        ? (e.end != null ? (h > 0 ? '${h}h ${m}m' : '${m}m') : 'Incomplete')
        : '${e.durationMinutes}m';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 3),
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: Colors.grey.shade300,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: e.isSession ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: e.isSession ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: e.isSession ? const Color(0xFF166534) : const Color(0xFF92400E),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppTheme.mutedText,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      durationStr,
                      style: TextStyle(
                        color: e.isSession ? const Color(0xFF166534) : const Color(0xFF92400E),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineEvent {
  final bool isSession;
  final String start;
  final String? end;
  final int durationMinutes;
  final int number;

  _TimelineEvent({
    required this.isSession,
    required this.start,
    this.end,
    required this.durationMinutes,
    required this.number,
  });
}
