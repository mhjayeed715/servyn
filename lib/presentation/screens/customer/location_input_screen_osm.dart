import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geocoding/geocoding.dart';
import '../../theme/colors.dart';
import '../../../services/supabase_config.dart';

class LocationInputScreenOSM extends StatefulWidget {
  final String? initialAddress;
  final GeoPoint? initialCoordinates;
  
  const LocationInputScreenOSM({
    super.key,
    this.initialAddress,
    this.initialCoordinates,
  });

  @override
  State<LocationInputScreenOSM> createState() => _LocationInputScreenOSMState();
}

class _LocationInputScreenOSMState extends State<LocationInputScreenOSM> {
  final TextEditingController _searchController = TextEditingController();
  late MapController _mapController;
  
  GeoPoint _currentPosition = GeoPoint(latitude: 23.8103, longitude: 90.4125); // Dhaka, Bangladesh
  String _selectedAddress = '';
  bool _isLoadingLocation = false;
  
  final List<Map<String, dynamic>> _savedAddresses = [];
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController(
      initMapWithUserPosition: const UserTrackingOption(
        enableTracking: true,
        unFollowUser: false,
      ),
    );
    
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
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedAddresses() async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user != null) {
        final savedAddressList = await SupabaseConfig.client
            .from('customer_saved_addresses')
            .select('*')
            .eq('user_id', user.id)
            .order('created_at', ascending: false);
        
        setState(() {
          _savedAddresses.clear();
          for (var addr in savedAddressList) {
            _savedAddresses.add({
              'id': addr['id'],
              'icon': _getIconForLabel(addr['label']),
              'label': addr['label'],
              'address': addr['address'],
              'latitude': addr['latitude'],
              'longitude': addr['longitude'],
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading saved addresses: $e');
    }
  }

  IconData _getIconForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'home':
        return Icons.home;
      case 'work':
      case 'office':
        return Icons.work;
      default:
        return Icons.location_on;
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled. Please enable them.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied.';
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      final newPosition = GeoPoint(latitude: position.latitude, longitude: position.longitude);
      
      await _reverseGeocodePosition(newPosition);
      
      setState(() {
        _currentPosition = newPosition;
        _isLoadingLocation = false;
      });
      
      await _mapController.changeLocation(newPosition);
      await _mapController.setZoom(zoomLevel: 16);
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _reverseGeocodePosition(GeoPoint position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = _formatAddress(place);
        
        setState(() {
          _selectedAddress = address;
          _searchController.text = address;
        });
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
      setState(() {
        _selectedAddress = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      });
    }
  }

  String _formatAddress(Placemark place) {
    List<String> parts = [];
    
    if (place.street != null && place.street!.isNotEmpty) {
      parts.add(place.street!);
    }
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      parts.add(place.subLocality!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    }
    
    return parts.join(', ');
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }
    
    try {
      List<Location> locations = await locationFromAddress('$query, Bangladesh');
      
      List<Map<String, dynamic>> results = [];
      
      for (var location in locations.take(5)) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );
        
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final address = _formatAddress(place);
          
          results.add({
            'address': address,
            'latitude': location.latitude,
            'longitude': location.longitude,
          });
        }
      }
      
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      debugPrint('Search error: $e');
      setState(() {
        _searchResults.clear();
      });
    }
  }

  void _selectAddress(String address, double? latitude, double? longitude) async {
    setState(() {
      _selectedAddress = address;
      _searchController.text = address;
      _searchResults.clear();
      
      if (latitude != null && longitude != null) {
        _currentPosition = GeoPoint(latitude: latitude, longitude: longitude);
      }
    });
    
    if (latitude != null && longitude != null) {
      await _mapController.changeLocation(GeoPoint(latitude: latitude, longitude: longitude));
      await _mapController.setZoom(zoomLevel: 16);
    }
  }

  Future<void> _confirmLocation() async {
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111418)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Location',
          style: TextStyle(
            color: Color(0xFF111418),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // OpenStreetMap
          OSMFlutter(
            controller: _mapController,
            osmOption: OSMOption(
              zoomOption: const ZoomOption(
                initZoom: 14,
                minZoomLevel: 3,
                maxZoomLevel: 19,
                stepZoom: 1.0,
              ),
              userLocationMarker: UserLocationMaker(
                personMarker: const MarkerIcon(
                  icon: Icon(
                    Icons.location_history_rounded,
                    color: Colors.red,
                    size: 48,
                  ),
                ),
                directionArrowMarker: const MarkerIcon(
                  icon: Icon(
                    Icons.double_arrow,
                    color: Colors.red,
                    size: 48,
                  ),
                ),
              ),
              staticPoints: [],
            ),
          ),
          
          // Search bar and controls
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search field
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search location...',
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF5F758C)),
                        suffixIcon: _isLoadingLocation
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.my_location, color: AppColors.primaryBlue),
                                onPressed: _getCurrentLocation,
                              ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onSubmitted: _searchAddress,
                    ),
                  ),
                  
                  // Search results
                  if (_searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];
                          return ListTile(
                            leading: const Icon(Icons.location_on, color: AppColors.primaryBlue),
                            title: Text(result['address']),
                            onTap: () => _selectAddress(
                              result['address'],
                              result['latitude'],
                              result['longitude'],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Confirm button
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: _confirmLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Confirm Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
