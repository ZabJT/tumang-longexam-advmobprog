import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0.0, -1.0)).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
        );

    // Start animation
    _animationController.forward();

    // Navigate after loading
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    // Wait for 2 seconds to show the loading screen
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // Start the loading screen sliding up
      _slideController.forward();

      // Always start as unauthenticated - navigate to public home
      print(
        'Loading Screen - Starting as unauthenticated, redirecting to /public-home',
      );
      Navigator.pushReplacementNamed(context, '/public-home');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // Get adaptive brand color based on theme
  Color _getBrandColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? const Color(0xFF4A5A7A)
        : const Color(0xFF202A44); // Lighter blue for dark mode
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Scaffold(
        backgroundColor: _getBrandColor(context), // Adaptive brand color
        body: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Logo/Image
                      Image.asset(
                        'assets/images/Car_Icon.png',
                        width: 300.w,
                        height: 300.h,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 300.w,
                            height: 300.h,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.store,
                              size: 120,
                              color: Theme.of(context).primaryColor,
                            ),
                          );
                        },
                      ),

                      // Subtle tagline text - overlapping the image
                      Transform.translate(
                        offset: Offset(
                          0,
                          -80.h,
                        ), // Move text up to be only 10px from the image
                        child: Text(
                          'Legends Don\'t Come Stock, Drive Now with Z-Customs',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontStyle: FontStyle.italic,
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w300,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
