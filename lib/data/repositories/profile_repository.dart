import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import '../../domain/entities/profile.dart';

class ProfileRepository {
  final SupabaseClient _supabase;

  ProfileRepository(this._supabase);

  // Customer Profile Methods
  Future<CustomerProfile> getCustomerProfile(String customerId) async {
    try {
      final response = await _supabase
          .from('customer_profiles')
          .select()
          .eq('id', customerId)
          .single();

      return CustomerProfile.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch customer profile: $e');
    }
  }

  Future<void> updateCustomerProfile({
    required String customerId,
    required String fullName,
    required String phoneNumber,
    String? address,
    double? latitude,
    double? longitude,
    List<String>? savedAddresses,
    List<String>? preferredServiceCategories,
    String? preferredLanguage,
    bool? receiveNotifications,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (fullName.isNotEmpty) updates['full_name'] = fullName;
      if (phoneNumber.isNotEmpty) updates['phone_number'] = phoneNumber;
      if (address != null) updates['address'] = address;
      if (latitude != null) updates['latitude'] = latitude;
      if (longitude != null) updates['longitude'] = longitude;
      if (savedAddresses != null) updates['saved_addresses'] = savedAddresses;
      if (preferredServiceCategories != null)
        updates['preferred_service_categories'] = preferredServiceCategories;
      if (preferredLanguage != null)
        updates['preferred_language'] = preferredLanguage;
      if (receiveNotifications != null)
        updates['receive_notifications'] = receiveNotifications;

      await _supabase
          .from('customer_profiles')
          .update(updates)
          .eq('id', customerId);
    } catch (e) {
      throw Exception('Failed to update customer profile: $e');
    }
  }

  // Provider Profile Methods
  Future<ProviderProfile> getProviderProfile(String providerId) async {
    try {
      final response = await _supabase
          .from('provider_profiles')
          .select()
          .eq('id', providerId)
          .single();

      return ProviderProfile.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch provider profile: $e');
    }
  }

  Future<void> updateProviderProfile({
    required String providerId,
    required String fullName,
    required String phoneNumber,
    String? description,
    double? latitude,
    double? longitude,
    List<String>? certifications,
    List<String>? workingDays,
    String? workingHoursStart,
    String? workingHoursEnd,
    int? maxConcurrentJobs,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (fullName.isNotEmpty) updates['full_name'] = fullName;
      if (phoneNumber.isNotEmpty) updates['phone_number'] = phoneNumber;
      if (description != null) updates['description'] = description;
      if (latitude != null) updates['latitude'] = latitude;
      if (longitude != null) updates['longitude'] = longitude;
      if (certifications != null) updates['certifications'] = certifications;
      if (workingDays != null) updates['working_days'] = workingDays;
      if (workingHoursStart != null)
        updates['working_hours_start'] = workingHoursStart;
      if (workingHoursEnd != null) updates['working_hours_end'] = workingHoursEnd;
      if (maxConcurrentJobs != null)
        updates['max_concurrent_jobs'] = maxConcurrentJobs;

      await _supabase
          .from('provider_profiles')
          .update(updates)
          .eq('id', providerId);
    } catch (e) {
      throw Exception('Failed to update provider profile: $e');
    }
  }

  Future<void> updateProviderLocation({
    required String providerId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _supabase.from('provider_profiles').update({
        'latitude': latitude,
        'longitude': longitude,
        'last_location_update': DateTime.now().toIso8601String(),
      }).eq('id', providerId);

      // Also update provider_locations table for real-time tracking
      await _supabase.from('provider_locations').upsert({
        'provider_id': providerId,
        'latitude': latitude,
        'longitude': longitude,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update provider location: $e');
    }
  }

  Future<void> setSavedAddress({
    required String customerId,
    required String label, // Home, Work, etc.
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _supabase.from('saved_addresses').insert({
        'id': '${customerId}_${label.toLowerCase()}',
        'customer_id': customerId,
        'label': label,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to save address: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSavedAddresses(String customerId) async {
    try {
      final response = await _supabase
          .from('saved_addresses')
          .select()
          .eq('customer_id', customerId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch saved addresses: $e');
    }
  }

  Future<void> deleteSavedAddress(String addressId) async {
    try {
      await _supabase.from('saved_addresses').delete().eq('id', addressId);
    } catch (e) {
      throw Exception('Failed to delete address: $e');
    }
  }

  // Profile Picture Upload
  Future<String> uploadProfilePicture({
    required String userId,
    required List<int> imageBytes,
    required String fileName,
  }) async {
    try {
      final uploadPath = 'profile_pictures/$userId/$fileName';

      await _supabase.storage
          .from('avatars')
          .uploadBinary(uploadPath, Uint8List.fromList(imageBytes));

      final url = _supabase.storage.from('avatars').getPublicUrl(uploadPath);
      return url.toString();
    } catch (e) {
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  // Banking Information (for providers)
  Future<void> updateBankingInfo({
    required String providerId,
    required String bankName,
    required String accountNumber,
    required String accountHolderName,
  }) async {
    try {
      await _supabase.from('provider_profiles').update({
        'bank_account_info': {
          'bank_name': bankName,
          'account_number': accountNumber,
          'account_holder_name': accountHolderName,
        },
      }).eq('id', providerId);
    } catch (e) {
      throw Exception('Failed to update banking info: $e');
    }
  }

  // Service Preferences
  Future<void> updatePreferredServices({
    required String customerId,
    required List<String> serviceCategories,
  }) async {
    try {
      await _supabase.from('customer_profiles').update({
        'preferred_service_categories': serviceCategories,
      }).eq('id', customerId);
    } catch (e) {
      throw Exception('Failed to update service preferences: $e');
    }
  }

  // Working Schedule for Providers
  Future<void> updateWorkingSchedule({
    required String providerId,
    required List<String> workingDays,
    required String startTime, // HH:mm format
    required String endTime,
  }) async {
    try {
      await _supabase.from('provider_profiles').update({
        'working_days': workingDays,
        'working_hours_start': startTime,
        'working_hours_end': endTime,
      }).eq('id', providerId);
    } catch (e) {
      throw Exception('Failed to update working schedule: $e');
    }
  }
}
