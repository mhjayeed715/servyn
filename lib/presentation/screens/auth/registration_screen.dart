import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/colors.dart';
import 'otp_verification_screen.dart';
import 'login_screen.dart';

class RegistrationScreen extends StatefulWidget {
  final String userType;
  
  const RegistrationScreen({super.key, required this.userType});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _showError = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _validateAndGetOTP() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Both customer and provider use phone-based registration with hardcoded OTP
      String phone = _phoneController.text.trim().replaceAll(' ', '').replaceAll('-', '');
      
      // Remove leading 0 if present (01XXXXXXXXX → 1XXXXXXXXX)
      if (phone.startsWith('0') && phone.length == 11) {
        phone = phone.substring(1);
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
        return;
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
        return;
      }
      
      setState(() {
        _showError = false;
      });
      
      // No actual OTP sending - hardcoded OTP for both
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Use OTP: 111000'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate to OTP screen
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
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      appBar: AppBar(
        backgroundColor: AppColors.neutralLight.withOpacity(0.9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF101418)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Register',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF101418),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenHeight * 0.02),
                    
                    // Hero Section
                    Text(
                      'Create your account',
                      style: TextStyle(
                        fontSize: screenWidth * 0.08,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF101418),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.012),
                    Text(
                      'Registering as ${widget.userType == 'customer' ? 'Customer' : 'Service Provider'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    
                    // Phone Input for both customer and provider
                    const Text(
                      'Mobile Number',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF101418),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _showError
                              ? Colors.red
                              : const Color(0xFFDAE0E7),
                          width: 1,
                        ),
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
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                hintText: '1XXXXXXXXX',
                                hintStyle: TextStyle(
                                  color: Color(0xFF9AAAB9),
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
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
                    
                    // Helper Text
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info,
                            size: 16,
                            color: Color(0xFF5E758D),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _showError
                                  ? 'Please enter a valid Bangladesh number.'
                                  : 'Enter 10 or 11 digits. OTP: 111000',
                              style: TextStyle(
                                fontSize: 12,
                                color: _showError
                                    ? Colors.red
                                    : const Color(0xFF5E758D),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    
                    // Trust Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.verified_user,
                          color: AppColors.primaryBlue,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Secure & Trusted Platform',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF5E758D).withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Actions
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: screenHeight * 0.02,
              ),
              child: Column(
                children: [
                  // Get OTP Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _validateAndGetOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: AppColors.primaryBlue.withOpacity(0.2),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Get OTP',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  
                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF5E758D),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginScreen(
                                userType: widget.userType,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Log in',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  
                  // Footer Links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          // TODO: Navigate to Terms of Service
                        },
                        child: const Text(
                          'Terms of Service',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9AAAB9),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      GestureDetector(
                        onTap: () {
                          // TODO: Navigate to Privacy Policy
                        },
                        child: const Text(
                          'Privacy Policy',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9AAAB9),
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
