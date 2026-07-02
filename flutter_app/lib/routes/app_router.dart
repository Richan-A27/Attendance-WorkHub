import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/auth/login_screen.dart';
import '../screens/app_shell.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/employees/employee_list_screen.dart';
import '../screens/attendance/attendance_screen.dart';
import '../screens/payroll/payroll_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/device_status/device_status_screen.dart';
import '../screens/settings/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          GoRoute(
              path: '/', builder: (context, state) => const DashboardScreen()),
          GoRoute(
              path: '/employees',
              builder: (context, state) => const EmployeeListScreen()),
          GoRoute(
              path: '/attendance',
              builder: (context, state) => const AttendanceScreen()),
          GoRoute(
              path: '/payroll',
              builder: (context, state) => const PayrollScreen()),
          GoRoute(
              path: '/reports',
              builder: (context, state) => const ReportsScreen()),
          GoRoute(
              path: '/device-status',
              builder: (context, state) => const DeviceStatusScreen()),
          GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen()),
        ],
      ),
    ],
  );
});
