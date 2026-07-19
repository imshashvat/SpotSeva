import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';

class HomeShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const HomeShellScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        backgroundColor: Colors.white,
        indicatorColor:
            const Color(AppConstants.colorTeal).withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map,
                color: Color(AppConstants.colorTeal)),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard,
                color: Color(AppConstants.colorTeal)),
            label: 'Leaderboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_giftcard_outlined),
            selectedIcon: Icon(Icons.card_giftcard,
                color: Color(AppConstants.colorTeal)),
            label: 'Rewards',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person,
                color: Color(AppConstants.colorTeal)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
