import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/colors.dart';
import 'registration_screen.dart';
import 'otp_verification_screen.dart';
import '../admin/login_screen.dart';
import '../../../core/services/supabase_service.dart';

class LoginScreen extends StatefulWidget {
  final String userType;
  
  const LoginScreen({super.key, required this.userType});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _showError = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _validateAndContinue() async {
    String phone = _phoneController.text.trim().replaceAll(' ', '').replaceAll('-', '');
    
    // Remove leading 0 if present (01XXXXXXXXX → 1XXXXXXXXX)
    if (phone.startsWith('0') && phone.length == 11) {
      phone = phone.substring(1);
    }
    
    // Check for admin credentials
    if (phone == '1794506068') {
      // Redirect to admin login screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AdminLoginScreen(),
        ),
      );
      return;
    }
    
    // Bangladesh phone numbers: Valid series are 013, 014, 015, 016, 017, 018, 019
    final RegExp phoneRegex = RegExp(r'^1[3-9][0-9]{8}$');
    
    if (phone.isEmpty) {
      setState(() {
        _showError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your phone number'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    } else if (!phoneRegex.hasMatch(phone)) {
      setState(() {
        _showError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid Bangladesh number (013-019 series, e.g., 01712345678)'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      setState(() {
        _showError = false;
      });
      
      // Send OTP for login
      setState(() {
        _isLoading = true;
      });
      
      try {
        await SupabaseService.sendOtp(phone);
        
        if (!mounted) return;
        
        setState(() {
          _isLoading = false;
        });
        
        // Navigate to OTP verification
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              phoneNumber: phone,
              userType: widget.userType,
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending OTP: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: screenHeight * 0.02),
            
            // Header Section
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.06,
                vertical: screenHeight * 0.02,
              ),
              child: Column(
                children: [
                  // Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primaryBlue.withOpacity(0.2),
                          AppColors.primaryBlue.withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.handshake,
                      color: AppColors.primaryBlue,
                      size: 48,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  
                  // Title
                  Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: screenWidth * 0.075,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF101418),
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.008),
                  
                  // Subtitle
                  Text(
                    'Welcome back to Servyn',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            // Form Section
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenHeight * 0.02),
                    
                    // Show selected user type
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            widget.userType == 'customer' ? Icons.person : Icons.engineering,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Signing in as ${widget.userType == 'customer' ? 'Customer' : 'Service Provider'}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    
                    // Phone Number Input
                    Text(
                      'Phone Number',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF101418),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _showError
                              ? Colors.red
                              : const Color(0xFFE2E8F0),
                        ),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Flag and Prefix
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF9FAFB),
                              border: Border(
                                right: BorderSide(
                                  color: Color(0xFFDAE0E7),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Text(
                                  '🇧🇩',
                                  style: TextStyle(fontSize: 20),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '+880',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF101418),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Input
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              maxLength: 13,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(11),
                              ],
                              decoration: InputDecoration(
                                hintText: '1712345678',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                ),
                                border: InputBorder.none,
                                counterText: '',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                suffixIcon: _showError
                                    ? const Icon(
                                        Icons.error,
                                        color: Colors.red,
                                      )
                                    : null,
                              ),
                              onChanged: (value) {
                                if (_showError) {
                                  setState(() {
                                    _showError = false;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    if (_showError)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info,
                              size: 14,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Please enter a valid phone number.',
                              style: TextStyle(
                                fontSize: screenWidth * 0.03,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    SizedBox(height: screenHeight * 0.02),
                  ],
                ),
              ),
            ),

            // Bottom Actions
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.06,
                vertical: screenHeight * 0.02,
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _validateAndContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: Colors.blue.withOpacity(0.2),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Continue',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  
                  // Test Credentials Display (for demo purposes)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.science,
                              color: Colors.green.shade700,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Demo Test Accounts',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '📱 Phone: +8801712345678 | OTP: 123456',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const Text(
                          '📱 Phone: +8801987654321 | OTP: 123456',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const Text(
                          '📱 Phone: +8801823456789 | OTP: 654321',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '💡 Use any of these for testing',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  
                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegistrationScreen(
                                userType: widget.userType,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'Register',
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
