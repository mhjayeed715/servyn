import 'package:flutter/material.dart';
import 'package:clipboard/clipboard.dart';
import '../../../core/services/supabase_service.dart';

class BookingsManagementScreen extends StatefulWidget {
  const BookingsManagementScreen({super.key});

  @override
  State<BookingsManagementScreen> createState() => _BookingsManagementScreenState();
}

class _BookingsManagementScreenState extends State<BookingsManagementScreen> {
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _filteredBookings = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBookings();
    _searchController.addListener(_filterBookings);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final bookings = await SupabaseService.getAllBookings();
      setState(() {
        _bookings = bookings;
        _filterBookings();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load bookings: $e')),
        );
      }
    }
  }

  void _filterBookings() {
    setState(() {
      _filteredBookings = _bookings.where((booking) {
        final matchesFilter = _selectedFilter == 'All' ||
            booking['status']?.toString().toLowerCase() == _selectedFilter.toLowerCase();

        final searchQuery = _searchController.text.toLowerCase();
        final matchesSearch = searchQuery.isEmpty ||
            booking['id'].toString().toLowerCase().contains(searchQuery) ||
            (booking['service_name']?.toString().toLowerCase().contains(searchQuery) ?? false);

        return matchesFilter && matchesSearch;
      }).toList();
    });
  }

  void _showBookingDetails(Map<String, dynamic> booking) {
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
                    Text(
                      'Booking Details',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getStatusColor(booking['status'] ?? 'pending').withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getStatusIcon(booking['status'] ?? 'pending'),
                            color: _getStatusColor(booking['status'] ?? 'pending'),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            (booking['status'] ?? 'pending').toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(booking['status'] ?? 'pending'),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(Icons.receipt, 'Booking ID', booking['id'] ?? 'N/A'),
                    _buildDetailRow(Icons.build, 'Service', booking['service_name'] ?? 'N/A'),
                    _buildDetailRow(Icons.person, 'Customer ID', booking['customer_id'] ?? 'N/A'),
                    _buildDetailRow(Icons.work, 'Provider ID', booking['provider_id'] ?? 'N/A'),
                    _buildDetailRow(Icons.location_on, 'Address', booking['address'] ?? 'N/A'),
                    _buildDetailRow(Icons.calendar_today, 'Date', _formatDate(booking['booking_date'])),
                    _buildDetailRow(Icons.access_time, 'Time', booking['booking_time'] ?? 'N/A'),
                    _buildDetailRow(Icons.attach_money, 'Amount', '৳${booking['total_amount'] ?? 0}'),
                    _buildDetailRow(Icons.date_range, 'Created', _formatDateTime(booking['created_at'])),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEC9213),
                        padding: const EdgeInsets.all(16),
                      ),
                      child: const Text('Close'),
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
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
      return date.toString();
    }
  }

  String _formatDateTime(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dt = DateTime.parse(date.toString());
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'in_progress':
      case 'in-progress':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'in_progress':
      case 'in-progress':
        return Icons.pending;
      case 'pending':
        return Icons.schedule;
      default:
        return Icons.help_outline;
    }
  }

  Future<void> _exportBookingsCSV() async {
    try {
      String csv = 'Booking ID,Service,Customer,Provider,Status,Date,Amount\n';
      
      for (var booking in _filteredBookings) {
        final id = booking['id']?.toString().substring(0, 8) ?? 'N/A';
        final service = booking['service_name'] ?? 'N/A';
        final customer = booking['customer_name'] ?? 'N/A';
        final provider = booking['provider_name'] ?? 'N/A';
        final status = booking['status'] ?? 'N/A';
        final date = _formatDate(booking['booking_date']);
        final amount = booking['total_amount'] ?? 0;
        
        csv += '"$id","$service","$customer","$provider","$status","$date","$amount"\n';
      }
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Bookings'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${_filteredBookings.length} bookings ready to export'),
                  const SizedBox(height: 16),
                  SelectableText(
                    csv,
                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  FlutterClipboard.copy(csv).then(( value ) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('CSV copied to clipboard!')),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bookings Management',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.download),
                      tooltip: 'Export CSV',
                      onPressed: _exportBookingsCSV,
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                      onPressed: _loadBookings,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search bookings...',
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
                    children: ['All', 'Pending', 'In-Progress', 'Completed', 'Cancelled'].map((filter) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: _selectedFilter == filter,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                              _filterBookings();
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
                : _filteredBookings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No bookings found',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadBookings,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredBookings.length,
                          itemBuilder: (context, index) {
                            final booking = _filteredBookings[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(booking['status'] ?? 'pending').withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getStatusIcon(booking['status'] ?? 'pending'),
                                    color: _getStatusColor(booking['status'] ?? 'pending'),
                                  ),
                                ),
                                title: Text(
                                  booking['service_name'] ?? 'Service Booking',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('ID: ${booking['id']?.toString().substring(0, 8) ?? 'N/A'}...'),
                                    Text('Date: ${_formatDate(booking['booking_date'])}'),
                                    Text('Amount: ৳${booking['total_amount'] ?? 0}'),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(booking['status'] ?? 'pending').withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        (booking['status'] ?? 'pending').toUpperCase(),
                                        style: TextStyle(
                                          color: _getStatusColor(booking['status'] ?? 'pending'),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () => _showBookingDetails(booking),
                              ),
                            );
                          },
                        ),
                      ),
            ),
          ],
        ),
      ),
        ],
      ),
    );
  }
}
