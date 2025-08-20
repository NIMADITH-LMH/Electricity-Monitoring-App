import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../widgets/electricity_loading_animation.dart';
import '../utils/page_transitions.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({super.key, required this.nextScreen});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );

    _logoController.forward();

    Timer(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        FadePageRoute(page: widget.nextScreen),
      );
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[900],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Scale animation for logo
            ScaleTransition(
              scale: _animation,
              child: Image.asset(
                'assets/images/logo.png',
                width: 150,
                height: 150,
                errorBuilder: (context, error, stackTrace) {
                  // Placeholder if logo.png doesn't exist yet
                  return Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.blue[800],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.electric_bolt,
                      size: 80,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 40),

            // Custom electricity loading animation
            const SizedBox(
              width: 120,
              height: 120,
              child: ElectricityLoadingAnimation(
                color: Colors.white,
                size: 100,
              ),
            ),

            const SizedBox(height: 30),

            // Animated text
            AnimatedTextKit(
              animatedTexts: [
                TypewriterAnimatedText(
                  'Electricity Monitoring',
                  textStyle: const TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  speed: const Duration(milliseconds: 100),
                ),
              ],
              totalRepeatCount: 1,
              displayFullTextOnTap: true,
            ),

            const SizedBox(height: 20),

            Text(
              'Saving Energy, Saving Money',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
