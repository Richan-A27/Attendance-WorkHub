import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';
import '../widgets/responsive_layout.dart';

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  static const List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
      route: '/',
      group: 'Overview',
    ),
    _NavItem(
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_rounded,
      label: 'Employees',
      route: '/employees',
      group: 'Workspace',
    ),
    _NavItem(
      icon: Icons.event_available_outlined,
      selectedIcon: Icons.event_available_rounded,
      label: 'Attendance',
      route: '/attendance',
      group: 'Workspace',
    ),
    _NavItem(
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet_rounded,
      label: 'Payroll',
      route: '/payroll',
      group: 'Workspace',
    ),
    _NavItem(
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights_rounded,
      label: 'Reports',
      route: '/reports',
      group: 'Insights',
    ),
    _NavItem(
      icon: Icons.monitor_heart_outlined,
      selectedIcon: Icons.monitor_heart_rounded,
      label: 'System',
      route: '/device-status',
      group: 'Insights',
    ),
    _NavItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      label: 'Settings',
      route: '/settings',
      group: 'Admin',
    ),
  ];

  int _selectedIndex(BuildContext context) {
    final location =
        GoRouter.of(context).routeInformationProvider.value.uri.path;
    final index = _navItems.indexWhere(
      (item) =>
          item.route == '/' ? location == '/' : location.startsWith(item.route),
    );
    return index == -1 ? 0 : index;
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authServiceProvider).signOut();
    if (context.mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _selectedIndex(context);

    return ResponsiveLayout(
      mobile: Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex.clamp(0, 4),
          onDestinationSelected: (index) => context.go(_navItems[index].route),
          destinations: _navItems.take(5).map((item) {
            return NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
            );
          }).toList(),
        ),
      ),
      tablet: Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              backgroundColor: AppTheme.softWhite,
              indicatorColor: AppTheme.sage,
              extended: false,
              minWidth: 92,
              labelType: NavigationRailLabelType.selected,
              leading: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryGreen, AppTheme.emerald],
                    ),
                  ),
                  child: const Icon(Icons.agriculture_rounded,
                      color: Colors.white),
                ),
              ),
              destinations: _navItems
                  .map(
                    (item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: Text(item.label),
                    ),
                  )
                  .toList(),
              onDestinationSelected: (index) =>
                  context.go(_navItems[index].route),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: IconButton(
                    onPressed: () => _logout(context, ref),
                    icon: const Icon(Icons.logout_rounded),
                    tooltip: 'Sign out',
                  ),
                ),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
      desktop: Scaffold(
        body: Row(
          children: [
            Container(
              width: 316,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.darkGreenSidebar, Color(0xFF193728)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSurfaceCard(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0.04),
                      ],
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              colors: [AppTheme.accentGold, Color(0xFFE7C766)],
                            ),
                          ),
                          child: const Icon(
                            Icons.agriculture_rounded,
                            color: AppTheme.darkGreenSidebar,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ISRAVEL WorkHub',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Enterprise workforce intelligence',
                                style: TextStyle(
                                  color: Color(0xFFD4E1D7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _SidebarMetaCard(),
                  const SizedBox(height: 28),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        for (final group in _groupNames) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                            child: Text(
                              group.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF9BB4A5),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          ..._navItems.where((item) => item.group == group).map(
                                (item) => _SidebarItem(
                                  item: item,
                                  isSelected:
                                      _navItems.indexOf(item) == selectedIndex,
                                  onTap: () => context.go(item.route),
                                ),
                              ),
                          const SizedBox(height: 14),
                        ],
                      ],
                    ),
                  ),
                  AppSurfaceCard(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.08),
                        Colors.white.withValues(alpha: 0.03),
                      ],
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Color(0x33D4AF37),
                              child: Icon(Icons.admin_panel_settings_rounded,
                                  color: Colors.white),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Administrator',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Premium operations workspace',
                                    style: TextStyle(
                                      color: Color(0xFFD4E1D7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _logout(context, ref),
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Sign out'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0x2BFFFFFF)),
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.04),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

const List<String> _groupNames = ['Overview', 'Workspace', 'Insights', 'Admin'];

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;
  final String group;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
    required this.group,
  });
}

class _SidebarMetaCard extends StatelessWidget {
  const _SidebarMetaCard();

  @override
  Widget build(BuildContext context) {
    return const AppSurfaceCard(
      gradient: LinearGradient(
        colors: [Color(0xFF2D5942), Color(0xFF244736)],
      ),
      padding: EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s pulse',
            style: TextStyle(
              color: Color(0xFFD8E6DB),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Operations look healthy across attendance, payroll, and sync reliability.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.45,
            ),
          ),
          SizedBox(height: 16),
          AppStatusBadge(
            label: 'Enterprise view active',
            color: AppTheme.accentGold,
            icon: Icons.auto_graph_rounded,
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isSelected;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isActive
              ? const LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.emerald],
                )
              : null,
          color: !isActive && _hovered
              ? Colors.white.withValues(alpha: 0.06)
              : null,
          border: Border.all(
            color: isActive
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: isActive
                          ? Colors.white.withValues(alpha: 0.14)
                          : Colors.white.withValues(alpha: 0.05),
                    ),
                    child: Icon(
                      isActive ? widget.item.selectedIcon : widget.item.icon,
                      color: isActive ? Colors.white : const Color(0xFFC7D8CD),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.item.label,
                      style: TextStyle(
                        color:
                            isActive ? Colors.white : const Color(0xFFE4EFE7),
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isActive ? Colors.white : Colors.white38,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
