import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardPage(
      emoji: '🗺️',
      title: 'Adopt Your Spot',
      desc:
          'Find a public space near you — a bench, bus stop, or park — and make it yours to care for.',
    ),
    _OnboardPage(
      emoji: '✅',
      title: 'Check In Daily',
      desc:
          'Visit your spot and check in to earn points. Build a streak for bonus rewards!',
    ),
    _OnboardPage(
      emoji: '📸',
      title: 'Report Issues',
      desc:
          'Spot a problem? Take a photo and report it. Our AI classifies it and municipal officers get notified instantly.',
    ),
    _OnboardPage(
      emoji: '🏆',
      title: 'Earn Rewards',
      desc:
          'Redeem your points for real coupons from local businesses. Be the civic hero of your ward!',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => _pages[i],
          ),
          // Page indicators
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _currentPage ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _currentPage
                        ? const Color(AppConstants.colorTeal)
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          // Next / Get Started button
          Positioned(
            bottom: 48,
            left: 32,
            right: 32,
            child: ElevatedButton(
              onPressed: () {
                if (_currentPage < _pages.length - 1) {
                  _controller.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else {
                  context.go('/home');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppConstants.colorTeal),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                _currentPage < _pages.length - 1
                    ? 'Next'
                    : 'Get Started 🚀',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          // Skip button
          if (_currentPage < _pages.length - 1)
            Positioned(
              top: 56,
              right: 24,
              child: TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('Skip',
                    style: TextStyle(color: Colors.grey)),
              ),
            ),
        ],
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  final String emoji, title, desc;
  const _OnboardPage(
      {required this.emoji, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFF0FAF7)],
        ),
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 80))
              .animate()
              .scale(duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 32),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(AppConstants.colorTeal),
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 16),
          Text(
            desc,
            style: const TextStyle(
                fontSize: 15, color: Colors.black54, height: 1.7),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 350.ms),
        ],
      ),
    );
  }
}
