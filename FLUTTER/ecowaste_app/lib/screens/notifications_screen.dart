import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/waste_provider.dart';
import '../providers/auth_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      print('Loading notifications...');
      final wasteProvider = Provider.of<WasteProvider>(context, listen: false);
      final notifications = await wasteProvider.getNotifications();
      print('Notifications loaded: ${notifications.length}');
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading notifications: $e')),
        );
      }
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      final wasteProvider = Provider.of<WasteProvider>(context, listen: false);
      await wasteProvider.markNotificationRead(notificationId);
      await _loadNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final wasteProvider = Provider.of<WasteProvider>(context, listen: false);
      await wasteProvider.markAllNotificationsRead();
      await _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _showApproveDialog(Map<String, dynamic> notification) async {
    _addressController.text = notification['waste_report_details']?['full_address'] ?? '';
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Pickup Request'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Shop: ${notification['pickup_request_details']?['buyer_details']?['shop_name'] ?? 'Unknown'}'),
              const SizedBox(height: 8),
              Text('Waste Type: ${notification['waste_report_details']?['waste_type_display'] ?? 'Unknown'}'),
              const SizedBox(height: 8),
              Text('Offered Price: ₹${notification['pickup_request_details']?['offered_price'] ?? '0'}'),
              const SizedBox(height: 16),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Pickup Address *',
                  hintText: 'Enter complete address for pickup',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              const Text(
                'Please provide your complete address where the buyer can collect the waste.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_addressController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter pickup address')),
                );
                return;
              }
              Navigator.pop(context);
              await _approveRequest(notification, _addressController.text.trim());
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveRequest(Map<String, dynamic> notification, String address) async {
    try {
      final wasteProvider = Provider.of<WasteProvider>(context, listen: false);
      final requestId = notification['pickup_request'];
      
      await wasteProvider.approvePickupRequest(requestId, address);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pickup request approved successfully')),
        );
        await _loadNotifications();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving request: $e')),
        );
      }
    }
  }

  Future<void> _rejectRequest(Map<String, dynamic> notification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Pickup Request'),
        content: const Text('Are you sure you want to reject this pickup request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final wasteProvider = Provider.of<WasteProvider>(context, listen: false);
        final requestId = notification['pickup_request'];
        
        await wasteProvider.rejectPickupRequest(requestId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pickup request rejected')),
          );
          await _loadNotifications();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error rejecting request: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => n['is_read'] == false).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, color: Colors.white),
              label: Text(
                'Mark All Read ($unreadCount)',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off,
                        size: 80,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final isUnread = notification['is_read'] == false;
                      final isPickupRequest = notification['notification_type'] == 'pickup_request';
                      final requestStatus = notification['pickup_request_details']?['status'] ?? '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: isUnread
                            ? const Color(0xFF1E3A5F)
                            : const Color(0xFF1E293B),
                        child: InkWell(
                          onTap: isUnread ? () => _markAsRead(notification['id']) : null,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _getNotificationIcon(notification['notification_type']),
                                      color: _getNotificationColor(notification['notification_type']),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  notification['title'] ?? 'Notification',
                                                  style: TextStyle(
                                                    fontWeight: isUnread
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                              if (isUnread)
                                                Container(
                                                  width: 10,
                                                  height: 10,
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFF10b981),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            notification['message'] ?? '',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[300],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _formatDateTime(notification['created_at']),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                if (isPickupRequest && requestStatus == 'pending') ...[
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () => _rejectRequest(notification),
                                        icon: const Icon(Icons.close, size: 18),
                                        label: const Text('Reject'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(color: Colors.red),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton.icon(
                                        onPressed: () => _showApproveDialog(notification),
                                        icon: const Icon(Icons.check, size: 18),
                                        label: const Text('Approve'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF10b981),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'pickup_request':
        return Icons.local_shipping;
      case 'request_accepted':
        return Icons.check_circle;
      case 'request_rejected':
        return Icons.cancel;
      case 'pickup_completed':
        return Icons.done_all;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'pickup_request':
        return const Color(0xFF10b981);
      case 'request_accepted':
        return Colors.green;
      case 'request_rejected':
        return Colors.red;
      case 'pickup_completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return '';
    try {
      final dt = DateTime.parse(dateTime);
      final now = DateTime.now();
      final difference = now.difference(dt);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes} minutes ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours} hours ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${dt.day}/${dt.month}/${dt.year}';
      }
    } catch (e) {
      return dateTime;
    }
  }
}
