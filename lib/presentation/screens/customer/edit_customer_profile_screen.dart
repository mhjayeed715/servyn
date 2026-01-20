import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/entities/profile.dart';

class EditCustomerProfileScreen extends StatefulWidget {
  final String customerId;

  const EditCustomerProfileScreen({required this.customerId});

  @override
  State<EditCustomerProfileScreen> createState() =>
      _EditCustomerProfileScreenState();
}

class _EditCustomerProfileScreenState extends State<EditCustomerProfileScreen> {
  late ProfileRepository _profileRepository;
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  
  late TextEditingController _newAddressLabel;
  late TextEditingController _newAddressValue;

  CustomerProfile? _profile;
  List<Map<String, dynamic>> _savedAddresses = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _selectedLanguage = 'Bengali';
  bool _receiveNotifications = true;
  List<String> _selectedServices = [];

  final List<String> _languages = ['Bengali', 'English', 'Hindi'];
  final List<String> _serviceCategories = [
    'Plumbing',
    'Electrical',
    'Cleaning',
    'Carpentry',
    'Painting',
    'Gardening',
  ];

  @override
  void initState() {
    super.initState();
    final supabase = Supabase.instance.client;
    _profileRepository = ProfileRepository(supabase);

    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _newAddressLabel = TextEditingController();
    _newAddressValue = TextEditingController();

    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileRepository.getCustomerProfile(widget.customerId);
      final addresses = await _profileRepository.getSavedAddresses(widget.customerId);

      setState(() {
        _profile = profile;
        _savedAddresses = addresses;
        _fullNameController.text = profile.fullName;
        _phoneController.text = profile.phoneNumber;
        _addressController.text = profile.address ?? '';
        _selectedLanguage = profile.preferredLanguage ?? 'Bengali';
        _receiveNotifications = profile.receiveNotifications;
        _selectedServices = List.from(profile.preferredServiceCategories);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      await _profileRepository.updateCustomerProfile(
        customerId: widget.customerId,
        fullName: _fullNameController.text,
        phoneNumber: _phoneController.text,
        address: _addressController.text,
        preferredLanguage: _selectedLanguage,
        receiveNotifications: _receiveNotifications,
        preferredServiceCategories: _selectedServices,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _addSavedAddress() async {
    if (_newAddressLabel.text.isEmpty || _newAddressValue.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    try {
      // For now, using dummy coordinates. In real app, use geocoding
      await _profileRepository.setSavedAddress(
        customerId: widget.customerId,
        label: _newAddressLabel.text,
        address: _newAddressValue.text,
        latitude: 23.8103,
        longitude: 90.4125,
      );

      _newAddressLabel.clear();
      _newAddressValue.clear();
      await _loadProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving address: $e')),
        );
      }
    }
  }

  Future<void> _deleteSavedAddress(String addressId) async {
    try {
      await _profileRepository.deleteSavedAddress(addressId);
      await _loadProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting address: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Info Section
            Text(
              'Basic Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Current Address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Preferences Section
            Text(
              'Preferences',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: _selectedLanguage,
              isExpanded: true,
              items: _languages.map((lang) {
                return DropdownMenuItem(value: lang, child: Text(lang));
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedLanguage = value);
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Receive Notifications'),
              value: _receiveNotifications,
              onChanged: (value) {
                setState(() => _receiveNotifications = value);
              },
            ),
            const SizedBox(height: 24),

            // Service Categories
            Text(
              'Preferred Services',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _serviceCategories.map((service) {
                final isSelected = _selectedServices.contains(service);
                return FilterChip(
                  label: Text(service),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedServices.add(service);
                      } else {
                        _selectedServices.remove(service);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Saved Addresses
            Text(
              'Saved Addresses',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (_savedAddresses.isEmpty)
              const Text('No saved addresses')
            else
              ..._savedAddresses.map((addr) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(addr['label']),
                    subtitle: Text(addr['address']),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteSavedAddress(addr['id']),
                    ),
                  ),
                );
              }).toList(),
            const SizedBox(height: 16),

            // Add New Address
            Text(
              'Add New Address',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newAddressLabel,
              decoration: InputDecoration(
                labelText: 'Label (e.g., Home, Work)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newAddressValue,
              decoration: InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _addSavedAddress,
              child: const Text('Add Address'),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _newAddressLabel.dispose();
    _newAddressValue.dispose();
    super.dispose();
  }
}
