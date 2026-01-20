import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MethodSelectionScreen extends StatefulWidget {
  final double totalAmount;

  const MethodSelectionScreen({super.key, this.totalAmount = 12000.0});

  @override
  State<MethodSelectionScreen> createState() => _MethodSelectionScreenState();
}

class _MethodSelectionScreenState extends State<MethodSelectionScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.digital;
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _proceedToReview() {
    if (_selectedMethod == PaymentMethod.digital) {
      // Validate card details
      if (_cardNumberController.text.isEmpty ||
          _expiryController.text.isEmpty ||
          _cvvController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all card details'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Proceeding with ${_selectedMethod == PaymentMethod.digital ? 'Digital Payment' : 'Cash Payment'}',
        ),
      ),
    );

    // Navigate to next screen
    // Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F7F6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF181511)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payment Method',
          style: TextStyle(color: Color(0xFF181511), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress Indicators
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildProgressDot(false),
                const SizedBox(width: 8),
                _buildProgressDot(false),
                const SizedBox(width: 8),
                _buildProgressDot(true), // Current step
                const SizedBox(width: 8),
                _buildProgressDot(false),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                // Headline
                const Text(
                  'Select Payment Method',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF181511),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose how you would like to pay for your service.',
                  style: TextStyle(fontSize: 16, color: Color(0xFF897961), height: 1.5),
                ),
                const SizedBox(height: 24),

                // Digital Payment Option
                GestureDetector(
                  onTap: () => setState(() => _selectedMethod = PaymentMethod.digital),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedMethod == PaymentMethod.digital
                            ? const Color(0xFFEC9213)
                            : const Color(0xFFE6E1DB),
                        width: _selectedMethod == PaymentMethod.digital ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'Secure Digital Payment',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF181511),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEC9213).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'Recommended',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFEC9213),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Funds held in Escrow until job is complete',
                                      style: TextStyle(fontSize: 14, color: Color(0xFF897961)),
                                    ),
                                  ],
                                ),
                              ),
                              Radio<PaymentMethod>(
                                value: PaymentMethod.digital,
                                groupValue: _selectedMethod,
                                onChanged: (value) => setState(() => _selectedMethod = value!),
                                activeColor: const Color(0xFFEC9213),
                              ),
                            ],
                          ),
                        ),

                        // Card Input Fields (only shown when digital is selected)
                        if (_selectedMethod == PaymentMethod.digital)
                          Container(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            decoration: const BoxDecoration(
                              border: Border(top: BorderSide(color: Color(0xFFE6E1DB))),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                // Card Number
                                const Text(
                                  'Card Number',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF897961),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _cardNumberController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(16),
                                    _CardNumberFormatter(),
                                  ],
                                  decoration: InputDecoration(
                                    hintText: '0000 0000 0000 0000',
                                    hintStyle: const TextStyle(color: Color(0xFFB0A89A)),
                                    prefixIcon: const Icon(Icons.credit_card, color: Color(0xFF897961)),
                                    suffixIcon: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.8),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Container(
                                          width: 16,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.8),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                      ],
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF8F7F6),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFFE6E1DB)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFFE6E1DB)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFFEC9213)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Expiry and CVV
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Expiry Date',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF897961),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          TextField(
                                            controller: _expiryController,
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter.digitsOnly,
                                              LengthLimitingTextInputFormatter(4),
                                              _ExpiryDateFormatter(),
                                            ],
                                            decoration: InputDecoration(
                                              hintText: 'MM/YY',
                                              hintStyle: const TextStyle(color: Color(0xFFB0A89A)),
                                              filled: true,
                                              fillColor: const Color(0xFFF8F7F6),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: const BorderSide(color: Color(0xFFE6E1DB)),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: const BorderSide(color: Color(0xFFE6E1DB)),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: const BorderSide(color: Color(0xFFEC9213)),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'CVV / CVC',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF897961),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          TextField(
                                            controller: _cvvController,
                                            keyboardType: TextInputType.number,
                                            obscureText: true,
                                            inputFormatters: [
                                              FilteringTextInputFormatter.digitsOnly,
                                              LengthLimitingTextInputFormatter(3),
                                            ],
                                            decoration: InputDecoration(
                                              hintText: '123',
                                              hintStyle: const TextStyle(color: Color(0xFFB0A89A)),
                                              suffixIcon: const Icon(Icons.help_outline, color: Color(0xFF897961), size: 18),
                                              filled: true,
                                              fillColor: const Color(0xFFF8F7F6),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: const BorderSide(color: Color(0xFFE6E1DB)),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: const BorderSide(color: Color(0xFFE6E1DB)),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: const BorderSide(color: Color(0xFFEC9213)),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Trust Indicator
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.verified_user, color: Colors.green, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Your payment is protected by Escrow Shield.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.green[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Cash Option
                GestureDetector(
                  onTap: () => setState(() => _selectedMethod = PaymentMethod.cash),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedMethod == PaymentMethod.cash
                            ? const Color(0xFFEC9213)
                            : const Color(0xFFE6E1DB),
                        width: _selectedMethod == PaymentMethod.cash ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Cash',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF181511),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Pay provider directly after service',
                                style: TextStyle(fontSize: 14, color: Color(0xFF897961)),
                              ),
                            ],
                          ),
                        ),
                        Radio<PaymentMethod>(
                          value: PaymentMethod.cash,
                          groupValue: _selectedMethod,
                          onChanged: (value) => setState(() => _selectedMethod = value!),
                          activeColor: const Color(0xFFEC9213),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // Sticky Footer
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFE6E1DB))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total to pay',
                    style: TextStyle(fontSize: 14, color: Color(0xFF897961)),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '৳${widget.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF181511),
                        ),
                      ),
                      const Text(
                        'Includes taxes & fees',
                        style: TextStyle(fontSize: 11, color: Color(0xFF897961)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _proceedToReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC9213),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 6,
                  shadowColor: const Color(0xFFEC9213).withOpacity(0.3),
                ),
                child: const Text(
                  'Continue to Review',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressDot(bool isActive) {
    return Container(
      width: 32,
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFEC9213) : const Color(0xFFE6E1DB),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

enum PaymentMethod { digital, cash }

// Card Number Formatter
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

// Expiry Date Formatter
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      if (i == 2) {
        buffer.write('/');
      }
      buffer.write(text[i]);
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}