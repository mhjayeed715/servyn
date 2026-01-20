import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';

/// Example widget demonstrating how to use localization in your screens
class LocalizationExampleWidget extends StatelessWidget {
  const LocalizationExampleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the localization instance
    final loc = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        // Using convenience getter
        title: Text(loc?.appName ?? 'Servyn'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Example 1: Using convenience getters
            Text(
              loc?.welcome ?? 'Welcome',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 16),
            
            // Example 2: Using translate method
            Text(
              loc?.translate('dashboard') ?? 'Dashboard',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            
            // Example 3: In buttons
            ElevatedButton(
              onPressed: () {},
              child: Text(loc?.login ?? 'Login'),
            ),
            const SizedBox(height: 16),
            
            // Example 4: In forms
            TextField(
              decoration: InputDecoration(
                labelText: loc?.phoneNumber ?? 'Phone Number',
                hintText: loc?.enterPhone ?? 'Enter your phone number',
              ),
            ),
            const SizedBox(height: 16),
            
            // Example 5: In dialogs
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(loc?.logout ?? 'Logout'),
                    content: Text(
                      loc?.translate('logout_confirmation') ?? 
                      'Are you sure you want to logout?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(loc?.cancel ?? 'Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          // Logout action
                          Navigator.pop(context);
                        },
                        child: Text(loc?.confirm ?? 'Confirm'),
                      ),
                    ],
                  ),
                );
              },
              child: Text('Show Dialog Example'),
            ),
            const SizedBox(height: 16),
            
            // Example 6: In SnackBars
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(loc?.translate('login_success') ?? 'Login successful'),
                  ),
                );
              },
              child: Text('Show SnackBar Example'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example of how to add translations to existing screens
/// 
/// BEFORE:
/// ```dart
/// Text('Dashboard')
/// Text('Welcome')
/// ```
/// 
/// AFTER:
/// ```dart
/// final loc = AppLocalizations.of(context);
/// Text(loc?.dashboard ?? 'Dashboard')
/// Text(loc?.welcome ?? 'Welcome')
/// ```
/// 
/// For new translations not in en.json/bn.json:
/// 1. Add to assets/localization/translations/en.json
/// 2. Add to assets/localization/translations/bn.json
/// 3. Optionally add convenience getter in app_localizations.dart
/// 
/// Example:
/// en.json: "my_new_key": "My New Text"
/// bn.json: "my_new_key": "আমার নতুন টেক্সট"
/// 
/// Usage: loc?.translate('my_new_key') ?? 'My New Text'
