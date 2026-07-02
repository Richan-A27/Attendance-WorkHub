import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/company_profile.dart';
import '../../repositories/settings_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_ui.dart';
import 'holidays_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final userInitial = (user?.email ?? 'A').substring(0, 1).toUpperCase();

    return Scaffold(
      body: AppView(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppPageHeader(
                eyebrow: 'Administration',
                title: 'Workspace settings',
                subtitle:
                    'Manage company details, configuration touchpoints, and account controls with a cleaner enterprise layout.',
                trailing: AppStatusBadge(
                  label: 'Admin account',
                  color: AppTheme.primaryGreen,
                  icon: Icons.admin_panel_settings_rounded,
                ),
              ),
              const SizedBox(height: 24),
              AppSurfaceCard(
                gradient: const LinearGradient(
                  colors: [AppTheme.darkGreenSidebar, Color(0xFF204531)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor:
                          AppTheme.accentGold.withValues(alpha: 0.16),
                      child: Text(
                        userInitial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.email ?? 'Administrator',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            user?.id ?? '',
                            style: const TextStyle(
                              color: Color(0xFFD1E1D7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const AppStatusBadge(
                      label: 'Secure session',
                      color: AppTheme.accentGold,
                      icon: Icons.verified_user_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SettingsSection(
                title: 'Organization',
                subtitle:
                    'Core business identity and policy-related administration.',
                children: [
                  AppInfoTile(
                    icon: Icons.business_rounded,
                    title: 'Company profile',
                    subtitle: 'ISRAVEL WorkHub identity and contact settings',
                    onTap: () => _showEditCompanyProfileDialog(context, ref),
                  ),
                  const Divider(),
                  AppInfoTile(
                    icon: Icons.beach_access_rounded,
                    title: 'Holidays',
                    subtitle:
                        'Maintain public holidays used by attendance workflows',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const HolidaysScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SettingsSection(
                title: 'Integrations',
                subtitle: 'Operational connections and health touchpoints.',
                children: [
                  AppInfoTile(
                    icon: Icons.fingerprint_rounded,
                    title: 'Biometric Scanner Integration',
                    subtitle: 'Status: Connected',
                    onTap: () => _showInfoDialog(
                      context,
                      'Biometric Scanner Status',
                      'Biometric scanner is integrated and synchronized automatically.',
                    ),
                  ),
                  const Divider(),
                  AppInfoTile(
                    icon: Icons.cloud_done_rounded,
                    title: 'Supabase Sync',
                    subtitle: 'lvuefyqmvlnjofdiponm.supabase.co',
                    onTap: () => _showInfoDialog(
                      context,
                      'Supabase Sync',
                      'URL: lvuefyqmvlnjofdiponm.supabase.co\nStatus: CONNECTED\nQueue: 0 items pending',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SettingsSection(
                title: 'Account',
                subtitle: 'Secure access and session actions.',
                children: [
                  AppInfoTile(
                    icon: Icons.logout_rounded,
                    accentColor: const Color(0xFFC45B4A),
                    title: 'Sign out',
                    subtitle: 'End your current administrator session',
                    onTap: () async {
                      await Supabase.instance.client.auth.signOut();
                      if (context.mounted) {
                        Navigator.of(context)
                            .pushNamedAndRemoveUntil('/login', (_) => false);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
        contentPadding: const EdgeInsets.fromLTRB(28, 18, 28, 10),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        content: AppSurfaceCard(
          color: const Color(0xFFF7F1E6),
          padding: const EdgeInsets.all(20),
          child: Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditCompanyProfileDialog(
      BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    try {
      final profile =
          await ref.read(settingsRepositoryProvider).getCompanyProfile();
      nameCtrl.text = profile.companyName;
      addressCtrl.text = profile.address ?? '';
      emailCtrl.text = profile.contactEmail ?? '';
      phoneCtrl.text = profile.contactPhone ?? '';
    } catch (_) {
      // No company profile has been saved yet.
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
        contentPadding: const EdgeInsets.fromLTRB(28, 18, 28, 12),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Company profile',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Update business contact details while keeping the existing backend contract unchanged.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Company name',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Contact email',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Contact phone',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
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
              final profile = CompanyProfile(
                companyName: nameCtrl.text,
                address: addressCtrl.text,
                contactEmail: emailCtrl.text,
                contactPhone: phoneCtrl.text,
              );
              try {
                await ref
                    .read(settingsRepositoryProvider)
                    .saveCompanyProfile(profile);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile saved successfully')),
                  );
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
            label: const Text('Save profile'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: title, subtitle: subtitle),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}
