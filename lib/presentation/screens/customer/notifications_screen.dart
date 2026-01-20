import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:servyn/services/push_notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen();

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Stream<List<Map<String, dynamic>>> _notificationsStream;
  final NotificationService _notificationService = NotificationService();
  int _unreadCount = 0; // Optionally, use this field in your UI if you want to display unread count

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _initializeNotifications() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _notificationsStream = Supabase.instance.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    _loadUnreadCount(userId);
  }

  Future<void> _loadUnreadCount(String userId) async {
    final count = await _notificationService.getUnreadNotificationsCount(userId);
    setState(() => _unreadCount = count);
  }

  Future<void> _markAsRead(String notificationId, String userId) async {
    await _notificationService.markNotificationAsRead(notificationId);
    await _loadUnreadCount(userId);
  }

  Future<void> _markAllAsRead(List<Map<String, dynamic>> notifications) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    for (final notification in notifications) {
      if (notification['read'] == false) {
        await _notificationService.markNotificationAsRead(notification['id']);
      }
    }
    await _loadUnreadCount(userId);
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'booking_assigned':
        return Colors.blue;
      case 'provider_accepted':
        return Colors.green;
      case 'provider_declined':
        return Colors.orange;
      case 'payment_received':
        return Colors.green;
      case 'dispute_filed':
        return Colors.red;
      case 'sos_alert':
        return Colors.red;
      case 'booking_completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'booking_assigned':
        return Icons.assignment;
      case 'provider_accepted':
        return Icons.check_circle;
      case 'provider_declined':
        return Icons.cancel;
      case 'payment_received':
        return Icons.payment;
      case 'dispute_filed':
        return Icons.warning;
      case 'sos_alert':
        return Icons.emergency;
      case 'booking_completed':
        return Icons.done_all;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _notificationsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Notifications')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final notifications = snapshot.data ?? [];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Notifications'),
            elevation: 0,
            actions: [
              if (notifications.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.done_all),
                  tooltip: 'Mark all as read',
                  onPressed: () => _markAllAsRead(notifications),
                ),
            ],
          ),
          body: notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _initializeNotifications());
                  },
                  child: ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      final isRead = notification['read'] ?? false;

                      return Dismissible(
                        key: Key(notification['id']),
                        onDismissed: (_) async {
                          // Delete notification
                          await Supabase.instance.client
                              .from('notifications')
                              .delete()
                              .eq('id', notification['id']);
                        },
                        child: Container(
                          color: isRead ? null : Colors.blue.shade50,
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _getNotificationColor(
                                  notification['type'] ?? 'general',
                                ).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getNotificationIcon(
                                  notification['type'] ?? 'general',
                                ),
                                color: _getNotificationColor(
                                  notification['type'] ?? 'general',
                                ),
                              ),
                            ),
                            title: Text(
                              notification['title'] ?? 'Notification',
                              style: TextStyle(
                                fontWeight:
                                    isRead ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  notification['body'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTime(
                                    DateTime.parse(
                                      notification['created_at'] ?? '',
                                    ),
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(color: Colors.grey),
                                ),
                              ],
                            ),
                            trailing: isRead
                                ? null
                                : Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                            onTap: () {
                              if (!isRead) {
                                _markAsRead(
                                  notification['id'],
                                  Supabase.instance.client.auth.currentUser?.id ??
                                      '',
                                );
                              }
                              // Handle notification tap - navigate based on type
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
        );
      },
    );
  }

  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }
}
