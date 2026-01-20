import 'package:flutter/material.dart';

import '../../../core/services/supabase_service.dart';
import '../../../core/services/session_service.dart';
import '../../../services/supabase_config.dart';
import '../../theme/colors.dart';
import 'job_acceptance_screen.dart';
import 'active_job_screen.dart';
import '../auth/auth_choice_screen.dart';

class LegacyProviderDashboardScreen extends StatefulWidget {
	const LegacyProviderDashboardScreen({super.key});

	@override
	State<LegacyProviderDashboardScreen> createState() => _LegacyProviderDashboardScreenState();
}

class _LegacyProviderDashboardScreenState extends State<LegacyProviderDashboardScreen> {
	bool _isLoading = true;
	List<Map<String, dynamic>> _requests = [];
	List<Map<String, dynamic>> _active = [];

	@override
	void initState() {
		super.initState();
		_loadData();
	}

	Future<void> _loadData() async {
		String? userId = await SessionService.getUserId();
        // Fallback
        if (userId == null) {
            userId = SupabaseConfig.client.auth.currentUser?.id;
        }

		if (userId == null) {
			setState(() {
				_requests = [];
				_active = [];
				_isLoading = false;
			});
			return;
		}

		setState(() => _isLoading = true);

		final requests = await SupabaseService.getProviderBookings(
			providerId: userId,
			statuses: const ['pending', 'requested', 'pending_assignment'],
		);

		final active = await SupabaseService.getProviderBookings(
			providerId: userId,
			statuses: const ['accepted', 'in_progress', 'confirmed'],
		);

		if (!mounted) return;
		setState(() {
			_requests = requests;
			_active = active;
			_isLoading = false;
		});
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('Provider Dashboard'),
				backgroundColor: Colors.white,
				foregroundColor: Colors.black,
				elevation: 0,
				actions: [
					IconButton(
						onPressed: _loadData,
						icon: const Icon(Icons.refresh),
						tooltip: 'Refresh',
					),
					PopupMenuButton<String>(
						icon: const Icon(Icons.more_vert),
						onSelected: (value) {
							if (value == 'logout') {
								_showLogoutDialog();
							} else if (value == 'profile') {
								ScaffoldMessenger.of(context).showSnackBar(
									const SnackBar(content: Text('Provider profile edit coming soon!')),
								);
							}
						},
						itemBuilder: (context) => [
							const PopupMenuItem(
								value: 'profile',
								child: Row(
									children: [
										Icon(Icons.person, size: 20),
										SizedBox(width: 12),
										Text('Edit Profile'),
									],
								),
							),
							const PopupMenuItem(
								value: 'logout',
								child: Row(
									children: [
										Icon(Icons.logout, size: 20, color: Colors.red),
										SizedBox(width: 12),
										Text('Logout', style: TextStyle(color: Colors.red)),
									],
								),
							),
						],
					),
				],
			),
			backgroundColor: const Color(0xFFF7F9FB),
			body: _isLoading
					? const Center(child: CircularProgressIndicator())
					: RefreshIndicator(
							onRefresh: _loadData,
							child: ListView(
								padding: const EdgeInsets.all(16),
								children: [
									const Text('New Requests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
									const SizedBox(height: 8),
									if (_requests.isEmpty)
										_emptyCard('No new job requests right now.')
									else
										..._requests.map((b) => _BookingCard(
													booking: b,
													ctaLabel: 'Review & Accept',
													onTap: () async {
														await Navigator.push(
															context,
															MaterialPageRoute(
																builder: (_) => JobAcceptanceScreen(booking: b),
															),
														);
														_loadData();
													},
												)),
									const SizedBox(height: 16),
									const Text('Active Jobs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
									const SizedBox(height: 8),
									if (_active.isEmpty)
										_emptyCard('No active jobs. Accept a request to start working.')
									else
										..._active.map((b) => _BookingCard(
													booking: b,
													ctaLabel: 'Open',
													onTap: () async {
														await Navigator.push(
															context,
															MaterialPageRoute(
																builder: (_) => ActiveJobScreen(booking: b),
															),
														);
														_loadData();
													},
												)),
								],
							),
						),
		);
	}

	void _showLogoutDialog() {
		showDialog(
			context: context,
			builder: (context) => AlertDialog(
				title: const Text('Logout'),
				content: const Text('Are you sure you want to logout?'),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(context),
						child: const Text('Cancel'),
					),
					TextButton(
						onPressed: () async {
							Navigator.pop(context);
							await SessionService.clearSession();
							await SupabaseConfig.client.auth.signOut();
							if (mounted) {
								Navigator.of(context).pushAndRemoveUntil(
									MaterialPageRoute(
										builder: (context) => const AuthChoiceScreen(),
									),
									(route) => false,
								);
							}
						},
						child: const Text('Logout', style: TextStyle(color: Colors.red)),
					),
				],
			),
		);
	}

	Widget _emptyCard(String text) {
		return Container(
			width: double.infinity,
			padding: const EdgeInsets.all(16),
			decoration: BoxDecoration(
				color: Colors.white,
				borderRadius: BorderRadius.circular(12),
				boxShadow: [
					BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
				],
			),
			child: Text(text, style: const TextStyle(color: Colors.black54)),
		);
	}
}

class _BookingCard extends StatelessWidget {
	final Map<String, dynamic> booking;
	final String ctaLabel;
	final VoidCallback onTap;

	const _BookingCard({required this.booking, required this.ctaLabel, required this.onTap});

	@override
	Widget build(BuildContext context) {
		final address = booking['address'] ?? booking['location'] ?? 'Address not provided';
		final status = booking['status'] ?? 'pending';
		final service = booking['service_name'] ?? booking['service_id'] ?? booking['service_type'] ?? 'Service';
		final time = booking['booking_time'] ?? '';

		return Container(
			margin: const EdgeInsets.only(bottom: 12),
			padding: const EdgeInsets.all(16),
			decoration: BoxDecoration(
				color: Colors.white,
				borderRadius: BorderRadius.circular(12),
				boxShadow: [
					BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
				],
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Row(
						children: [
							Container(
								padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
								decoration: BoxDecoration(
									color: _statusColor(status).withOpacity(0.1),
									borderRadius: BorderRadius.circular(20),
								),
								child: Text(
									status.toString().toUpperCase(),
									style: TextStyle(color: _statusColor(status), fontSize: 12, fontWeight: FontWeight.bold),
								),
							),
							const Spacer(),
							TextButton(onPressed: onTap, child: Text(ctaLabel)),
						],
					),
					const SizedBox(height: 8),
					Text(service, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
					const SizedBox(height: 4),
					Row(children: [const Icon(Icons.schedule, size: 16, color: Colors.grey), const SizedBox(width: 4), Text(time)]),
					const SizedBox(height: 4),
					Row(children: [const Icon(Icons.location_on, size: 16, color: Colors.grey), const SizedBox(width: 4), Expanded(child: Text(address))]),
				],
			),
		);
	}

	Color _statusColor(String status) {
		switch (status) {
			case 'accepted':
				return AppColors.primaryBlue;
			case 'in_progress':
				return Colors.orange;
			case 'confirmed':
				return Colors.teal;
			case 'completed':
				return Colors.green;
			default:
				return Colors.grey;
		}
	}
}
