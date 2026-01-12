import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
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
  GoogleMapController? _mapController;
  
  LatLng _currentPosition = const LatLng(23.8103, 90.4125); // Dhaka, Bangladesh
  String _selectedAddress = '';
  bool _isLoadingLocation = false;
  bool _isSearching = false;
  
  final List<Map<String, dynamic>> _savedAddresses = [];
  List<Map<String, dynamic>> _searchResults = [];
  
  final Set<Marker> _markers = {};

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
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadSavedAddresses() async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user != null) {
        // Load all saved addresses from customer_saved_addresses table
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
        
        // Also load customer profile address if no saved addresses
        if (_savedAddresses.isEmpty) {
          final profile = await SupabaseConfig.client
              .from('customer_profiles')
              .select('address, city')
              .eq('user_id', user.id)
              .single();
          
          if (profile['address'] != null) {
            setState(() {
              _savedAddresses.add({
                'icon': Icons.home,
                'label': 'Home',
                'address': '${profile['address']}, ${profile['city']}',
                'latitude': null,
                'longitude': null,
              });
            });
          }
        }
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
        throw 'Location permissions are permanently denied. Please enable them in settings.';
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      final newPosition = LatLng(position.latitude, position.longitude);
      
      // Reverse geocode to get address
      await _reverseGeocodePosition(newPosition);
      
      setState(() {
        _currentPosition = newPosition;
        _isLoadingLocation = false;
      });
      
      // Move camera to current location
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 16),
      );
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

  Future<void> _reverseGeocodePosition(LatLng position) async {
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
    if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty && place.subAdministrativeArea != place.locality) {
      parts.add(place.subAdministrativeArea!);
    }
    
    return parts.join(', ');
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }
    
    setState(() => _isSearching = true);
    
    try {
      // Search for locations using geocoding
      List<Location> locations = await locationFromAddress(query);
      
      List<Map<String, dynamic>> results = [];
      
      for (var location in locations.take(5)) {
        // Reverse geocode to get full address
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
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('Search error: $e');
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No results found. Try a different search term.'),
          ),
        );
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _currentPosition = position.target;
    });
  }

  Future<void> _onCameraIdle() async {
    // Reverse geocode the center position
    await _reverseGeocodePosition(_currentPosition);
  }

  void _selectAddress(String address, double? latitude, double? longitude) {
    setState(() {
      _selectedAddress = address;
      _searchController.text = address;
      _searchResults.clear();
      
      if (latitude != null && longitude != null) {
        _currentPosition = LatLng(latitude, longitude);
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition, 16),
        );
      }
    });
  }

  Future<void> _saveCurrentAddress() async {
    if (_selectedAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location first')),
      );
      return;
    }
    
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _SaveAddressDialog(initialAddress: _selectedAddress),
    );
    
    if (result != null) {
      try {
        final user = SupabaseConfig.client.auth.currentUser;
        if (user != null) {
          await SupabaseConfig.client.from('customer_saved_addresses').insert({
            'user_id': user.id,
            'label': result['label'],
            'address': result['address'],
            'latitude': _currentPosition.latitude,
            'longitude': _currentPosition.longitude,
          });
          
          await _loadSavedAddresses();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Address saved successfully')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving address: $e')),
          );
        }
      }
    }
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
          // Google Map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 14,
            ),
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _markers,
            mapType: MapType.normal,
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
          
          // Top Search Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search street, city, or area...',
                              hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                              border: InputBorder.none,
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                _searchAddress(value);
                              } else {
                                setState(() {
                                  _searchResults.clear();
                                });
                              }
                            },
                            onSubmitted: _searchAddress,
                          ),
                        ),
                        if (_isSearching)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.mic, color: Color(0xFF5F758C)),
                            onPressed: () {
                              // TODO: Implement voice search
                            },
                          ),
                      ],
                    ),
                  ),
                  
                  // Search Results
                  if (_searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      constraints: const BoxConstraints(maxHeight: 300),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
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
          
          // GPS Button
          Positioned(
            right: 16,
            bottom: 400,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: _isLoadingLocation ? null : _getCurrentLocation,
              child: _isLoadingLocation
                  ? const CircularProgressIndicator()
                  : const Icon(
                      Icons.my_location,
                      color: AppColors.primaryBlue,
                    ),
            ),
          ),
          
          // Bottom Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Drag Handle
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Selected Address
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: AppColors.primaryBlue,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Selected Location',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedAddress.isEmpty 
                                          ? 'Move map to select location' 
                                          : _selectedAddress,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Save Address Button
                          OutlinedButton.icon(
                            onPressed: _selectedAddress.isNotEmpty ? _saveCurrentAddress : null,
                            icon: const Icon(Icons.bookmark_border),
                            label: const Text('Save this address'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryBlue,
                              side: const BorderSide(color: AppColors.primaryBlue),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Saved Addresses
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Saved Addresses',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: _loadSavedAddresses,
                                child: const Text('Refresh'),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          if (_savedAddresses.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.bookmark_border,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No saved addresses yet',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...(_savedAddresses.map((address) {
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: Icon(
                                    address['icon'],
                                    color: AppColors.primaryBlue,
                                  ),
                                  title: Text(
                                    address['label'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(address['address']),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                  onTap: () => _selectAddress(
                                    address['address'],
                                    address['latitude'],
                                    address['longitude'],
                                  ),
                                ),
                              );
                            })),
                          
                          const SizedBox(height: 100), // Space for button
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Confirm Button
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: ElevatedButton(
                onPressed: _selectedAddress.isNotEmpty ? _confirmLocation : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Confirm Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveAddressDialog extends StatefulWidget {
  final String initialAddress;
  
  const _SaveAddressDialog({required this.initialAddress});

  @override
  State<_SaveAddressDialog> createState() => _SaveAddressDialogState();
}

class _SaveAddressDialogState extends State<_SaveAddressDialog> {
  final _labelController = TextEditingController();
  final _addressController = TextEditingController();
  String _selectedLabel = 'Home';
  
  final List<String> _labels = ['Home', 'Work', 'Other'];

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.initialAddress;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save Address'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Label'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedLabel,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _labels.map((label) {
              return DropdownMenuItem(
                value: label,
                child: Text(label),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedLabel = value!;
                if (value == 'Other') {
                  _labelController.text = '';
                }
              });
            },
          ),
          
          if (_selectedLabel == 'Other') ...[
            const SizedBox(height: 16),
            const Text('Custom Label'),
            const SizedBox(height: 8),
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter label (e.g., Gym, Friend\'s Place)',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          const Text('Address'),
          const SizedBox(height: 8),
          TextField(
            controller: _addressController,
            maxLines: 2,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final label = _selectedLabel == 'Other' && _labelController.text.isNotEmpty
                ? _labelController.text
                : _selectedLabel;
            
            Navigator.pop(context, {
              'label': label,
              'address': _addressController.text,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
