import 'package:flutter/material.dart';

class ComplaintManagementScreen extends StatefulWidget {
  const ComplaintManagementScreen({super.key});

  @override
  State<ComplaintManagementScreen> createState() => _ComplaintManagementScreenState();
}

class _ComplaintManagementScreenState extends State<ComplaintManagementScreen> {
  String _selectedFilter = 'All';
  
  final List<Map<String, dynamic>> _complaints = [
    {
      'id': '1',
      'title': 'Service Not Completed',
      'customer': 'Alice Johnson',
      'provider': 'John Smith - Plumber',
      'bookingId': '#12345',
      'description': 'Provider did not complete the plumbing repair work as promised. Left the job halfway.',
      'status': 'pending',
      'priority': 'high',
      'date': '2 hours ago',
      'category': 'Service Quality',
    },
    {
      'id': '2',
      'title': 'Overcharging Issue',
      'customer': 'Bob Williams',
      'provider': 'Sarah Chen - Electrician',
      'bookingId': '#12344',
      'description': 'Provider charged extra ৳2000 beyond the agreed price without prior notice.',
      'status': 'pending',
      'priority': 'medium',
      'date': '5 hours ago',
      'category': 'Payment',
    },
    {
      'id': '3',
      'title': 'Late Arrival',
      'customer': 'Carol Davis',
      'provider': 'Mike Brown - Cleaner',
      'bookingId': '#12343',
      'description': 'Provider arrived 2 hours late without any notification.',
      'status': 'resolved',
      'priority': 'low',
      'date': '1 day ago',
      'category': 'Punctuality',
    },
    {
      'id': '4',
      'title': 'Damaged Property',
      'customer': 'David Lee',
      'provider': 'Emma Wilson - Carpenter',
      'bookingId': '#12342',
      'description': 'Provider accidentally broke a glass table while working. Requesting compensation.',
      'status': 'in_progress',
      'priority': 'high',
      'date': '3 hours ago',
      'category': 'Damage',
    },
  ];

  List<Map<String, dynamic>> get _filteredComplaints {
    if (_selectedFilter == 'All') return _complaints;
    return _complaints.where((c) => c['status'] == _selectedFilter.toLowerCase()).toList();
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return const Color(0xFFEC9213);
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFEC9213);
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      default:
        return status;
    }
  }

  void _viewComplaintDetails(Map<String, dynamic> complaint) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ComplaintDetailsSheet(
        complaint: complaint,
        onResolve: () {
          setState(() {
            complaint['status'] = 'resolved';
          });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Complaint marked as resolved')),
          );
        },
        onInvestigate: () {
          setState(() {
            complaint['status'] = 'in_progress';
          });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Investigation started')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Complaint Management',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF181511),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF181511)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFF181511)),
            onPressed: () {
              _showFilterOptions();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Overview
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatBox(
                    'Pending',
                    _complaints.where((c) => c['status'] == 'pending').length.toString(),
                    const Color(0xFFEC9213),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatBox(
                    'In Progress',
                    _complaints.where((c) => c['status'] == 'in_progress').length.toString(),
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatBox(
                    'Resolved',
                    _complaints.where((c) => c['status'] == 'resolved').length.toString(),
                    Colors.green,
                  ),
                ),
              ],
            ),
          ),

          // Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All'),
                  _buildFilterChip('Pending'),
                  _buildFilterChip('In Progress'),
                  _buildFilterChip('Resolved'),
                ],
              ),
            ),
          ),

          // Complaints List
          Expanded(
            child: _filteredComplaints.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No $_selectedFilter complaints',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredComplaints.length,
                    itemBuilder: (context, index) {
                      final complaint = _filteredComplaints[index];
                      return _buildComplaintCard(complaint);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF897961),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = label;
          });
        },
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFFEC9213),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF181511),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? const Color(0xFFEC9213) : const Color(0xFFE6E1DB),
        ),
      ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> complaint) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E1DB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _viewComplaintDetails(complaint),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(complaint['priority']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.flag,
                            size: 12,
                            color: _getPriorityColor(complaint['priority']),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            complaint['priority'].toString().toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getPriorityColor(complaint['priority']),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(complaint['status']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _getStatusColor(complaint['status']).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _getStatusLabel(complaint['status']),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(complaint['status']),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Title
                Text(
                  complaint['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF181511),
                  ),
                ),

                const SizedBox(height: 8),

                // Details
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Color(0xFF897961)),
                    const SizedBox(width: 4),
                    Text(
                      complaint['customer'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF897961),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.work, size: 16, color: Color(0xFF897961)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        complaint['provider'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF897961),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.receipt, size: 16, color: Color(0xFF897961)),
                    const SizedBox(width: 4),
                    Text(
                      'Booking ${complaint['bookingId']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF897961),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      complaint['date'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF897961),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  complaint['description'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF181511),
                  ),
                ),

                const SizedBox(height: 12),

                // Footer
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F7F6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        complaint['category'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF897961),
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF897961)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter by Priority',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFilterOption('All Priorities'),
            _buildFilterOption('High Priority'),
            _buildFilterOption('Medium Priority'),
            _buildFilterOption('Low Priority'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label) {
    return ListTile(
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        // Apply filter logic here
      },
    );
  }
}

class _ComplaintDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> complaint;
  final VoidCallback onResolve;
  final VoidCallback onInvestigate;

  const _ComplaintDetailsSheet({
    required this.complaint,
    required this.onResolve,
    required this.onInvestigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE6E1DB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    complaint['title'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF181511),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Status & Priority
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEC9213).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          complaint['priority'].toString().toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEC9213),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          complaint['status'].toString().toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Details
                  _buildDetailRow('Customer', complaint['customer'], Icons.person),
                  _buildDetailRow('Provider', complaint['provider'], Icons.work),
                  _buildDetailRow('Booking ID', complaint['bookingId'], Icons.receipt),
                  _buildDetailRow('Category', complaint['category'], Icons.category),
                  _buildDetailRow('Reported', complaint['date'], Icons.access_time),

                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF181511),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    complaint['description'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF897961),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onInvestigate,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEC9213),
                        side: const BorderSide(color: Color(0xFFEC9213)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Investigate'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onResolve,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEC9213),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Mark Resolved'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF897961)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF897961),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF181511),
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
