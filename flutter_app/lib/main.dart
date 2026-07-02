import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase (Placeholders for now)
  await Supabase.initialize(
    url: 'https://lvuefyqmvlnjofdiponm.supabase.co',
    anonKey: 'sb_publishable_DTBBWzaGEZ5cZswh9WHLFw_qWXIKLKO',
  );

  runApp(
    const ProviderScope(
      child: IsravelWorkHubApp(),
    ),
  );
}

class IsravelWorkHubApp extends ConsumerWidget {
  const IsravelWorkHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'ISRAVEL WorkHub',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
