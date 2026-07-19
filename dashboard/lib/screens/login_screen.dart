import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';

class DashboardLoginScreen extends StatelessWidget {
  const DashboardLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<DashboardAuthBloc, DashboardAuthState>(
      listener: (ctx, state) {
        if (state is DashboardAuthSuccess) {
          context.go('/overview');
        }
        if (state is DashboardAuthFailed) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F1117),
        body: Center(
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2330),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('📍', style: TextStyle(fontSize: 52)),
                const SizedBox(height: 16),
                const Text(
                  'SpotSeva',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Municipal Command Centre',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 40),
                BlocBuilder<DashboardAuthBloc, DashboardAuthState>(
                  builder: (_, state) {
                    final loading = state is DashboardAuthLoading;
                    return SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: loading
                            ? null
                            : () => context
                                .read<DashboardAuthBloc>()
                                .add(DashboardSignIn()),
                        icon: loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Text('G',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18)),
                        label: Text(
                            loading ? 'Signing in…' : 'Sign in with Google'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Municipal officer accounts only.\nContact your ward administrator for access.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
