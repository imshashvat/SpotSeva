import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class PointsToast {
  static void show(
    BuildContext context, {
    required int points,
    String message = '',
  }) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => _PointsToastWidget(
        points: points,
        message: message,
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), entry.remove);
  }
}

class _PointsToastWidget extends StatefulWidget {
  final int points;
  final String message;
  const _PointsToastWidget({required this.points, required this.message});

  @override
  State<_PointsToastWidget> createState() => _PointsToastWidgetState();
}

class _PointsToastWidgetState extends State<_PointsToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _ctrl.reverse();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Center(
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(50),
              color: const Color(AppConstants.colorTeal),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('💎',
                        style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      '+${widget.points} pts',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.message.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
