import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import '../../../services/supabase_config.dart';
import 'package:url_launcher/url_launcher.dart';
import '../chat/chat_list_screen.dart';

class JobStatusTimelineScreen extends StatefulWidget {
  final String bookingId;

  const JobStatusTimelineScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<JobStatusTimelineScreen> createState() => _JobStatusTimelineScreenState();
}

class _JobStatusTimelineScreenState extends State<JobStatusTimelineScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _pulseController;
  Timer? _statusUpdateTimer;

  Map<String, dynamic>? _bookingData;
  Map<String, dynamic>? _providerData;
  List<Map<String, dynamic>> _statusHistory = [];
  String _currentStatus = 'pending';
  LatLng? _location;
  bool _isLoading = true;

  final Map<String, int> _statusSteps = {
    'pending': 0,
    'confirmed': 1,
    'provider_assigned': 2,
    'en_route': 3,
    'in_progress': 4,
    'completed': 5,
  };

  final List<Map<String, dynamic>> _timelineSteps = [
    {
      'status': 'confirmed',
      'title': 'Booking Confirmed',
      'description': 'We received your request.',
      'icon': Icons.check_circle,
    },
    {
      'status': 'provider_assigned',
      'title': 'Provider Assigned',
      'description': 'Provider has accepted your job.',
      'icon': Icons.badge,
    },
    {
      'status': 'en_route',
      'title': 'En Route',
      'description': 'Provider is on the way.',
      'icon': Icons.local_shipping,
    },
    {
      'status': 'in_progress',
      'title': 'Service Started',
      'description': 'Work is in progress.',
      'icon': Icons.construction,
    },
    {
      'status': 'completed',
      'title': 'Job Completed',
      'description': 'Service finished successfully.',
      'icon': Icons.check_circle_outline,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _loadBookingData();
    _startStatusUpdates();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _statusUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBookingData() async {
    try {
      // Get booking details with service category
      final supabase = SupabaseConfig.client;
      
      final bookingResponse = await supabase
          .from('bookings')
          .select('*, service_categories(*)')
          .eq('id', widget.bookingId)
          .single();

      _bookingData = bookingResponse;
      _currentStatus = _bookingData!['status'] ?? 'pending';

      // Get provider details if assigned
      if (_bookingData!['provider_id'] != null) {
        final providerResponse = await supabase
            .from('provider_profiles')
            .select('*, users(*)')
            .eq('user_id', _bookingData!['provider_id'])
            .single();

        _providerData = providerResponse;
      }

      // Get location
      if (_bookingData!['latitude'] != null && _bookingData!['longitude'] != null) {
        _location = LatLng(
          _bookingData!['latitude'],
          _bookingData!['longitude'],
        );
      }

      // Get status history
      final historyResponse = await supabase
          .from('booking_status_history')
          .select()
          .eq('booking_id', widget.bookingId)
          .order('created_at', ascending: true);

      _statusHistory = List<Map<String, dynamic>>.from(historyResponse);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading booking data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startStatusUpdates() {
    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _loadBookingData();
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openChat() async {
    // Navigate to chat screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatListScreen(),
      ),
    );
  }

  Future<void> _cancelBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text(
          'Are you sure you want to cancel this booking? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, Keep It'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final client = SupabaseConfig.client;
        await client
            .from('bookings')
            .update({'status': 'cancelled'})
            .eq('id', widget.bookingId);

        // Add to history
        await client.from('booking_status_history').insert({
          'booking_id': widget.bookingId,
          'status': 'cancelled',
          'notes': 'Cancelled by customer',
        });

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking cancelled successfully'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int get _currentStepIndex {
    return _statusSteps[_currentStatus] ?? 0;
  }

  String _getStatusTime(String status) {
    final history = _statusHistory.firstWhere(
      (h) => h['status'] == status,
      orElse: () => {},
    );

    if (history.isNotEmpty && history['created_at'] != null) {
      final time = DateTime.parse(history['created_at']);
      return TimeOfDay.fromDateTime(time).format(context);
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFEC9213)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF181511)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Order #${widget.bookingId.substring(0, 8)}',
          style: const TextStyle(
            color: Color(0xFF181511),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE6E1DB),
            height: 1,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadBookingData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Map Section
              if (_location != null)
                SizedBox(
                  height: 200,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _location!,
                      initialZoom: 15,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.servyn.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _location!,
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFEC9213).withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEC9213),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFFEC9213),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Provider Profile Card
              if (_providerData != null)
                Transform.translate(
                  offset: const Offset(0, -48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE6E1DB)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Provider photo
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                    ),
                                  ],
                                  image: _providerData!['profile_photo_url'] != null
                                      ? DecorationImage(
                                          image: NetworkImage(
                                            _providerData!['profile_photo_url'],
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                  color: _providerData!['profile_photo_url'] == null
                                      ? Colors.grey[300]
                                      : null,
                                ),
                                child: _providerData!['profile_photo_url'] == null
                                    ? const Icon(
                                        Icons.person,
                                        color: Colors.grey,
                                        size: 32,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              // Provider info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _providerData!['full_name'] ?? 'Provider',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF181511),
                                      ),
                                    ),
                                    Text(
                                      _bookingData?['service_categories']?['name'] ?? 'Service',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF897961),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Rating badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.yellow[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _providerData!['average_rating']?.toString() ?? '5.0',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _openChat,
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 40),
                                    side: const BorderSide(color: Color(0xFFE6E1DB)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Message',
                                    style: TextStyle(color: Color(0xFF181511)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (_providerData!['users']?['phone'] != null) {
                                      _makePhoneCall(_providerData!['users']['phone']);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEC9213),
                                    minimumSize: const Size(0, 40),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: const Text('Call'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Timeline Header
              Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  _providerData != null ? 0 : 24,
                  24,
                  16,
                ),
                child: const Text(
                  'Status Updates',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF181511),
                  ),
                ),
              ),

              // Timeline
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: List.generate(_timelineSteps.length, (index) {
                    final step = _timelineSteps[index];
                    final stepIndex = _statusSteps[step['status']]!;
                    final isCompleted = stepIndex <= _currentStepIndex;
                    final isActive = stepIndex == _currentStepIndex;
                    final isFuture = stepIndex > _currentStepIndex;
                    final statusTime = _getStatusTime(step['status']);

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timeline indicator
                        Column(
                          children: [
                            // Top line
                            if (index > 0)
                              Container(
                                width: 2,
                                height: 12,
                                color: isCompleted
                                    ? const Color(0xFFEC9213)
                                    : const Color(0xFFE6E1DB),
                              ),
                            // Icon
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive
                                    ? const Color(0xFFEC9213)
                                    : isFuture
                                        ? Colors.white
                                        : const Color(0xFFEC9213).withOpacity(0.1),
                                border: Border.all(
                                  color: isCompleted
                                      ? const Color(0xFFEC9213)
                                      : const Color(0xFFE6E1DB),
                                  width: 2,
                                ),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFEC9213).withOpacity(0.5),
                                          blurRadius: 15,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                step['icon'],
                                size: isActive ? 20 : 18,
                                color: isActive
                                    ? Colors.white
                                    : isCompleted
                                        ? const Color(0xFFEC9213)
                                        : const Color(0xFF897961),
                              ),
                            ),
                            // Bottom line
                            if (index < _timelineSteps.length - 1)
                              Container(
                                width: 2,
                                height: 60,
                                color: isCompleted
                                    ? const Color(0xFFEC9213)
                                    : const Color(0xFFE6E1DB),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Content
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      step['title'],
                                      style: TextStyle(
                                        fontSize: isActive ? 18 : 16,
                                        fontWeight: isActive
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        color: isActive
                                            ? const Color(0xFFEC9213)
                                            : isFuture
                                                ? const Color(0xFF897961)
                                                : const Color(0xFF181511),
                                      ),
                                    ),
                                    if (statusTime.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? const Color(0xFFEC9213).withOpacity(0.1)
                                              : const Color(0xFFF8F7F6),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          statusTime,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isActive
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isActive
                                                ? const Color(0xFFEC9213)
                                                : const Color(0xFF897961),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  step['description'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isActive
                                        ? const Color(0xFF181511)
                                        : const Color(0xFF897961),
                                  ),
                                ),
                                // Extra info for active step
                                if (isActive && _currentStatus == 'en_route')
                                  Container(
                                    margin: const EdgeInsets.only(top: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8F7F6),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFE6E1DB),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.near_me,
                                          size: 16,
                                          color: Color(0xFF897961),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Location updated recently near ${_bookingData?['address'] ?? 'your area'}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF897961),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          border: const Border(
            top: BorderSide(color: Color(0xFFE6E1DB)),
          ),
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _cancelBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF8F7F6),
              foregroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Cancel Booking',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
