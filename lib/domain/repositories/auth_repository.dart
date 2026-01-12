abstract class AuthRepository {
  Future<void> sendOtp(String phone);
  
  Future<String?> verifyOtp(String phone, String otp);
  
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
  });
  
  Future<void> createProvider({
    required String userId,
    required String phone,
    required String fullName,
    required String nidNumber,
    required String? nidPhotoBase64,
    required List<String> services,
    required String bankAccountName,
    required String bankAccountNumber,
    required String bankRoutingNumber,
  });
}
