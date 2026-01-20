import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/session_service.dart';
import 'rate_service_screen.dart';
import 'file_complaint_screen.dart';
import '../tracking/job_status_timeline_screen.dart';
import '../tracking/live_tracking_screen.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  String _selectedFilter = 'all';
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;

  final List<Map<String, String>> _filters = [
    {'value': 'all', 'label': 'All'},
    {'value': 'pending', 'label': 'Pending'},
    {'value': 'in_progress', 'label': 'Active'},
    {'value': 'completed', 'label': 'Completed'},
    {'value': 'cancelled', 'label': 'Cancelled'},
  ];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);

    try {
      final userId = await SessionService.getUserId();
      if (userId == null) return;

      // Build base query
      var baseQuery = Supabase.instance.client
          .from('bookings')
          .select('''
            *,
            service_categories(*)
          ''')
          .eq('customer_id', userId);

      // Apply status filter
      if (_selectedFilter != 'all') {
        if (_selectedFilter == 'in_progress') {
          // For multiple status values, we need to do multiple queries or use inFilter
          baseQuery = baseQuery.inFilter('status', ['confirmed', 'provider_assigned', 'en_route', 'in_progress']);
        } else {
          baseQuery = baseQuery.eq('status', _selectedFilter);
        }
      }

      // Apply ordering and execute
      final response = await baseQuery.order('created_at', ascending: false);
      setState(() {
        _bookings = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading bookings: $e');
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
      case 'provider_assigned':
        return Colors.blue;
      case 'en_route':
      case 'in_progress':
        return Colors.green;
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'provider_assigned':
        return 'Provider Assigned';
      case 'en_route':
        return 'En Route';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
      case 'provider_assigned':
        return Icons.check_circle_outline;
      case 'en_route':
        return Icons.directions_car;
      case 'in_progress':
        return Icons.construction;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF181511)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Bookings',
          style: TextStyle(
            color: Color(0xFF181511),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter['value'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter['label']!),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter['value']!;
                        });
                        _loadBookings();
                      },
                      backgroundColor: Colors.white,
                      selectedColor: const Color(0xFFEC9213).withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected ? const Color(0xFFEC9213) : const Color(0xFF897961),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFFEC9213) : const Color(0xFFE6E1DB),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Bookings list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFEC9213),
                    ),
                  )
                : _bookings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No bookings found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadBookings,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _bookings.length,
                          itemBuilder: (context, index) {
                            final booking = _bookings[index];
                            final status = booking['status'] ?? 'pending';
                            final isCompleted = status == 'completed';
                            final isActive = ['en_route', 'in_progress'].contains(status);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => JobStatusTimelineScreen(
                                        bookingId: booking['id'],
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header row with service and status
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  booking['service_categories']?['name'] ?? 'Service',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF181511),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Order #${booking['id'].substring(0, 8)}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF897961),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(status).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: _getStatusColor(status),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _getStatusIcon(status),
                                                  size: 14,
                                                  color: _getStatusColor(status),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _getStatusLabel(status),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: _getStatusColor(status),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 12),
                                      const Divider(height: 1),
                                      const SizedBox(height: 12),

                                      // Details
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today, size: 16, color: Color(0xFF897961)),
                                          const SizedBox(width: 8),
                                          Text(
                                            booking['scheduled_time'] != null
                                                ? '${DateTime.parse(booking['scheduled_time']).toLocal().toString().split(' ')[0]}'
                                                : 'Not scheduled',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF181511),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.person, size: 16, color: Color(0xFF897961)),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Provider #${booking['provider_id'].toString().substring(0, 8)}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF181511),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.payment, size: 16, color: Color(0xFF897961)),
                                          const SizedBox(width: 8),
                                          Text(
                                            '৳${booking['total_amount']?.toStringAsFixed(2) ?? '0.00'}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFEC9213),
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Action buttons for completed bookings
                                      if (isCompleted) ...[
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => RateServiceScreen(
                                                        bookingId: booking['id'],
                                                        providerId: booking['provider_id'],
                                                        providerName: 'Provider',
                                                        serviceCategory: booking['service_categories']?['name'] ?? 'Service',
                                                      ),
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(Icons.star_outline, size: 18),
                                                label: const Text('Rate Service'),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: const Color(0xFFEC9213),
                                                  side: const BorderSide(color: Color(0xFFEC9213)),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => FileComplaintScreen(
                                                        bookingId: booking['id'],
                                                        providerId: booking['provider_id'],
                                                        providerName: 'Provider',
                                                      ),
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(Icons.report_outlined, size: 18),
                                                label: const Text('Complaint'),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.red[700],
                                                  side: BorderSide(color: Colors.red[300]!),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],

                                      // Track button for active bookings
                                      if (isActive) ...[
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => LiveTrackingScreen(
                                                    bookingId: booking['id'],
                                                  ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.location_on),
                                            label: const Text('Track Live'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFEC9213),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
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
