import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'escrow_confirmation_screen.dart';

class PaymentMethodSelectionScreen extends StatefulWidget {
  final double amount;
  final String bookingId;

  const PaymentMethodSelectionScreen({
    Key? key,
    required this.amount,
    required this.bookingId,
  }) : super(key: key);

  @override
  State<PaymentMethodSelectionScreen> createState() => _PaymentMethodSelectionScreenState();
}

class _PaymentMethodSelectionScreenState extends State<PaymentMethodSelectionScreen> {
  String _selectedMethod = 'digital';
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
    if (_selectedMethod == 'digital') {
      // Validate card details
      if (_cardNumberController.text.isEmpty ||
          _expiryController.text.isEmpty ||
          _cvvController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all card details')),
        );
        return;
      }

      // Show escrow confirmation
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => EscrowConfirmationSheet(
          amount: widget.amount,
          bookingId: widget.bookingId,
        ),
      );
    } else {
      // Cash payment - proceed directly
      Navigator.pop(context, {'method': 'cash', 'confirmed': true});
    }
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
          style: TextStyle(
            color: Color(0xFF181511),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
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
                _buildProgressDot(false),
                _buildProgressDot(true),
                _buildProgressDot(false),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Payment Method',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF181511),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose how you would like to pay for your service.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF897961),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Digital Payment Option
                  GestureDetector(
                    onTap: () => setState(() => _selectedMethod = 'digital'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedMethod == 'digital'
                              ? const Color(0xFFEC9213)
                              : const Color(0xFFE6E1DB),
                          width: _selectedMethod == 'digital' ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
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
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEC9213).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'Recommended',
                                            style: TextStyle(
                                              fontSize: 12,
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
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF897961),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Radio<String>(
                                value: 'digital',
                                groupValue: _selectedMethod,
                                onChanged: (value) => setState(() => _selectedMethod = value!),
                                activeColor: const Color(0xFFEC9213),
                              ),
                            ],
                          ),

                          // Card Input Fields (visible when selected)
                          if (_selectedMethod == 'digital') ...[
                            const Divider(height: 32),
                            // Card Number
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Card Number',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF897961),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _cardNumberController,
                                  decoration: InputDecoration(
                                    hintText: '0000 0000 0000 0000',
                                    prefixIcon: const Icon(Icons.credit_card, color: Color(0xFF897961)),
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
                                    filled: true,
                                    fillColor: const Color(0xFFF8F7F6),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(16),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Expiry & CVV
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
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _expiryController,
                                        decoration: InputDecoration(
                                          hintText: 'MM/YY',
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
                                          filled: true,
                                          fillColor: const Color(0xFFF8F7F6),
                                        ),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          LengthLimitingTextInputFormatter(4),
                                        ],
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
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _cvvController,
                                        decoration: InputDecoration(
                                          hintText: '123',
                                          suffixIcon: const Icon(Icons.help_outline, color: Color(0xFF897961), size: 18),
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
                                          filled: true,
                                          fillColor: const Color(0xFFF8F7F6),
                                        ),
                                        keyboardType: TextInputType.number,
                                        obscureText: true,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          LengthLimitingTextInputFormatter(3),
                                        ],
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
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.verified_user, color: Colors.green, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Your payment is protected by Escrow Shield.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Cash Option
                  GestureDetector(
                    onTap: () => setState(() => _selectedMethod = 'cash'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedMethod == 'cash'
                              ? const Color(0xFFEC9213)
                              : const Color(0xFFE6E1DB),
                          width: _selectedMethod == 'cash' ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
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
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF897961),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Radio<String>(
                            value: 'cash',
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
          ),

          // Sticky Footer
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total to pay',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF897961),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '৳${widget.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF181511),
                          ),
                        ),
                        const Text(
                          'Includes taxes & fees',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF897961),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _proceedToReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEC9213),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'Continue to Review',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDot(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 32,
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFEC9213) : const Color(0xFFE6E1DB),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
