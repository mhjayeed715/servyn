import 'package:servyn/core/services/supabase_service.dart';
import 'package:servyn/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  
  @override
  Future<void> sendOtp(String phone) async {
    await SupabaseService.sendOtp(phone);
  }

  @override
  Future<String?> verifyOtp(String phone, String otp) async {
    return await SupabaseService.verifyOtp(phone, otp);
  }

  @override
  Future<void> createCustomer({
    required String userId,
    required String phone,
    required String fullName,
    required String email,
    required String city,
    required String address,
    required String? photoBase64,
    required String emergencyName,
    required String emergencyPhone,
  }) async {
    // Create user entry (phone is stored in users table)
    await SupabaseService.createUser(userId, phone, 'customer');
    
    // Save profile (customer_profiles table doesn't have phone column)
    await SupabaseService.saveCustomerProfile(
      userId: userId,
      fullName: fullName,
      email: email,
      city: city,
      address: address,
      photoBase64: photoBase64,
      emergencyName: emergencyName,
      emergencyPhone: emergencyPhone,
    );
  }

  @override
  Future<void> createProvider({
    required String userId,
    required String phone,
    required String fullName,
    required String docNumber,
    required String? docPhotoBase64,
    required String docType,
    required List<String> services,
    required String bankAccountName,
    required String bankAccountNumber,
    required String bankRoutingNumber,
  }) async {
    // Create user entry
    await SupabaseService.createUser(userId, phone, 'provider');
    
    // Save verification
    await SupabaseService.saveProviderVerification(
      userId: userId,
      fullName: fullName,
      docNumber: docNumber,
      docPhotoBase64: docPhotoBase64,
      docType: docType,
      services: services,
      bankAccountName: bankAccountName,
      bankAccountNumber: bankAccountNumber,
      bankRoutingNumber: bankRoutingNumber,
    );
  }
}
