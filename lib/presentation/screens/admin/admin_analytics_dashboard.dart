import 'package:flutter/material.dart';
import 'package:servyn/services/analytics_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminAnalyticsDashboard extends StatefulWidget {
  const AdminAnalyticsDashboard();

  @override
  State<AdminAnalyticsDashboard> createState() =>
      _AdminAnalyticsDashboardState();
}

class _AdminAnalyticsDashboardState extends State<AdminAnalyticsDashboard> {
  late AnalyticsService _analyticsService;
  Map<String, dynamic>? _adminMetrics;
  List<Map<String, dynamic>> _revenueByCategory = [];
  List<Map<String, dynamic>> _topProviders = [];
  Map<String, dynamic>? _userGrowth;
  
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final supabase = Supabase.instance.client;
    _analyticsService = AnalyticsService(supabase);
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final metrics = await _analyticsService.getAdminDashboardMetrics(
        startDate: _startDate,
        endDate: _endDate,
      );
      final revenue = await _analyticsService.getRevenueByCategory(
        startDate: _startDate,
        endDate: _endDate,
      );
      final providers = await _analyticsService.getTopProviders(
        startDate: _startDate,
        endDate: _endDate,
        limit: 5,
      );
      final growth = await _analyticsService.getUserGrowthMetrics(
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _adminMetrics = metrics;
        _revenueByCategory = revenue;
        _topProviders = providers;
        _userGrowth = growth;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      await _loadAnalytics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Select date range',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date range indicator
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Data from ${_startDate.toString().split(' ')[0]} to ${_endDate.toString().split(' ')[0]}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Key metrics
                  Text(
                    'Key Metrics',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (_adminMetrics != null) ...[
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        _buildMetricCard(
                          title: 'Total Bookings',
                          value: '${_adminMetrics!['total_bookings']}',
                          icon: Icons.shopping_bag,
                          color: Colors.blue,
                        ),
                        _buildMetricCard(
                          title: 'Completed',
                          value:
                              '${(_adminMetrics!['completion_rate'] * 100).toStringAsFixed(1)}%',
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                        _buildMetricCard(
                          title: 'Total Revenue',
                          value:
                              '৳${(_adminMetrics!['total_revenue'] as num).toStringAsFixed(0)}',
                          icon: Icons.attach_money,
                          color: Colors.orange,
                        ),
                        _buildMetricCard(
                          title: 'Avg Rating',
                          value:
                              '${(_adminMetrics!['average_rating'] as num).toStringAsFixed(1)}/5',
                          icon: Icons.star,
                          color: Colors.amber,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),

                  // User Growth
                  if (_userGrowth != null) ...[
                    Text(
                      'User Growth',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        _buildMetricCard(
                          title: 'New Customers',
                          value: '${_userGrowth!['new_customers']}',
                          icon: Icons.person_add,
                          color: Colors.purple,
                        ),
                        _buildMetricCard(
                          title: 'New Providers',
                          value: '${_userGrowth!['new_providers']}',
                          icon: Icons.person_add,
                          color: Colors.teal,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Revenue by Category
                  if (_revenueByCategory.isNotEmpty) ...[
                    Text(
                      'Revenue by Category',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _revenueByCategory.length,
                      itemBuilder: (context, index) {
                        final category = _revenueByCategory[index];
                        final revenue =
                            (category['revenue'] as num).toDouble();
                        final maxRevenue = _revenueByCategory.fold<double>(
                          0,
                          (max, cat) =>
                              (cat['revenue'] as num).toDouble() > max
                                  ? (cat['revenue'] as num).toDouble()
                                  : max,
                        );
                        final percentage = maxRevenue > 0
                            ? revenue / maxRevenue
                            : 0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(category['category']),
                                  Text('৳${revenue.toStringAsFixed(0)}'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percentage.toDouble(),
                                  minHeight: 8,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Top Providers
                  if (_topProviders.isNotEmpty) ...[
                    Text(
                      'Top Performing Providers',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _topProviders.length,
                      itemBuilder: (context, index) {
                        final provider = _topProviders[index];
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          title: Text(provider['name']),
                          subtitle: Text(
                            '${provider['completed_jobs']} completed • ${provider['rating']}/5',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star,
                                  size: 16, color: Colors.amber),
                              Text('${provider['rating']}'),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
