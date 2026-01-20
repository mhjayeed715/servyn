import 'package:flutter/material.dart';

import '../../../core/services/supabase_service.dart';
import '../../../services/supabase_config.dart';
import '../../theme/colors.dart';
import 'active_job_screen.dart';

class JobAcceptanceScreen extends StatefulWidget {
	final Map<String, dynamic> booking;

	const JobAcceptanceScreen({super.key, required this.booking});

	@override
	State<JobAcceptanceScreen> createState() => _JobAcceptanceScreenState();
}

class _JobAcceptanceScreenState extends State<JobAcceptanceScreen> {
	bool _isSubmitting = false;

	Future<void> _accept() async {
		final providerId = SupabaseConfig.client.auth.currentUser?.id;
		if (providerId == null) return;
		setState(() => _isSubmitting = true);
		try {
			await SupabaseService.acceptBooking(
				bookingId: widget.booking['id'].toString(),
				providerId: providerId,
			);
			if (!mounted) return;
			Navigator.pushReplacement(
				context,
				MaterialPageRoute(
					builder: (_) => ActiveJobScreen(booking: {
						...widget.booking,
						'provider_id': providerId,
						'status': 'accepted',
					}),
				),
			);
		} catch (e) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('Failed to accept: $e')),
			);
		} finally {
			if (mounted) setState(() => _isSubmitting = false);
		}
	}

	Future<void> _decline() async {
		setState(() => _isSubmitting = true);
		try {
			await SupabaseService.declineBooking(bookingId: widget.booking['id'].toString());
			if (!mounted) return;
			Navigator.pop(context);
		} catch (e) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('Failed to decline: $e')),
			);
		} finally {
			if (mounted) setState(() => _isSubmitting = false);
		}
	}

	@override
	Widget build(BuildContext context) {
		final booking = widget.booking;
		final service = booking['service_name'] ?? booking['service_id'] ?? booking['service_type'] ?? 'Service';
		final address = booking['address'] ?? booking['location'] ?? 'Address not provided';
		final time = booking['booking_time'] ?? '';
		final date = booking['booking_date'] ?? '';
		final notes = booking['notes'] ?? '';

		return Scaffold(
			appBar: AppBar(
				title: const Text('Job Request'),
				backgroundColor: Colors.white,
				foregroundColor: Colors.black,
				elevation: 0,
			),
			backgroundColor: const Color(0xFFF7F9FB),
			body: Padding(
				padding: const EdgeInsets.all(16),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						_infoTile(Icons.build, 'Service', service),
						_infoTile(Icons.schedule, 'Time', '$date $time'),
						_infoTile(Icons.location_on, 'Address', address),
						if (notes.isNotEmpty) _infoTile(Icons.note, 'Notes', notes),
						const Spacer(),
						Row(
							children: [
								Expanded(
									child: OutlinedButton(
										onPressed: _isSubmitting ? null : _decline,
										style: OutlinedButton.styleFrom(
											padding: const EdgeInsets.symmetric(vertical: 16),
											side: const BorderSide(color: Colors.red),
										),
										child: const Text('Decline', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
									),
								),
								const SizedBox(width: 12),
								Expanded(
									child: ElevatedButton(
										onPressed: _isSubmitting ? null : _accept,
										style: ElevatedButton.styleFrom(
											backgroundColor: AppColors.primaryBlue,
											padding: const EdgeInsets.symmetric(vertical: 16),
										),
										child: _isSubmitting
												? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
												: const Text('Accept Job', style: TextStyle(fontWeight: FontWeight.bold)),
									),
								),
							],
						),
					],
				),
			),
		);
	}

	Widget _infoTile(IconData icon, String title, String value) {
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
			child: Row(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Icon(icon, color: AppColors.primaryBlue),
					const SizedBox(width: 12),
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
								const SizedBox(height: 6),
								Text(value, style: const TextStyle(color: Colors.black87)),
							],
						),
					),
				],
			),
		);
	}
}
