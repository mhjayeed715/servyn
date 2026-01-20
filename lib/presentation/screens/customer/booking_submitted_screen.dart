import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import 'home_screen.dart';

class BookingSubmittedScreen extends StatelessWidget {
	final Map<String, dynamic> booking;

	const BookingSubmittedScreen({super.key, required this.booking});

	@override
	Widget build(BuildContext context) {
		final serviceName = booking['service_name'] ?? 'Your service';
		final status = booking['status'] ?? 'pending';

		return Scaffold(
			backgroundColor: const Color(0xFFF7F9FB),
			body: SafeArea(
				child: Padding(
					padding: const EdgeInsets.all(24),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.center,
						children: [
							const SizedBox(height: 32),
							Container(
								padding: const EdgeInsets.all(16),
								decoration: const BoxDecoration(
									color: Color(0xFFE8F3FF),
									shape: BoxShape.circle,
								),
								child: const Icon(Icons.check_circle, color: AppColors.primaryBlue, size: 72),
							),
							const SizedBox(height: 24),
							const Text(
								'Booking Confirmed!',
								style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
							),
							const SizedBox(height: 8),
							Text(
								'Status: ${status.toString().toUpperCase()}',
								style: const TextStyle(color: Colors.black54),
							),
							const SizedBox(height: 16),
							Container(
								width: double.infinity,
								padding: const EdgeInsets.all(16),
								decoration: BoxDecoration(
									color: Colors.white,
									borderRadius: BorderRadius.circular(12),
									boxShadow: [
										BoxShadow(
											color: Colors.black.withOpacity(0.05),
											blurRadius: 10,
											offset: const Offset(0, 4),
										),
									],
								),
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text(serviceName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
										const SizedBox(height: 8),
										Text(booking['address'] ?? 'No address provided'),
										const SizedBox(height: 8),
										Text('Amount: ৳${(booking['total_amount'] ?? 0).toString()}'),
										const SizedBox(height: 8),
										Text('When: ${booking['booking_time'] ?? ''}'),
									],
								),
							),
							const Spacer(),
							SizedBox(
								width: double.infinity,
								child: ElevatedButton(
									onPressed: () {
										Navigator.pushAndRemoveUntil(
											context,
											MaterialPageRoute(builder: (_) => const HomeScreen()),
											(route) => false,
										);
									},
									style: ElevatedButton.styleFrom(
										backgroundColor: AppColors.primaryBlue,
										padding: const EdgeInsets.symmetric(vertical: 16),
										shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
									),
									child: const Text('Back to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
								),
							),
							const SizedBox(height: 12),
						],
					),
				),
			),
		);
	}
}
