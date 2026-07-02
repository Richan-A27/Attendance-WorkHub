import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repositories/schedule_repository.dart';
import '../../widgets/app_ui.dart';

class WorkSchedulesScreen extends ConsumerWidget {
  const WorkSchedulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(workSchedulesProvider);

    return Scaffold(
      body: AppView(
        child: schedulesAsync.when(
          data: (schedules) => SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppPageHeader(
                  eyebrow: 'Scheduling',
                  title: 'Work schedule library',
                  subtitle:
                      'A clearer overview of the saved work schedule rules currently available in the system.',
                ),
                const SizedBox(height: 24),
                if (schedules.isEmpty)
                  const AppEmptyState(
                    icon: Icons.schedule_outlined,
                    title: 'No work schedules yet',
                    description:
                        'Schedules created for employees will appear here once configuration is available.',
                  )
                else
                  AppSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppSectionHeader(
                          title: 'Saved schedules',
                          subtitle:
                              'Employee schedule windows, work days, and timing defaults.',
                        ),
                        const SizedBox(height: 20),
                        ...schedules.map((schedule) {
                          final workDays = schedule.workDays.join(', ');
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: AppSurfaceCard(
                              color: const Color(0xFFF8F3E8),
                              padding: const EdgeInsets.all(18),
                              child: AppInfoTile(
                                icon: Icons.schedule_rounded,
                                title: 'Employee ID ${schedule.employeeId}',
                                subtitle:
                                    '${schedule.startTime.format(context)} - ${schedule.endTime.format(context)} • $workDays',
                                trailing: AppStatusBadge(
                                  label:
                                      schedule.active ? 'Active' : 'Inactive',
                                  color: schedule.active
                                      ? const Color(0xFF2F7A52)
                                      : const Color(0xFFC45B4A),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          loading: () => const SingleChildScrollView(
            child: AppSkeletonCard(height: 280),
          ),
          error: (error, stack) => AppEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Unable to load schedules',
            description: error.toString(),
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(workSchedulesProvider),
          ),
        ),
      ),
    );
  }
}
