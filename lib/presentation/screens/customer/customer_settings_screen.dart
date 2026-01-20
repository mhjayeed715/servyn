import 'package:flutter/material.dart';
import '../../../core/services/session_service.dart';
import '../../../services/supabase_config.dart';
import '../auth/auth_choice_screen.dart';

class CustomerSettingsScreen extends StatefulWidget {
  const CustomerSettingsScreen({Key? key}) : super(key: key);

  @override
  State<CustomerSettingsScreen> createState() => _CustomerSettingsScreenState();
}

class _CustomerSettingsScreenState extends State<CustomerSettingsScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isBangla = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final userId = await SessionService.getUserId();
      if (userId != null) {
        final response = await SupabaseConfig.client
            .from('customer_profiles')
            .select('*, users!inner(phone)')
            .eq('user_id', userId)
            .single();
        setState(() {
          _userData = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SessionService.clearSession();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthChoiceScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F7F6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF181511)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings & Profile',
          style: TextStyle(
            color: Color(0xFF181511),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEC9213)))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFF8F7F6),
                                  width: 4,
                                ),
                                image: _userData?['profile_photo'] != null
                                    ? DecorationImage(
                                        image: NetworkImage(_userData!['profile_photo']),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                color: const Color(0xFFE6E1DB),
                              ),
                              child: _userData?['profile_photo'] == null
                                  ? const Icon(Icons.person, size: 48, color: Color(0xFF897961))
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEC9213),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.verified, color: Colors.white, size: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _userData?['name'] ?? 'User',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF181511),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              'Trust Score: ${(_userData?['trust_score'] ?? 4.8).toStringAsFixed(1)}/5',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF897961),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: () {
                              // Navigate to edit profile
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEC9213).withOpacity(0.1),
                              foregroundColor: const Color(0xFFEC9213),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Edit Profile',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Account Section
                  _buildSection(
                    'Account',
                    [
                      _buildListTile(
                        icon: Icons.person,
                        title: 'Personal Information',
                        onTap: () {},
                      ),
                      _buildListTile(
                        icon: Icons.location_on,
                        title: 'Saved Addresses',
                        onTap: () {},
                      ),
                      _buildListTile(
                        icon: Icons.credit_card,
                        title: 'Payment Methods',
                        onTap: () {},
                      ),
                    ],
                  ),

                  // Preferences Section
                  _buildSection(
                    'Preferences',
                    [
                      _buildListTile(
                        icon: Icons.notifications,
                        title: 'Notifications',
                        onTap: () {},
                      ),
                      _buildLanguageToggle(),
                      _buildListTile(
                        icon: Icons.security,
                        title: 'Privacy & Security',
                        onTap: () {},
                      ),
                    ],
                  ),

                  // Support Section
                  _buildSection(
                    'Support',
                    [
                      _buildListTile(
                        icon: Icons.help,
                        title: 'Help Center',
                        onTap: () {},
                      ),
                      _buildListTile(
                        icon: Icons.description,
                        title: 'Terms of Service',
                        onTap: () {},
                      ),
                    ],
                  ),

                  // Logout Button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _logout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Colors.red.withOpacity(0.2),
                                ),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.logout),
                                SizedBox(width: 8),
                                Text(
                                  'Log Out',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Version 1.0.2',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF897961),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF897961),
                letterSpacing: 1.2,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: items.map((item) {
                final isLast = items.indexOf(item) == items.length - 1;
                return Column(
                  children: [
                    item,
                    if (!isLast)
                      const Divider(height: 1, indent: 72, color: Color(0xFFF4F3F0)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFEC9213).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFFEC9213), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF181511),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF897961)),
      onTap: onTap,
    );
  }

  Widget _buildLanguageToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEC9213).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.translate, color: Color(0xFFEC9213), size: 20),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Language',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF181511),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F3F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLanguageButton('Eng', !_isBangla),
                _buildLanguageButton('বাংলা', _isBangla),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _isBangla = text == 'বাংলা'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFFEC9213) : const Color(0xFF897961),
          ),
        ),
      ),
    );
  }
}
