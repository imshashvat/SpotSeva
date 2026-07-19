import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';

class CouponQRScreen extends StatelessWidget {
  final String rewardId;
  const CouponQRScreen({super.key, required this.rewardId});

  @override
  Widget build(BuildContext context) {
    // The coupon code is passed as extra from the router
    final couponCode = (GoRouterState.of(context).extra as String?) ?? 'SPOTSEVA-DEMO';

    return Scaffold(
      backgroundColor: const Color(0xFF0F6E56),
      appBar: AppBar(
        title: const Text('Your Coupon'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/rewards'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '🎉 Coupon Redeemed!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Show this QR to the merchant',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 32),
              // QR Code
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: couponCode,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: couponCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Coupon code copied!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(AppConstants.colorTeal)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              couponCode,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(AppConstants.colorTeal),
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.copy,
                                size: 16,
                                color: Color(AppConstants.colorTeal)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '⚠️ Valid for single use only.\nExpires in 30 days.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
