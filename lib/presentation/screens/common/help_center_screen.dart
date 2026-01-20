import 'package:flutter/material.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedTopic = 'Booking';
  int? _expandedFaqIndex = 1;

  final List<String> _topics = ['Booking', 'Payments', 'Safety', 'Account'];

  final List<Map<String, dynamic>> _faqs = [
    {
      'question': 'How do I cancel a booking?',
      'answer':
          'To cancel a booking, go to "My Bookings", select the booking, and tap "Cancel Booking". Cancellation policies vary based on timing.',
      'actions': <String>[],
    },
    {
      'question': 'What if the provider is late?',
      'answer':
          'If your service provider is more than 15 minutes late, you can track their location in the "My Bookings" tab or contact them directly. If they do not arrive, you are eligible for a full refund or rescheduling at no extra cost.',
      'actions': ['Track Provider', 'Report Issue'],
    },
    {
      'question': 'Is my payment secure?',
      'answer':
          'Yes, all payments are processed through secure, encrypted channels. We use industry-standard security measures to protect your financial information.',
      'actions': <String>[],
    },
    {
      'question': 'How do I update my profile?',
      'answer':
          'Go to Settings → Profile to update your personal information, profile picture, and contact details.',
      'actions': <String>[],
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitTicket() {
    if (_subjectController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // TODO: Submit to backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ticket submitted successfully'),
        backgroundColor: Colors.green,
      ),
    );

    _subjectController.clear();
    _descriptionController.clear();
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
          'Help Center',
          style: TextStyle(
            color: Color(0xFF181511),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search issues (e.g. "refund")',
                hintStyle: const TextStyle(color: Color(0xFF897961)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF897961)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEC9213)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Topic Pills
            const Text(
              'BROWSE BY TOPIC',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF897961),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _topics.length,
                itemBuilder: (context, index) {
                  final topic = _topics[index];
                  final isSelected = _selectedTopic == topic;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTopic = topic;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? const Color(0xFFEC9213) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected
                              ? null
                              : Border.all(color: Colors.grey[300]!),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFEC9213).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getTopicIcon(topic),
                              size: 18,
                              color:
                                  isSelected ? Colors.white : const Color(0xFF897961),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              topic,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color:
                                    isSelected ? Colors.white : const Color(0xFF181511),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            // FAQs
            const Text(
              'Common Questions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF181511),
              ),
            ),
            const SizedBox(height: 16),
            ..._faqs.asMap().entries.map((entry) {
              final index = entry.key;
              final faq = entry.value;
              final isExpanded = _expandedFaqIndex == index;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isExpanded
                        ? const Color(0xFFEC9213).withOpacity(0.3)
                        : Colors.grey[200]!,
                  ),
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
                    onTap: () {
                      setState(() {
                        _expandedFaqIndex = isExpanded ? null : index;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  faq['question'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isExpanded
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isExpanded
                                        ? const Color(0xFFEC9213)
                                        : const Color(0xFF181511),
                                  ),
                                ),
                              ),
                              Icon(
                                isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: isExpanded
                                    ? const Color(0xFFEC9213)
                                    : const Color(0xFF897961),
                              ),
                            ],
                          ),
                          if (isExpanded) ..[
                            const SizedBox(height: 12),
                            Container(
                              height: 1,
                              color: Colors.grey[200],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              faq['answer'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF897961),
                                height: 1.5,
                              ),
                            ),
                            if (faq['actions'].isNotEmpty) ..[
                              const SizedBox(height: 16),
                              Row(
                                children: faq['actions'].map<Widget>((action) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: OutlinedButton(
                                      onPressed: () {},
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: Colors.grey[300]!),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        action,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF181511),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            Center(
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  'View all FAQs',
                  style: TextStyle(
                    color: Color(0xFFEC9213),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Divider(color: Colors.grey[300]),
            const SizedBox(height: 24),

            // Contact Form
            const Text(
              'Still need help?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF181511),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Send us a message and we\'ll get back to you.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF897961),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'SUBJECT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF181511),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                hintText: 'Briefly describe the issue',
                hintStyle: const TextStyle(color: Color(0xFF897961)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFEC9213)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'DESCRIPTION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF181511),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Provide more details...',
                hintStyle: const TextStyle(color: Color(0xFF897961)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFEC9213)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitTicket,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC9213),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 4,
              ),
              child: const Text(
                'Submit Ticket',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  IconData _getTopicIcon(String topic) {
    switch (topic) {
      case 'Booking':
        return Icons.calendar_month;
      case 'Payments':
        return Icons.payments;
      case 'Safety':
        return Icons.shield;
      case 'Account':
        return Icons.person;
      default:
        return Icons.help_outline;
    }
  }
}
