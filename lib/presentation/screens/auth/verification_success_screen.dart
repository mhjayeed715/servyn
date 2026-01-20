import 'package:flutter/material.dart';
import 'dart:async';
import '../../theme/colors.dart';
import '../provider/provider_dashboard_screen.dart';
import '../customer/home_screen.dart';

class VerificationSuccessScreen extends StatefulWidget {
  final String userType;
  final String verificationType; // 'email', 'phone', 'document'
  
  const VerificationSuccessScreen({
    super.key,
    this.userType = 'customer',
    this.verificationType = 'email',
  });

  @override
  State<VerificationSuccessScreen> createState() =>
      _VerificationSuccessScreenState();
}

class _VerificationSuccessScreenState extends State<VerificationSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _redirectTimer;
  int _secondsRemaining = 3;

  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    // Start animation
    _animationController.forward();

    // Start countdown timer
    _startRedirectTimer();
  }

  void _startRedirectTimer() {
    _redirectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        _navigateToDashboard();
      }
    });
  }

  void _navigateToDashboard() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => widget.userType == 'customer'
              ? const HomeScreen()
              : const ProviderDashboardScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  String _getVerificationMessage() {
    switch (widget.verificationType) {
      case 'email':
        return 'Your email address has been successfully confirmed. Your account is now secure.';
      case 'phone':
        return 'Your phone number has been successfully verified. Your account is now active.';
      case 'document':
        return 'Your documents have been verified. You can now start providing services.';
      default:
        return 'Verification successful. Your account is now ready to use.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      body: SafeArea(
        child: Column(
          children: [
            // Top Spacer
            SizedBox(height: screenHeight * 0.1),

            // Main Content Area
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success Icon with Animation
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981), // Success green
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.3),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 56,
                          weight: 700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Text Stack
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const Text(
                          'Verified!',
                          style: TextStyle(
                            color: Color(0xFF101418),
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _getVerificationMessage(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF5E758D),
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Auto-redirect Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryBlue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Redirecting in ${_secondsRemaining}s...',
                          style: const TextStyle(
                            color: Color(0xFF5E758D),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Actions Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFF5F7F8).withOpacity(0),
                    const Color(0xFFF5F7F8),
                    const Color(0xFFF5F7F8),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Primary Action Button
                  ElevatedButton(
                    onPressed: () {
                      _redirectTimer?.cancel();
                      _navigateToDashboard();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: AppColors.primaryBlue.withOpacity(0.3),
                    ),
                    child: const Text(
                      'Continue to Dashboard',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Manual Link
                  TextButton(
                    onPressed: () {
                      _redirectTimer?.cancel();
                      _navigateToDashboard();
                    },
                    child: const Text(
                      'Not redirecting? Click here.',
                      style: TextStyle(
                        color: Color(0xFF5E758D),
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFFCBD5E1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
