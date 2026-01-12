import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';

class ProvidersManagementScreen extends StatefulWidget {
  const ProvidersManagementScreen({super.key});

  @override
  State<ProvidersManagementScreen> createState() => _ProvidersManagementScreenState();
}

class _ProvidersManagementScreenState extends State<ProvidersManagementScreen> {
  List<Map<String, dynamic>> _providers = [];
  List<Map<String, dynamic>> _filteredProviders = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProviders();
    _searchController.addListener(_filterProviders);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProviders() async {
    setState(() => _isLoading = true);
    try {
      final users = await SupabaseService.getAllUsers();
      _providers = users.where((u) => u['role'] == 'Provider').toList();
      _filterProviders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load providers: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterProviders() {
    setState(() {
      _filteredProviders = _providers.where((provider) {
        final matchesFilter = _selectedFilter == 'All' ||
            provider['status']?.toString().toLowerCase() == _selectedFilter.toLowerCase();

        final searchQuery = _searchController.text.toLowerCase();
        final matchesSearch = searchQuery.isEmpty ||
            provider['name'].toString().toLowerCase().contains(searchQuery) ||
            provider['email'].toString().toLowerCase().contains(searchQuery) ||
            provider['phone'].toString().contains(searchQuery);

        return matchesFilter && matchesSearch;
      }).toList();
    });
  }

  Future<void> _toggleProviderStatus(String userId, bool isSuspended) async {
    try {
      final currentUser = SupabaseService.getCurrentUser();
      await SupabaseService.toggleUserStatus(
        userId: userId,
        role: 'Provider',
        newStatus: isSuspended ? 'suspended' : 'active',
        adminId: currentUser?.id,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isSuspended ? 'Provider suspended' : 'Provider activated'),
          backgroundColor: Colors.green,
        ),
      );
      
      _loadProviders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update provider: $e')),
      );
    }
  }

  Future<void> _deleteProvider(String userId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Provider'),
        content: Text('Are you sure you want to permanently delete $name? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService.deleteUser(userId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Provider deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadProviders();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete provider: $e')),
        );
      }
    }
  }

  void _showProviderDetails(Map<String, dynamic> provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(0xFFEC9213),
                          child: Text(
                            (provider['name'] ?? 'P')[0].toUpperCase(),
                            style: const TextStyle(fontSize: 32, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider['name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(provider['status'] ?? 'active').withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  (provider['status'] ?? 'active').toUpperCase(),
                                  style: TextStyle(
                                    color: _getStatusColor(provider['status'] ?? 'active'),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(Icons.email, 'Email', provider['email'] ?? 'N/A'),
                    _buildDetailRow(Icons.phone, 'Phone', provider['phone'] ?? 'N/A'),
                    _buildDetailRow(Icons.calendar_today, 'Joined', _formatDate(provider['created_at'])),
                    _buildDetailRow(Icons.book_online, 'Total Bookings', '${provider['bookings_count'] ?? 0}'),
                    if (provider['verified'] == true)
                      _buildDetailRow(Icons.verified, 'Verification', 'Verified', color: Colors.green),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _toggleProviderStatus(
                                provider['id'],
                                provider['status'] != 'suspended',
                              );
                            },
                            icon: Icon(provider['status'] == 'suspended' ? Icons.check_circle : Icons.block),
                            label: Text(provider['status'] == 'suspended' ? 'Activate' : 'Suspend'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: provider['status'] == 'suspended' ? Colors.green : Colors.orange,
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteProvider(provider['id'], provider['name'] ?? 'this provider');
                            },
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: color ?? Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dt = DateTime.parse(date.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'suspended':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFFEC9213),
        title: const Text('Providers Management'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search providers...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Active', 'Suspended', 'Pending'].map((filter) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: _selectedFilter == filter,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                              _filterProviders();
                            });
                          },
                          selectedColor: const Color(0xFFEC9213),
                          labelStyle: TextStyle(
                            color: _selectedFilter == filter ? Colors.white : Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProviders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No providers found',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadProviders,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredProviders.length,
                          itemBuilder: (context, index) {
                            final provider = _filteredProviders[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFEC9213),
                                  child: Text(
                                    (provider['name'] ?? 'P')[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        provider['name'] ?? 'Unknown',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    if (provider['verified'] == true)
                                      const Icon(Icons.verified, size: 16, color: Colors.blue),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(provider['email'] ?? 'N/A'),
                                    Text(provider['phone'] ?? 'N/A'),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(provider['status'] ?? 'active').withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        (provider['status'] ?? 'active').toUpperCase(),
                                        style: TextStyle(
                                          color: _getStatusColor(provider['status'] ?? 'active'),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () => _showProviderDetails(provider),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
