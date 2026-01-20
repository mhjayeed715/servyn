import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:intl/intl.dart';

import '../../../presentation/theme/colors.dart';
import '../../../services/supabase_config.dart';
import 'booking_submitted_screen.dart';
import 'location_input_screen_osm.dart';
import '../payment/digital_payment_screen.dart';

class BookingConfirmationScreen extends StatefulWidget {
	final String serviceId;
	final String serviceName;
	final double price;
	final DateTime scheduledAt;
	final String? providerId;
	final String? providerName;
	final String? notes;
	final String? initialAddress;
	final double? initialLatitude;
	final double? initialLongitude;

	const BookingConfirmationScreen({
		super.key,
		required this.serviceId,
		required this.serviceName,
		required this.price,
		required this.scheduledAt,
		this.providerId,
		this.providerName,
		this.notes,
		this.initialAddress,
		this.initialLatitude,
		this.initialLongitude,
	});

	@override
	State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
	late MapController _mapController;
	String _address = '';
	double? _latitude;
	double? _longitude;
	bool _isSubmitting = false;

	@override
	void initState() {
		super.initState();
		_address = widget.initialAddress ?? '';
		_latitude = widget.initialLatitude ?? 23.8103; // Default Dhaka
		_longitude = widget.initialLongitude ?? 90.4125;
		_mapController = MapController.withPosition(
			initPosition: GeoPoint(latitude: _latitude!, longitude: _longitude!),
		);
	}

	@override
	void dispose() {
		_mapController.dispose();
		super.dispose();
	}

	Future<void> _pickLocation() async {
		final result = await Navigator.push<Map<String, dynamic>?>(
			context,
			MaterialPageRoute(
				builder: (_) => LocationInputScreenOSM(
					initialAddress: _address.isNotEmpty ? _address : null,
					initialCoordinates: GeoPoint(latitude: _latitude!, longitude: _longitude!),
				),
			),
		);

		if (result == null) return;

		setState(() {
			_address = result['address'] as String? ?? _address;
			_latitude = (result['latitude'] as num?)?.toDouble() ?? _latitude;
			_longitude = (result['longitude'] as num?)?.toDouble() ?? _longitude;
		});

		if (_latitude != null && _longitude != null) {
			await _mapController.changeLocation(
				GeoPoint(latitude: _latitude!, longitude: _longitude!),
			);
			await _mapController.setZoom(zoomLevel: 15);
		}
	}

	Future<void> _confirmBooking() async {
		final userId = SupabaseConfig.client.auth.currentUser?.id;
		if (userId == null) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('You need to be signed in to book.')),
			);
			return;
		}

		if (_address.isEmpty || _latitude == null || _longitude == null) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Please select a service location.')),
			);
			return;
		}

		setState(() => _isSubmitting = true);

		try {
			// Create temporary booking ID for payment
			final tempBookingId = 'BKG-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
			
			// Navigate to payment screen
			final paymentResult = await Navigator.push(
				context,
				MaterialPageRoute(
					builder: (_) => DigitalPaymentScreen(
						amount: widget.price,
						bookingId: tempBookingId,
						serviceTitle: widget.serviceName,
					),
				),
			);
			
			// If payment was successful, create the booking
			if (paymentResult == true || mounted) {
				final payload = {
					'customer_id': userId,
					'service_id': widget.serviceId,
					'provider_id': widget.providerId,
					'status': widget.providerId == null ? 'pending_assignment' : 'pending',
					'total_amount': widget.price,
					'address': _address,
					'latitude': _latitude,
					'longitude': _longitude,
					'booking_date': widget.scheduledAt.toIso8601String(),
					'booking_time': DateFormat('HH:mm').format(widget.scheduledAt),
					'notes': widget.notes,
					'payment_status': 'paid',
				};

				final response = await SupabaseConfig.client
						.from('bookings')
						.insert(payload)
						.select()
						.single();

				if (!mounted) return;

				Navigator.pushReplacement(
					context,
					MaterialPageRoute(
						builder: (_) => BookingSubmittedScreen(booking: response),
					),
				);
			}
		} catch (e) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(content: Text('Failed to process booking: $e')),
			);
		} finally {
			if (mounted) {
				setState(() => _isSubmitting = false);
			}
		}
	}

	String _formatDate(DateTime date) {
		return DateFormat('EEE, MMM d, yyyy').format(date);
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('Confirm Booking'),
				backgroundColor: Colors.white,
				foregroundColor: Colors.black,
				elevation: 0,
			),
			backgroundColor: const Color(0xFFF7F9FB),
			body: Column(
				children: [
					Expanded(
						child: ListView(
							padding: const EdgeInsets.all(16),
							children: [
								_BookingSummaryCard(
									title: widget.serviceName,
									subtitle: widget.providerName ?? 'Provider will be assigned',
									price: widget.price,
									scheduledText: '${_formatDate(widget.scheduledAt)} • ${DateFormat('hh:mm a').format(widget.scheduledAt)}',
								),
								const SizedBox(height: 12),
								_LocationCard(
									address: _address.isEmpty ? 'No location selected' : _address,
									latitude: _latitude,
									longitude: _longitude,
									mapController: _mapController,
									onChangeLocation: _pickLocation,
								),
								if (widget.notes != null && widget.notes!.isNotEmpty) ...[
									const SizedBox(height: 12),
									_NotesCard(notes: widget.notes!),
								],
							],
						),
					),
					SafeArea(
						child: Padding(
							padding: const EdgeInsets.all(16),
							child: SizedBox(
								width: double.infinity,
								child: ElevatedButton(
									onPressed: _isSubmitting ? null : _confirmBooking,
									style: ElevatedButton.styleFrom(
										backgroundColor: AppColors.primaryBlue,
										padding: const EdgeInsets.symmetric(vertical: 16),
										shape: RoundedRectangleBorder(
											borderRadius: BorderRadius.circular(12),
										),
									),
									child: _isSubmitting
											? const SizedBox(
													height: 20,
													width: 20,
													child: CircularProgressIndicator(
														strokeWidth: 2,
														valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
													),
												)
											: const Text(
													'Proceed to Payment',
													style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
												),
								),
							),
						),
					),
				],
			),
		);
	}
}

class _BookingSummaryCard extends StatelessWidget {
	final String title;
	final String subtitle;
	final double price;
	final String scheduledText;

	const _BookingSummaryCard({
		required this.title,
		required this.subtitle,
		required this.price,
		required this.scheduledText,
	});

	@override
	Widget build(BuildContext context) {
		return Container(
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
			padding: const EdgeInsets.all(16),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(
						title,
						style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
					),
					const SizedBox(height: 4),
					Text(
						subtitle,
						style: const TextStyle(color: Colors.black54),
					),
					const SizedBox(height: 12),
					Row(
						mainAxisAlignment: MainAxisAlignment.spaceBetween,
						children: [
							Row(
								children: [
									const Icon(Icons.schedule, size: 18, color: Colors.black54),
									const SizedBox(width: 6),
									Text(
										scheduledText,
										style: const TextStyle(color: Colors.black87),
									),
								],
							),
							Text(
								'৳${price.toStringAsFixed(0)}',
								style: const TextStyle(
									fontSize: 18,
									fontWeight: FontWeight.bold,
									color: AppColors.primaryBlue,
								),
							),
						],
					),
				],
			),
		);
	}
}

class _LocationCard extends StatelessWidget {
	final String address;
	final double? latitude;
	final double? longitude;
	final MapController mapController;
	final VoidCallback onChangeLocation;

	const _LocationCard({
		required this.address,
		required this.latitude,
		required this.longitude,
		required this.mapController,
		required this.onChangeLocation,
	});

	@override
	Widget build(BuildContext context) {
		return Container(
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
					Padding(
						padding: const EdgeInsets.all(16),
						child: Row(
							children: [
								const Icon(Icons.location_on, color: AppColors.primaryBlue),
								const SizedBox(width: 8),
								Expanded(
									child: Text(
										address,
										style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
									),
								),
								TextButton(
									onPressed: onChangeLocation,
									child: const Text('Change'),
								),
							],
						),
					),
					if (latitude != null && longitude != null)
						SizedBox(
							height: 200,
							child: ClipRRect(
								borderRadius: const BorderRadius.only(
									bottomLeft: Radius.circular(12),
									bottomRight: Radius.circular(12),
								),
								child: OSMFlutter(
									controller: mapController,
									osmOption: OSMOption(
										zoomOption: const ZoomOption(initZoom: 14),
										staticPoints: [
											StaticPositionGeoPoint(
												'booking_location',
												const MarkerIcon(
													icon: Icon(Icons.location_pin, color: AppColors.primaryBlue, size: 48),
												),
												[GeoPoint(latitude: latitude!, longitude: longitude!)],
											),
										],
									),
								),
							),
						)
					else
						const Padding(
							padding: EdgeInsets.all(16),
							child: Text('No location selected'),
						),
				],
			),
		);
	}
}

class _NotesCard extends StatelessWidget {
	final String notes;

	const _NotesCard({required this.notes});

	@override
	Widget build(BuildContext context) {
		return Container(
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
			padding: const EdgeInsets.all(16),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					const Text(
						'Notes',
						style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
					),
					const SizedBox(height: 8),
					Text(notes),
				],
			),
		);
	}
}
