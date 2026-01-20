import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import '../../../core/services/supabase_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String bookingId;

  const LiveTrackingScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  Timer? _locationUpdateTimer;
  late AnimationController _pulseController;

  // Location data
  LatLng? _providerLocation;
  LatLng? _customerLocation;
  List<LatLng> _routePoints = [];

  // Booking data
  Map<String, dynamic>? _bookingData;
  Map<String, dynamic>? _providerData;
  String _eta = 'Calculating...';
  double _progressPercentage = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _loadBookingData();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadBookingData() async {
    try {
      final supabaseService = SupabaseService();
      
      // Get booking details
      final bookingResponse = await supabaseService.client
          .from('bookings')
          .select('*, service_categories(*)')
          .eq('id', widget.bookingId)
          .single();

      _bookingData = bookingResponse;

      // Get provider details
      if (_bookingData!['provider_id'] != null) {
        final providerResponse = await supabaseService.client
            .from('provider_profiles')
            .select('*, users(*)')
            .eq('user_id', _bookingData!['provider_id'])
            .single();

        _providerData = providerResponse;
      }

      // Get customer location from booking
      if (_bookingData!['latitude'] != null && _bookingData!['longitude'] != null) {
        _customerLocation = LatLng(
          _bookingData!['latitude'],
          _bookingData!['longitude'],
        );
      }

      // Get provider's current location
      await _updateProviderLocation();

      setState(() {
        _isLoading = false;
      });

      // Center map to show both markers
      if (_providerLocation != null && _customerLocation != null) {
        _fitMapBounds();
      }
    } catch (e) {
      print('Error loading booking data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProviderLocation() async {
    try {
      final supabaseService = SupabaseService();
      
      // Get provider's latest location from provider_locations table
      final locationResponse = await supabaseService.client
          .from('provider_locations')
          .select()
          .eq('provider_id', _bookingData!['provider_id'])
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (locationResponse != null) {
        setState(() {
          _providerLocation = LatLng(
            locationResponse['latitude'],
            locationResponse['longitude'],
          );
        });

        // Calculate ETA and progress
        _calculateETAAndProgress();
        
        // Update route
        if (_customerLocation != null) {
          _updateRoute();
        }
      }
    } catch (e) {
      print('Error updating provider location: $e');
    }
  }

  void _calculateETAAndProgress() {
    if (_providerLocation == null || _customerLocation == null) return;

    // Calculate distance in meters
    final distance = Geolocator.distanceBetween(
      _providerLocation!.latitude,
      _providerLocation!.longitude,
      _customerLocation!.latitude,
      _customerLocation!.longitude,
    );

    // Estimate time (assuming average speed of 30 km/h in city)
    final estimatedMinutes = (distance / 1000 / 30 * 60).round();
    final estimatedTime = DateTime.now().add(Duration(minutes: estimatedMinutes));

    setState(() {
      _eta = '${estimatedMinutes} mins';
      
      // Calculate progress based on original distance
      // Assuming progress increases as provider gets closer
      final totalDistance = 5000.0; // Example: 5km original distance
      _progressPercentage = ((totalDistance - distance) / totalDistance * 100).clamp(0, 100);
    });
  }

  void _updateRoute() {
    if (_providerLocation == null || _customerLocation == null) return;

    // Simple straight line route (for production, use a routing API)
    setState(() {
      _routePoints = [_providerLocation!, _customerLocation!];
    });
  }

  void _fitMapBounds() {
    if (_providerLocation == null || _customerLocation == null) return;

    final bounds = LatLngBounds(
      _providerLocation!,
      _customerLocation!,
    );

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(80),
      ),
    );
  }

  void _startLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateProviderLocation();
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openChat() async {
    // TODO: Navigate to chat screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat feature coming soon')),
    );
  }

  Future<void> _showSOSDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency SOS'),
        content: const Text('Do you need emergency assistance?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Call emergency number
              _makePhoneCall('911');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Call Emergency'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelService() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Service'),
        content: const Text('Are you sure you want to cancel this service? This action cannot be undone.'),
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
        final supabaseService = SupabaseService();
        await supabaseService.client
            .from('bookings')
            .update({'status': 'cancelled'})
            .eq('id', widget.bookingId);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Service cancelled successfully'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling service: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF221a10),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFEC9213)),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _providerLocation ?? const LatLng(37.7749, -122.4194),
              initialZoom: 13,
              minZoom: 3,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.servyn.app',
              ),
              // Route polyline
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 6,
                      color: const Color(0xFFEC9213),
                      borderStrokeWidth: 2,
                      borderColor: Colors.white.withOpacity(0.5),
                    ),
                  ],
                ),
              // Markers
              MarkerLayer(
                markers: [
                  // Provider marker
                  if (_providerLocation != null)
                    Marker(
                      point: _providerLocation!,
                      width: 80,
                      height: 100,
                      child: Column(
                        children: [
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFEC9213).withOpacity(
                                        0.5 * (1 - _pulseController.value),
                                      ),
                                      blurRadius: 20 * _pulseController.value,
                                      spreadRadius: 10 * _pulseController.value,
                                    ),
                                  ],
                                ),
                                child: child,
                              );
                            },
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFEC9213),
                                  width: 4,
                                ),
                                image: _providerData?['profile_photo_url'] != null
                                    ? DecorationImage(
                                        image: NetworkImage(_providerData!['profile_photo_url']),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                color: _providerData?['profile_photo_url'] == null
                                    ? const Color(0xFF221a10)
                                    : null,
                              ),
                              child: _providerData?['profile_photo_url'] == null
                                  ? const Icon(
                                      Icons.person,
                                      color: Color(0xFFEC9213),
                                      size: 32,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF221a10).withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _providerData?['users']?['full_name']?.split(' ')[0] ?? 'Provider',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Customer marker
                  if (_customerLocation != null)
                    Marker(
                      point: _customerLocation!,
                      width: 80,
                      height: 80,
                      child: Column(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFFEC9213),
                            size: 48,
                            shadows: [
                              Shadow(
                                color: Colors.black38,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Text(
                              'You',
                              style: TextStyle(
                                color: Color(0xFF181511),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Gradient overlay at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Top App Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF221a10).withOpacity(0.8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  // Title with live indicator
                  Column(
                    children: [
                      const Text(
                        'Live Tracking',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black38,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Real-time update',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              shadows: [
                                Shadow(
                                  color: Colors.black38,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // SOS button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.shield_outlined, color: Colors.white),
                      onPressed: _showSOSDialog,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.38,
            minChildSize: 0.38,
            maxChildSize: 0.7,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF221a10),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      // Drag handle
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Container(
                          width: 48,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                        child: Column(
                          children: [
                            // ETA Header
                            Column(
                              children: [
                                Text(
                                  'ARRIVING IN $_eta',
                                  style: const TextStyle(
                                    color: Color(0xFFEC9213),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _bookingData?['scheduled_time'] != null
                                      ? TimeOfDay.fromDateTime(
                                          DateTime.parse(_bookingData!['scheduled_time']),
                                        ).format(context)
                                      : '12:45 PM',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Progress bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    height: 6,
                                    child: LinearProgressIndicator(
                                      value: _progressPercentage / 100,
                                      backgroundColor: Colors.white.withOpacity(0.1),
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                        Color(0xFFEC9213),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${_providerData?['users']?['full_name']?.split(' ')[0] ?? 'Provider'} is on the way to your location',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Provider Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2c2215),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.05),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Provider photo
                                  Stack(
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.1),
                                            width: 2,
                                          ),
                                          image: _providerData?['profile_photo_url'] != null
                                              ? DecorationImage(
                                                  image: NetworkImage(
                                                    _providerData!['profile_photo_url'],
                                                  ),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                          color: _providerData?['profile_photo_url'] == null
                                              ? Colors.grey[700]
                                              : null,
                                        ),
                                        child: _providerData?['profile_photo_url'] == null
                                            ? const Icon(
                                                Icons.person,
                                                color: Colors.white,
                                                size: 32,
                                              )
                                            : null,
                                      ),
                                      if (_providerData?['verification_status'] == 'verified')
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: const Color(0xFF2c2215),
                                                width: 2,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  // Provider info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _providerData?['users']?['full_name'] ?? 'Provider',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              color: Color(0xFFEC9213),
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _providerData?['average_rating']?.toString() ?? '5.0',
                                              style: const TextStyle(
                                                color: Color(0xFFEC9213),
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '•',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _providerData?['vehicle_info'] ?? 'Vehicle',
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 14,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Vehicle number
                                  if (_providerData?['vehicle_number'] != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _providerData!['vehicle_number'],
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.5),
                                          fontSize: 12,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _openChat,
                                    icon: const Icon(Icons.chat_bubble_outline),
                                    label: const Text('Chat'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white.withOpacity(0.1),
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(0, 56),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      if (_providerData?['users']?['phone'] != null) {
                                        _makePhoneCall(_providerData!['users']['phone']);
                                      }
                                    },
                                    icon: const Icon(Icons.call),
                                    label: Text('Call ${_providerData?['users']?['full_name']?.split(' ')[0] ?? 'Provider'}'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFEC9213),
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(0, 56),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Cancel Link
                            TextButton(
                              onPressed: _cancelService,
                              child: Text(
                                'Cancel Service',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
