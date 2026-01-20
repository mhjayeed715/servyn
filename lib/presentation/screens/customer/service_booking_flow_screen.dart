import 'package:flutter/material.dart';
import 'location_picker_screen.dart';

class ServiceBookingFlowScreen extends StatefulWidget {
  const ServiceBookingFlowScreen({super.key});

  @override
  State<ServiceBookingFlowScreen> createState() => _ServiceBookingFlowScreenState();
}

class _ServiceBookingFlowScreenState extends State<ServiceBookingFlowScreen> {
  final List<ServiceCategory> _categories = [
    ServiceCategory(
      id: 'electrician',
      name: 'Electrician',
      icon: Icons.electrical_services,
      description: 'Wiring, outlets, circuit breakers',
      color: const Color(0xFFFFA726),
    ),
    ServiceCategory(
      id: 'plumber',
      name: 'Plumber',
      icon: Icons.plumbing,
      description: 'Pipes, leaks, bathroom fittings',
      color: const Color(0xFF42A5F5),
    ),
    ServiceCategory(
      id: 'cleaner',
      name: 'Cleaning',
      icon: Icons.cleaning_services,
      description: 'Home, office, deep cleaning',
      color: const Color(0xFF66BB6A),
    ),
    ServiceCategory(
      id: 'carpenter',
      name: 'Carpenter',
      icon: Icons.handyman,
      description: 'Furniture, doors, repairs',
      color: const Color(0xFF8D6E63),
    ),
    ServiceCategory(
      id: 'painter',
      name: 'Painter',
      icon: Icons.format_paint,
      description: 'Interior, exterior, touch-ups',
      color: const Color(0xFFEF5350),
    ),
    ServiceCategory(
      id: 'ac_repair',
      name: 'AC Repair',
      icon: Icons.air,
      description: 'Installation, repair, servicing',
      color: const Color(0xFF26C6DA),
    ),
    ServiceCategory(
      id: 'tutor',
      name: 'Tutor',
      icon: Icons.school,
      description: 'Home tutoring, all subjects',
      color: const Color(0xFFAB47BC),
    ),
    ServiceCategory(
      id: 'gardener',
      name: 'Gardener',
      icon: Icons.yard,
      description: 'Lawn, plants, landscaping',
      color: const Color(0xFF9CCC65),
    ),
  ];

  String? _selectedCategoryId;

  void _onCategorySelected(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
  }

  void _continueToLocation() {
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a service category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final selectedCategory = _categories.firstWhere((c) => c.id == _selectedCategoryId);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          serviceCategory: selectedCategory,
        ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF181511)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Book a Service',
          style: TextStyle(color: Color(0xFF181511), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            color: Colors.white,
            child: Row(
              children: [
                _buildProgressStep(1, 'Category', true),
                _buildProgressLine(),
                _buildProgressStep(2, 'Location', false),
                _buildProgressLine(),
                _buildProgressStep(3, 'Provider', false),
                _buildProgressLine(),
                _buildProgressStep(4, 'Time', false),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'What service do you need?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF181511),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose a category to find verified professionals',
                  style: TextStyle(fontSize: 16, color: Color(0xFF897961)),
                ),
                const SizedBox(height: 24),

                // Category Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategoryId == category.id;

                    return GestureDetector(
                      onTap: () => _onCategorySelected(category.id),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFEC9213) : const Color(0xFFE6E1DB),
                            width: isSelected ? 2 : 1,
                          ),
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: category.color.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                category.icon,
                                color: category.color,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              category.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? const Color(0xFFEC9213) : const Color(0xFF181511),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                category.description,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF897961),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
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
          child: ElevatedButton(
            onPressed: _continueToLocation,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC9213),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            child: const Text(
              'Continue',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStep(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFEC9213) : const Color(0xFFE6E1DB),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF897961),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? const Color(0xFFEC9213) : const Color(0xFF897961),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine() {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: const Color(0xFFE6E1DB),
      ),
    );
  }
}

class ServiceCategory {
  final String id;
  final String name;
  final IconData icon;
  final String description;
  final Color color;

  ServiceCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.color,
  });
}
