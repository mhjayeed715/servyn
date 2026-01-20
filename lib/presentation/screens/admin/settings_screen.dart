import 'package:flutter/material.dart';
import 'package:clipboard/clipboard.dart';
import '../../../core/services/supabase_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _autoApproveProviders = false;
  bool _maintenanceMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            width: double.infinity,
            child: const Text(
              'Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionHeader('General Settings'),
                _buildSettingCard(
                  icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Receive admin notifications',
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Notifications ${value ? 'enabled' : 'disabled'}')),
                );
              },
                    activeColor: const Color(0xFFEC9213),
                  ),
                ),
                _buildSettingCard(
                  icon: Icons.verified_user,
                  title: 'Auto-approve Providers',
                  subtitle: 'Automatically approve new provider registrations',
                  trailing: Switch(
              value: _autoApproveProviders,
              onChanged: (value) {
                setState(() => _autoApproveProviders = value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Auto-approve ${value ? 'enabled' : 'disabled'}')),
                );
              },
                    activeColor: const Color(0xFFEC9213),
                  ),
                ),
                _buildSettingCard(
                  icon: Icons.build,
                  title: 'Maintenance Mode',
                  subtitle: 'Put the app in maintenance mode',
                  trailing: Switch(
              value: _maintenanceMode,
              onChanged: (value) {
                setState(() => _maintenanceMode = value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Maintenance mode ${value ? 'enabled' : 'disabled'}'),
                    backgroundColor: value ? Colors.orange : Colors.green,
                  ),
                );
              },
                    activeColor: Colors.orange,
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('Admin Actions'),
                _buildActionCard(
                  icon: Icons.search,
                  title: 'Search System',
                  subtitle: 'Search users, providers, and bookings',
                  color: Colors.blue,
                  onTap: () {
                    _showSearchDialog();
                  },
                ),
                _buildActionCard(
                  icon: Icons.analytics,
                  title: 'Generate Reports',
                  subtitle: 'Export analytics and reports',
                  color: Colors.green,
                  onTap: () {
                    _generateReports();
                  },
                ),
                _buildActionCard(
                  icon: Icons.backup,
                  title: 'Backup Data',
                  subtitle: 'Create a backup of all data',
                  color: Colors.purple,
                  onTap: () {
                    _showBackupDialog();
                  },
                ),
                _buildActionCard(
                  icon: Icons.restore,
                  title: 'Restore Data',
                  subtitle: 'Restore from a previous backup',
                  color: Colors.orange,
                  onTap: () {
                    _showComingSoonDialog('Restore Data');
                  },
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('Danger Zone'),
                _buildActionCard(
                  icon: Icons.delete_forever,
                  title: 'Clear Cache',
                  subtitle: 'Clear all cached data',
                  color: Colors.red,
                  onTap: () {
                    _showClearCacheDialog();
                  },
                ),
                _buildActionCard(
                  icon: Icons.logout,
                  title: 'Logout',
                  subtitle: 'Sign out from admin panel',
                  color: Colors.grey,
                  onTap: () {
                    _showLogoutDialog();
                  },
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('About'),
                _buildInfoCard('App Version', '1.0.0'),
                _buildInfoCard('Admin ID', SupabaseService.getCurrentUser()?.id ?? 'N/A'),
                _buildInfoCard('Last Updated', DateTime.now().toString().split(' ')[0]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEC9213).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFFEC9213)),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: trailing,
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: const Text('This feature is coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Data'),
        content: const Text('Are you sure you want to create a backup of all data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Backup created successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Backup'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('Are you sure you want to clear all cached data? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout from admin panel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await SupabaseService.logout();
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.popUntil(context, (route) => route.isFirst); // Go to login
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Logout failed: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateReports() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final stats = await SupabaseService.getAdminDashboardStats();
      
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        
        String report = 'ADMIN DASHBOARD REPORT\n';
        report += '=' * 40 + '\n\n';
        report += 'Generated: ${DateTime.now()}\n\n';
        report += 'STATISTICS:\n';
        report += '-' * 40 + '\n';
        report += 'Total Customers: ${stats['total_customers'] ?? 0}\n';
        report += 'Active Customers: ${stats['active_customers'] ?? 0}\n';
        report += 'Total Providers: ${stats['total_providers'] ?? 0}\n';
        report += 'Active Providers: ${stats['active_providers'] ?? 0}\n';
        report += 'Pending Verifications: ${stats['pending_verifications'] ?? 0}\n';
        report += 'Total Bookings: ${stats['total_bookings'] ?? 0}\n';
        report += 'Completed Bookings: ${stats['completed_bookings'] ?? 0}\n';
        report += 'Total Complaints: ${stats['total_complaints'] ?? 0}\n';
        report += 'Pending Complaints: ${stats['pending_complaints'] ?? 0}\n';
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('System Report'),
            content: SingleChildScrollView(
              child: SelectableText(report),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  FlutterClipboard.copy(report).then(( value ) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Report copied to clipboard!')),
                    );
                  });
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Copy'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate report: $e')),
        );
      }
    }
  }

  void _showSearchDialog() {
    final searchController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search System'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Search by name, email, or phone...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Search across all users, providers, and bookings',
              style: TextStyle(fontSize: 12, color: Colors.grey),
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
              if (searchController.text.isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Searching for: ${searchController.text}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEC9213)),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
}
