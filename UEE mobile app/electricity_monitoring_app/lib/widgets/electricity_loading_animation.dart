import 'dart:math' as math;
import 'package:flutter/material.dart';

class ElectricityLoadingAnimation extends StatefulWidget {
  final Color color;
  final double size;

  const ElectricityLoadingAnimation({
    super.key,
    this.color = Colors.white,
    this.size = 100.0,
  });

  @override
  _ElectricityLoadingAnimationState createState() =>
      _ElectricityLoadingAnimationState();
}

class _ElectricityLoadingAnimationState
    extends State<ElectricityLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Base circular progress
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                strokeWidth: 4.0,
              ),
            ),

            // Lightning bolt icon with pulse animation
            Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Icon(
                  Icons.electric_bolt,
                  color: widget.color,
                  size: widget.size * 0.5,
                ),
              ),
            ),

            // Small dots rotating around the circle
            ..._buildRotatingDots(),
          ],
        );
      },
    );
  }

  List<Widget> _buildRotatingDots() {
    final List<Widget> dots = [];
    final int dotCount = 5;

    for (int i = 0; i < dotCount; i++) {
      final double angle =
          (i / dotCount) * 2 * 3.14 + (_animationController.value * 2 * 3.14);

      final double x = widget.size / 2 * 0.8 * cos(angle);
      final double y = widget.size / 2 * 0.8 * sin(angle);

      dots.add(
        Transform.translate(
          offset: Offset(x, y),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }

    return dots;
  }
}

// Helper functions to calculate sine and cosine
double sin(double x) => math.sin(x);
double cos(double x) => math.cos(x);
