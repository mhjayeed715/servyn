import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/supabase_config.dart';
import '../../../core/services/session_service.dart';

class SosAlertsHistoryScreen extends StatefulWidget {
  const SosAlertsHistoryScreen({Key? key}) : super(key: key);

  @override
  State<SosAlertsHistoryScreen> createState() => _SosAlertsHistoryScreenState();
}

class _SosAlertsHistoryScreenState extends State<SosAlertsHistoryScreen> {
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;
  String _filterStatus = 'all'; // all, active, cancelled, resolved

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    try {
      setState(() => _isLoading = true);
      final userId = await SessionService.getUserId();
      if (userId == null) throw 'User not authenticated';

      var query = SupabaseConfig.client
          .from('sos_alerts')
          .select()
          .eq('user_id', userId);

      if (_filterStatus != 'all') {
        query = query.eq('status', _filterStatus);
      }

      final response = await query.order('created_at', ascending: false);

      setState(() {
        _alerts = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading alerts: $e')),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.red;
      case 'resolved':
        return Colors.green;
      case 'cancelled':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.warning;
      case 'resolved':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getReasonIcon(String reason) {
    final iconMap = {
      'Unsafe Behavior': '⚠️',
      'Suspicious Activity': '👁️',
      'Injury/Medical Emergency': '🏥',
      'Property Damage': '🔨',
      'Lost Items': '❌',
      'Other': '❓',
    };
    return iconMap[reason] ?? '❓';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Alert History'),
        centerTitle: true,
        backgroundColor: Colors.red.shade700,
      ),
      body: Column(
        children: [
          // Filter Tabs
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All'),
                  _buildFilterChip('active', 'Active'),
                  _buildFilterChip('resolved', 'Resolved'),
                  _buildFilterChip('cancelled', 'Cancelled'),
                ],
              ),
            ),
          ),
          // Alerts List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _alerts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            const Text(
                              'No SOS Alerts',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5F758C),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _alerts.length,
                        itemBuilder: (context, index) {
                          final alert = _alerts[index];
                          final createdAt = DateTime.parse(alert['created_at']);
                          final formattedDate = DateFormat('dd MMM, yyyy - hh:mm a').format(createdAt);
                          final status = alert['status'] ?? 'unknown';
                          final reason = alert['reason'] ?? 'Unknown';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                                color: status == 'active' ? Colors.red.shade50 : Colors.white,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header with status and reason
                                    Row(
                                      children: [
                                        Text(
                                          _getReasonIcon(reason),
                                          style: const TextStyle(fontSize: 28),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                reason,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF181511),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                formattedDate,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF5F758C),
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
                                            border: Border.all(color: _getStatusColor(status)),
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
                                                status[0].toUpperCase() + status.substring(1),
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
                                    const SizedBox(height: 16),

                                    // Location info
                                    if (alert['latitude'] != null && alert['longitude'] != null)
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            size: 16,
                                            color: Colors.red,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Location: ${alert['latitude']?.toStringAsFixed(4)}, ${alert['longitude']?.toStringAsFixed(4)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF5F758C),
                                            ),
                                          ),
                                        ],
                                      ),

                                    // Booking reference
                                    if (alert['booking_id'] != null) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.receipt,
                                            size: 16,
                                            color: Colors.blue,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Booking: ${alert['booking_id']}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF5F758C),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],

                                    // Resolution time
                                    if (alert['cancelled_at'] != null) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.access_time,
                                            size: 16,
                                            color: Colors.orange,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Cancelled at: ${DateFormat('hh:mm a').format(DateTime.parse(alert['cancelled_at']))}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF5F758C),
                                            ),
                                          ),
                                        ],
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
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filterStatus == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filterStatus = value;
            _loadAlerts();
          });
        },
        backgroundColor: Colors.white,
        selectedColor: Colors.red.shade700,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide(
          color: isSelected ? Colors.red.shade700 : Colors.grey.shade300,
        ),
      ),
    );
  }
}
