import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/colors.dart';
import '../../../services/supabase_config.dart';

class LocationInputScreen extends StatefulWidget {
  final String? initialAddress;
  final LatLng? initialCoordinates;
  
  const LocationInputScreen({
    super.key,
    this.initialAddress,
    this.initialCoordinates,
  });

  @override
  State<LocationInputScreen> createState() => _LocationInputScreenState();
}

class _LocationInputScreenState extends State<LocationInputScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  
  LatLng _currentPosition = const LatLng(23.8103, 90.4125); // Dhaka, Bangladesh
  String _selectedAddress = '';
  bool _isLoadingLocation = false;
  
  final List<Map<String, dynamic>> _savedAddresses = [];
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      _selectedAddress = widget.initialAddress!;
    }
    if (widget.initialCoordinates != null) {
      _currentPosition = widget.initialCoordinates!;
    }
    _loadSavedAddresses();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
        
        _reverseGeocodePosition(_currentPosition);
        _mapController.move(_currentPosition, 16);
      }
    } catch (e) {
      print('Error getting current location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _reverseGeocodePosition(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        final address =
            '${place.street}, ${place.locality}, ${place.administrativeArea}';
        
        setState(() {
          _selectedAddress = address;
        });
      }
    } catch (e) {
      print('Error reverse geocoding: $e');
    }
  }

  Future<void> _searchAddress(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    try {
      final locations = await locationFromAddress(query);
      final results = <Map<String, dynamic>>[];

      for (var location in locations) {
        final placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks[0];
          results.add({
            'address':
                '${place.street}, ${place.locality}, ${place.administrativeArea}',
            'latitude': location.latitude,
            'longitude': location.longitude,
          });
        }
      }

      setState(() => _searchResults = results);
    } catch (e) {
      print('Error searching address: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching address: $e')),
      );
    }
  }

  Future<void> _loadSavedAddresses() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return;

      final response = await SupabaseConfig.client
          .from('users')
          .select('address, city, postal_code')
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        final address = response['address'] ?? '';
        final city = response['city'] ?? '';
        final postal = response['postal_code'] ?? '';

        setState(() {
          _savedAddresses.add({
            'address': '$address, $city, $postal',
            'type': 'home',
          });
        });
      }
    } catch (e) {
      print('Error loading saved addresses: $e');
    }
  }

  Future<String?> _getCurrentUserId() async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      return user?.id;
    } catch (e) {
      return null;
    }
  }

  void _selectLocation(String address, LatLng position) {
    setState(() {
      _selectedAddress = address;
      _currentPosition = position;
      _searchResults = [];
      _searchController.clear();
    });
    _mapController.move(position, 16);
  }

  void _confirmLocation() {
    if (_selectedAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location')),
      );
      return;
    }
    
    Navigator.pop(context, {
      'address': _selectedAddress,
      'latitude': _currentPosition.latitude,
      'longitude': _currentPosition.longitude,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Flutter Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 14,
              minZoom: 3,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
            ],
          ),

          // Center Pin Indicator
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 48,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(height: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _searchAddress,
                decoration: InputDecoration(
                  hintText: 'Search address...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.primaryBlue),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _searchAddress('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ),
          ),

          // Search Results
          if (_searchResults.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final result = _searchResults[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text(result['address'] ?? ''),
                      onTap: () {
                        _selectLocation(
                          result['address'] ?? '',
                          LatLng(result['latitude'], result['longitude']),
                        );
                      },
                    );
                  },
                ),
              ),
            ),

          // Current Location Button
          Positioned(
            bottom: 180,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: AppColors.primaryBlue,
              onPressed: _isLoadingLocation ? null : _getCurrentLocation,
              child: _isLoadingLocation
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.my_location),
            ),
          ),

          // Selected Address & Confirm Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Selected Address
                  if (_selectedAddress.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedAddress,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  if (_selectedAddress.isNotEmpty) const SizedBox(height: 16),

                  // Saved Addresses
                  if (_savedAddresses.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Saved Addresses',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(
                          _savedAddresses.length,
                          (index) {
                            final addr = _savedAddresses[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: GestureDetector(
                                onTap: () {
                                  _selectLocation(
                                    addr['address'] ?? '',
                                    LatLng(
                                      addr['latitude'] ?? 23.8103,
                                      addr['longitude'] ?? 90.4125,
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        addr['type'] == 'home'
                                            ? Icons.home
                                            : Icons.location_on_outlined,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          addr['address'] ?? '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),

                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _confirmLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Confirm Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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
}
