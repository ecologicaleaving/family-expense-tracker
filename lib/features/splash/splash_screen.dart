import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/app_theme.dart';
/// Distinctive splash screen with Italian Brutalism aesthetic.
class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;
  late Animation<double> _scaleIcon;

  @override
  void initState() {
    super.initState();

    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _scaleIcon = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    _slideUp = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Navigate after animation completes
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.parchment,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.terracotta.withValues(alpha: 0.08),
              AppColors.parchment,
              AppColors.copper.withValues(alpha: 0.05),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Animated icon
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleIcon.value,
                      child: child,
                    );
                  },
                  child: _buildAppIcon(),
                ),

                const SizedBox(height: 32),

                // App name with animation
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeIn.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideUp.value),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Text(
                        'Spese',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 42,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        'FAMIGLIA',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.terracotta,
                          letterSpacing: 6,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Bottom tagline
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeIn.value * 0.6,
                      child: child,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 48),
                    child: Text(
                      'Gestione spese condivisa',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppColors.inkFaded,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.terracotta,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.terracotta.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Euro symbol
          Text(
            '€',
            style: GoogleFonts.playfairDisplay(
              fontSize: 64,
              fontWeight: FontWeight.w600,
              color: AppColors.cream,
            ),
          ),
          // Decorative corner accent
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
