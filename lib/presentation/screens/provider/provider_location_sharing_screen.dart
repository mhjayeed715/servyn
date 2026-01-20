import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../services/location_tracking_service.dart';

class ProviderLocationSharingScreen extends StatefulWidget {
  final String bookingId;
  final String providerId;

  const ProviderLocationSharingScreen({
    Key? key,
    required this.bookingId,
    required this.providerId,
  }) : super(key: key);

  @override
  State<ProviderLocationSharingScreen> createState() => _ProviderLocationSharingScreenState();
}

class _ProviderLocationSharingScreenState extends State<ProviderLocationSharingScreen> {
  bool _isTracking = false;
  bool _isLoading = false;
  Position? _lastPosition;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      _showPermissionDeniedDialog();
    }
  }

  Future<void> _startTracking() async {
    try {
      setState(() => _isLoading = true);

      // Request permission if needed
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermissionDeniedDialog();
        return;
      }

      // Start tracking
      await LocationTrackingService.startProviderTracking(widget.bookingId, widget.providerId);

      setState(() {
        _isTracking = true;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location sharing started'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _stopTracking() async {
    try {
      setState(() => _isLoading = true);
      await LocationTrackingService.stopProviderTracking();

      setState(() {
        _isTracking = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location sharing stopped'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'This app needs location access to share your location with customers. '
          'Please enable location permission in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Geolocator.openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await LocationTrackingService.getCurrentLocation();
      if (position != null) {
        setState(() => _lastPosition = position);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Location'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _isTracking ? Colors.green.shade50 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isTracking ? Colors.green.shade200 : Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Location Sharing',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF181511),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isTracking ? Colors.green : Colors.grey,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _isTracking ? 'Active' : 'Inactive',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isTracking
                        ? 'Your location is being shared with the customer in real-time.'
                        : 'Start sharing your location so customers can track your arrival.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF5F758C),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Current Location Info
            if (_lastPosition != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Location',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF181511),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_lastPosition!.latitude.toStringAsFixed(6)}, ${_lastPosition!.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF5F758C)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.speed, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Speed: ${(_lastPosition!.speed * 3.6).toStringAsFixed(1)} km/h',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF5F758C)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.info, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Accuracy: ±${_lastPosition!.accuracy.toStringAsFixed(1)}m',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF5F758C)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // Control Buttons
            SizedBox(
              width: double.infinity,
              child: _isTracking
                  ? Column(
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading ? null : _stopTracking,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Stop Sharing Location',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _getCurrentLocation,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh Location'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ElevatedButton(
                      onPressed: _isLoading ? null : _startTracking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEC9213),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text(
                              'Start Sharing Location',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
            ),

            const SizedBox(height: 24),

            // Info Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your location will be updated every 10 meters or every 5 seconds, whichever comes first.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber.shade900,
                            height: 1.5,
                          ),
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
    );
  }
}
