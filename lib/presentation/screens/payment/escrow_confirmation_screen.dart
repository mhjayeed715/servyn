import 'package:flutter/material.dart';
import 'payment_status_screen.dart';

class EscrowConfirmationSheet extends StatelessWidget {
  final double amount;
  final String bookingId;

  const EscrowConfirmationSheet({
    Key? key,
    required this.amount,
    required this.bookingId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F7F6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFD0D0D0),
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF181511)),
                ),
              ],
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  // Hero Section
                  Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEC9213).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.shield_outlined,
                              color: Color(0xFFEC9213),
                              size: 44,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Your Payment is on Hold',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF181511),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4E5D6D),
                            height: 1.5,
                          ),
                          children: [
                            const TextSpan(
                              text:
                                  'To protect both you and the service provider, your payment of ',
                            ),
                            TextSpan(
                              text: '৳${amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF181511),
                              ),
                            ),
                            const TextSpan(
                              text:
                                  ' is currently held in our secure escrow vault.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Timeline
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE6E1DB)),
                    ),
                    child: Column(
                      children: [
                        _buildTimelineStep(
                          icon: Icons.check_circle,
                          iconColor: Colors.green,
                          title: 'Payment Authorized',
                          subtitle: 'Funds verified successfully',
                          isCompleted: true,
                          showConnector: true,
                          connectorColor: Colors.green,
                        ),
                        _buildTimelineStep(
                          icon: Icons.lock,
                          iconColor: const Color(0xFFEC9213),
                          title: 'Held in Escrow',
                          subtitle: 'Funds are secure',
                          isActive: true,
                          showConnector: true,
                          connectorColor: const Color(0xFFE6E1DB),
                        ),
                        _buildTimelineStep(
                          icon: Icons.radio_button_unchecked,
                          iconColor: const Color(0xFFD0D0D0),
                          title: 'Job Completion',
                          subtitle: 'Pending provider action',
                          showConnector: true,
                          connectorColor: const Color(0xFFE6E1DB),
                        ),
                        _buildTimelineStep(
                          icon: Icons.radio_button_unchecked,
                          iconColor: const Color(0xFFD0D0D0),
                          title: 'Provider Paid',
                          subtitle: 'Released upon satisfaction',
                          showConnector: false,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.shade100,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'The money will only be released to the provider once you confirm the job is done to your satisfaction.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade900,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Understand Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentStatusScreen(
                              isSuccess: true,
                              amount: amount,
                              transactionId: 'TXN${DateTime.now().millisecondsSinceEpoch}',
                              paymentMethod: 'Escrow Payment',
                              bookingId: bookingId,
                            ),
                          ),
                        );
                      },
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
                        'Understood',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool isCompleted = false,
    bool isActive = false,
    bool showConnector = true,
    Color? connectorColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isActive
                    ? iconColor.withOpacity(0.1)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: isActive
                    ? Border.all(
                        color: iconColor.withOpacity(0.3),
                        width: 2,
                      )
                    : null,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: isActive ? 18 : 24,
              ),
            ),
            if (showConnector)
              Container(
                width: 2,
                height: 32,
                color: connectorColor ?? const Color(0xFFE6E1DB),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive
                        ? const Color(0xFFEC9213)
                        : const Color(0xFF181511),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive
                        ? const Color(0xFFEC9213).withOpacity(0.8)
                        : const Color(0xFF897961),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
