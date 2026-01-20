import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../services/supabase_config.dart';
import '../../../core/services/session_service.dart';
import '../../../services/location_tracking_service.dart';

class SosAlertScreen extends StatefulWidget {
  final String? bookingId;
  final String? providerId;

  const SosAlertScreen({
    Key? key,
    this.bookingId,
    this.providerId,
  }) : super(key: key);

  @override
  State<SosAlertScreen> createState() => _SosAlertScreenState();
}

class _SosAlertScreenState extends State<SosAlertScreen> {
  bool _isSosActive = false;
  bool _isLoading = false;
  Position? _currentLocation;
  List<Map<String, dynamic>> _emergencyContacts = [];
  final List<String> _sosReasons = [
    'Unsafe Behavior',
    'Suspicious Activity',
    'Injury/Medical Emergency',
    'Property Damage',
    'Lost Items',
    'Other',
  ];
  String? _selectedReason;

  @override
  void initState() {
    super.initState();
    _loadEmergencyContacts();
  }

  Future<void> _loadEmergencyContacts() async {
    try {
      final userId = await SessionService.getUserId();
      if (userId == null) return;

      final response = await SupabaseConfig.client
          .from('emergency_contacts')
          .select()
          .eq('customer_id', userId)
          .order('created_at', ascending: true);

      setState(() {
        _emergencyContacts = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error loading emergency contacts: $e');
    }
  }

  Future<void> _triggerSosAlert() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a reason for SOS'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get current location
      final position = await LocationTrackingService.getCurrentLocation();
      if (position != null) {
        _currentLocation = position;
      }

      final userId = await SessionService.getUserId();
      if (userId == null) throw 'User not authenticated';

      // Create SOS alert in database
      await SupabaseConfig.client.from('sos_alerts').insert({
        'user_id': userId,
        'booking_id': widget.bookingId,
        'provider_id': widget.providerId,
        'reason': _selectedReason,
        'latitude': _currentLocation?.latitude ?? 0,
        'longitude': _currentLocation?.longitude ?? 0,
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Notify emergency contacts
      for (var contact in _emergencyContacts) {
        // In real app, send SMS/call notifications
        print('📞 Notifying ${contact['contact_name']} at ${contact['contact_phone']}');
      }

      // Notify authorities if available
      if (widget.bookingId != null) {
        // Notify provider/support
        print('🚨 SOS Alert sent for booking: ${widget.bookingId}');
      }

      setState(() {
        _isSosActive = true;
        _isLoading = false;
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('SOS Alert Activated'),
            icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Your emergency alert has been sent to:',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ..._emergencyContacts.map((contact) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contact['contact_name'] ?? 'Contact',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  contact['contact_phone'] ?? '',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                if (_emergencyContacts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No emergency contacts added'),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error triggering SOS: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelSosAlert() async {
    try {
      final currentUserId = await SessionService.getUserId();
      final response = await SupabaseConfig.client
          .from('sos_alerts')
          .update({'status': 'cancelled', 'cancelled_at': DateTime.now().toIso8601String()})
          .eq('customer_id', currentUserId ?? '')
          .eq('status', 'active')
          .select();

      if (response.isNotEmpty) {
        setState(() => _isSosActive = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SOS alert cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error cancelling SOS: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isSosActive ? Colors.red.shade50 : Colors.white,
      appBar: AppBar(
        title: const Text('Emergency SOS'),
        centerTitle: true,
        backgroundColor: _isSosActive ? Colors.red : Colors.red.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isSosActive)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 40),
                    const SizedBox(height: 12),
                    const Text(
                      'SOS Alert Active',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your location and emergency contacts have been notified.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ],
                ),
              )
            else ...[
              const Text(
                'Emergency SOS Alert',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF181511),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Send an emergency alert to your emergency contacts and authorities',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF5F758C),
                ),
              ),
              const SizedBox(height: 24),

              // Reason Selection
              const Text(
                'Select Reason',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF181511),
                ),
              ),
              const SizedBox(height: 12),
              Column(
                children: _sosReasons.map((reason) {
                  final isSelected = _selectedReason == reason;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? Colors.red : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: isSelected ? Colors.red.shade50 : Colors.white,
                      ),
                      child: RadioListTile<String>(
                        title: Text(reason),
                        value: reason,
                        groupValue: _selectedReason,
                        onChanged: (value) {
                          setState(() => _selectedReason = value);
                        },
                        activeColor: Colors.red,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Emergency Contacts
              const Text(
                'Emergency Contacts to Notify',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF181511),
                ),
              ),
              const SizedBox(height: 12),
              if (_emergencyContacts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.amber.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'No Emergency Contacts',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add contacts in Settings to receive notifications',
                              style: TextStyle(fontSize: 12, color: Colors.amber.shade700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: _emergencyContacts.map((contact) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person, color: Colors.blue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    contact['contact_name'] ?? 'Contact',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    contact['contact_phone'] ?? '',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF5F758C)),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 32),
            ],

            // Action Buttons
            if (!_isSosActive)
              ElevatedButton(
                onPressed: _isLoading ? null : _triggerSosAlert,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Trigger SOS Alert',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              )
            else
              ElevatedButton(
                onPressed: _cancelSosAlert,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cancel SOS Alert',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
