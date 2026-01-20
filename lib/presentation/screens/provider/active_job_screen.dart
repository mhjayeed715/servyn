import 'package:flutter/material.dart';

import '../../../core/services/supabase_service.dart';
import '../../theme/colors.dart';

class ActiveJobScreen extends StatefulWidget {
	final Map<String, dynamic> booking;

	const ActiveJobScreen({super.key, required this.booking});

	@override
	State<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends State<ActiveJobScreen> {
	late Map<String, dynamic> _booking;
	bool _isBusy = false;

	@override
	void initState() {
		super.initState();
		_booking = Map<String, dynamic>.from(widget.booking);
	}

	Future<void> _startJob() async {
		await _updateStatus('in_progress', () => SupabaseService.startJob(bookingId: _booking['id'].toString()));
	}

	Future<void> _completeJob() async {
		await _updateStatus('confirmed', () => SupabaseService.providerCompleteJob(bookingId: _booking['id'].toString()));
	}

	Future<void> _updateStatus(String status, Future<void> Function() action) async {
		setState(() => _isBusy = true);
		try {
			await action();
			if (!mounted) return;
			setState(() => _booking['status'] = status);
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('Status updated to $status')),
			);
		} catch (e) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('Failed: $e')),
			);
		} finally {
			if (mounted) setState(() => _isBusy = false);
		}
	}

	@override
	Widget build(BuildContext context) {
		final status = _booking['status'] ?? 'accepted';
		final service = _booking['service_name'] ?? _booking['service_id'] ?? _booking['service_type'] ?? 'Service';
		final address = _booking['address'] ?? _booking['location'] ?? 'Address not provided';
		final time = _booking['booking_time'] ?? '';
		final date = _booking['booking_date'] ?? '';
		final notes = _booking['notes'] ?? '';

		final isAccepted = status == 'accepted';
		final isInProgress = status == 'in_progress';
		final isAwaitingConfirm = status == 'confirmed';

		return Scaffold(
			appBar: AppBar(
				title: const Text('Active Job'),
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
						_statusPill(status),
						const SizedBox(height: 12),
						_infoTile(Icons.build, 'Service', service),
						_infoTile(Icons.schedule, 'Time', '$date $time'),
						_infoTile(Icons.location_on, 'Address', address),
						if (notes.isNotEmpty) _infoTile(Icons.note, 'Notes', notes),
						const SizedBox(height: 12),
						_timeline(status),
						const Spacer(),
						if (isAccepted)
							_primaryButton('Start Job', _startJob)
						else if (isInProgress)
							_primaryButton('Job Completed', _completeJob)
						else if (isAwaitingConfirm)
							_disabledInfo('Waiting for customer confirmation')
						else
							_disabledInfo('Status: $status'),
					],
				),
			),
		);
	}

	Widget _primaryButton(String label, Future<void> Function() onPressed) {
		return SizedBox(
			width: double.infinity,
			child: ElevatedButton(
				onPressed: _isBusy ? null : onPressed,
				style: ElevatedButton.styleFrom(
					backgroundColor: AppColors.primaryBlue,
					padding: const EdgeInsets.symmetric(vertical: 16),
					shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
				),
				child: _isBusy
						? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
						: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
			),
		);
	}

	Widget _disabledInfo(String text) {
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
			child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87)),
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

	Widget _statusPill(String status) {
		final color = _statusColor(status);
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
			decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
			child: Text(status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
		);
	}

	Widget _timeline(String status) {
		final steps = [
			'Accepted',
			'In Progress',
			'Provider Completed',
			'Customer Confirmed',
		];
		int activeIndex = 0;
		if (status == 'accepted') activeIndex = 0;
		if (status == 'in_progress') activeIndex = 1;
		if (status == 'confirmed') activeIndex = 2;
		if (status == 'completed') activeIndex = 3;

		return Container(
			padding: const EdgeInsets.all(16),
			decoration: BoxDecoration(
				color: Colors.white,
				borderRadius: BorderRadius.circular(12),
				boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					const Text('Progress', style: TextStyle(fontWeight: FontWeight.bold)),
					const SizedBox(height: 12),
					...List.generate(steps.length, (index) {
						final done = index <= activeIndex;
						return Padding(
							padding: const EdgeInsets.symmetric(vertical: 6),
							child: Row(
								children: [
									Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
											color: done ? AppColors.primaryBlue : Colors.grey),
									const SizedBox(width: 8),
									Text(steps[index], style: TextStyle(fontWeight: FontWeight.w600, color: done ? Colors.black : Colors.black54)),
								],
							),
						);
					}),
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
