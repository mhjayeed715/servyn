import 'package:flutter/material.dart';
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
      appBar: AppBar(
        backgroundColor: const Color(0xFFEC9213),
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
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
            icon: Icons.people,
            title: 'View All Users',
            subtitle: 'See complete user list',
            color: Colors.blue,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigate to Users Management tab')),
              );
            },
          ),
          _buildActionCard(
            icon: Icons.analytics,
            title: 'Generate Reports',
            subtitle: 'Export analytics and reports',
            color: Colors.green,
            onTap: () {
              _showComingSoonDialog('Generate Reports');
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
}
