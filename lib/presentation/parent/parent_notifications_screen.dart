import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../state/parent_provider.dart';
import '../common/status_badge.dart';

class ParentNotificationsScreen extends ConsumerWidget {
  const ParentNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(parentNotificationsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(parentNotificationsProvider.notifier).loadNotifications(),
          ),
        ],
      ),
      body: notifsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.notifications_none_rounded, size: 48, color: AppTheme.textMuted),
                    SizedBox(height: 16),
                    Text(
                      'No Notifications Yet',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Confirmed attendance updates for your children will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final isRead = notif.isRead;

              return Card(
                color: isRead ? AppTheme.surface : AppTheme.primary.withAlpha(8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isRead ? AppTheme.cardBorder : AppTheme.primary.withAlpha(50),
                    width: isRead ? 1 : 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              StatusBadge(status: notif.status, isSmall: true),
                              const SizedBox(width: 8),
                              Text(
                                notif.studentName,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              if (!isRead)
                                IconButton(
                                  icon: const Icon(Icons.mark_email_read_outlined, size: 18, color: AppTheme.primary),
                                  tooltip: 'Mark as read',
                                  onPressed: () => ref.read(parentNotificationsProvider.notifier).markAsRead(notif.notificationId),
                                ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.textMuted),
                                tooltip: 'Delete notification',
                                onPressed: () => ref.read(parentNotificationsProvider.notifier).deleteNotification(notif.notificationId),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notif.message,
                        style: const TextStyle(fontSize: 13, height: 1.4, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person_pin_outlined, size: 14, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            'Tutor: ${notif.tutorName} • Subject: ${notif.subject}',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppTheme.absent))),
      ),
    );
  }
}
