import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class LocationTrackingService {
  static final LocationTrackingService _instance = LocationTrackingService._internal();  static StreamSubscription<Position>? _positionStream;  
  factory LocationTrackingService() {
    return _instance;
  }
  
  LocationTrackingService._internal();
  
  /// Start tracking provider location
  static Future<void> startProviderTracking(String bookingId, String providerId) async {
    try {
      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw 'Location permission denied';
      }
      
      // Start listening to location updates
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 10, // Update every 10 meters
          timeLimit: Duration(seconds: 5),
        ),
      ).listen((Position position) {
        _updateProviderLocation(bookingId, providerId, position);
      });
      
      print('✅ Provider location tracking started for booking: $bookingId');
    } catch (e) {
      print('❌ Error starting provider tracking: $e');
    }
  }
  
  /// Stop tracking provider location
  static Future<void> stopProviderTracking() async {
    try {
      await _positionStream?.cancel();
      _positionStream = null;
      print('✅ Provider location tracking stopped');
    } catch (e) {
      print('❌ Error stopping provider tracking: $e');
    }
  }
  
  /// Update provider location in database
  static Future<void> _updateProviderLocation(
    String bookingId,
    String providerId,
    Position position,
  ) async {
    try {
      final supabase = Supabase.instance.client;
      
      await supabase
          .from('booking_locations')
          .upsert({
            'booking_id': bookingId,
            'provider_id': providerId,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'accuracy': position.accuracy,
            'speed': position.speed,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'booking_id')
          .select();
      
      print('📍 Location updated: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('❌ Error updating location: $e');
    }
  }
  
  /// Get current provider location for a booking
  static Future<Map<String, dynamic>?> getProviderLocation(String bookingId) async {
    try {
      final supabase = Supabase.instance.client;
      
      final response = await supabase
          .from('booking_locations')
          .select()
          .eq('booking_id', bookingId)
          .maybeSingle();
      
      return response;
    } catch (e) {
      print('❌ Error getting provider location: $e');
      return null;
    }
  }
  
  /// Stream provider location updates
  static Stream<Map<String, dynamic>?> streamProviderLocation(String bookingId) {
    try {
      final supabase = Supabase.instance.client;
      
      return supabase
          .from('booking_locations')
          .select()
          .eq('booking_id', bookingId)
          .stream(primaryKey: ['booking_id'])
          .map((data) {
            if (data.isNotEmpty) {
              return data.first;
            }
            return null;
          });
    } catch (e) {
      print('❌ Error streaming provider location: $e');
      return Stream.value(null);
    }
  }
  
  /// Get current device location
  static Future<Position?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );
      return position;
    } catch (e) {
      print('❌ Error getting current location: $e');
      return null;
    }
  }
  
  /// Calculate distance between two coordinates (in meters)
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
}
