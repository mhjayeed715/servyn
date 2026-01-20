import 'package:flutter/material.dart';

class StatusUpdateScreen extends StatefulWidget {
  final Map<String, dynamic>? jobData;

  const StatusUpdateScreen({super.key, this.jobData});

  @override
  State<StatusUpdateScreen> createState() => _StatusUpdateScreenState();
}

class _StatusUpdateScreenState extends State<StatusUpdateScreen> {
  JobStatus _currentStatus = JobStatus.enRoute;
  
  @override
  void initState() {
    super.initState();
    // Initialize status from job data if provided
    if (widget.jobData != null) {
      final status = widget.jobData!['status'] ?? 'en_route';
      _currentStatus = _parseJobStatus(status);
    }
  }

  JobStatus _parseJobStatus(String status) {
    switch (status) {
      case 'accepted':
        return JobStatus.accepted;
      case 'en_route':
        return JobStatus.enRoute;
      case 'arrived':
        return JobStatus.arrived;
      case 'in_progress':
        return JobStatus.inProgress;
      case 'completed':
        return JobStatus.completed;
      default:
        return JobStatus.enRoute;
    }
  }

  void _handleStatusUpdate(JobStatus newStatus) {
    setState(() {
      _currentStatus = newStatus;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('Status Updated', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton(
              onPressed: () {
                // Undo functionality
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
              child: const Text('UNDO', style: TextStyle(color: Color(0xFFEC9213), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2C241B),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _makeCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Calling customer...')),
    );
  }

  void _getHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.support_agent, color: Color(0xFFEC9213)),
            SizedBox(width: 8),
            Text('Help & Support'),
          ],
        ),
        content: const Text('Need assistance? Our support team is here to help.\n\n• Call: 09639-333-444\n• Email: support@servyn.com\n• Live chat available 24/7'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.jobData ?? {
      'id': '4092',
      'service_name': 'Plumbing Leak Repair',
      'customer_name': 'Alice Smith',
      'address': '123 Maple Ave, Apt 4B',
      'distance': '4.2 mi',
      'duration': '12 min',
      'is_urgent': true,
      'accepted_at': '08:30 AM',
    };

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
          'Current Job',
          style: TextStyle(color: Color(0xFF181511), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _getHelp,
              icon: const Icon(Icons.support_agent, size: 18, color: Color(0xFF897961)),
              label: const Text('Help', style: TextStyle(color: Color(0xFF897961), fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFF4F3F0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Job Header Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Map Preview
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Stack(
                    children: [
                      Container(
                        height: 144,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.map, size: 60, color: Colors.grey),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black.withOpacity(0.05)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.directions_car, color: Color(0xFFEC9213), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '${job['duration']} (${job['distance']})',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF181511)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Job Details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (job['is_urgent'] == true)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'URGENT',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '#${job['id']}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  job['service_name'],
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF181511),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 18, color: Color(0xFF897961)),
                                    const SizedBox(width: 8),
                                    Text(
                                      job['customer_name'],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF181511),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 18, color: Color(0xFF897961)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        job['address'],
                                        style: const TextStyle(fontSize: 14, color: Color(0xFF897961)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Call Button
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F7F6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE6E1DB)),
                            ),
                            child: IconButton(
                              onPressed: _makeCall,
                              icon: const Icon(Icons.call, color: Color(0xFF181511)),
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

          const SizedBox(height: 24),

          // Timeline Steps
          _buildTimeline(job),
        ],
      ),
    );
  }

  Widget _buildTimeline(Map<String, dynamic> job) {
    return Column(
      children: [
        // Step 1: Accepted (Completed)
        _buildTimelineStep(
          icon: Icons.check,
          iconColor: Colors.white,
          bgColor: Colors.green,
          title: 'Job Accepted',
          subtitle: job['accepted_at'],
          isCompleted: true,
          showLine: true,
        ),

        // Step 2: En Route (Current)
        if (_currentStatus == JobStatus.enRoute || _currentStatus == JobStatus.accepted)
          _buildActiveStep(
            icon: Icons.local_shipping,
            title: 'STATUS: EN ROUTE',
            subtitle: 'You are on the way to the customer',
            buttonText: 'I Have Arrived',
            buttonSubtext: 'Tap to confirm arrival',
            onPressed: () => _handleStatusUpdate(JobStatus.arrived),
          ),

        // Step 2: Arrived (Current)
        if (_currentStatus == JobStatus.arrived)
          _buildActiveStep(
            icon: Icons.pin_drop,
            title: 'STATUS: ARRIVED',
            subtitle: 'You have reached the customer location',
            buttonText: 'Start Job',
            buttonSubtext: 'Begin working on the service',
            onPressed: () => _handleStatusUpdate(JobStatus.inProgress),
          ),

        // Step 3: Start Job
        _buildTimelineStep(
          icon: Icons.play_arrow,
          iconColor: _currentStatus.index >= JobStatus.inProgress.index ? Colors.white : Colors.grey[400]!,
          bgColor: _currentStatus.index >= JobStatus.inProgress.index ? const Color(0xFFEC9213) : Colors.grey[100]!,
          title: 'Start Job',
          subtitle: _currentStatus.index >= JobStatus.inProgress.index ? 'In progress...' : 'Locked until arrival',
          isCompleted: _currentStatus.index >= JobStatus.inProgress.index,
          isLocked: _currentStatus.index < JobStatus.arrived.index,
          showLine: true,
        ),

        // Step 4: Complete Job
        _buildTimelineStep(
          icon: Icons.check_circle,
          iconColor: _currentStatus == JobStatus.completed ? Colors.white : Colors.grey[400]!,
          bgColor: _currentStatus == JobStatus.completed ? Colors.green : Colors.grey[100]!,
          title: 'Complete Job',
          subtitle: _currentStatus == JobStatus.completed ? 'Job finished' : 'Locked until started',
          isCompleted: _currentStatus == JobStatus.completed,
          isLocked: _currentStatus.index < JobStatus.inProgress.index,
          showLine: false,
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required bool isCompleted,
    bool isLocked = false,
    required bool showLine,
  }) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF8F7F6), width: 3),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Opacity(
                opacity: isCompleted ? 0.5 : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: isLocked
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE6E1DB), style: BorderStyle.solid),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const Icon(Icons.lock, color: Colors.grey, size: 20),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF181511),
                              ),
                            ),
                            Text(
                              subtitle,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF897961)),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
        if (showLine)
          Container(
            margin: const EdgeInsets.only(left: 19),
            width: 2,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE6E1DB),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
      ],
    );
  }

  Widget _buildActiveStep({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required String buttonSubtext,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Icon with Pulse
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEC9213),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF8F7F6), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEC9213).withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Icon(icon, color: const Color(0xFF181511), size: 20),
            ),
            const SizedBox(width: 16),
            // Active Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEC9213),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF897961)),
                  ),
                  const SizedBox(height: 16),
                  // Action Button
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEC9213).withOpacity(0.3), width: 2),
                    ),
                    child: ElevatedButton(
                      onPressed: onPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEC9213),
                        foregroundColor: const Color(0xFF181511),
                        elevation: 8,
                        shadowColor: const Color(0xFFEC9213).withOpacity(0.3),
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFF181511).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.pin_drop, size: 28),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  buttonText,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  buttonSubtext,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF181511).withOpacity(0.7),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Icon(Icons.arrow_forward, size: 28),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.notifications_active, size: 14, color: Color(0xFF897961)),
                      const SizedBox(width: 4),
                      Text(
                        'Customer will be notified automatically',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        Container(
          margin: const EdgeInsets.only(left: 19, top: 16, bottom: 16),
          width: 2,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFE6E1DB),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}

enum JobStatus {
  accepted,
  enRoute,
  arrived,
  inProgress,
  completed,
}