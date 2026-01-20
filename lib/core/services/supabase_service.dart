import 'dart:io';
import 'package:uuid/uuid.dart';
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

  // Test email OTPs for demo (used when _enableTestMode is true)
  static const Map<String, String> _testEmailOtps = {
    'test@servyn.dev': '123456',
    'demo@servyn.dev': '123456',
    'customer@test.local': '123456',
  };

  // ============ AUTH METHODS ============
  
  /// Send OTP to phone
  static Future<void> sendOtp(String phone) async {
    // Test mode: Skip actual OTP sending for test numbers
    final fullPhone = '+880$phone';
    if (_enableTestMode && (_testCredentials.containsKey(phone) || _testCredentials.containsKey(fullPhone))) {
      print('🧪 TEST MODE: OTP would be sent to $phone');
      return; // Skip actual Supabase OTP in test mode
    }

    try {
      // In test/demo mode, we don't actually send OTP via Supabase
      // The app uses hardcoded OTP: 111000
      print('📱 OTP request for phone: $phone (using hardcoded: 111000)');
    } catch (e) {
      throw 'OTP sending failed: $e';
    }
  }

  /// Send OTP to email for customer registration
  static Future<void> sendEmailOtp(String email) async {
    // Test mode: Skip actual email sending for test emails
    if (_enableTestMode && _testEmailOtps.containsKey(email.toLowerCase())) {
      // OTP exists in test credentials, skip sending
      return;
    }

    try {
      // Use Supabase's built-in email OTP with configured Gmail SMTP
      // This automatically sends via jayedhossain809@gmail.com (Servyn Team)
      await _auth.signInWithOtp(
        email: email,
        shouldCreateUser: true,
        emailRedirectTo: 'servyn://otp-callback',
      );
      
      // Email sent successfully via configured SMTP
    } on AuthException catch (e) {
      // Specific error handling for auth exceptions
      if (e.message.contains('Email rate limit exceeded')) {
        throw 'Please wait 60 seconds before requesting another OTP';
      } else if (e.message.contains('Invalid email')) {
        throw 'Invalid email address format';
      } else if (e.message.contains('User already registered')) {
        throw 'This email is already registered. Please login instead.';
      } else if (e.message.contains('Email link is invalid')) {
        throw 'Configuration error. Please contact support.';
      } else {
        // For SMTP errors, provide helpful message
        throw 'Email service temporarily unavailable. Please try again or contact support.';
      }
    } catch (e) {
      throw 'Network error. Please check your internet connection and try again.';
    }
  }

  /// Verify email OTP
  static Future<String?> verifyEmailOtp(String email, String otp) async {
    // Test mode: Allow test email OTPs
    if (_enableTestMode && _testEmailOtps.containsKey(email.toLowerCase())) {
      final expected = _testEmailOtps[email.toLowerCase()];
      if (expected == otp) {
        return 'test-email-user-$email';
      } else {
        throw 'Invalid OTP for test email';
      }
    }

    try {
      final response = await _auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );
      return response.user?.id;
    } on AuthException catch (e) {
      throw 'Email OTP verification failed: ${e.message}';
    } catch (e) {
      throw 'Email OTP verification failed: $e';
    }
  }

  /// Verify provider OTP with hardcoded OTP "111000"
  static Future<String?> verifyProviderOtp(String phone, String otp) async {
    // Check hardcoded OTP for providers
    if (otp == '111000') {
      print('✅ Provider hardcoded OTP verified for $phone');
      
      try {
        // First check if user already has an active session
        final currentUser = _auth.currentUser;
        if (currentUser != null && currentUser.id.isNotEmpty) {
          print('✅ Using existing auth session: ${currentUser.id}');
          return currentUser.id;
        }
        
        // Check if a user with this phone already exists in the database
        final existingUserResponse = await _client
            .from('users')
            .select('id')
            .eq('phone', phone)
            .maybeSingle();
        
        if (existingUserResponse != null) {
          // User exists - return their ID
          final existingUserId = existingUserResponse['id'];
          print('✅ Found existing user in database, user_id: $existingUserId');
          return existingUserId;
        }
        
        // No existing user - generate a proper UUID v4
        print('🆔 Generating new UUID for phone: $phone');
        const uuid = Uuid();
        final newUserId = uuid.v4();
        print('✅ Generated new user ID: $newUserId');
        return newUserId;
        
      } catch (e) {
        print('❌ Error in verifyProviderOtp: $e');
        throw 'Authentication failed: $e';
      }
    } else {
      throw 'Invalid OTP. Use: 111000';
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
        // Generate a proper UUID v4 for test mode (instead of invalid 'test-user-' format)
        final userId = const Uuid().v4();
        print('🧪 Generated UUID for test user: $userId');
        return userId;
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
  static Future<bool> customerProfileExists(String userId, {String? phone}) async {
    try {
      // If phone is provided, search users table by phone to get the correct user_id
      if (phone != null) {
        print('🔍 Checking user by phone in users table: $phone');
        final userResponse = await _client
            .from('users')
            .select('id')
            .eq('phone', phone)
            .eq('role', 'customer')
            .maybeSingle();
        
        if (userResponse != null) {
          final foundUserId = userResponse['id'];
          print('✅ Found user with phone $phone, user_id: $foundUserId');
          
          // Now check if this user has a customer profile
          final profileResponse = await _client
              .from('customer_profiles')
              .select('user_id')
              .eq('user_id', foundUserId)
              .maybeSingle();
          
          if (profileResponse != null) {
            print('✅ Found customer profile for user_id: $foundUserId');
            return true;
          }
        }
      }
      
      // Fallback: try by user_id directly
      print('🔍 Checking customer profile by user_id: $userId');
      final response = await _client
          .from('customer_profiles')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();
      
      if (response != null) {
        print('✅ Found customer profile by user_id');
        return true;
      }
      
      print('❌ No customer profile found');
      return false;
    } catch (e) {
      print('❌ Error checking customer profile: $e');
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
  
  /// Get provider verification status
  static Future<String?> getProviderVerificationStatus(String userId) async {
    try {
      final response = await _client
          .from('provider_profiles')
          .select('verification_status')
          .eq('user_id', userId)
          .maybeSingle();
      
      if (response != null) {
        return response['verification_status'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting provider verification status: $e');
      return null;
    }
  }
  
  /// Mark verification success screen as shown for provider
  static Future<void> markVerificationSuccessShown(String userId) async {
    try {
      await _client
          .from('provider_profiles')
          .update({'verification_success_shown': true})
          .eq('user_id', userId);
    } catch (e) {
      print('Error marking verification success shown: $e');
      throw 'Failed to update verification status: $e';
    }
  }

  // ============ USER CREATION ============

  /// Create user role entry in database
  static Future<void> createUser(String userId, String phone, String role) async {
    try {
      print('👤 Creating user: id=$userId, phone=$phone, role=$role');
      
      // Validate UUID format (basic check)
      if (!_isValidUuid(userId)) {
        print('❌ Invalid UUID format: $userId');
        throw 'Invalid user ID format (not a valid UUID)';
      }
      
      // Check if user already exists by ID
      final existing = await _client
          .from('users')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      
      if (existing != null) {
        print('ℹ️ User already exists with id: $userId');
        return;
      }
      
      print('🆔 Inserting new user record into database...');
      await _client.from('users').insert({
        'id': userId,
        'phone': phone,
        'role': role,
      });
      
      print('✅ User created successfully: $userId');
    } catch (e) {
      // Check if it's a duplicate key error (phone is unique)
      if (e.toString().contains('duplicate key') || e.toString().contains('23505')) {
        print('ℹ️ User already exists, skipping creation: $e');
        return;
      }
      print('❌ User creation error: $e');
      throw 'User creation failed: $e';
    }
  }
  
  static bool _isValidUuid(String uuid) {
    // Simple UUID v4 validation
    final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$', caseSensitive: false);
    return uuidRegex.hasMatch(uuid);
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
      print('💾 Saving customer profile for userId: $userId');
      print('   Full name: $fullName, Email: $email, City: $city');
      
      await _client.from('customer_profiles').insert({
        'user_id': userId,
        'full_name': fullName,
        'email': email,
        'city': city,
        'address': address,
        'profile_photo_base64': photoBase64,
        'verified': true,
      });
      
      // Add emergency contact to separate table if provided
      if (emergencyName.isNotEmpty && emergencyPhone.isNotEmpty) {
        try {
          await _client.from('emergency_contacts').insert({
            'user_id': userId,
            'contact_name': emergencyName,
            'contact_phone': emergencyPhone,
            'relationship': 'Emergency Contact',
          });
          print('✅ Emergency contact saved successfully');
        } catch (e) {
          print('⚠️ Emergency contact save failed: $e');
          // Don't fail the whole profile creation if emergency contact fails
        }
      }
      
      print('✅ Customer profile saved successfully for userId: $userId');
    } catch (e) {
      print('❌ Customer profile save failed: $e');
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
    required String docNumber,
    required String? docPhotoBase64,
    required String docType,
    required List<String> services,
    required String bankAccountName,
    required String bankAccountNumber,
    required String bankRoutingNumber,
  }) async {
    try {
      // Ensure user exists before saving provider profile
      final userExists = await _client
          .from('users')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      
      if (userExists == null) {
        throw 'User does not exist in users table. Create user first before provider profile.';
      }
      
      await _client.from('provider_profiles').insert({
        'user_id': userId,
        'full_name': fullName,
        // Map ID document to existing schema fields
        'nid_number': docNumber,
        'nid_photo_base64': docPhotoBase64,
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
            // Use verification_status as primary status if 'pending'
            'status': (provider['verification_status'] == 'pending') 
                ? 'pending' 
                : (provider['status'] ?? 'active'),
            'verified': provider['verification_status'] == 'approved',
            'verification_status': provider['verification_status'] ?? 'pending',
            'rating': 0.0, // Will be calculated from bookings if needed
            'created_at': provider['created_at'],
            'nid_number': provider['nid_number'],
            'nid_photo_base64': provider['nid_photo_base64'],
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
            // Remove verified_by to avoid foreign key constraint
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

  /// List approved providers (optionally filtered by service)
  static Future<List<Map<String, dynamic>>> getApprovedProviders({String? serviceId}) async {
    try {
      var query = _client
          .from('provider_profiles')
          .select()
          .eq('verification_status', 'verified');

      if (serviceId != null && serviceId.isNotEmpty) {
        try {
          query = query.contains('services', [serviceId]);
        } catch (_) {
          // If the column is not an array, fallback to a simple filter
          query = query.eq('service_id', serviceId);
        }
      }

      final data = await query.order('rating', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Failed to load approved providers: $e');
      return [];
    }
  }

  // ============ PROVIDER BOOKING FLOW (UC5) ============

  /// Fetch bookings assigned to a provider, optionally filtered by status.
  static Future<List<Map<String, dynamic>>> getProviderBookings({
    required String providerId,
    List<String>? statuses,
    int limit = 50,
  }) async {
    try {
      var query = _client
          .from('bookings')
          .select('*')
          .eq('provider_id', providerId)
          .order('created_at', ascending: false)
          .limit(limit);

      final data = await query;
      final bookings = List<Map<String, dynamic>>.from(data);

      if (statuses != null && statuses.isNotEmpty) {
        return bookings
            .where((b) => statuses.contains(b['status'].toString()))
            .toList();
      }

      return bookings;
    } catch (e) {
      print('Failed to load provider bookings: $e');
      return [];
    }
  }

  /// Provider accepts a booking (assigns themselves if not already set).
  static Future<void> acceptBooking({
    required String bookingId,
    required String providerId,
  }) async {
    try {
      await _client.from('bookings').update({
        'provider_id': providerId,
        'status': 'accepted',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);
    } catch (e) {
      throw 'Failed to accept booking: $e';
    }
  }

  /// Provider declines booking; booking goes back to assignment pool.
  static Future<void> declineBooking({
    required String bookingId,
  }) async {
    try {
      await _client.from('bookings').update({
        'provider_id': null,
        'status': 'pending_assignment',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);
    } catch (e) {
      throw 'Failed to decline booking: $e';
    }
  }

  /// Provider starts job.
  static Future<void> startJob({
    required String bookingId,
  }) async {
    try {
      await _client.from('bookings').update({
        'status': 'in_progress',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);
    } catch (e) {
      throw 'Failed to start job: $e';
    }
  }

  /// Provider marks job completed (awaiting customer confirmation).
  static Future<void> providerCompleteJob({
    required String bookingId,
  }) async {
    try {
      await _client.from('bookings').update({
        'status': 'confirmed',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);
    } catch (e) {
      throw 'Failed to mark job complete: $e';
    }
  }

  /// Customer confirms completion.
  static Future<void> customerConfirmCompletion({
    required String bookingId,
  }) async {
    try {
      await _client.from('bookings').update({
        'status': 'completed',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);
    } catch (e) {
      throw 'Failed to confirm completion: $e';
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
      // Use smaller selects for better performance - only select id
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
        final customersData = await _client.from('customer_profiles').select('id');
        totalCustomers = (customersData as List).length;
        final activeCustomersData = await _client.from('customer_profiles').select('id').eq('status', 'active');
        activeCustomers = (activeCustomersData as List).length;
      } catch (e) {
        print('Error loading customer stats: $e');
      }

      try {
        final providersData = await _client.from('provider_profiles').select('id');
        totalProviders = (providersData as List).length;
        final activeProvidersData = await _client.from('provider_profiles').select('id').eq('status', 'active');
        activeProviders = (activeProvidersData as List).length;
        final pendingVerificationsData = await _client.from('provider_profiles').select('id').eq('verification_status', 'pending');
        pendingVerifications = (pendingVerificationsData as List).length;
      } catch (e) {
        print('Error loading provider stats: $e');
      }

      try {
        final bookingsData = await _client.from('bookings').select('id');
        totalBookings = (bookingsData as List).length;
        final completedBookingsData = await _client.from('bookings').select('id').eq('status', 'completed');
        completedBookings = (completedBookingsData as List).length;
      } catch (e) {
        print('Error loading booking stats: $e');
      }

      try {
        final complaintsData = await _client.from('complaints').select('id');
        totalComplaints = (complaintsData as List).length;
        final pendingComplaintsData = await _client.from('complaints').select('id').eq('status', 'pending');
        pendingComplaints = (pendingComplaintsData as List).length;
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
          .select('*')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Error loading bookings: $e');
      return []; // Return empty list instead of throwing
    }
  }

  // ============ PROVIDER PROFILE & REVIEWS ============

  /// Get provider profile details (public view for customers)
  static Future<Map<String, dynamic>?> getPublicProviderProfile(String providerId) async {
    try {
      final data = await _client
          .from('provider_profiles')
          .select()
          .eq('user_id', providerId)
          .single();
      return data;
    } catch (e) {
      print('Error loading provider profile: $e');
      return null;
    }
  }

  /// Get provider reviews
  static Future<List<Map<String, dynamic>>> getPublicProviderReviews(String providerId) async {
    try {
      final data = await _client
          .from('reviews')
          .select('''
            *,
            customer:customer_profiles!customer_id(name, profile_photo)
          ''')
          .eq('provider_id', providerId)
          .order('created_at', ascending: false)
          .limit(50);
      
      return data.map<Map<String, dynamic>>((review) {
        return {
          'id': review['id'],
          'rating': review['rating'],
          'comment': review['comment'],
          'created_at': review['created_at'],
          'customer_name': review['customer']?['name'] ?? 'Anonymous',
          'customer_photo': review['customer']?['profile_photo'],
        };
      }).toList();
    } catch (e) {
      print('Error loading provider reviews: $e');
      return [];
    }
  }

  /// Get provider portfolio items
  static Future<List<Map<String, dynamic>>> getPublicProviderPortfolio(String providerId) async {
    try {
      final data = await _client
          .from('portfolio')
          .select()
          .eq('provider_id', providerId)
          .order('created_at', ascending: false)
          .limit(20);
      
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Error loading provider portfolio: $e');
      return [];
    }
  }

  /// Submit a review for a provider
  static Future<void> submitProviderReview({
    required String bookingId,
    required String providerId,
    required String customerId,
    required int rating,
    required String comment,
  }) async {
    try {
      // Insert review
      await _client.from('reviews').insert({
        'booking_id': bookingId,
        'provider_id': providerId,
        'customer_id': customerId,
        'rating': rating,
        'comment': comment,
      });

      // Update provider's average rating
      final reviews = await _client
          .from('reviews')
          .select('rating')
          .eq('provider_id', providerId);

      if (reviews.isNotEmpty) {
        final totalRating = reviews.fold(0.0, (sum, review) => sum + (review['rating'] as int));
        final averageRating = totalRating / reviews.length;

        await _client.from('provider_profiles').update({
          'average_rating': averageRating,
          'total_reviews': reviews.length,
        }).eq('user_id', providerId);
      }
    } catch (e) {
      throw 'Failed to submit review: $e';
    }
  }

  // ============ PROVIDER DASHBOARD STATS ============

  /// Get provider dashboard statistics
  static Future<Map<String, dynamic>> getProviderDashboardStats(String providerId) async {
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      // Get today's earnings
      final todayBookings = await _client
          .from('bookings')
          .select('total_amount')
          .eq('provider_id', providerId)
          .eq('status', 'completed')
          .gte('completed_at', todayStart.toIso8601String());

      final todayEarnings = todayBookings.fold<double>(
        0,
        (sum, booking) => sum + ((booking['total_amount'] as num?)?.toDouble() ?? 0),
      );

      // Get completed jobs count
      final completedBookings = await _client
          .from('bookings')
          .select('id')
          .eq('provider_id', providerId)
          .eq('status', 'completed');

      // Get average rating
      final profile = await _client
          .from('provider_profiles')
          .select('rating')
          .eq('user_id', providerId)
          .single();

      return {
        'todayEarnings': todayEarnings,
        'completedJobs': completedBookings.length,
        'averageRating': profile['rating'] ?? 0.0,
      };
    } catch (e) {
      print('Error loading provider dashboard stats: $e');
      return {
        'todayEarnings': 0.0,
        'completedJobs': 0,
        'averageRating': 0.0,
      };
    }
  }

  /// Get active job for provider
  static Future<Map<String, dynamic>?> getProviderActiveJob(String providerId) async {
    try {
      final data = await _client
          .from('bookings')
          .select('''
            *,
            customer:customer_profiles!customer_id(name, phone, address)
          ''')
          .eq('provider_id', providerId)
          .inFilter('status', ['confirmed', 'in_progress'])
          .order('scheduled_date', ascending: true)
          .limit(1)
          .maybeSingle();

      if (data == null) return null;

      return {
        'id': data['id'],
        'service_name': data['service_name'],
        'status': data['status'],
        'scheduled_date': data['scheduled_date'],
        'scheduled_time': data['scheduled_time'],
        'customer_name': data['customer']?['name'] ?? 'Customer',
        'customer_phone': data['customer']?['phone'],
        'customer_address': data['customer']?['address'],
        'total_amount': data['total_amount'],
      };
    } catch (e) {
      print('Error loading active job: $e');
      return null;
    }
  }

  /// Get upcoming jobs for provider
  static Future<List<Map<String, dynamic>>> getProviderUpcomingJobs(String providerId) async {
    try {
      final now = DateTime.now();
      final data = await _client
          .from('bookings')
          .select('*')
          .eq('provider_id', providerId)
          .eq('status', 'confirmed')
          .gte('scheduled_date', now.toIso8601String())
          .order('scheduled_date', ascending: true)
          .limit(10);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Error loading upcoming jobs: $e');
      return [];
    }
  }
}