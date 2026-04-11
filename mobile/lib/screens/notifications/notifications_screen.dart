import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../services/notification_service.dart';
import '../../models/notification_model.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _icon(String type) => switch (type) {
    'reminder'     => Icons.alarm,
    'confirmation' => Icons.check_circle_outline,
    'cancellation' => Icons.cancel_outlined,
    'prescription' => Icons.medication_outlined,
    _              => Icons.notifications_outlined,
  };

  Color _color(String type) => switch (type) {
    'reminder'     => const Color(0xFF1A56DB),
    'confirmation' => const Color(0xFF16A34A),
    'cancellation' => const Color(0xFFDC2626),
    'prescription' => const Color(0xFF7C3AED),
    _              => const Color(0xFF64748B),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationServiceProvider).markAllRead();
              ref.invalidate(notificationsProvider);
            },
            child: const Text('Tout lire', style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
      body: notifAsync.when(
        data: (notifs) {
          if (notifs.isEmpty) {
            return const Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.notifications_none, size: 64, color: Color(0xFFCBD5E1)),
                SizedBox(height: 12),
                Text('Aucune notification', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16)),
              ]),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _NotifTile(
              notif: notifs[i],
              icon: _icon(notifs[i].type),
              color: _color(notifs[i].type),
              onTap: () async {
                if (notifs[i].isUnread) {
                  await ref.read(notificationServiceProvider).markRead(notifs[i].id);
                  ref.invalidate(notificationsProvider);
                }
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final NotificationModel notif;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _NotifTile({required this.notif, required this.icon,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(
              color: notif.isUnread ? color : Colors.transparent,
              width: 3,
            ),
            right: const BorderSide(color: Color(0xFFE5E9EF)),
            top:   const BorderSide(color: Color(0xFFE5E9EF)),
            bottom: const BorderSide(color: Color(0xFFE5E9EF)),
          ),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (notif.titre != null)
              Text(notif.titre!, style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: notif.isUnread ? const Color(0xFF1E293B) : const Color(0xFF64748B),
              )),
            const SizedBox(height: 3),
            Text(notif.message, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(DateFormat('dd MMM HH:mm', 'fr').format(notif.dateEnvoi),
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600)),
          ])),
          if (notif.isUnread)
            Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(color: Color(0xFF1A56DB), shape: BoxShape.circle)),
        ]),
      ),
    );
  }
}
