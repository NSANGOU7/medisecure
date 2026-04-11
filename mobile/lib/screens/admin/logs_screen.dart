import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../services/admin_service.dart';

class LogsScreen extends ConsumerWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(logsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Journaux d'activité"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(logsProvider)),
        ],
      ),
      body: logsAsync.when(
        data: (logs) => logs.isEmpty
            ? const Center(child: Text('Aucun log disponible'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: logs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) => _LogTile(log: logs[i]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final Map<String, dynamic> log;
  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final action = log['action'] as String? ?? '';
    final ip     = log['adresse_ip'] as String? ?? '—';
    final ts     = log['date_action'] as String?;
    final userId = log['user_id'];
    DateTime? dt;
    try { dt = ts != null ? DateTime.parse(ts) : null; } catch (_) {}

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.history, size: 18, color: Color(0xFF64748B)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(action, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B))),
            const SizedBox(height: 3),
            Row(children: [
              const Icon(Icons.person_outline, size: 12, color: Color(0xFF94A3B8)),
              const SizedBox(width: 3),
              Text('User #$userId', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              const SizedBox(width: 10),
              const Icon(Icons.computer, size: 12, color: Color(0xFF94A3B8)),
              const SizedBox(width: 3),
              Text(ip, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ]),
            if (dt != null) ...[
              const SizedBox(height: 2),
              Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(dt.toLocal()),
                  style: const TextStyle(fontSize: 10, color: Color(0xFFCBD5E1),
                      fontWeight: FontWeight.w600)),
            ],
          ])),
        ]),
      ),
    );
  }
}
