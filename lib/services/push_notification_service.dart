import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestResponse;
import 'dart:async';
import 'package:uuid/uuid.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final SupabaseClient _supabase = Supabase.instance.client;
  StreamSubscription? _notificationListener;

  Future<void> initialize() async {
    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload);
      },
    );

    // Start listening to new notifications
    _startListeningToNotifications();
  }

  /// Listen to new unread notifications from Supabase
  void _startListeningToNotifications() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _notificationListener = _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .eq('read', false)
        .listen(
          (data) {
            for (final notification in data) {
              _showLocalNotification(
                title: notification['title'] ?? 'Notification',
                body: notification['body'] ?? '',
                notificationId: notification['id'],
                type: notification['type'] ?? 'general',
              );
            }
          },
          onError: (error) {
            print('Error listening to notifications: $error');
          },
        );
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String notificationId,
    required String type,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'servyn_channel',
      'Servyn Notifications',
      channelDescription: 'Notifications for Servyn service booking',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notificationId.hashCode,
      title,
      body,
      details,
      payload: notificationId,
    );
  }

  /// Handle notification tap
  void _handleNotificationTap(String? payload) {
    if (payload == null || payload.isEmpty) return;
    print('Notification tapped with payload: $payload');
    // Navigate based on notification type if needed
  }

  /// Send notification to user (creates record in Supabase)
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'id': const Uuid().v4(),
        'user_id': userId,
        'type': type,
        'title': title,
        'body': body,
        'data': data ?? {},
        'read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  /// Send notification to multiple users
  Future<void> sendBulkNotifications({
    required List<String> userIds,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    for (final userId in userIds) {
      await sendNotification(
        userId: userId,
        title: title,
        body: body,
        type: type,
        data: data,
      );
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'read': true})
          .eq('id', notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Get unread notifications count
  Future<int> getUnreadNotificationsCount(String userId) async {
    try {
      final resp = await _supabase
          .from('notifications')
          .select('id', const {'count': 'exact'})
          .eq('user_id', userId)
          .eq('read', false);
      // For Supabase Dart, count is in resp.count if using .select(..., {'count': 'exact'})
      if (resp is PostgrestResponse && resp.count != null) {
        return resp.count!;
      } else if (resp is Map && resp['count'] != null) {
        return resp['count'] as int;
      }
      return 0;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  /// Cleanup resources
  void dispose() {
    _notificationListener?.cancel();
  }
}

class BookingNotifications {
  static final BookingNotifications _instance =
      BookingNotifications._internal();

  factory BookingNotifications() {
    return _instance;
  }

  BookingNotifications._internal();

  final NotificationService _notificationService = NotificationService();
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Notify customer when provider accepts
  Future<void> notifyCustomerProviderAccepted({
    required String customerId,
    required String providerName,
    required String bookingId,
  }) async {
    await _notificationService.sendNotification(
      userId: customerId,
      title: 'Provider Accepted',
      body: '$providerName has accepted your booking',
      type: 'provider_accepted',
      data: {'booking_id': bookingId},
    );
  }

  /// Notify customer when provider is en route
  Future<void> notifyCustomerProviderEnRoute({
    required String customerId,
    required String providerName,
    required String bookingId,
  }) async {
    await _notificationService.sendNotification(
      userId: customerId,
      title: 'Provider On The Way',
      body: '$providerName is heading to your location',
      type: 'provider_en_route',
      data: {'booking_id': bookingId},
    );
  }

  /// Notify provider about new booking
  Future<void> notifyProviderNewBooking({
    required String providerId,
    required String customerName,
    required String serviceType,
    required String bookingId,
  }) async {
    await _notificationService.sendNotification(
      userId: providerId,
      title: 'New Booking Available',
      body: '$customerName requested $serviceType',
      type: 'new_booking',
      data: {'booking_id': bookingId},
    );
  }

  /// Notify customer when booking completed
  Future<void> notifyCustomerBookingCompleted({
    required String customerId,
    required String bookingId,
  }) async {
    await _notificationService.sendNotification(
      userId: customerId,
      title: 'Booking Completed',
      body: 'Please review your service experience',
      type: 'booking_completed',
      data: {'booking_id': bookingId},
    );
  }

  /// Notify both parties of payment
  Future<void> notifyPaymentProcessed({
    required String customerId,
    required String providerId,
    required String amount,
    required String bookingId,
  }) async {
    await _notificationService.sendNotification(
      userId: customerId,
      title: 'Payment Processed',
      body: 'Amount held in escrow: ৳$amount',
      type: 'payment_processed',
      data: {'booking_id': bookingId},
    );

    await _notificationService.sendNotification(
      userId: providerId,
      title: 'Payment Received',
      body: 'Amount ৳$amount is held in escrow',
      type: 'payment_received',
      data: {'booking_id': bookingId},
    );
  }

  /// Notify on dispute filing
  Future<void> notifyDisputeFiled({
    required String customerId,
    required String providerId,
    required String bookingId,
  }) async {
    await _notificationService.sendNotification(
      userId: providerId,
      title: 'Dispute Filed',
      body: 'A dispute has been filed for your booking',
      type: 'dispute_filed',
      data: {'booking_id': bookingId},
    );
  }

  /// Notify on SOS alert
  Future<void> notifySOSAlert({
    required String customerId,
    required String providerId,
    required String bookingId,
  }) async {
    await _notificationService.sendNotification(
      userId: providerId,
      title: 'SOS Alert',
      body: 'Customer has sent an SOS alert',
      type: 'sos_alert',
      data: {'booking_id': bookingId},
    );
  }
}
