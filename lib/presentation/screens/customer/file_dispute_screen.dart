import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/dispute_repository.dart';

class FileDisputeScreen extends StatefulWidget {
  final String bookingId;
  final String providerId;
  final String providerName;
  final double bookingAmount;

  const FileDisputeScreen({
    required this.bookingId,
    required this.providerId,
    required this.providerName,
    required this.bookingAmount,
  });

  @override
  State<FileDisputeScreen> createState() => _FileDisputeScreenState();
}

class _FileDisputeScreenState extends State<FileDisputeScreen> {
  final _reasonController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _disruptionLevelController = TextEditingController();
  
  late DisputeRepository _disputeRepository;
  List<String> _selectedReasons = [];
  List<PlatformFile> _selectedFiles = [];
  String? _selectedPriority;
  bool _isSubmitting = false;

  final List<String> _reasonOptions = [
    'Service Not Provided',
    'Poor Quality Work',
    'Incomplete Service',
    'Damage to Property',
    'Safety Concern',
    'Harassment',
    'No-show',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final supabase = Supabase.instance.client;
    _disputeRepository = DisputeRepository(supabase);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _descriptionController.dispose();
    _disruptionLevelController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'mp4'],
      );

      if (result != null) {
        setState(() {
          _selectedFiles.addAll(result.files);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking files: $e')),
      );
    }
  }

  Future<void> _uploadFileToSupabase(PlatformFile file) async {
    try {
      final fileBytes = await file.readStream?.toList() ?? [];
      final fileName = 'disputes/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      
      await Supabase.instance.client.storage
          .from('dispute_evidence')
          .uploadBinary(fileName, Stream.value(fileBytes as List<int>).expand((x) => x).toList());

      return Supabase.instance.client.storage
          .from('dispute_evidence')
          .getPublicUrl(fileName);
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  Future<void> _submitDispute() async {
    if (_selectedReasons.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Upload evidence files
      final evidenceUrls = <String>[];
      for (final file in _selectedFiles) {
        final url = await _uploadFileToSupabase(file);
        if (url != null) {
          evidenceUrls.add(url.toString());
        }
      }

      final customerId = Supabase.instance.client.auth.currentUser?.id ?? '';

      await _disputeRepository.createDispute(
        bookingId: widget.bookingId,
        customerId: customerId,
        providerId: widget.providerId,
        reason: _selectedReasons.join(', '),
        description: _descriptionController.text,
        evidenceUrls: evidenceUrls,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dispute filed successfully')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File a Dispute'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider info card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dispute Details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('Provider: ${widget.providerName}'),
                  Text('Amount: ৳${widget.bookingAmount.toStringAsFixed(2)}'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Reason selection
            Text(
              'Select Reason(s)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _reasonOptions.map((reason) {
                final isSelected = _selectedReasons.contains(reason);
                return FilterChip(
                  label: Text(reason),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedReasons.add(reason);
                      } else {
                        _selectedReasons.remove(reason);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Description
            Text(
              'Describe the Issue',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Provide detailed explanation of the dispute...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Evidence upload
            Text(
              'Upload Evidence',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickFiles,
              icon: const Icon(Icons.attach_file),
              label: const Text('Add Photos/Videos'),
            ),
            if (_selectedFiles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _selectedFiles.map((file) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            file.name.endsWith('.mp4')
                                ? Icons.videocam
                                : Icons.image,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(file.name)),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() => _selectedFiles.remove(file));
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitDispute,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('File Dispute'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
