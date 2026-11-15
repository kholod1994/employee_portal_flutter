import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/app_notification.dart';
import '../providers/portal_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PortalProvider>();
    final notifications = provider.notifications.reversed.toList(growable: false);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('التنبيهات'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (notifications.isNotEmpty)
            IconButton(
              tooltip: 'تمييز الكل كمقروء',
              onPressed: provider.markAllNotificationsRead,
              icon: const Icon(Icons.done_all_rounded),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Text('لا توجد تنبيهات جديدة', style: TextStyle(color: AppTheme.muted)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationTile(
                  notification: notification,
                  onTap: () async {
                    try {
                      await provider.markNotificationRead(notification);
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('تعذر تحديث التنبيه: $error')),
                        );
                      }
                    }
                  },
                );
              },
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPermit = notification.type.startsWith('permit');
    final createdAt = notification.createdAt;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFECE6DE)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                foregroundColor: AppTheme.primary,
                child: Icon(isPermit ? Icons.access_time_rounded : Icons.beach_access_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notification.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 5),
                    Text(notification.message, style: const TextStyle(color: AppTheme.muted, height: 1.45)),
                    if (createdAt != null) ...[
                      const SizedBox(height: 7),
                      Text(
                        DateFormat('yyyy/MM/dd  HH:mm').format(createdAt.toLocal()),
                        style: const TextStyle(color: AppTheme.muted, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.circle, size: 8, color: AppTheme.accent),
            ],
          ),
        ),
      ),
    );
  }
}