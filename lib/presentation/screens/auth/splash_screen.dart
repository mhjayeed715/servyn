import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import 'auth_choice_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToAuthChoice();
    }
  }

  void _navigateToAuthChoice() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const AuthChoiceScreen(),
      ),
    );
  }

  final List<Map<String, String>> _onboardingData = [
    {
      "title": "Welcome to Servyn",
      "description":
          "The easiest way to find reliable local help in your neighborhood.",
      "image":
          "https://lh3.googleusercontent.com/aida-public/AB6AXuCBsXGmDoRYonJmO63dNcfh9Cso1s3L4o4XYPCHOQymUObSrlgklX4_FqmMZ7XKp4tMynpJgDUGYyeHNNMSPWgWBrsNJPb1rbN0Vdi1ZXvK8TVwsYcVs_brwr_RATSj_ZF15Wifjc5gTDp9jhPvTGsajYTMm4WUIRSbDG-Aeriifhpe28ik_5aJiJA11JRdPyPJRpsApNDn9KoHhmhwWLwyCKj4xSQanXjO6xvC-iVkBczwuy-SQyoQ67dLGP46MrqLrElq5zQfDX0"
    },
    {
      "title": "Verified Trust",
      "description":
          "Every service provider is identity-verified for your safety and peace of mind.",
      "image":
          "https://lh3.googleusercontent.com/aida-public/AB6AXuCiUIaIPE5zGRwuaIVYKxYnRWMfGJULOzZAtFq7d6KzVAuJ46jz7gxn_BjiEk5f2-irtYQVXFHs9uK4mat35IW5355jyp1NOqfsvVYz0sBHBRl9qqHSOd3st7A5epTR_SbsZC8vWbpGpPjjgmekyGCxSDTMHIVEmGMc8io47I6gi1t9pznIP6D8hnmYPKLoOwFf0IFIAS42x2MsPhz5pUzqNUJzXs_Z1mEsTsM2GafqRK3UjN-3kmFAVzS7EnOf-bZWJdqTnYuzdh8"
    },
    {
      "title": "Quick Booking",
      "description":
          "Book plumbers, electricians, and cleaners in just a few taps.",
      "image":
          "https://lh3.googleusercontent.com/aida-public/AB6AXuA8HQCloYfVO9uUjtPHvbGuB__iHdZClim3Jqam4226_h-kNOs7EBV68DOWvNZv6yHW0ZnjmCakXketNOdok676F4VWkqCkGKjJAsjgZwah5JPtHbu-HGfo8HoA2qWMLHF67iTBfaQfNgMsXTUa2umO68CFgUlQDIhfzkTO0klSqMgXTjvfc68XJxA30AlHJMfAQ1z6xCn5adDotx8tSaW2_vcDjCwa6v3F8hsRByWQsZ68Fv_1KQn1NzJjkSPeNCxvb9hApxBHd-k"
    },
    {
      "title": "Start Now",
      "description":
          "Join thousands of users in Bangladesh getting things done today.",
      "image":
          "https://lh3.googleusercontent.com/aida-public/AB6AXuBAn9UHwPL7N12vXOyvvW6UuK2meTLtGv_XkTN7tyy-G49vEks7A4NpahI1v_wZUNX_zaLw9a0FFJQnuc4KxfRdTrSw9qPJ6fb9lb7t99TYiFEk1AXHBDWnLfNsSEKuL8AXFhthMpPSBV5BoEOIyseNTA0eiAbDYyVMahAD51SdXjvOO1jZtgFjRLPmJsKd11FWgWEdZW1S04anFKgz7q9EG7aPBgW5wao7vtqgD06in8sWNv2tyI9w2I0lawXBlwmmixuIUfjc4K8"
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: AppColors.neutralLight,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: screenHeight * 0.02),
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Centered Logo and Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.handyman,
                          color: AppColors.primaryBlue,
                          size: screenWidth * 0.08),
                      SizedBox(width: screenWidth * 0.02),
                      Text(
                        'Servyn',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: screenWidth * 0.075,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                  // Skip button positioned on the right
                  Positioned(
                    right: 0,
                    child: TextButton(
                      onPressed: _navigateToAuthChoice,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: const Color(0xFF64748B),
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            // Subtitle
            Text(
              'Reliable Local Services in Bangladesh',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF64748B),
                fontSize: screenWidth * 0.032,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),

            // Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingData.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final data = _onboardingData[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: double.infinity,
                          height: screenHeight * 0.35,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            image: DecorationImage(
                              image: NetworkImage(data['image']!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: screenWidth * 0.75),
                          child: Text(
                            data['title']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF101418),
                              fontSize: screenWidth * 0.065,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.012),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: screenWidth * 0.75),
                          child: Text(
                            data['description']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF64748B), // Slate-500
                              fontSize: screenWidth * 0.038,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Actions
            Padding(
              padding: EdgeInsets.fromLTRB(
                screenWidth * 0.06,
                screenHeight * 0.015,
                screenWidth * 0.06,
                screenHeight * 0.025,
              ),
              child: Column(
                children: [
                  // Pagination Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: index == _currentPage ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: index == _currentPage
                              ? AppColors.primaryBlue
                              : const Color(0xFFCBD5E1), // Slate-300
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),

                  // CTA Button - Changes based on current page
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: Colors.blue.withOpacity(0.2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == _onboardingData.length - 1
                                ? 'Get Started'
                                : 'Next',
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward,
                              size: 20, color: Colors.white),
                        ],
                      ),
                    ),
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
