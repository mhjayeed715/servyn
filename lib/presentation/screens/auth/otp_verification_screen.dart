import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/colors.dart';
import 'customer_profile_setup_screen.dart';
import 'provider_verification_screen.dart';
import '../customer/home_screen.dart';
import '../../../core/services/supabase_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String userType;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.userType = 'customer',
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  
  int _secondsRemaining = 59;
  Timer? _timer;
  bool _canResend = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Auto-focus first field
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _secondsRemaining = 59;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _resendOTP() async {
    if (_canResend) {
      try {
        await SupabaseService.sendOtp(widget.phoneNumber);
        _startTimer();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP has been resent'),
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resending OTP: $e'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _verifyOTP() async {
    String otp = _controllers.map((c) => c.text).join();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter complete OTP'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    setState(() {
      _isVerifying = true;
    });
    
    try {
      // Verify OTP via Supabase
      final userId = await SupabaseService.verifyOtp(widget.phoneNumber, otp);
      
      if (!mounted) return;
      
      if (userId != null) {
        // Check if profile already exists
        bool profileExists = false;
        
        if (widget.userType == 'customer') {
          profileExists = await SupabaseService.customerProfileExists(userId);
        } else {
          profileExists = await SupabaseService.providerProfileExists(userId);
        }
        
        if (!mounted) return;
        
        if (profileExists) {
          // Profile exists, navigate to home
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
        } else {
          // No profile, navigate to profile setup
          if (widget.userType == 'customer') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => CustomerProfileSetupScreen(userId: userId),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ProviderVerificationScreen(userId: userId),
              ),
            );
          }
        }
      } else {
        setState(() {
          _isVerifying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid OTP'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isVerifying = false;
      });
      
      // Check if OTP expired
      bool isExpired = e.toString().contains('expired') || e.toString().contains('invalid');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isExpired ? 'OTP expired. Please request a new code.' : 'Verification failed: $e'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getMaskedPhone() {
    // Format: +880 1XXX *** XXX
    if (widget.phoneNumber.length >= 4) {
      String last3 = widget.phoneNumber.substring(widget.phoneNumber.length - 2);
      String first4 = widget.phoneNumber.substring(0, 4);
      return '+880 $first4 *** **$last3';
    }
    return '+880 ${widget.phoneNumber}';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF101418)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                child: Column(
                  children: [
                    SizedBox(height: screenHeight * 0.02),
                    
                    // Icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_open,
                        color: AppColors.primaryBlue,
                        size: 30,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    
                    // Title
                    const Text(
                      'Enter OTP',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF101418),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    
                    // Description
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF64748B),
                            height: 1.5,
                          ),
                          children: [
                            const TextSpan(
                              text: 'We sent a 6-digit code to ',
                            ),
                            TextSpan(
                              text: _getMaskedPhone(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF101418),
                              ),
                            ),
                            const TextSpan(
                              text: '. Enter it below to verify your account.',
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    
                    // OTP Input Fields
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: SizedBox(
                            width: screenWidth * 0.12,
                            height: screenWidth * 0.12,
                            child: TextField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF101418),
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                hintText: '•',
                                hintStyle: const TextStyle(
                                  fontSize: 24,
                                  color: Color(0xFFCBD5E1),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(50),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(50),
                                  borderSide: const BorderSide(
                                    color: AppColors.primaryBlue,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.all(0),
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  if (index < 5) {
                                    _focusNodes[index + 1].requestFocus();
                                  } else {
                                    _focusNodes[index].unfocus();
                                  }
                                }
                              },
                              onTap: () {
                                _controllers[index].selection =
                                    TextSelection.fromPosition(
                                  TextPosition(
                                      offset: _controllers[index].text.length),
                                );
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    
                    // Timer and Resend
                    Column(
                      children: [
                        Text(
                          'Resend code in ',
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _canResend
                              ? '00:00'
                              : '00:${_secondsRemaining.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF101418),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _canResend ? _resendOTP : null,
                          child: Text(
                            'Resend Code',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _canResend
                                  ? AppColors.primaryBlue
                                  : AppColors.primaryBlue.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Verify Button
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.06,
                vertical: screenHeight * 0.02,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 8,
                    shadowColor: AppColors.primaryBlue.withOpacity(0.3),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Verify',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
          ],
        ),
      ),
    );
  }
}
