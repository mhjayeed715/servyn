import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import 'booking_submitted_screen.dart';

class DateTimeSelectionScreen extends StatefulWidget {
	final String serviceId;
	final String serviceName;
	final double price;
	final String? providerId;
	final String? providerName;

	const DateTimeSelectionScreen({
		super.key,
		required this.serviceId,
		required this.serviceName,
		required this.price,
		this.providerId,
		this.providerName,
	});

	@override
	State<DateTimeSelectionScreen> createState() => _DateTimeSelectionScreenState();
}

class _DateTimeSelectionScreenState extends State<DateTimeSelectionScreen> {
	DateTime _selectedDate = DateTime.now().add(const Duration(hours: 2));
	String _selectedSlot = '';
	final TextEditingController _notesController = TextEditingController();

	final List<String> _slots = const [
		'08:00 AM',
		'10:00 AM',
		'12:00 PM',
		'02:00 PM',
		'04:00 PM',
		'06:00 PM',
		'08:00 PM',
	];

	@override
	void dispose() {
		_notesController.dispose();
		super.dispose();
	}

	Future<void> _pickDate() async {
		final picked = await showDatePicker(
			context: context,
			initialDate: _selectedDate,
			firstDate: DateTime.now(),
			lastDate: DateTime.now().add(const Duration(days: 30)),
		);
		if (picked != null) {
			setState(() {
				_selectedDate = DateTime(
					picked.year,
					picked.month,
					picked.day,
					_selectedDate.hour,
					_selectedDate.minute,
				);
			});
		}
	}

	void _selectSlot(String slot) {
		setState(() => _selectedSlot = slot);
		final parts = slot.split(' ');
		if (parts.length == 2) {
			final time = parts[0];
			final ampm = parts[1];
			final hourMinute = time.split(':');
			var hour = int.tryParse(hourMinute[0]) ?? 0;
			final minute = int.tryParse(hourMinute[1]) ?? 0;
			if (ampm.toUpperCase() == 'PM' && hour != 12) hour += 12;
			if (ampm.toUpperCase() == 'AM' && hour == 12) hour = 0;
			setState(() {
				_selectedDate = DateTime(
					_selectedDate.year,
					_selectedDate.month,
					_selectedDate.day,
					hour,
					minute,
				);
			});
		}
	}

	void _continue() {
		if (_selectedSlot.isEmpty) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Please select a time slot.')),
			);
			return;
		}

		Navigator.push(
			context,
			MaterialPageRoute(
				builder: (_) => BookingSubmittedScreen(
					booking: {
						'service_name': widget.serviceName,
						'status': 'pending',
						'scheduled_date': _selectedDate.toIso8601String(),
						'provider_id': widget.providerId,
						'provider_name': widget.providerName,
						'price': widget.price,
						'notes': _notesController.text.trim(),
					},
				),
			),
		);
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('Select Date & Time'),
				backgroundColor: Colors.white,
				foregroundColor: Colors.black,
				elevation: 0,
			),
			backgroundColor: const Color(0xFFF7F9FB),
			body: Column(
				children: [
					Padding(
						padding: const EdgeInsets.all(16),
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Row(
									mainAxisAlignment: MainAxisAlignment.spaceBetween,
									children: [
										const Text('Preferred Date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
										TextButton(
											onPressed: _pickDate,
											child: const Text('Change'),
										),
									],
								),
								const SizedBox(height: 8),
								Container(
									width: double.infinity,
									padding: const EdgeInsets.all(16),
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
									child: Text(
										'${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
										style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
									),
								),
								const SizedBox(height: 20),
								const Text('Select a time slot', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
								const SizedBox(height: 12),
								Wrap(
									spacing: 10,
									runSpacing: 10,
									children: _slots.map((slot) {
										final selected = slot == _selectedSlot;
										return ChoiceChip(
											label: Text(slot),
											selected: selected,
											onSelected: (_) => _selectSlot(slot),
											selectedColor: AppColors.primaryBlue.withOpacity(0.1),
											labelStyle: TextStyle(
												color: selected ? AppColors.primaryBlue : Colors.black87,
												fontWeight: FontWeight.w600,
											),
											side: BorderSide(color: selected ? AppColors.primaryBlue : Colors.grey.shade300),
										);
									}).toList(),
								),
								const SizedBox(height: 24),
								const Text('Notes (optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
								const SizedBox(height: 8),
								TextField(
									controller: _notesController,
									maxLines: 3,
									decoration: InputDecoration(
										hintText: 'Any special instructions for the provider...',
										filled: true,
										fillColor: Colors.white,
										border: OutlineInputBorder(
											borderRadius: BorderRadius.circular(12),
											borderSide: BorderSide.none,
										),
									),
								),
							],
						),
					),
					const Spacer(),
					SafeArea(
						child: Padding(
							padding: const EdgeInsets.all(16),
							child: SizedBox(
								width: double.infinity,
								child: ElevatedButton(
									onPressed: _continue,
									style: ElevatedButton.styleFrom(
										backgroundColor: AppColors.primaryBlue,
										padding: const EdgeInsets.symmetric(vertical: 16),
										shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
									),
									child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
								),
							),
						),
					),
				],
			),
		);
	}
}
