import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'presentation/screens/auth/splash_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/registration_screen.dart';
import 'presentation/screens/auth/otp_verification_screen.dart';
import 'presentation/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/theme_provider.dart';
import 'services/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocaleProvider, ThemeProvider>(
      builder: (context, localeProvider, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          
          // Theme - Apply proper theme data
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: themeProvider.themeMode,
          
          // Localization
          locale: localeProvider.locale,
          supportedLocales: const [
            Locale('en', ''),
            Locale('bn', ''),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (locale, supportedLocales) {
            if (locale == null) {
              return supportedLocales.first;
            }
            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale.languageCode) {
                return supportedLocale;
              }
            }
            return supportedLocales.first;
          },
          
          // Use builder to apply theme colors to system UI
          builder: (context, child) {
            return child ?? const SizedBox.shrink();
          },
          
          // Routes
          initialRoute: '/splash',
          routes: {
            '/splash': (_) => const SplashScreen(),
            '/login': (_) => const LoginScreen(userType: '',),
            '/register': (_) => const RegistrationScreen(userType: '',),
            '/otp': (_) => const OtpVerificationScreen(phoneNumber: '',),
          },
        );
      },
    );
  }
}
