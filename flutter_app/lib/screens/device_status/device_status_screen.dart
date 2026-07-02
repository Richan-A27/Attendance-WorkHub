import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repositories/device_status_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/responsive_layout.dart';

class DeviceStatusScreen extends ConsumerWidget {
  const DeviceStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagAsync = ref.watch(diagnosticsProvider);

    return Scaffold(
      body: AppView(
        child: diagAsync.when(
          data: (diag) => _DiagnosticsBody(diag: diag, ref: ref),
          loading: () => const SingleChildScrollView(
            child: Column(
              children: [
                AppSkeletonCard(height: 180),
                SizedBox(height: 24),
                AppSkeletonCard(height: 180),
                SizedBox(height: 24),
                AppSkeletonCard(height: 320),
              ],
            ),
          ),
          error: (e, _) => AppEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Unable to load system health',
            description: e.toString(),
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(diagnosticsProvider),
          ),
        ),
      ),
    );
  }
}

class _DiagnosticsBody extends StatelessWidget {
  final Map<String, dynamic> diag;
  final WidgetRef ref;

  const _DiagnosticsBody({required this.diag, required this.ref});

  @override
  Widget build(BuildContext context) {
    final deviceStatus = diag['deviceStatus'] as Map<String, dynamic>? ?? {};
    final deviceOnline = diag['deviceReachable'] == true;
    final dbReachable = diag['databaseReachable'] == true;
    final lastSyncStatus = diag['lastSyncStatus']?.toString() ?? 'UNKNOWN';
    final lastSyncDuration = diag['lastSyncDuration']?.toString() ?? 'N/A';
    final recentFailures = diag['recentFailures']?.toString() ?? '0';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppPageHeader(
            eyebrow: 'Monitoring',
            title: 'System health command center',
            subtitle:
                'Keep an eye on biometric connectivity, database reachability, and sync reliability from one polished monitoring surface.',
            trailing: OutlinedButton.icon(
              onPressed: () => ref.invalidate(diagnosticsProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh health'),
            ),
          ),
          const SizedBox(height: 24),
          AppSurfaceCard(
            gradient: LinearGradient(
              colors: [
                AppTheme.darkGreenSidebar,
                deviceOnline
                    ? const Color(0xFF204531)
                    : const Color(0xFF55362A),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runSpacing: 18,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppStatusBadge(
                          label: deviceOnline
                              ? 'Scanner online'
                              : 'Scanner offline',
                          color: deviceOnline
                              ? const Color(0xFF9BE3AC)
                              : const Color(0xFFE88A7B),
                          icon: deviceOnline
                              ? Icons.check_circle_rounded
                              : Icons.error_outline_rounded,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'ISRAVEL sync environment',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Track infrastructure confidence before it affects attendance or payroll operations.',
                          style: TextStyle(
                            color: Color(0xFFD1E1D7),
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await ref
                              .read(deviceStatusRepositoryProvider)
                              .triggerManualSync();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Manual sync triggered'),
                              ),
                            );
                            ref.invalidate(diagnosticsProvider);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Sync failed: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.sync_rounded),
                      label: const Text('Trigger manual sync'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.darkGreenSidebar,
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
                    desktop: 4,
                  ),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.45,
                  children: [
                    _MonitorMetric(
                      label: 'Last sync status',
                      value: lastSyncStatus,
                    ),
                    _MonitorMetric(
                      label: 'Last sync duration',
                      value: lastSyncDuration,
                    ),
                    _MonitorMetric(
                      label: 'Recent failures',
                      value: recentFailures,
                    ),
                    _MonitorMetric(
                      label: 'Connection status',
                      value: deviceStatus['connectionStatus']?.toString() ??
                          'UNKNOWN',
                    ),
                  ],
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
              desktop: 2,
            ),
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: ResponsiveLayout.isDesktop(context) ? 1.38 : 1.05,
            children: [
              _ServiceStatusCard(
                deviceOnline: deviceOnline,
                dbReachable: dbReachable,
                lastSyncStatus: lastSyncStatus,
              ),
              _DiagnosticsCard(
                deviceStatus: deviceStatus,
                lastSyncStatus: lastSyncStatus,
                lastSyncDuration: lastSyncDuration,
                recentFailures: recentFailures,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonitorMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MonitorMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFD1E1D7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceStatusCard extends StatelessWidget {
  final bool deviceOnline;
  final bool dbReachable;
  final String lastSyncStatus;

  const _ServiceStatusCard({
    required this.deviceOnline,
    required this.dbReachable,
    required this.lastSyncStatus,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Service status',
            subtitle:
                'At-a-glance operational health across core dependencies.',
          ),
          const SizedBox(height: 24),
          _ServiceTile(
            title: 'eSSL X2008 Biometric',
            status: deviceOnline ? 'ONLINE' : 'OFFLINE',
            color: deviceOnline
                ? const Color(0xFF2F7A52)
                : const Color(0xFFC45B4A),
            icon: Icons.fingerprint_rounded,
          ),
          const SizedBox(height: 12),
          _ServiceTile(
            title: 'PostgreSQL Database',
            status: dbReachable ? 'CONNECTED' : 'DISCONNECTED',
            color:
                dbReachable ? const Color(0xFF2F7A52) : const Color(0xFFC45B4A),
            icon: Icons.storage_rounded,
          ),
          const SizedBox(height: 12),
          const _ServiceTile(
            title: 'Spring Boot API',
            status: 'RUNNING',
            color: Color(0xFF2F7A52),
            icon: Icons.cloud_done_rounded,
          ),
          const SizedBox(height: 12),
          _ServiceTile(
            title: 'Sync Queue',
            status: lastSyncStatus,
            color:
                lastSyncStatus == 'SUCCESS' || lastSyncStatus == 'NEVER_SYNCED'
                    ? const Color(0xFF2F7A52)
                    : const Color(0xFFBF8A2A),
            icon: Icons.sync_rounded,
          ),
        ],
      ),
    );
  }
}

class _DiagnosticsCard extends StatelessWidget {
  final Map<String, dynamic> deviceStatus;
  final String lastSyncStatus;
  final String lastSyncDuration;
  final String recentFailures;

  const _DiagnosticsCard({
    required this.deviceStatus,
    required this.lastSyncStatus,
    required this.lastSyncDuration,
    required this.recentFailures,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Diagnostics',
            subtitle:
                'Important values currently exposed by the diagnostics payload.',
          ),
          const SizedBox(height: 24),
          AppKeyValueRow(
            label: 'Device IP',
            value: deviceStatus['deviceIp']?.toString() ?? '192.168.1.201',
          ),
          const Divider(),
          AppKeyValueRow(
            label: 'Connection status',
            value: deviceStatus['connectionStatus']?.toString() ?? 'UNKNOWN',
          ),
          const Divider(),
          AppKeyValueRow(label: 'Last sync status', value: lastSyncStatus),
          const Divider(),
          AppKeyValueRow(label: 'Last sync duration', value: lastSyncDuration),
          const Divider(),
          AppKeyValueRow(label: 'Recent failures', value: recentFailures),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final String title;
  final String status;
  final Color color;
  final IconData icon;

  const _ServiceTile({
    required this.title,
    required this.status,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F3E8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(status,
                    style:
                        TextStyle(color: color, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
