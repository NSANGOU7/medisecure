import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/admin_service.dart';
import '../../widgets/stat_card.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(adminStatsProvider)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          statsAsync.when(
            data: (s) => GridView.count(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2, childAspectRatio: 1.4,
              crossAxisSpacing: 10, mainAxisSpacing: 10,
              children: [
                StatCard(icon: Icons.people, iconBg: const Color(0xFFDBEAFE),
                    value: s['total_users'].toString(),          label: 'Utilisateurs'),
                StatCard(icon: Icons.local_hospital_outlined, iconBg: const Color(0xFFDCFCE7),
                    value: s['active_doctors'].toString(),       label: 'Médecins actifs'),
                StatCard(icon: Icons.calendar_today, iconBg: const Color(0xFFFEF3C7),
                    value: s['appointments_today'].toString(),   label: "RDV aujourd'hui"),
                StatCard(icon: Icons.pending_outlined, iconBg: const Color(0xFFFEE2E2),
                    value: s['pending_appointments'].toString(), label: 'En attente'),
              ],
            ),
            loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Text('$e'),
          ),
          const SizedBox(height: 20),
          _AdminNavTile(icon: Icons.people_outline, label: 'Gestion des utilisateurs',
              subtitle: 'Créer, modifier, suspendre', color: const Color(0xFFDBEAFE),
              onTap: () => context.push('/admin/users')),
          const SizedBox(height: 8),
          _AdminNavTile(icon: Icons.assignment_outlined, label: "Journaux d'activité",
              subtitle: 'Traçabilité complète des actions', color: const Color(0xFFFEF3C7),
              onTap: () => context.push('/admin/logs')),
          const SizedBox(height: 8),
          _AdminNavTile(icon: Icons.shield_outlined, label: 'Rôles & Permissions (RBAC)',
              subtitle: 'Patient, Médecin, Infirmier, Admin', color: const Color(0xFFDCFCE7),
              onTap: () {}),
          const SizedBox(height: 8),
          _AdminNavTile(icon: Icons.bar_chart_rounded, label: 'Rapports & Analytics',
              subtitle: 'Statistiques globales du système', color: const Color(0xFFF3E8FF),
              onTap: () {}),
          const SizedBox(height: 8),
          _AdminNavTile(icon: Icons.settings_outlined, label: 'Paramètres système',
              subtitle: 'Configuration générale', color: const Color(0xFFF1F5F9),
              onTap: () {}),
        ]),
      ),
    );
  }
}

class _AdminNavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _AdminNavTile({required this.icon, required this.label,
      required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      leading: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: const Color(0xFF1A56DB), size: 22),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
    ),
  );
}
