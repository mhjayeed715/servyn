import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/supabase_config.dart';
import '../../../core/services/session_service.dart';

class ManageComplaintsScreen extends StatefulWidget {
  const ManageComplaintsScreen({Key? key}) : super(key: key);

  @override
  State<ManageComplaintsScreen> createState() => _ManageComplaintsScreenState();
}

class _ManageComplaintsScreenState extends State<ManageComplaintsScreen> {
  List<Map<String, dynamic>> _complaints = [];
  bool _isLoading = true;
  String _filterStatus = 'open';
  final _resolutionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    try {
      setState(() => _isLoading = true);

      var query = SupabaseConfig.client
          .from('complaints')
          .select('''
            *,
            customer_profiles!inner(*),
            provider_profiles!inner(*)
          ''');

      if (_filterStatus != 'all') {
        query = query.eq('status', _filterStatus);
      }

      final response = await query.order('created_at', ascending: false);

      setState(() {
        _complaints = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading complaints: $e');
    }
  }

  Future<void> _updateComplaintStatus(String complaintId, String newStatus, String? notes) async {
    try {
      final userId = await SessionService.getUserId();
      if (userId == null) return;

      final updateData = {
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (notes != null && notes.isNotEmpty) {
        updateData['resolution_notes'] = notes;
        updateData['resolved_by'] = userId;
        updateData['resolved_at'] = DateTime.now().toIso8601String();
      }

      await SupabaseConfig.client
          .from('complaints')
          .update(updateData)
          .eq('id', complaintId);

      _loadComplaints();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complaint status updated'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showResolutionDialog(String complaintId, String currentStatus) {
    _resolutionController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Complaint Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<String>(
              isExpanded: true,
              value: currentStatus,
              items: ['open', 'in_review', 'resolved', 'closed']
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.replaceAll('_', ' ').toUpperCase()),
                      ))
                  .toList(),
              onChanged: (newStatus) {
                if (newStatus != null) {
                  setState(() {});
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _resolutionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Resolution Notes (Optional)',
                border: OutlineInputBorder(),
              ),
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
              _updateComplaintStatus(
                complaintId,
                currentStatus,
                _resolutionController.text,
              );
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Complaints'),
        centerTitle: true,
        backgroundColor: Colors.red.shade700,
      ),
      body: Column(
        children: [
          // Filter
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['all', 'open', 'in_review', 'resolved', 'closed']
                    .map((status) {
                  final isSelected = _filterStatus == status;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(status.replaceAll('_', ' ').toUpperCase()),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _filterStatus = status;
                          _loadComplaints();
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: Colors.red.shade700,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _complaints.isEmpty
                    ? const Center(
                        child: Text('No complaints found'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _complaints.length,
                        itemBuilder: (context, index) {
                          final complaint = _complaints[index];
                          final createdAt = DateTime.parse(complaint['created_at']);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              complaint['title'],
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              DateFormat('dd MMM yyyy')
                                                  .format(createdAt),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF5F758C),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            _showResolutionDialog(complaint['id'],
                                                complaint['status']),
                                        child: const Text('Resolve'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    complaint['description'],
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF181511),
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
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

  @override
  void dispose() {
    _resolutionController.dispose();
    super.dispose();
  }
}
