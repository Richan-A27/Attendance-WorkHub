import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/holiday.dart';
import '../../repositories/schedule_repository.dart';
import '../../widgets/app_ui.dart';

class HolidaysScreen extends ConsumerWidget {
  const HolidaysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holidaysAsync = ref.watch(holidaysProvider);

    return Scaffold(
      body: AppView(
        child: holidaysAsync.when(
          data: (holidays) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppPageHeader(
                    eyebrow: 'Calendar',
                    title: 'Holiday configuration',
                    subtitle:
                        'Maintain the holiday calendar used by attendance and payroll operations.',
                    trailing: ElevatedButton.icon(
                      onPressed: () => _showAddHolidayDialog(context, ref),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add holiday'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (holidays.isEmpty)
                    AppEmptyState(
                      icon: Icons.event_busy_outlined,
                      title: 'No holidays configured',
                      description:
                          'Add the first holiday so attendance and payroll calculations can respect calendar exceptions.',
                      actionLabel: 'Add holiday',
                      onAction: () => _showAddHolidayDialog(context, ref),
                    )
                  else
                    AppSurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppSectionHeader(
                            title: 'Configured holidays',
                            subtitle:
                                'A clean list of upcoming public calendar exceptions already saved in the system.',
                          ),
                          const SizedBox(height: 20),
                          ...holidays.map((holiday) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: AppSurfaceCard(
                                color: const Color(0xFFF8F3E8),
                                padding: const EdgeInsets.all(18),
                                child: AppInfoTile(
                                  icon: Icons.beach_access_rounded,
                                  title: holiday.description,
                                  subtitle: holiday.date,
                                  trailing: AppStatusBadge(
                                    label: holiday.type,
                                    color: const Color(0xFFBF8A2A),
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
            );
          },
          loading: () => const SingleChildScrollView(
            child: AppSkeletonCard(height: 320),
          ),
          error: (error, stack) => AppEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Unable to load holidays',
            description: error.toString(),
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(holidaysProvider),
          ),
        ),
      ),
    );
  }

  void _showAddHolidayDialog(BuildContext context, WidgetRef ref) {
    final descCtrl = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
            contentPadding: const EdgeInsets.fromLTRB(28, 18, 28, 10),
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add holiday',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a calendar exception while keeping the existing holiday model intact.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.edit_calendar_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_rounded),
                    label: Text(
                      selectedDate != null
                          ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'
                          : 'Select date',
                    ),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setState(() => selectedDate = date);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  if (descCtrl.text.isEmpty || selectedDate == null) {
                    return;
                  }

                  final dateStr =
                      '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}';
                  final holiday =
                      Holiday(date: dateStr, description: descCtrl.text);

                  try {
                    await ref
                        .read(scheduleRepositoryProvider)
                        .saveHoliday(holiday);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ref.invalidate(holidaysProvider);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save holiday'),
              ),
            ],
          );
        },
      ),
    );
  }
}
