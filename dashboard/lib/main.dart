import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';
import 'screens/overview_screen.dart';
import 'screens/report_queue_screen.dart';
import 'screens/field_workers_screen.dart';
import 'screens/spot_manager_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/citizens_screen.dart';
import 'bloc/dashboard_bloc.dart';
import 'bloc/auth_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      // Replace with your Firebase project values after running flutterfire configure
      apiKey: "YOUR_API_KEY",
      authDomain: "YOUR_PROJECT.firebaseapp.com",
      projectId: "YOUR_PROJECT_ID",
      storageBucket: "YOUR_PROJECT.appspot.com",
      messagingSenderId: "YOUR_SENDER_ID",
      appId: "YOUR_APP_ID",
    ),
  );
  runApp(const DashboardApp());
}

class DashboardApp extends StatelessWidget {
  const DashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => DashboardAuthBloc()),
        BlocProvider(create: (_) => DashboardBloc()),
      ],
      child: MaterialApp.router(
        title: 'SpotSeva — Municipal Command Centre',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        routerConfig: _router,
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0F6E56),
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      scaffoldBackgroundColor: const Color(0xFF0F1117),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E2330),
        elevation: 0,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (_, __) => const DashboardLoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) =>
          DashboardShell(child: child),
      routes: [
        GoRoute(
          path: '/overview',
          builder: (_, __) => const OverviewScreen(),
        ),
        GoRoute(
          path: '/reports',
          builder: (_, __) => const ReportQueueScreen(),
        ),
        GoRoute(
          path: '/workers',
          builder: (_, __) => const FieldWorkersScreen(),
        ),
        GoRoute(
          path: '/spots',
          builder: (_, __) => const SpotManagerScreen(),
        ),
        GoRoute(
          path: '/analytics',
          builder: (_, __) => const AnalyticsScreen(),
        ),
        GoRoute(
          path: '/citizens',
          builder: (_, __) => const CitizensScreen(),
        ),
      ],
    ),
  ],
);

// ── Sidebar Navigation Shell ────────────────────────────────
class DashboardShell extends StatelessWidget {
  final Widget child;
  const DashboardShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    return Scaffold(
      body: Row(
        children: [
          // ── Sidebar ────────────────────────────────────────
          Container(
            width: 220,
            color: const Color(0xFF141821),
            child: Column(
              children: [
                // Logo
                Container(
                  padding: const EdgeInsets.all(20),
                  child: const Row(
                    children: [
                      Text('📍', style: TextStyle(fontSize: 24)),
                      SizedBox(width: 8),
                      Text(
                        'SpotSeva',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white12),
                const SizedBox(height: 8),
                _NavItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Overview',
                  path: '/overview',
                  currentPath: location,
                ),
                _NavItem(
                  icon: Icons.report_outlined,
                  label: 'Report Queue',
                  path: '/reports',
                  currentPath: location,
                ),
                _NavItem(
                  icon: Icons.engineering_outlined,
                  label: 'Field Workers',
                  path: '/workers',
                  currentPath: location,
                ),
                _NavItem(
                  icon: Icons.push_pin_outlined,
                  label: 'Spot Manager',
                  path: '/spots',
                  currentPath: location,
                ),
                _NavItem(
                  icon: Icons.bar_chart_outlined,
                  label: 'Analytics',
                  path: '/analytics',
                  currentPath: location,
                ),
                _NavItem(
                  icon: Icons.people_outlined,
                  label: 'Citizens',
                  path: '/citizens',
                  currentPath: location,
                ),
                const Spacer(),
                const Divider(color: Colors.white12),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 14,
                        backgroundColor: Color(0xFF0F6E56),
                        child: Text('M',
                            style: TextStyle(
                                fontSize: 12, color: Colors.white)),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Municipal Officer',
                          style: TextStyle(
                              fontSize: 11, color: Colors.white60),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout,
                            size: 16, color: Colors.white38),
                        onPressed: () => context.go('/login'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Main content ───────────────────────────────────
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label, path, currentPath;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    final selected = currentPath == path;
    return GestureDetector(
      onTap: () => context.go(path),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF0F6E56).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: selected
                  ? const Color(0xFF82CFB5)
                  : Colors.white38,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: selected ? Colors.white : Colors.white54,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
