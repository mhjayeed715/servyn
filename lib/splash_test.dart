import 'package:flutter/material.dart';

import 'presentation/screens/auth/splash_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/registration_screen.dart';
import 'presentation/screens/auth/otp_verification_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(userType: '',),
        '/register': (_) => const RegistrationScreen(userType: '',),
        '/otp': (_) => const OtpVerificationScreen(phoneNumber: '',),
      },
    );
  }
}
