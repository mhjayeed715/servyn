import 'package:flutter/material.dart';

class ComplaintStatusScreen extends StatefulWidget {
  const ComplaintStatusScreen({super.key});

  @override
  State<ComplaintStatusScreen> createState() => _ComplaintStatusScreenState();
}

class _ComplaintStatusScreenState extends State<ComplaintStatusScreen> {
  String _selectedFilter = 'Active';
  bool _showNotification = true;

  final List<Map<String, dynamic>> _complaints = [
    {
      'id': '#49201',
      'provider': 'Green Leaf Landscaping',
      'issue': 'Incomplete yard work on Saturday.',
      'date': 'Today, 10:30 AM',
      'status': 'Provider Responded',
      'progress': 2,
      'statusMessage': 'Waiting for your confirmation.',
      'type': 'active',
    },
    {
      'id': '#49188',
      'provider': 'Fix-It Plumbing',
      'issue': 'Overcharged for replacement parts.',
      'date': 'Yesterday',
      'status': 'Pending Review',
      'progress': 1,
      'statusMessage': 'Submitted to support team.',
      'type': 'active',
    },
    {
      'id': '#48900',
      'provider': 'Sparkle Cleaners',
      'issue': 'Cleaner arrived 2 hours late.',
      'date': '3 days ago',
      'status': 'Resolved',
      'progress': 4,
      'statusMessage': 'Refund processed on Oct 12.',
      'type': 'resolved',
    },
  ];

  List<Map<String, dynamic>> get _filteredComplaints {
    if (_selectedFilter == 'All') return _complaints;
    if (_selectedFilter == 'Active') {
      return _complaints.where((c) => c['type'] == 'active').toList();
    }
    return _complaints.where((c) => c['type'] == 'resolved').toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F7F6).withOpacity(0.95),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF181511)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Resolution Center',
          style: TextStyle(
            color: Color(0xFF181511),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF181511)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('Active'),
                const SizedBox(width: 12),
                _buildFilterChip('Resolved'),
                const SizedBox(width: 12),
                _buildFilterChip('All'),
              ],
            ),
          ),

          // Notification Banner
          if (_showNotification)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: const Border(
                  left: BorderSide(color: Color(0xFFEC9213), width: 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEC9213).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.notifications_active,
                      color: Color(0xFFEC9213),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Update from Support',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF181511),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Green Leaf Landscaping has responded to your complaint. Tap to view the details.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF897961),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: Colors.grey,
                    onPressed: () {
                      setState(() {
                        _showNotification = false;
                      });
                    },
                  ),
                ],
              ),
            ),

          // Complaints List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filteredComplaints.length,
              itemBuilder: (context, index) {
                return _buildComplaintCard(_filteredComplaints[index]);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to complaint form
        },
        backgroundColor: const Color(0xFFEC9213),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEC9213) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? null : Border.all(color: Colors.grey[300]!),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFEC9213).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : const Color(0xFF181511),
          ),
        ),
      ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> complaint) {
    final isResolved = complaint['type'] == 'resolved';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.business,
                        color: Color(0xFFEC9213),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            complaint['provider'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF181511),
                            ),
                          ),
                          Text(
                            'ID: ${complaint['id']} • ${complaint['date']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF897961),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  complaint['issue'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF181511),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isResolved
                        ? Colors.green.withOpacity(0.05)
                        : const Color(0xFFF8F7F6),
                    borderRadius: BorderRadius.circular(8),
                    border: isResolved
                        ? Border.all(color: Colors.green.withOpacity(0.1))
                        : null,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              if (isResolved)
                                const Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Colors.green,
                                ),
                              if (isResolved) const SizedBox(width: 4),
                              Text(
                                complaint['status'],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isResolved
                                      ? Colors.green
                                      : const Color(0xFFEC9213),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            isResolved
                                ? 'Complete'
                                : 'Step ${complaint['progress']} of 4',
                            style: TextStyle(
                              fontSize: 12,
                              color: isResolved
                                  ? Colors.green.withOpacity(0.7)
                                  : const Color(0xFF897961),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(4, (index) {
                          return Expanded(
                            child: Container(
                              margin: EdgeInsets.only(
                                right: index < 3 ? 6 : 0,
                              ),
                              height: 6,
                              decoration: BoxDecoration(
                                color: index < complaint['progress']
                                    ? (isResolved ? Colors.green : const Color(0xFFEC9213))
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        complaint['statusMessage'],
                        style: TextStyle(
                          fontSize: 12,
                          color: isResolved ? Colors.green[700] : const Color(0xFF897961),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
