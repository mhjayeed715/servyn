import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import 'customer_profile_setup_screen.dart';
import 'provider_verification_screen.dart';

class UserTypeSelectionScreen extends StatefulWidget {
  final String userId;
  const UserTypeSelectionScreen({super.key, required this.userId});

  @override
  State<UserTypeSelectionScreen> createState() =>
      _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState extends State<UserTypeSelectionScreen> {
  String _selectedType = 'customer';

  void _continueToAuth() {
    // Navigate to appropriate profile setup screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _selectedType == 'customer'
            ? CustomerProfileSetupScreen(userId: widget.userId)
            : ProviderVerificationScreen(userId: widget.userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      body: SafeArea(
        child: Column(
          children: [
            // Back Button
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.01,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF101418)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Header Section
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.06,
                vertical: screenHeight * 0.01,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose Your Role',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF101418),
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select your account type to get started.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF5E758D),
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.008),
                      Row(
                        children: [
                          const Icon(
                            Icons.lock,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'This cannot be changed later.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: screenHeight * 0.03),

            // Options
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                child: Column(
                  children: [
                    // Customer Option
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedType = 'customer';
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _selectedType == 'customer'
                              ? AppColors.primaryBlue.withOpacity(0.05)
                              : Colors.white,
                          border: Border.all(
                            color: _selectedType == 'customer'
                                ? AppColors.primaryBlue
                                : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Icon
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _selectedType == 'customer'
                                    ? AppColors.primaryBlue.withOpacity(0.2)
                                    : const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.person,
                                color: _selectedType == 'customer'
                                    ? AppColors.primaryBlue
                                    : const Color(0xFF64748B),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Text
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'I want to hire',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF101418),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Find trusted professionals for your local needs.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF5E758D),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Radio Button
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _selectedType == 'customer'
                                    ? AppColors.primaryBlue
                                    : Colors.transparent,
                                border: Border.all(
                                  color: _selectedType == 'customer'
                                      ? AppColors.primaryBlue
                                      : const Color(0xFFCBD5E1),
                                  width: 2,
                                ),
                              ),
                              child: _selectedType == 'customer'
                                  ? const Center(
                                      child: Icon(
                                        Icons.circle,
                                        size: 10,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),

                    // Provider Option
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedType = 'provider';
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _selectedType == 'provider'
                              ? AppColors.primaryBlue.withOpacity(0.05)
                              : Colors.white,
                          border: Border.all(
                            color: _selectedType == 'provider'
                                ? AppColors.primaryBlue
                                : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Icon
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _selectedType == 'provider'
                                    ? AppColors.primaryBlue.withOpacity(0.2)
                                    : const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.work,
                                color: _selectedType == 'provider'
                                    ? AppColors.primaryBlue
                                    : const Color(0xFF64748B),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Text
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'I want to work',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF101418),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Offer your services and grow your business.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF5E758D),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Radio Button
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _selectedType == 'provider'
                                    ? AppColors.primaryBlue
                                    : Colors.transparent,
                                border: Border.all(
                                  color: _selectedType == 'provider'
                                      ? AppColors.primaryBlue
                                      : const Color(0xFFCBD5E1),
                                  width: 2,
                                ),
                              ),
                              child: _selectedType == 'provider'
                                  ? const Center(
                                      child: Icon(
                                        Icons.circle,
                                        size: 10,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Section
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.06,
                vertical: screenHeight * 0.025,
              ),
              child: Column(
                children: [
                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _continueToAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 8,
                        shadowColor: AppColors.primaryBlue.withOpacity(0.3),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.015),

                  // Security Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.verified_user,
                        size: 14,
                        color: Color(0xFF5E758D),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Secure Trust System Encrypted',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF5E758D).withOpacity(0.8),
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
