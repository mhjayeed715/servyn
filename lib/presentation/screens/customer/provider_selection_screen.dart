import 'package:flutter/material.dart';

import '../../../core/services/supabase_service.dart';
import '../../theme/colors.dart';
import 'date_time_selection_screen.dart';

class ProviderSelectionScreen extends StatefulWidget {
	final String serviceId;
	final String serviceName;
	final double price;

	const ProviderSelectionScreen({
		super.key,
		required this.serviceId,
		required this.serviceName,
		required this.price,
	});

	@override
	State<ProviderSelectionScreen> createState() => _ProviderSelectionScreenState();
}

class _ProviderSelectionScreenState extends State<ProviderSelectionScreen> {
	bool _isLoading = true;
	List<Map<String, dynamic>> _providers = [];
	String _search = '';

	@override
	void initState() {
		super.initState();
		_loadProviders();
	}

	Future<void> _loadProviders() async {
		setState(() => _isLoading = true);
		final data = await SupabaseService.getApprovedProviders(serviceId: widget.serviceId);
		setState(() {
			_providers = data;
			_isLoading = false;
		});
	}

	@override
	Widget build(BuildContext context) {
		final filtered = _providers.where((p) {
			if (_search.isEmpty) return true;
			final name = (p['full_name'] ?? '').toString().toLowerCase();
			final city = (p['city'] ?? '').toString().toLowerCase();
			return name.contains(_search.toLowerCase()) || city.contains(_search.toLowerCase());
		}).toList();

		return Scaffold(
			appBar: AppBar(
				title: const Text('Choose Provider'),
				backgroundColor: Colors.white,
				foregroundColor: Colors.black,
				elevation: 0,
			),
			backgroundColor: const Color(0xFFF7F9FB),
			body: Column(
				children: [
					Padding(
						padding: const EdgeInsets.all(16),
						child: TextField(
							decoration: InputDecoration(
								hintText: 'Search by name or city',
								prefixIcon: const Icon(Icons.search),
								filled: true,
								fillColor: Colors.white,
								border: OutlineInputBorder(
									borderRadius: BorderRadius.circular(12),
									borderSide: BorderSide.none,
								),
							),
							onChanged: (v) => setState(() => _search = v),
						),
					),
					Expanded(
						child: _isLoading
								? const Center(child: CircularProgressIndicator())
								: filtered.isEmpty
										? const Center(child: Text('No providers available right now.'))
										: ListView.separated(
												padding: const EdgeInsets.all(16),
												itemBuilder: (context, index) {
													final provider = filtered[index];
													return _ProviderCard(
														provider: provider,
														serviceName: widget.serviceName,
														price: widget.price,
														onSelect: () {
															Navigator.push(
																context,
																MaterialPageRoute(
																	builder: (_) => DateTimeSelectionScreen(
																		serviceId: widget.serviceId,
																		serviceName: widget.serviceName,
																		price: widget.price,
																		providerId: provider['user_id']?.toString(),
																		providerName: provider['full_name']?.toString() ?? 'Provider',
																	),
																),
															);
														},
													);
												},
												separatorBuilder: (_, __) => const SizedBox(height: 12),
												itemCount: filtered.length,
											),
					),
				],
			),
		);
	}
}

class _ProviderCard extends StatelessWidget {
	final Map<String, dynamic> provider;
	final String serviceName;
	final double price;
	final VoidCallback onSelect;

	const _ProviderCard({
		required this.provider,
		required this.serviceName,
		required this.price,
		required this.onSelect,
	});

	@override
	Widget build(BuildContext context) {
		final rating = (provider['rating'] ?? 4.5).toDouble();
		final city = provider['city'] ?? 'Nearby';
		final bio = provider['bio'] ?? 'Reliable and experienced professional.';

		return Container(
			decoration: BoxDecoration(
				color: Colors.white,
				borderRadius: BorderRadius.circular(12),
				boxShadow: [
					BoxShadow(
						color: Colors.black.withOpacity(0.05),
						blurRadius: 8,
						offset: const Offset(0, 4),
					),
				],
			),
			padding: const EdgeInsets.all(16),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Row(
						children: [
							CircleAvatar(
								radius: 24,
								backgroundColor: Colors.grey.shade200,
								child: const Icon(Icons.person, color: AppColors.primaryBlue),
							),
							const SizedBox(width: 12),
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text(
											provider['full_name'] ?? 'Provider',
											style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
										),
										const SizedBox(height: 4),
										Row(
											children: [
												Icon(Icons.star, color: Colors.amber.shade600, size: 16),
												const SizedBox(width: 4),
												Text(rating.toStringAsFixed(1)),
												const SizedBox(width: 8),
												const Icon(Icons.location_on, size: 16, color: Colors.grey),
												const SizedBox(width: 2),
												Text(city, style: const TextStyle(color: Colors.grey)),
											],
										),
									],
								),
							),
							Container(
								padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
								decoration: BoxDecoration(
									color: const Color(0xFFE8F3FF),
									borderRadius: BorderRadius.circular(20),
								),
								child: Text(
									'৳${price.toStringAsFixed(0)}',
									style: const TextStyle(
										color: AppColors.primaryBlue,
										fontWeight: FontWeight.bold,
									),
								),
							),
						],
					),
					const SizedBox(height: 12),
					Text(
						bio,
						style: const TextStyle(color: Colors.black87),
					),
					const SizedBox(height: 12),
					SizedBox(
						width: double.infinity,
						child: ElevatedButton(
							onPressed: onSelect,
							style: ElevatedButton.styleFrom(
								backgroundColor: AppColors.primaryBlue,
								padding: const EdgeInsets.symmetric(vertical: 12),
								shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
							),
							child: const Text('Select Provider'),
						),
					),
				],
			),
		);
	}
}
