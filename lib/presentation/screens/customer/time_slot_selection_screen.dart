import 'package:flutter/material.dart';
import 'service_booking_flow_screen.dart';
import 'provider_list_screen.dart';
import '../payment/payment_method_selection_screen.dart';
import '../../../services/supabase_config.dart';
import 'home_screen.dart';

class TimeSlotSelectionScreen extends StatefulWidget {
  final ServiceCategory serviceCategory;
  final String location;
  final ProviderInfo provider;

  const TimeSlotSelectionScreen({
    super.key,
    required this.serviceCategory,
    required this.location,
    required this.provider,
  });

  @override
  State<TimeSlotSelectionScreen> createState() => _TimeSlotSelectionScreenState();
}

class _TimeSlotSelectionScreenState extends State<TimeSlotSelectionScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  final List<String> _timeSlots = [
    '08:00 AM',
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '01:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
    '05:00 PM',
    '06:00 PM',
    '07:00 PM',
  ];

  List<String> _bookedSlots = [];
  bool _isLoadingSlots = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableSlots();
  }

  Future<void> _loadAvailableSlots() async {
    setState(() => _isLoadingSlots = true);

    // Simulate API call to get booked slots
    await Future.delayed(const Duration(seconds: 1));

    // Mock booked slots
    setState(() {
      _bookedSlots = ['09:00 AM', '12:00 PM', '03:00 PM'];
      _isLoadingSlots = false;
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _selectedTimeSlot = null;
    });
    _loadAvailableSlots();
  }

  void _confirmBooking() {
    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a time slot'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Service', widget.serviceCategory.name),
            const SizedBox(height: 8),
            _buildInfoRow('Provider', widget.provider.name),
            const SizedBox(height: 8),
            _buildInfoRow('Date', '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
            const SizedBox(height: 8),
            _buildInfoRow('Time', _selectedTimeSlot!),
            const SizedBox(height: 8),
            _buildInfoRow('Location', widget.location),
            const SizedBox(height: 8),
            _buildInfoRow('Price', '৳${widget.provider.pricePerHour.toInt()}/hr'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'If provider declines, we\'ll automatically match you with the next available provider',
                      style: TextStyle(fontSize: 12, color: Color(0xFF181511)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF897961))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _goToPayment();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC9213),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Proceed to Payment', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _goToPayment() async {
    // Navigate to payment method selection
    final paymentResult = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentMethodSelectionScreen(
          amount: widget.provider.pricePerHour,
          bookingId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        ),
      ),
    );

    if (paymentResult != null && paymentResult['confirmed'] == true) {
      _processBooking();
    }
  }

  Future<void> _processBooking() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFFEC9213)),
                SizedBox(height: 16),
                Text('Processing booking...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Get current user ID
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Save booking to database
      await SupabaseConfig.client.from('bookings').insert({
        'customer_id': userId,
        'provider_id': widget.provider.id,
        'service_category': widget.serviceCategory.name,
        'service_location': widget.location,
        'scheduled_date': _selectedDate.toIso8601String().split('T')[0],
        'scheduled_time': _selectedTimeSlot,
        'estimated_price': widget.provider.pricePerHour,
        'status': 'confirmed',
        'payment_status': 'paid',
      });

      // Booking successful
      Navigator.pop(context); // Close loading dialog
      _showSuccessDialog();
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      
      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Booking Failed'),
            content: Text('Error: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showSuccessDialog({bool isRematched = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 60, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'Booking Confirmed!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF181511)),
            ),
            const SizedBox(height: 8),
            Text(
              isRematched ? 'Rematched with a new provider' : 'Your service request has been confirmed',
              style: const TextStyle(color: Color(0xFF897961)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Service: ${widget.serviceCategory.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF181511)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Provider: ${widget.provider.name}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF897961)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} at $_selectedTimeSlot',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF897961)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              // Navigate back to home screen, removing all booking flow screens
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC9213),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF897961))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF181511))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF181511)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Time Slot',
          style: TextStyle(color: Color(0xFF181511), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            color: Colors.white,
            child: Row(
              children: [
                _buildProgressStep(1, 'Category', false),
                _buildProgressLine(),
                _buildProgressStep(2, 'Location', false),
                _buildProgressLine(),
                _buildProgressStep(3, 'Provider', false),
                _buildProgressLine(),
                _buildProgressStep(4, 'Time', true),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Provider Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: widget.serviceCategory.color.withOpacity(0.2),
                          child: Icon(widget.serviceCategory.icon, color: widget.serviceCategory.color, size: 30),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.provider.name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF181511)),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.provider.rating.toStringAsFixed(1),
                                    style: const TextStyle(color: Color(0xFF897961)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '৳${widget.provider.pricePerHour.toInt()}/hr',
                                    style: const TextStyle(
                                      color: Color(0xFFEC9213),
                                      fontWeight: FontWeight.bold,
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
                ),

                const SizedBox(height: 24),

                const Text(
                  'Select Date',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF181511)),
                ),
                const SizedBox(height: 12),

                // Date Picker (Next 7 days)
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 7,
                    itemBuilder: (context, index) {
                      final date = DateTime.now().add(Duration(days: index));
                      final isSelected = _selectedDate.day == date.day &&
                          _selectedDate.month == date.month &&
                          _selectedDate.year == date.year;

                      return GestureDetector(
                        onTap: () => _selectDate(date),
                        child: Container(
                          width: 70,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFEC9213) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFEC9213) : const Color(0xFFE6E1DB),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getDayName(date.weekday),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected ? Colors.white : const Color(0xFF897961),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : const Color(0xFF181511),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getMonthName(date.month),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected ? Colors.white : const Color(0xFF897961),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Select Time Slot',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF181511)),
                ),
                const SizedBox(height: 12),

                // Time Slots
                if (_isLoadingSlots)
                  const Center(child: CircularProgressIndicator(color: Color(0xFFEC9213)))
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _timeSlots.length,
                    itemBuilder: (context, index) {
                      final slot = _timeSlots[index];
                      final isBooked = _bookedSlots.contains(slot);
                      final isSelected = _selectedTimeSlot == slot;

                      return GestureDetector(
                        onTap: isBooked ? null : () => setState(() => _selectedTimeSlot = slot),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isBooked
                                ? Colors.grey[200]
                                : isSelected
                                    ? const Color(0xFFEC9213)
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isBooked
                                  ? Colors.grey[300]!
                                  : isSelected
                                      ? const Color(0xFFEC9213)
                                      : const Color(0xFFE6E1DB),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              slot,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isBooked
                                    ? Colors.grey[500]
                                    : isSelected
                                        ? Colors.white
                                        : const Color(0xFF181511),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _confirmBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC9213),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            child: const Text(
              'Confirm Booking',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildProgressStep(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFEC9213) : const Color(0xFFE6E1DB),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF897961),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? const Color(0xFFEC9213) : const Color(0xFF897961),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine() {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: const Color(0xFFE6E1DB),
      ),
    );
  }
}
