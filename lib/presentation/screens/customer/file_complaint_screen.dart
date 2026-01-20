import 'package:flutter/material.dart';
import '../../../services/supabase_config.dart';
import '../../../core/services/session_service.dart';

class FileComplaintScreen extends StatefulWidget {
  final String bookingId;
  final String providerId;
  final String providerName;

  const FileComplaintScreen({
    Key? key,
    required this.bookingId,
    required this.providerId,
    required this.providerName,
  }) : super(key: key);

  @override
  State<FileComplaintScreen> createState() => _FileComplaintScreenState();
}

class _FileComplaintScreenState extends State<FileComplaintScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  
  final List<String> _complaintTypes = [
    'Quality of Service',
    'Safety Concerns',
    'Pricing Discrepancy',
    'Unprofessional Behavior',
    'Incomplete Work',
    'Not Shown Up',
    'Damage/Loss',
    'Other',
  ];
  String? _selectedType;

  final List<String> _urgencyLevels = ['Low', 'Medium', 'High', 'Critical'];
  String _selectedUrgency = 'Medium';

  Future<void> _submitComplaint() async {
    if (_selectedType == null || _titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = await SessionService.getUserId();
      if (userId == null) throw 'User not authenticated';

      // Insert complaint
      await SupabaseConfig.client.from('complaints').insert({
        'booking_id': widget.bookingId,
        'provider_id': widget.providerId,
        'customer_id': userId,
        'complaint_type': _selectedType,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'urgency_level': _selectedUrgency,
        'status': 'open',
        'created_at': DateTime.now().toIso8601String(),
      });

      setState(() => _isSubmitting = false);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Complaint Submitted'),
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 40),
            content: const Text('Your complaint has been submitted successfully. We will review it and take appropriate action.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Done', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting complaint: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency) {
      case 'Low':
        return Colors.blue;
      case 'Medium':
        return Colors.orange;
      case 'High':
        return Colors.red;
      case 'Critical':
        return Colors.red.shade900;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Complaint'),
        centerTitle: true,
        backgroundColor: Colors.red.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.red.shade700,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Complaint Against',
                          style: TextStyle(fontSize: 12, color: Color(0xFF5F758C)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.providerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF181511),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Complaint Type
            const Text(
              'Complaint Type *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF181511),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedType,
                hint: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Select complaint type'),
                ),
                items: _complaintTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(type),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedType = value);
                },
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Title *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF181511),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              maxLength: 100,
              decoration: InputDecoration(
                hintText: 'Brief title of the complaint',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red.shade700, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Description
            const Text(
              'Description *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF181511),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: 'Provide detailed information about your complaint...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red.shade700, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Urgency Level
            const Text(
              'Urgency Level',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF181511),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: _urgencyLevels.map((level) {
                final isSelected = _selectedUrgency == level;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedUrgency = level),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _getUrgencyColor(level).withOpacity(0.2)
                              : Colors.grey.shade100,
                          border: Border.all(
                            color: isSelected
                                ? _getUrgencyColor(level)
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _getUrgencyColor(level)
                                    : Colors.grey.shade400,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.flag,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              level,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? _getUrgencyColor(level)
                                    : Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Info Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Important',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Our support team will review this complaint within 24-48 hours.',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitComplaint,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text(
                      'Submit Complaint',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
