import 'package:flutter/material.dart';
import 'service_category_screen.dart';

class AllCategoriesScreen extends StatelessWidget {
  const AllCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'icon': Icons.electrical_services, 'name': 'Electrician', 'color': Colors.amber},
      {'icon': Icons.plumbing, 'name': 'Plumber', 'color': Colors.blue},
      {'icon': Icons.cleaning_services, 'name': 'Cleaning', 'color': Colors.green},
      {'icon': Icons.yard, 'name': 'Gardening', 'color': Colors.lightGreen},
      {'icon': Icons.construction, 'name': 'Carpentry', 'color': Colors.brown},
      {'icon': Icons.format_paint, 'name': 'Painting', 'color': Colors.purple},
      {'icon': Icons.school, 'name': 'Tutor', 'color': Colors.teal},
      {'icon': Icons.ac_unit, 'name': 'AC Repair', 'color': Colors.cyan},
      {'icon': Icons.tv, 'name': 'Appliance Repair', 'color': Colors.orange},
      {'icon': Icons.business_center, 'name': 'Pest Control', 'color': Colors.red},
      {'icon': Icons.local_laundry_service, 'name': 'Laundry', 'color': Colors.indigo},
      {'icon': Icons.car_repair, 'name': 'Car Wash', 'color': Colors.blueGrey},
      {'icon': Icons.computer, 'name': 'IT Support', 'color': Colors.deepPurple},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111418)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'All Categories',
          style: TextStyle(
            color: Color(0xFF111418),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceCategoryScreen(
                    categoryName: category['name'] as String,
                    categoryIcon: category['icon'] as IconData,
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: (category['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      category['icon'] as IconData,
                      size: 32,
                      color: category['color'] as Color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category['name'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111418),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
