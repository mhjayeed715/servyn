import 'package:flutter/material.dart';
import 'service_booking_flow_screen.dart';

class NoProvidersScreen extends StatefulWidget {
  final ServiceCategory serviceCategory;
  final String location;
  final double currentRadius;

  const NoProvidersScreen({
    super.key,
    required this.serviceCategory,
    required this.location,
    required this.currentRadius,
  });

  @override
  State<NoProvidersScreen> createState() => _NoProvidersScreenState();
}

class _NoProvidersScreenState extends State<NoProvidersScreen> {
  double _expandedRadius = 0;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _expandedRadius = widget.currentRadius + 10;
  }

  Future<void> _expandSearchArea() async {
    setState(() => _isSearching = true);

    // Simulate searching for providers in expanded area
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isSearching = false);

    // Simulate results
    final foundProviders = DateTime.now().millisecond % 10 > 3;

    if (foundProviders) {
      Navigator.pop(context, {'radius': _expandedRadius});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Found providers within ${_expandedRadius.toInt()} km'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Still no providers found. Try different time or contact support'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _scheduleLater() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule for Later'),
        content: const Text(
          'Would you like to schedule this service for a later date when providers may be available?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.popUntil(context, (route) => route.isFirst); // Return to home
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('You can try booking again later'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC9213),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _contactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.support_agent, color: Color(0xFFEC9213)),
            SizedBox(width: 8),
            Text('Contact Support'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Our support team can help you find a provider or suggest alternatives.',
              style: TextStyle(color: Color(0xFF897961)),
            ),
            const SizedBox(height: 16),
            _buildSupportOption(Icons.phone, 'Call', '+880 1234-567890'),
            const SizedBox(height: 12),
            _buildSupportOption(Icons.email, 'Email', 'support@servyn.com'),
            const SizedBox(height: 12),
            _buildSupportOption(Icons.chat, 'Live Chat', 'Available 9 AM - 9 PM'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportOption(IconData icon, String title, String details) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE6E1DB)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFEC9213), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF181511)),
                ),
                Text(
                  details,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF897961)),
                ),
              ],
            ),
          ),
        ],
      ),
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
          'No Providers Available',
          style: TextStyle(color: Color(0xFF181511), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info Icon
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off,
                size: 50,
                color: Colors.orange,
              ),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'No Providers Found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF181511),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            'We couldn\'t find any ${widget.serviceCategory.name.toLowerCase()}s available within ${widget.currentRadius.toInt()} km of your location.',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF897961),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Service Info Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Request',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF181511),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.construction,
                    'Service',
                    widget.serviceCategory.name,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.location_on,
                    'Location',
                    widget.location,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.radar,
                    'Search Radius',
                    '${widget.currentRadius.toInt()} km',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Expand Search Area Option
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.expand, color: Color(0xFFEC9213)),
                      SizedBox(width: 8),
                      Text(
                        'Expand Search Area',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF181511),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Increase the search radius to find providers further away from your location.',
                    style: TextStyle(color: Color(0xFF897961)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'Search up to:',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF181511)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: _expandedRadius,
                          min: widget.currentRadius + 5,
                          max: 50,
                          divisions: 9,
                          activeColor: const Color(0xFFEC9213),
                          label: '${_expandedRadius.toInt()} km',
                          onChanged: (value) {
                            setState(() => _expandedRadius = value);
                          },
                        ),
                      ),
                      Text(
                        '${_expandedRadius.toInt()} km',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF181511)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _isSearching ? null : _expandSearchArea,
                    icon: _isSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.search),
                    label: Text(_isSearching ? 'Searching...' : 'Search Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEC9213),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Alternative Options
          const Text(
            'Other Options',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF181511),
            ),
          ),

          const SizedBox(height: 12),

          // Schedule Later
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              onTap: _scheduleLater,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: Color(0xFF42A5F5)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Schedule for Later',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF181511),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Try booking at a different time',
                            style: TextStyle(fontSize: 12, color: Color(0xFF897961)),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF897961)),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Contact Support
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              onTap: _contactSupport,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.support_agent, color: Color(0xFFEC9213)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contact Support',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF181511),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Get help from our support team',
                            style: TextStyle(fontSize: 12, color: Color(0xFF897961)),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF897961)),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Info Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Provider availability varies by location and time. We recommend trying again during business hours (9 AM - 6 PM) for better results.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF181511)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF897961)),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(color: Color(0xFF897961)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF181511),
            ),
          ),
        ),
      ],
    );
  }
}
