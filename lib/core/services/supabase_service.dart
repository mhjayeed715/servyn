import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:servyn/services/supabase_config.dart';

class SupabaseService {
  static final _client = SupabaseConfig.client;
  static final _auth = _client.auth;

  // ============ TEST/DEMO MODE ============
  static const bool _enableTestMode = true; // Set to false in production
  
  // Test phone numbers and their OTPs for demo
  static const Map<String, String> _testCredentials = {
    '+8801712345678': '123456', // Test customer
    '+8801612345678': '123456', // Test customer
    '+8801987654321': '123456', // Test provider
    '+8801587654321': '123456', // Test provider
    '+8801611111111': '111111', // Test admin
    '+8801823456789': '654321', // Another test user
  };

  // ============ AUTH METHODS ============
  
  /// Send OTP to phone
  static Future<void> sendOtp(String phone) async {
    // Test mode: Skip actual OTP sending for test numbers
    final fullPhone = '+880$phone';
    if (_enableTestMode && (_testCredentials.containsKey(phone) || _testCredentials.containsKey(fullPhone))) {
      final otp = _testCredentials[phone] ?? _testCredentials[fullPhone];
      print('🧪 TEST MODE: OTP for $phone is: $otp');
      return; // Skip actual Supabase OTP
    }
    
    try {
      await _auth.signInWithOtp(
        phone: '+880$phone',  // Add country code
        shouldCreateUser: true, // Auto-create user if not exists
      );
    } catch (e) {
      throw 'OTP sending failed: $e';
    }
  }

  /// Verify OTP and create session
  static Future<String?> verifyOtp(String phone, String otp) async {
    // Test mode: Allow test credentials
    final fullPhone = '+880$phone';
    if (_enableTestMode && (_testCredentials.containsKey(phone) || _testCredentials.containsKey(fullPhone))) {
      final expectedOtp = _testCredentials[phone] ?? _testCredentials[fullPhone];
      if (expectedOtp == otp) {
        print('🧪 TEST MODE: Authentication successful for test number $phone');
        // Create a mock user ID for test mode
        return 'test-user-$phone';
      } else {
        throw 'Invalid OTP for test number';
      }
    }
    
    try {
      final response = await _auth.verifyOTP(
        phone: '+880$phone',
        token: otp,
        type: OtpType.sms,
      );
      return response.user?.id;
    } catch (e) {
      throw 'OTP verification failed: $e';
    }
  }

  /// Get current user
  static User? getCurrentUser() => _auth.currentUser;

  /// Logout
  static Future<void> logout() async => await _auth.signOut();

  // ============ PROFILE CHECK ============

  /// Check if customer profile exists
  static Future<bool> customerProfileExists(String userId) async {
    try {
      final response = await _client
          .from('customer_profiles')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Check if provider profile exists
  static Future<bool> providerProfileExists(String userId) async {
    try {
      final response = await _client
          .from('provider_profiles')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  // ============ USER CREATION ============

  /// Create user role entry in database
  static Future<void> createUser(String userId, String phone, String role) async {
    try {
      await _client.from('users').insert({
        'id': userId,
        'phone': phone,
        'role': role,
      });
    } catch (e) {
      throw 'User creation failed: $e';
    }
  }

  // ============ CUSTOMER PROFILE ============

  /// Save customer profile
  static Future<void> saveCustomerProfile({
    required String userId,
    required String fullName,
    required String email,
    required String city,
    required String address,
    required String? photoBase64,
    required String emergencyName,
    required String emergencyPhone,
  }) async {
    try {
      await _client.from('customer_profiles').insert({
        'user_id': userId,
        'full_name': fullName,
        'email': email,
        'city': city,
        'address': address,
        'profile_photo_base64': photoBase64,
        'emergency_contact_name': emergencyName,
        'emergency_contact_phone': emergencyPhone,
        'verified': true,
      });
    } catch (e) {
      throw 'Customer profile save failed: $e';
    }
  }

  /// Get customer profile
  static Future<Map<String, dynamic>?> getCustomerProfile(String userId) async {
    try {
      final data = await _client
          .from('customer_profiles')
          .select()
          .eq('user_id', userId)
          .single();
      return data;
    } catch (e) {
      return null;
    }
  }

  /// Add emergency contact
  static Future<void> addEmergencyContact({
    required String userId,
    required String contactName,
    required String contactPhone,
    required String relationship,
  }) async {
    try {
      await _client.from('emergency_contacts').insert({
        'user_id': userId,
        'contact_name': contactName,
        'contact_phone': contactPhone,
        'relationship': relationship,
      });
    } catch (e) {
      throw 'Emergency contact add failed: $e';
    }
  }

  /// Get emergency contacts
  static Future<List<Map<String, dynamic>>> getEmergencyContacts(String userId) async {
    try {
      final data = await _client
          .from('emergency_contacts')
          .select()
          .eq('user_id', userId);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  // ============ PROVIDER VERIFICATION ============

  /// Save provider verification data
  static Future<void> saveProviderVerification({
    required String userId,
    required String fullName,
    required String nidNumber,
    required String? nidPhotoBase64,
    required List<String> services,
    required String bankAccountName,
    required String bankAccountNumber,
    required String bankRoutingNumber,
  }) async {
    try {
      await _client.from('provider_profiles').insert({
        'user_id': userId,
        'full_name': fullName,
        'nid_number': nidNumber,
        'nid_photo_base64': nidPhotoBase64,
        'services': services,
        'bank_account_name': bankAccountName,
        'bank_account_number': bankAccountNumber,
        'bank_routing_number': bankRoutingNumber,
        'verification_status': 'pending',
      });
    } catch (e) {
      throw 'Provider verification save failed: $e';
    }
  }

  /// Get provider profile
  static Future<Map<String, dynamic>?> getProviderProfile(String userId) async {
    try {
      final data = await _client
          .from('provider_profiles')
          .select()
          .eq('user_id', userId)
          .single();
      return data;
    } catch (e) {
      return null;
    }
  }

  // ============ STORAGE (Photo Upload) ============

  /// Upload photo to storage and return URL
  static Future<String> uploadProfilePhoto(
    String userId,
    String filePath,
    {String bucket = 'profiles'}
  ) async {
    try {
      final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.png';
      await _client.storage.from(bucket).upload(fileName, File(filePath));
      
      final url = _client.storage.from(bucket).getPublicUrl(fileName);
      return url;
    } catch (e) {
      throw 'Photo upload failed: $e';
    }
  }

  // ============ SAVED ADDRESSES ============

  /// Get all saved addresses for a customer
  static Future<List<Map<String, dynamic>>> getSavedAddresses(String userId) async {
    try {
      final data = await _client
          .from('customer_saved_addresses')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw 'Failed to load saved addresses: $e';
    }
  }

  /// Save a new address for a customer
  static Future<Map<String, dynamic>> saveAddress({
    required String userId,
    required String label,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final data = await _client
          .from('customer_saved_addresses')
          .insert({
            'user_id': userId,
            'label': label,
            'address': address,
            'latitude': latitude,
            'longitude': longitude,
          })
          .select()
          .single();
      return data;
    } catch (e) {
      throw 'Failed to save address: $e';
    }
  }

  /// Update a saved address
  static Future<void> updateAddress({
    required String addressId,
    String? label,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (label != null) updates['label'] = label;
      if (address != null) updates['address'] = address;
      if (latitude != null) updates['latitude'] = latitude;
      if (longitude != null) updates['longitude'] = longitude;

      await _client
          .from('customer_saved_addresses')
          .update(updates)
          .eq('id', addressId);
    } catch (e) {
      throw 'Failed to update address: $e';
    }
  }

  /// Delete a saved address
  static Future<void> deleteAddress(String addressId) async {
    try {
      await _client
          .from('customer_saved_addresses')
          .delete()
          .eq('id', addressId);
    } catch (e) {
      throw 'Failed to delete address: $e';
    }
  }

  /// Get a specific saved address by ID
  static Future<Map<String, dynamic>?> getAddressById(String addressId) async {
    try {
      final data = await _client
          .from('customer_saved_addresses')
          .select()
          .eq('id', addressId)
          .single();
      return data;
    } catch (e) {
      return null;
    }
  }


  /// Get all users (customers and providers) - Admin only
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      List<Map<String, dynamic>> allUsers = [];
      
      // Get customers with error handling
      try {
        final customers = await _client
            .from('customer_profiles')
            .select('*, users!inner(phone)');
        
        for (var customer in customers) {
          allUsers.add({
            'id': customer['user_id'],
            'name': customer['full_name'],
            'email': customer['email'],
            'phone': customer['users']?['phone'] ?? 'N/A',
            'role': 'Customer',
            'status': customer['status'] ?? 'active',
            'verified': customer['verified'] ?? false,
            'created_at': customer['created_at'],
            'bookings_count': 0, // Will be populated separately if needed
          });
        }
      } catch (e) {
        print('Error loading customers: $e');
      }
      
      // Get providers with error handling
      try {
        final providers = await _client
            .from('provider_profiles')
            .select('*, users!inner(phone)');

        for (var provider in providers) {
          allUsers.add({
            'id': provider['user_id'],
            'name': provider['full_name'],
            'email': 'N/A',
            'phone': provider['users']?['phone'] ?? 'N/A',
            'role': 'Provider',
            'service': (provider['services'] as List?)?.join(', ') ?? 'N/A',
            'status': provider['status'] ?? 'active',
            'verified': provider['verification_status'] == 'approved',
            'rating': 0.0, // Will be calculated from bookings if needed
            'created_at': provider['created_at'],
            'bookings_count': 0,
          });
        }
      } catch (e) {
        print('Error loading providers: $e');
      }
      
      return allUsers;
    } catch (e) {
      print('Error in getAllUsers: $e');
      return []; // Return empty list instead of throwing
    }
  }

  /// Suspend or activate a user - Admin only
  static Future<void> toggleUserStatus({
    required String userId,
    required String role, // 'customer' or 'provider'
    required String newStatus, // 'active' or 'suspended'
    String? reason,
    String? adminId,
  }) async {
    try {
      final table = role.toLowerCase() == 'customer' 
          ? 'customer_profiles' 
          : 'provider_profiles';
      
      final updates = {
        'status': newStatus,
        if (newStatus == 'suspended') ...{
          'suspended_at': DateTime.now().toIso8601String(),
          'suspended_by': adminId,
          'suspension_reason': reason,
        }
      };

      await _client
          .from(table)
          .update(updates)
          .eq('user_id', userId);

      // Log admin activity
      if (adminId != null) {
        await logAdminActivity(
          adminId: adminId,
          actionType: newStatus == 'suspended' ? 'suspend_user' : 'activate_user',
          targetType: role.toLowerCase(),
          targetId: userId,
          details: {'reason': reason},
        );
      }
    } catch (e) {
      throw 'Failed to update user status: $e';
    }
  }

  // ============ ADMIN - PROVIDER VERIFICATION ============

  /// Get pending provider verifications - Admin only
  static Future<List<Map<String, dynamic>>> getPendingProviderVerifications() async {
    try {
      final data = await _client
          .from('provider_profiles')
          .select('*, users!inner(phone)')
          .eq('verification_status', 'pending')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw 'Failed to load pending verifications: $e';
    }
  }

  /// Get all provider verifications by status - Admin only
  static Future<List<Map<String, dynamic>>> getProviderVerificationsByStatus(String status) async {
    try {
      final data = await _client
          .from('provider_profiles')
          .select('*, users!inner(phone)')
          .eq('verification_status', status)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw 'Failed to load verifications: $e';
    }
  }

  /// Approve provider verification - Admin only
  static Future<void> approveProviderVerification({
    required String userId,
    required String adminId,
  }) async {
    try {
      await _client
          .from('provider_profiles')
          .update({
            'verification_status': 'verified',
            'verified_at': DateTime.now().toIso8601String(),
            'verified_by': adminId,
          })
          .eq('user_id', userId);

      // Log admin activity
      await logAdminActivity(
        adminId: adminId,
        actionType: 'approve_provider',
        targetType: 'provider',
        targetId: userId,
      );
    } catch (e) {
      throw 'Failed to approve provider: $e';
    }
  }

  /// Reject provider verification - Admin only
  static Future<void> rejectProviderVerification({
    required String userId,
    required String adminId,
    required String reason,
  }) async {
    try {
      await _client
          .from('provider_profiles')
          .update({
            'verification_status': 'rejected',
            'rejection_reason': reason,
          })
          .eq('user_id', userId);

      // Log admin activity
      await logAdminActivity(
        adminId: adminId,
        actionType: 'reject_provider',
        targetType: 'provider',
        targetId: userId,
        details: {'reason': reason},
      );
    } catch (e) {
      throw 'Failed to reject provider: $e';
    }
  }

  // ============ ADMIN - COMPLAINT MANAGEMENT ============

  /// Get all complaints - Admin only
  static Future<List<Map<String, dynamic>>> getAllComplaints() async {
    try {
      final data = await _client
          .from('complaints')
          .select()
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw 'Failed to load complaints: $e';
    }
  }

  /// Get complaints by status - Admin only
  static Future<List<Map<String, dynamic>>> getComplaintsByStatus(String status) async {
    try {
      final data = await _client
          .from('complaints')
          .select()
          .eq('status', status)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw 'Failed to load complaints: $e';
    }
  }

  /// Create a complaint - Customer or Provider
  static Future<void> createComplaint({
    required String title,
    required String description,
    required String category,
    required String customerId,
    required String customerName,
    String? providerId,
    String? providerName,
    String? providerService,
    String? bookingId,
    String priority = 'medium',
  }) async {
    try {
      await _client.from('complaints').insert({
        'title': title,
        'description': description,
        'category': category,
        'customer_id': customerId,
        'customer_name': customerName,
        'provider_id': providerId,
        'provider_name': providerName,
        'provider_service': providerService,
        'booking_id': bookingId,
        'priority': priority,
        'status': 'pending',
      });
    } catch (e) {
      throw 'Failed to create complaint: $e';
    }
  }

  /// Update complaint status - Admin only
  static Future<void> updateComplaintStatus({
    required String complaintId,
    required String status, // 'pending', 'in_progress', 'resolved'
    String? adminId,
    String? resolutionNotes,
  }) async {
    try {
      final updates = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
        if (adminId != null) 'assigned_admin_id': adminId,
        if (resolutionNotes != null) 'resolution_notes': resolutionNotes,
        if (status == 'resolved') 'resolved_at': DateTime.now().toIso8601String(),
      };

      await _client
          .from('complaints')
          .update(updates)
          .eq('id', complaintId);

      // Log admin activity
      if (adminId != null) {
        await logAdminActivity(
          adminId: adminId,
          actionType: 'update_complaint',
          targetType: 'complaint',
          targetId: complaintId,
          details: {'status': status, 'notes': resolutionNotes},
        );
      }
    } catch (e) {
      throw 'Failed to update complaint: $e';
    }
  }

  // ============ ADMIN - STATISTICS ============

  /// Get dashboard statistics - Admin only
  static Future<Map<String, dynamic>> getAdminDashboardStats() async {
    try {
      // Get stats using length of returned data with individual error handling
      int totalCustomers = 0;
      int activeCustomers = 0;
      int totalProviders = 0;
      int activeProviders = 0;
      int pendingVerifications = 0;
      int totalBookings = 0;
      int completedBookings = 0;
      int totalComplaints = 0;
      int pendingComplaints = 0;

      try {
        final customers = await _client.from('customer_profiles').select('id');
        totalCustomers = customers.length;
        final activeCustomersData = await _client.from('customer_profiles').select('id').eq('status', 'active');
        activeCustomers = activeCustomersData.length;
      } catch (e) {
        print('Error loading customer stats: $e');
      }

      try {
        final providers = await _client.from('provider_profiles').select('id');
        totalProviders = providers.length;
        final activeProvidersData = await _client.from('provider_profiles').select('id').eq('status', 'active');
        activeProviders = activeProvidersData.length;
        final pendingVerificationsData = await _client.from('provider_profiles').select('id').eq('verification_status', 'pending');
        pendingVerifications = pendingVerificationsData.length;
      } catch (e) {
        print('Error loading provider stats: $e');
      }

      try {
        final bookings = await _client.from('bookings').select('id');
        totalBookings = bookings.length;
        final completedBookingsData = await _client.from('bookings').select('id').eq('status', 'completed');
        completedBookings = completedBookingsData.length;
      } catch (e) {
        print('Error loading booking stats: $e');
      }

      try {
        final complaints = await _client.from('complaints').select('id');
        totalComplaints = complaints.length;
        final pendingComplaintsData = await _client.from('complaints').select('id').eq('status', 'pending');
        pendingComplaints = pendingComplaintsData.length;
      } catch (e) {
        print('Error loading complaint stats: $e');
      }

      return {
        'total_customers': totalCustomers,
        'active_customers': activeCustomers,
        'total_providers': totalProviders,
        'active_providers': activeProviders,
        'pending_verifications': pendingVerifications,
        'total_bookings': totalBookings,
        'completed_bookings': completedBookings,
        'total_complaints': totalComplaints,
        'pending_complaints': pendingComplaints,
      };
    } catch (e) {
      print('Error in getAdminDashboardStats: $e');
      // Return default values instead of throwing
      return {
        'total_customers': 0,
        'active_customers': 0,
        'total_providers': 0,
        'active_providers': 0,
        'pending_verifications': 0,
        'total_bookings': 0,
        'completed_bookings': 0,
        'total_complaints': 0,
        'pending_complaints': 0,
      };
    }
  }

  /// Get recent activity - Admin only
  static Future<List<Map<String, dynamic>>> getRecentAdminActivity({int limit = 10}) async {
    try {
      final data = await _client
          .from('admin_activity_log')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return []; // Return empty if table doesn't exist yet
    }
  }

  // ============ ADMIN - ACTIVITY LOGGING ============

  /// Log admin activity for audit trail
  static Future<void> logAdminActivity({
    required String adminId,
    required String actionType,
    String? targetType,
    String? targetId,
    Map<String, dynamic>? details,
  }) async {
    try {
      await _client.from('admin_activity_log').insert({
        'admin_id': adminId,
        'admin_name': 'Admin', // You can fetch actual admin name if available
        'action_type': actionType,
        'target_type': targetType,
        'target_id': targetId,
        'details': details,
      });
    } catch (e) {
      // Silent fail for logging - don't break main functionality
      print('Failed to log admin activity: $e');
    }
  }

  /// Get admin activity logs - Admin only
  static Future<List<Map<String, dynamic>>> getAdminActivityLogs({int limit = 50}) async {
    try {
      final data = await _client
          .from('admin_activity_log')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Failed to load admin activity logs: $e');
      return [];
    }
  }

  // ============ ADMIN - USER DELETION ============

  /// Delete a user (customer or provider) - Admin only
  static Future<void> deleteUser(String userId) async {
    try {
      // Delete from customer_profiles if exists (ignore errors if not found)
      try {
        await _client.from('customer_profiles').delete().eq('user_id', userId);
      } catch (e) {
        print('Customer profile not found or already deleted: $e');
      }
      
      // Delete from provider_profiles if exists (ignore errors if not found)
      try {
        await _client.from('provider_profiles').delete().eq('user_id', userId);
      } catch (e) {
        print('Provider profile not found or already deleted: $e');
      }
      
      // Delete from users table
      await _client.from('users').delete().eq('id', userId);
    } catch (e) {
      throw 'Failed to delete user: $e';
    }
  }

  // ============ ADMIN - BOOKINGS MANAGEMENT ============

  /// Get all bookings - Admin only
  static Future<List<Map<String, dynamic>>> getAllBookings() async {
    try {
      final data = await _client
          .from('bookings')
          .select('*, services(name)')
          .order('created_at', ascending: false);
      
      // Format the response to include service name
      return data.map<Map<String, dynamic>>((booking) {
        return {
          ...booking,
          'service_name': booking['services']?['name'] ?? 'Unknown Service',
        };
      }).toList();
    } catch (e) {
      print('Error loading bookings: $e');
      return []; // Return empty list instead of throwing
    }
  }
}