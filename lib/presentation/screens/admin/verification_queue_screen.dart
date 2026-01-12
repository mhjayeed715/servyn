import 'package:flutter/material.dart';
import 'package:servyn/core/services/supabase_service.dart';

class VerificationQueueScreen extends StatefulWidget {
  const VerificationQueueScreen({super.key});

  @override
  State<VerificationQueueScreen> createState() => _VerificationQueueScreenState();
}

class _VerificationQueueScreenState extends State<VerificationQueueScreen> {
  int _selectedTab = 1; // Verify tab selected by default
  bool _isLoading = true;
  List<Map<String, dynamic>> _verificationQueue = [];
  
  // Stats
  int _activeUsers = 0;
  int _pendingApproval = 0;
  int _resolvedIssues = 0;

  @override
  void initState() {
    super.initState();
    _loadVerifications();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await SupabaseService.getAdminDashboardStats();
      setState(() {
        _activeUsers = (stats['active_customers'] ?? 0) + (stats['active_providers'] ?? 0);
        _pendingApproval = stats['pending_verifications'] ?? 0;
        _resolvedIssues = (stats['total_complaints'] ?? 0) - (stats['pending_complaints'] ?? 0);
      });
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  Future<void> _loadVerifications() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.getPendingProviderVerifications();
      setState(() {
        _verificationQueue = data;
        _isLoading = false;
      });
      // Reload stats after verification changes
      _loadStats();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load verifications: $e')),
        );
      }
    }
  }

  String _getTimeAgo(String? createdAt) {
    if (createdAt == null) return 'Recently';
    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (e) {
      return 'Recently';
    }
  }

  Future<void> _exportToCSV() async {
    try {
      // Create CSV content
      String csv = 'Name,Phone,NID,Services,Status,Upload Time\n';
      
      for (var item in _verificationQueue) {
        final name = item['full_name'] ?? 'N/A';
        final phone = item['users']?['phone'] ?? 'N/A';
        final nid = item['nid_number'] ?? 'N/A';
        final services = (item['services'] as List?)?.join('; ') ?? 'N/A';
        final status = item['verification_status'] ?? 'N/A';
        final time = item['created_at'] ?? 'N/A';
        
        csv += '"$name","$phone","$nid","$services","$status","$time"\n';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV data ready (${_verificationQueue.length} records)'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('CSV Preview'),
                    content: SingleChildScrollView(
                      child: SelectableText(csv),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
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

  Future<void> _viewLogs() async {
    try {
      final logs = await SupabaseService.getAdminActivityLogs(limit: 50);
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Recent Admin Logs'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: logs.isEmpty
                ? const Center(child: Text('No logs found'))
                : ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return ListTile(
                        leading: Icon(
                          Icons.history,
                          color: const Color(0xFFEC9213),
                          size: 20,
                        ),
                        title: Text(
                          log['action_type'] ?? 'Unknown',
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          _getTimeAgo(log['created_at']),
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: Text(
                          log['target_type'] ?? '',
                          style: const TextStyle(fontSize: 11),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load logs: $e')),
        );
      }
    }
  }

  Future<void> _approveProvider(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Provider'),
        content: const Text('Are you sure you want to approve this provider?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC9213),
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final currentAdmin = SupabaseService.getCurrentUser();
        if (currentAdmin == null) {
          throw 'Admin not logged in';
        }
        
        await SupabaseService.approveProviderVerification(
          userId: userId,
          adminId: currentAdmin.id,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Provider approved successfully')),
          );
        }
        
        _loadVerifications(); // Reload list
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to approve: $e')),
          );
        }
      }
    }
  }

  Future<void> _rejectProvider(String userId) async {
    final reasonController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Provider'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter rejection reason...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a reason')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final currentAdmin = SupabaseService.getCurrentUser();
        if (currentAdmin == null) {
          throw 'Admin not logged in';
        }
        
        await SupabaseService.rejectProviderVerification(
          userId: userId,
          adminId: currentAdmin.id,
          reason: reasonController.text.trim(),
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Provider rejected')),
          );
        }
        
        _loadVerifications(); // Reload list
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to reject: $e')),
          );
        }
      }
    }
    
    reasonController.dispose();
  }

  Widget _buildDocumentLink(String label, String url, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _openDocument(url),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F7F6),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF897961)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF181511),
                  ),
                ),
              ),
              const Icon(
                Icons.open_in_new,
                size: 14,
                color: Color(0xFFEC9213),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDocumentLinks(dynamic documents) {
    if (documents == null) return [];
    
    List<Widget> widgets = [];
    if (documents is List) {
      for (int i = 0; i < documents.length; i++) {
        final doc = documents[i];
        final url = doc is Map ? doc['url'] : doc.toString();
        final name = doc is Map ? (doc['name'] ?? 'Document ${i + 1}') : 'Document ${i + 1}';
        widgets.add(_buildDocumentLink(name, url, Icons.description));
      }
    } else if (documents is Map) {
      documents.forEach((key, value) {
        widgets.add(_buildDocumentLink(
          key.toString(),
          value.toString(),
          Icons.description,
        ));
      });
    }
    
    return widgets;
  }

  Future<void> _openDocument(String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document URL not available')),
      );
      return;
    }

    try {
      // Show a dialog with document preview or download option
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Document'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Document URL:'),
              const SizedBox(height: 8),
              SelectableText(
                url,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF897961),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Copy the URL to view the document in your browser',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening document: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Admin Dashboard',
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
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Color(0xFF181511)),
                onPressed: () {},
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFEC9213).withOpacity(0.2),
              child: const Icon(
                Icons.admin_panel_settings,
                color: Color(0xFFEC9213),
                size: 18,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F7F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE6E1DB)),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.search, color: Color(0xFF897961)),
                        ),
                        const Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search users, logs, or IDs...',
                              hintStyle: TextStyle(color: Color(0xFF897961)),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.tune, color: Color(0xFF897961), size: 20),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Segmented Controls
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F7F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE6E1DB)),
              ),
              child: Row(
                children: [
                  _buildTab('Users', 0),
                  _buildTab('Verify', 1),
                  _buildTab('Complaints', 2),
                  _buildTab('Stats', 3),
                ],
              ),
            ),
          ),

          // Quick Stats
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildQuickStat(_activeUsers.toString(), 'Active\nUsers', false),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickStat(_pendingApproval.toString(), 'Pending\nApproval', true),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickStat(_resolvedIssues.toString(), 'Resolved\nIssues', false),
                ),
              ],
            ),
          ),

          // Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Verification Queue',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF181511),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.filter_list, size: 18),
                  label: const Text('Filter'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFEC9213),
                  ),
                ),
              ],
            ),
          ),

          // Verification List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFEC9213)))
                : _verificationQueue.isEmpty
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
                              'No pending verifications',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _verificationQueue.length,
                        itemBuilder: (context, index) {
                          final item = _verificationQueue[index];
                          return _buildVerificationCard(item);
                        },
                      ),
          ),
        ],
      ),

      // Fixed Bottom Actions Bar
      bottomNavigationBar: Container(
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
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: _exportToCSV,
                  child: _buildBottomAction(Icons.download, 'Export CSV'),
                ),
                GestureDetector(
                  onTap: _viewLogs,
                  child: _buildBottomAction(Icons.history, 'View Logs'),
                ),
                _buildBottomAction(Icons.admin_panel_settings, 'Admin', hasNotification: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEC9213) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF897961),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(String value, String label, bool isHighlighted) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted
              ? const Color(0xFFEC9213).withOpacity(0.3)
              : const Color(0xFFE6E1DB),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isHighlighted)
            Align(
              alignment: Alignment.topRight,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFEC9213),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          if (isHighlighted) const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? const Color(0xFFEC9213) : const Color(0xFF181511),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF897961),
              height: 1.1,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard(Map<String, dynamic> item) {
    final isInReview = item['verification_status'] == 'in_review';
    final services = (item['services'] as List?)?.join(', ') ?? 'N/A';
    final phone = item['users']?['phone'] ?? 'N/A';
    final nidNumber = item['nid_number'] ?? 'N/A';
    final uploadTime = _getTimeAgo(item['created_at']);
    final userId = item['user_id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F7F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    (item['full_name'] ?? 'NA').toString().split(' ').map((e) => e.isNotEmpty ? e[0] : '').join(''),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF897961),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['full_name'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF181511),
                      ),
                    ),
                    Text(
                      services,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF897961),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isInReview
                      ? const Color(0xFFF8F7F6)
                      : const Color(0xFFEC9213).withOpacity(0.1),
                  border: Border.all(
                    color: isInReview
                        ? const Color(0xFFE6E1DB)
                        : const Color(0xFFEC9213).withOpacity(0.2),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isInReview ? 'In Review' : 'Pending',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isInReview ? const Color(0xFF897961) : const Color(0xFFEC9213),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Document Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.badge,
                      size: 16,
                      color: Color(0xFF897961),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'NID: $nidNumber',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF181511),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.phone,
                      size: 16,
                      color: Color(0xFF897961),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        phone,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF181511),
                        ),
                      ),
                    ),
                    const Text(
                      '•',
                      style: TextStyle(color: Color(0xFF897961)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      uploadTime,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF897961),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Attached Documents Section
          if (item['nid_image_url'] != null || item['documents'] != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE6E1DB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.attach_file,
                        size: 16,
                        color: Color(0xFF897961),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Attached Documents',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF181511),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (item['nid_image_url'] != null)
                    _buildDocumentLink(
                      'NID Document',
                      item['nid_image_url'],
                      Icons.credit_card,
                    ),
                  if (item['documents'] != null)
                    ..._buildDocumentLinks(item['documents']),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: Colors.orange,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'No documents attached',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Actions
          if (isInReview)
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                onPressed: null,
                icon: const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                label: const Text('System Reviewing'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF8F7F6),
                  foregroundColor: const Color(0xFF897961),
                  disabledBackgroundColor: const Color(0xFFF8F7F6),
                  disabledForegroundColor: const Color(0xFF897961),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFFE6E1DB)),
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectProvider(userId),
                    icon: const Icon(Icons.close, size: 20),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Color(0xFFE6E1DB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveProvider(userId),
                    icon: const Icon(Icons.check, size: 20),
                    label: const Text('Approve'),
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
            ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(IconData icon, String label, {bool hasNotification = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            Icon(
              icon,
              color: hasNotification ? const Color(0xFFEC9213) : const Color(0xFF897961),
            ),
            if (hasNotification)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: hasNotification ? const Color(0xFFEC9213) : const Color(0xFF897961),
          ),
        ),
      ],
    );
  }
}
