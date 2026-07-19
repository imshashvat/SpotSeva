import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'injection_container.dart' as di;
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/spot/spot_bloc.dart';
import 'presentation/bloc/report/report_bloc.dart';
import 'presentation/bloc/points/points_bloc.dart';
import 'presentation/bloc/reward/reward_bloc.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/map_screen.dart';
import 'presentation/screens/spot_detail_screen.dart';
import 'presentation/screens/report_screen.dart';
import 'presentation/screens/profile_screen.dart';
import 'presentation/screens/leaderboard_screen.dart';
import 'presentation/screens/rewards_screen.dart';
import 'presentation/screens/coupon_qr_screen.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/screens/home_shell_screen.dart';

class AdoptASpotApp extends StatelessWidget {
  const AdoptASpotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AuthBloc>()),
        BlocProvider(create: (_) => di.sl<SpotBloc>()),
        BlocProvider(create: (_) => di.sl<ReportBloc>()),
        BlocProvider(create: (_) => di.sl<PointsBloc>()),
        BlocProvider(create: (_) => di.sl<RewardBloc>()),
      ],
      child: MaterialApp.router(
        title: 'SpotSeva — Adopt-a-Spot',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        routerConfig: _router,
      ),
    );
  }

  ThemeData _buildTheme() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0F6E56),
        brightness: Brightness.light,
      ),
    );
    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0F6E56),
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF0F6E56),
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF0F6E56).withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

// ── Navigation Shell (Bottom Nav) ──────────────────────────────
final _mapNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'map');
final _leaderboardNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'lb');
final _rewardsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rewards');
final _profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboard',
      builder: (_, __) => const OnboardingScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          HomeShellScreen(navigationShell: navigationShell),
      branches: [
        // Branch 1: Map
        StatefulShellBranch(
          navigatorKey: _mapNavigatorKey,
          routes: [
            GoRoute(
              path: '/home',
              builder: (_, __) => const MapScreen(),
              routes: [
                GoRoute(
                  path: 'spot/:spotId',
                  builder: (_, state) =>
                      SpotDetailScreen(spotId: state.pathParameters['spotId']!),
                ),
                GoRoute(
                  path: 'report/:spotId',
                  builder: (_, state) =>
                      ReportScreen(spotId: state.pathParameters['spotId']!),
                ),
              ],
            ),
          ],
        ),
        // Branch 2: Leaderboard
        StatefulShellBranch(
          navigatorKey: _leaderboardNavigatorKey,
          routes: [
            GoRoute(path: '/leaderboard', builder: (_, __) => const LeaderboardScreen()),
          ],
        ),
        // Branch 3: Rewards
        StatefulShellBranch(
          navigatorKey: _rewardsNavigatorKey,
          routes: [
            GoRoute(
              path: '/rewards',
              builder: (_, __) => const RewardsScreen(),
              routes: [
                GoRoute(
                  path: 'coupon/:rewardId',
                  builder: (_, state) =>
                      CouponQRScreen(rewardId: state.pathParameters['rewardId']!),
                ),
              ],
            ),
          ],
        ),
        // Branch 4: Profile
        StatefulShellBranch(
          navigatorKey: _profileNavigatorKey,
          routes: [
            GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          ],
        ),
      ],
    ),
  ],
);
