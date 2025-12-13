import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    // Navigate to home after 3 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        context.replace('/home');
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;
    
    // Calculate responsive sizes without sizer
    final logoSize = isMobile ? screenWidth * 0.5 : screenWidth * 0.25;
    final appNameFontSize = isMobile ? screenWidth * 0.09 : 28.0;
    final taglineFontSize = isMobile ? screenWidth * 0.065 : 20.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo - lebih besar di mobile
                        Image.asset(
                          'assets/logo.gif',
                          width: logoSize,
                          height: logoSize,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 24),

                        // App Name - lebih besar di mobile
                        Text(
                          'ANIMO',
                          style: GoogleFonts.cherryBombOne(
                            fontSize: appNameFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Tagline - lebih besar di mobile
                        Text(
                          'Enjoy Watching!',
                          style: GoogleFonts.cherryBombOne(
                            fontSize: taglineFontSize,
                            color: Colors.grey.shade700,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Loading Indicator
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
