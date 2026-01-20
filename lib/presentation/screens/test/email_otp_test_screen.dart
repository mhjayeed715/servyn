import 'package:flutter/material.dart';
import 'package:servyn/core/services/supabase_service.dart';

/// Test screen to demonstrate Email OTP functionality
/// 
/// This shows how the random 6-digit OTP generation works
class EmailOtpTestScreen extends StatefulWidget {
  const EmailOtpTestScreen({Key? key}) : super(key: key);

  @override
  State<EmailOtpTestScreen> createState() => _EmailOtpTestScreenState();
}

class _EmailOtpTestScreenState extends State<EmailOtpTestScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  String _status = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() {
      _isLoading = true;
      _status = 'Generating OTP...';
    });

    try {
      await SupabaseService.sendEmailOtp(_emailController.text);
      setState(() {
        _status = '✅ OTP sent! Check console for the 6-digit code.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = '📧 OTP Generated: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _isLoading = true;
      _status = 'Verifying OTP...';
    });

    try {
      final userId = await SupabaseService.verifyEmailOtp(
        _emailController.text,
        _otpController.text,
      );
      setState(() {
        _status = '✅ OTP Verified Successfully!\nUser ID: $userId';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Verification Failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email OTP Test'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Test Email OTP System',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Enter an email to generate a random 6-digit OTP',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            
            // Email Input
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            
            // Send OTP Button
            ElevatedButton(
              onPressed: _isLoading ? null : _sendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Generate & Send OTP',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 30),
            
            // OTP Input
            TextField(
              controller: _otpController,
              decoration: InputDecoration(
                labelText: 'Enter OTP (6 digits)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.lock),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 10),
            
            // Verify Button
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Verify OTP',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 30),
            
            // Status Display
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                _status.isEmpty ? 'Status will appear here...' : _status,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 20),
            
            // Info Card
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'ℹ️ How it works:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text('1. Enter your email address'),
                  Text('2. Click "Generate & Send OTP"'),
                  Text('3. Check the console/debug output for the OTP'),
                  Text('4. Enter the OTP and click "Verify"'),
                  SizedBox(height: 10),
                  Text(
                    '📧 Email from: Servyn Team <jayedhossain809@gmail.com>',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '🔐 OTP: Random 6-digit code (100000-999999)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
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
