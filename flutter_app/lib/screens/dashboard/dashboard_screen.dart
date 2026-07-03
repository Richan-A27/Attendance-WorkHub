import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/error_state_widget.dart';
import '../../repositories/dashboard_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/responsive_layout.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardSummaryProvider);

    return Scaffold(
      body: AppView(
        child: dashboardAsync.when(
          data: (summary) => _DashboardBody(summary: summary),
          loading: () => const _DashboardLoadingState(),
          error: (error, stack) => ErrorStateWidget(
            error: error.toString(),
            onRetry: () => ref.invalidate(dashboardSummaryProvider),
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final Map<String, dynamic> summary;

  const _DashboardBody({required this.summary});

  int _number(String key) => (summary[key] as num?)?.toInt() ?? 0;

  @override
  Widget build(BuildContext context) {
    final compactHero = ResponsiveLayout.isShortHeight(context);
    final present = _number('presentToday');
    final absent = _number('absentToday');
    final late = _number('lateToday');
    final totalEmployees = _number('totalEmployees');
    final checkedIn = present + late;
    final attendanceRate = totalEmployees == 0
        ? 0.0
        : (checkedIn / totalEmployees).clamp(0.0, 1.0);
    final lateRate =
        totalEmployees == 0 ? 0.0 : (late / totalEmployees).clamp(0.0, 1.0);
    final absenceRate =
        totalEmployees == 0 ? 0.0 : (absent / totalEmployees).clamp(0.0, 1.0);
    final weeklyBars = [
      (present * 0.82).round(),
      (present * 0.9).round(),
      (present * 0.96).round(),
      present,
      (present * 0.88).round(),
      (present * 0.72).round(),
      (present * 0.68).round(),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

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
            childAspectRatio: ResponsiveLayout.isMobile(context)
                ? 1.6
                : (ResponsiveLayout.isTablet(context) ? 1.4 : 1.2),
            children: [
              AppMetricCard(
                title: 'Present',
                value: '$checkedIn',
                caption: 'Employees recorded today',
                icon: Icons.how_to_reg_rounded,
                accentColor: AppTheme.primaryGreen,
                progress: attendanceRate,
                trend: '${(attendanceRate * 100).round()}%',
              ),
              AppMetricCard(
                title: 'Absent',
                value: '$absent',
                caption: 'Needs follow-up from supervisors',
                icon: Icons.person_off_rounded,
                accentColor: const Color(0xFFC45B4A),
                progress: absenceRate,
                trend: '${(absenceRate * 100).round()}%',
              ),
              AppMetricCard(
                title: 'Late arrivals',
                value: '$late',
                caption: 'Grace-period exceptions today',
                icon: Icons.alarm_on_rounded,
                accentColor: const Color(0xFFBF8A2A),
                progress: lateRate,
                trend: '${(lateRate * 100).round()}%',
              ),
              AppMetricCard(
                title: 'Headcount',
                value: '$totalEmployees',
                caption: 'Active workforce registered',
                icon: Icons.groups_rounded,
                accentColor: AppTheme.olive,
                progress: totalEmployees == 0 ? 0 : 1,
                trend: 'Live',
              ),
            ],
          ),
          const SizedBox(height: 28),
          ResponsiveLayout.isDesktop(context)
              ? IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _AttendanceCompositionCard(
                          present: checkedIn,
                          absent: absent,
                          late: late,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: _WeeklyPerformanceCard(weeklyBars: weeklyBars),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _AttendanceCompositionCard(
                      present: checkedIn,
                      absent: absent,
                      late: late,
                    ),
                    const SizedBox(height: 18),
                    _WeeklyPerformanceCard(weeklyBars: weeklyBars),
                  ],
                ),
          const SizedBox(height: 28),
          const _DeviceHealthCard(),
        ],
      ),
    );
  }
}

class _DeviceHealthCard extends ConsumerWidget {
  const _DeviceHealthCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(deviceStatusProvider);

    return statusAsync.when(
      data: (status) {
        final isOnline = status['status'] == 'Online';
        final accent =
            isOnline ? const Color(0xFF8FE0A9) : const Color(0xFFE88A7B);

        return AppSurfaceCard(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkGreenSidebar,
              isOnline ? const Color(0xFF1F4D35) : const Color(0xFF563428),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveLayout.isMobile(context)
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accent.withValues(alpha: 0.18),
                              ),
                              child: Icon(
                                Icons.router_rounded,
                                color: accent,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${status["deviceName"] ?? "Attendance"} scanner',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: Colors.white,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  AppStatusBadge(
                                    label: isOnline ? 'Online' : 'Offline',
                                    color: accent,
                                    icon: isOnline
                                        ? Icons.check_circle_rounded
                                        : Icons.error_outline_rounded,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => ref.invalidate(deviceStatusProvider),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Refresh device'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0x2BFFFFFF)),
                            backgroundColor: Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accent.withValues(alpha: 0.18),
                              ),
                              child: Icon(
                                Icons.router_rounded,
                                color: accent,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${status["deviceName"] ?? "Attendance"} scanner',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                AppStatusBadge(
                                  label: isOnline ? 'Online' : 'Offline',
                                  color: accent,
                                  icon: isOnline
                                      ? Icons.check_circle_rounded
                                      : Icons.error_outline_rounded,
                                ),
                              ],
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          onPressed: () => ref.invalidate(deviceStatusProvider),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Refresh device'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0x2BFFFFFF)),
                            backgroundColor: Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 22),
              GridView.count(
                crossAxisCount: ResponsiveLayout.adaptiveColumns(
                  context,
                  mobile: 1,
                  tablet: 2,
                  desktop: 5,
                ),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio:
                    ResponsiveLayout.isDesktop(context) ? 1.2 : 1.05,
                children: [
                  _DeviceStatTile(
                    label: 'Users synced',
                    value: '${status['usersSynced'] ?? 0}',
                  ),
                  _DeviceStatTile(
                    label: 'Attendance',
                    value: '${status['attendanceSynced'] ?? 0}',
                  ),
                  _DeviceStatTile(
                    label: 'Last sync',
                    value: status['lastSync'] != null
                        ? status['lastSync']
                            .toString()
                            .substring(0, 16)
                            .replaceFirst('T', ' ')
                        : 'Never',
                  ),
                  _DeviceStatTile(
                    label: 'Duplicates ignored',
                    value: '${status['duplicatesIgnored'] ?? 0}',
                  ),
                  _DeviceStatTile(
                    label: 'Sync duration',
                    value: '${status['syncDuration'] ?? 0} sec',
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const AppSkeletonCard(height: 220),
      error: (e, s) => const SizedBox.shrink(),
    );
  }
}

class _DeviceStatTile extends StatelessWidget {
  final String label;
  final String value;

  const _DeviceStatTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isLong = value.length > 8;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xB3FFFFFF),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isLong ? 13 : 22,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceCompositionCard extends StatelessWidget {
  final int present;
  final int absent;
  final int late;

  const _AttendanceCompositionCard({
    required this.present,
    required this.absent,
    required this.late,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = present + absent + late > 0;
    final chartHeight = ResponsiveLayout.isShortHeight(context) ? 200.0 : 240.0;

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Attendance composition',
            subtitle: 'A polished view of present, absent, and late signals.',
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: chartHeight,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 72,
                sectionsSpace: 3,
                sections: [
                  PieChartSectionData(
                    color: AppTheme.primaryGreen,
                    value: hasData ? present.toDouble() : 1,
                    title: hasData ? '$present' : '',
                    radius: 54,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  PieChartSectionData(
                    color: const Color(0xFFC45B4A),
                    value: hasData ? absent.toDouble() : 0,
                    title: hasData && absent > 0 ? '$absent' : '',
                    radius: 50,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  PieChartSectionData(
                    color: const Color(0xFFBF8A2A),
                    value: hasData ? late.toDouble() : 0,
                    title: hasData && late > 0 ? '$late' : '',
                    radius: 52,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              AppStatusBadge(label: 'Present', color: AppTheme.primaryGreen),
              AppStatusBadge(label: 'Absent', color: Color(0xFFC45B4A)),
              AppStatusBadge(label: 'Late', color: Color(0xFFBF8A2A)),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklyPerformanceCard extends StatelessWidget {
  final List<int> weeklyBars;

  const _WeeklyPerformanceCard({required this.weeklyBars});

  @override
  Widget build(BuildContext context) {
    final chartHeight = ResponsiveLayout.isShortHeight(context) ? 200.0 : 240.0;
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Workforce rhythm',
            subtitle: 'A richer weekly trend view for attendance activity.',
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: chartHeight,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY:
                    (weeklyBars.reduce((a, b) => a > b ? a : b) + 4).toDouble(),
                minY: 0,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => const FlLine(
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
                        const days = [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun'
                        ];
                        final index = value.toInt();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            index >= 0 && index < days.length
                                ? days[index]
                                : '',
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
                barGroups: List.generate(weeklyBars.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: weeklyBars[index].toDouble(),
                        width: 18,
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryGreen, AppTheme.accentGold],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: (weeklyBars.reduce((a, b) => a > b ? a : b) + 4)
                              .toDouble(),
                          color: const Color(0xFFF0E7D8),
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

class _DashboardLoadingState extends StatelessWidget {
  const _DashboardLoadingState();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const AppSkeletonCard(height: 240),
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
            childAspectRatio: ResponsiveLayout.isMobile(context) ? 1.18 : 0.92,
            children: const [
              AppSkeletonCard(),
              AppSkeletonCard(),
              AppSkeletonCard(),
              AppSkeletonCard(),
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
            childAspectRatio: ResponsiveLayout.isDesktop(context) ? 1.12 : 0.92,
            children: const [
              AppSkeletonCard(height: 280),
              AppSkeletonCard(height: 280),
            ],
          ),
        ],
      ),
    );
  }
}
