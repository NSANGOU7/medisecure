import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../services/auth_service.dart';
import '../../services/appointment_service.dart';
import '../../services/notification_service.dart';
import '../../services/admin_service.dart';
import '../../models/appointment_model.dart';
import '../../widgets/appointment_card.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/section_header.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox();
    return switch (user.role) {
      'admin'  => const _AdminDash(),
      'doctor' => const _DoctorDash(),
      'nurse'  => const _DoctorDash(),
      _        => const _PatientDash(),
    };
  }
}

// ── Patient Dashboard ─────────────────────────────────────────────────────────

class _PatientDash extends ConsumerWidget {
  const _PatientDash();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user         = ref.watch(currentUserProvider)!;
    final apptAsync    = ref.watch(appointmentsProvider);
    final unreadAsync  = ref.watch(unreadCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: const Color(0xFF1A56DB),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A56DB), Color(0xFF0A2D7A)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Bonjour 👋',
                              style: TextStyle(color: Colors.white70, fontSize: 14)),
                          Text(user.fullName,
                              style: const TextStyle(color: Colors.white, fontSize: 22,
                                  fontWeight: FontWeight.w700)),
                        ]),
                        Row(children: [
                          Stack(children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                              onPressed: () => context.go('/notifications'),
                            ),
                            unreadAsync.when(
                              data: (n) => n > 0
                                  ? Positioned(top: 8, right: 8,
                                      child: Container(width: 8, height: 8,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFEF4444), shape: BoxShape.circle)))
                                  : const SizedBox(),
                              loading: () => const SizedBox(),
                              error: (_, __) => const SizedBox(),
                            ),
                          ]),
                          const CircleAvatar(
                            backgroundColor: Colors.white24,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                        ]),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(delegate: SliverChildListDelegate([

              // Stats
              Row(children: [
                Expanded(child: StatCard(icon: Icons.calendar_month,
                    iconBg: const Color(0xFFDBEAFE), value: apptAsync.when(
                      data: (l) => l.where((a) => !a.isCancelled).length.toString(),
                      loading: () => '…', error: (_, __) => '0'),
                    label: 'RDV total')),
                const SizedBox(width: 10),
                Expanded(child: StatCard(icon: Icons.check_circle_outline,
                    iconBg: const Color(0xFFDCFCE7), value: apptAsync.when(
                      data: (l) => l.where((a) => a.isConfirmed).length.toString(),
                      loading: () => '…', error: (_, __) => '0'),
                    label: 'Confirmés')),
                const SizedBox(width: 10),
                Expanded(child: StatCard(icon: Icons.notifications_outlined,
                    iconBg: const Color(0xFFFEF3C7),
                    value: unreadAsync.when(data: (n) => n.toString(), loading: () => '…', error: (_, __) => '0'),
                    label: 'Alertes')),
              ]),
              const SizedBox(height: 20),

              // Quick actions
              const SectionHeader(title: 'Actions rapides'),
              const SizedBox(height: 10),
              Row(children: [
                _QuickAction(icon: Icons.add_circle, label: 'Prendre RDV',
                    color: const Color(0xFF1A56DB), onTap: () => context.push('/appointments/book')),
                const SizedBox(width: 10),
                _QuickAction(icon: Icons.folder_open, label: 'Mon dossier',
                    color: const Color(0xFF0D9488), onTap: () => context.go('/records')),
                const SizedBox(width: 10),
                _QuickAction(icon: Icons.qr_code, label: 'QR Code',
                    color: const Color(0xFF7C3AED), onTap: () => _showQr(context, user.id)),
                const SizedBox(width: 10),
                _QuickAction(icon: Icons.history, label: 'Historique',
                    color: const Color(0xFFC2410C), onTap: () => context.go('/records')),
              ]),
              const SizedBox(height: 20),

              // Next appointment
              apptAsync.when(
                data: (appts) {
                  final upcoming = appts.where((a) => !a.isCancelled &&
                      a.dateRdv.isAfter(DateTime.now())).toList()
                    ..sort((a, b) => a.dateRdv.compareTo(b.dateRdv));
                  if (upcoming.isEmpty) return const _NoNextAppt();
                  return _NextApptCard(appt: upcoming.first);
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 20),

              // Appointment list
              const SectionHeader(title: 'Mes rendez-vous', actionLabel: 'Voir tout',
                  onAction: null),
              const SizedBox(height: 10),
              apptAsync.when(
                data: (appts) => Column(
                  children: appts.take(4).map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppointmentCard(appointment: a,
                        onTap: () => context.push('/appointments/${a.id}')),
                  )).toList(),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Erreur: $e'),
              ),
              const SizedBox(height: 30),
            ])),
          ),
        ],
      ),
    );
  }

  void _showQr(BuildContext context, int userId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Mon QR Code Patient',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          Container(width: 160, height: 160, color: Colors.black12,
              child: Center(child: Text('QR #$userId',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)))),
          const SizedBox(height: 16),
          const Text('Présentez ce code à votre médecin.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        ]),
      ),
    );
  }
}

class _NoNextAppt extends StatelessWidget {
  const _NoNextAppt();
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const Icon(Icons.calendar_today_outlined, size: 40, color: Color(0xFF94A3B8)),
        const SizedBox(height: 10),
        const Text('Aucun RDV à venir', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => context.push('/appointments/book'),
          style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
          child: const Text('Prendre rendez-vous'),
        ),
      ]),
    ),
  );
}

class _NextApptCard extends StatelessWidget {
  final AppointmentModel appt;
  const _NextApptCard({required this.appt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A56DB), Color(0xFF0E3FA5)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Prochain rendez-vous',
            style: TextStyle(color: Colors.white70, fontSize: 12,
                fontWeight: FontWeight.w600, letterSpacing: .5)),
        const SizedBox(height: 8),
        Text('Médecin #${appt.doctorId}',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('📅 ${DateFormat('EEEE d MMMM · HH:mm', 'fr').format(appt.dateRdv)}',
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
        if (appt.motif != null) ...[
          const SizedBox(height: 4),
          Text('Motif : ${appt.motif}',
              style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ],
        const SizedBox(height: 14),
        Row(children: [
          _apptBtn('Reporter', () {}),
          const SizedBox(width: 8),
          _apptBtn('Annuler', () {}),
          const SizedBox(width: 8),
          _apptBtn('Détails', () => context.push('/appointments/${appt.id}')),
        ]),
      ]),
    );
  }

  Widget _apptBtn(String label, VoidCallback onPressed) => Expanded(
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white38),
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    ),
  );
}

// ── Doctor Dashboard ──────────────────────────────────────────────────────────

class _DoctorDash extends ConsumerWidget {
  const _DoctorDash();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user      = ref.watch(currentUserProvider)!;
    final apptAsync = ref.watch(appointmentsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Bonjour', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400)),
          Text(user.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined),
              onPressed: () => context.go('/notifications')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          apptAsync.when(
            data: (appts) => Row(children: [
              Expanded(child: StatCard(icon: Icons.people_outline, iconBg: const Color(0xFFDBEAFE),
                  value: appts.where((a) => a.dateRdv.day == DateTime.now().day).length.toString(),
                  label: "Patients aujourd'hui")),
              const SizedBox(width: 10),
              Expanded(child: StatCard(icon: Icons.pending_outlined, iconBg: const Color(0xFFFEF3C7),
                  value: appts.where((a) => a.isPending).length.toString(),
                  label: 'En attente')),
              const SizedBox(width: 10),
              Expanded(child: StatCard(icon: Icons.check_circle_outline, iconBg: const Color(0xFFDCFCE7),
                  value: appts.where((a) => a.isConfirmed).length.toString(),
                  label: 'Confirmés')),
            ]),
            loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Actions rapides'),
          const SizedBox(height: 10),
          Row(children: [
            _QuickAction(icon: Icons.folder_open, label: 'Dossiers',
                color: const Color(0xFF0D9488), onTap: () => context.go('/records')),
            const SizedBox(width: 10),
            _QuickAction(icon: Icons.calendar_month, label: 'Planning',
                color: const Color(0xFF1A56DB), onTap: () => context.go('/appointments')),
            const SizedBox(width: 10),
            _QuickAction(icon: Icons.note_add_outlined, label: 'Ordonnance',
                color: const Color(0xFF7C3AED), onTap: () => context.push('/records/prescriptions')),
            const SizedBox(width: 10),
            _QuickAction(icon: Icons.bar_chart, label: 'Stats',
                color: const Color(0xFFC2410C), onTap: () {}),
          ]),
          const SizedBox(height: 20),
          const SectionHeader(title: "RDV d'aujourd'hui"),
          const SizedBox(height: 10),
          apptAsync.when(
            data: (appts) {
              final today = appts.where((a) => a.dateRdv.day == DateTime.now().day).toList();
              if (today.isEmpty) return const Center(child: Text('Aucun RDV aujourd\'hui',
                  style: TextStyle(color: Color(0xFF94A3B8))));
              return Column(children: today.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppointmentCard(appointment: a, onTap: () => context.push('/appointments/${a.id}')),
              )).toList());
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e'),
          ),
        ]),
      ),
    );
  }
}

// ── Admin Dashboard ───────────────────────────────────────────────────────────

class _AdminDash extends ConsumerWidget {
  const _AdminDash();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Administration'),
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.go('/profile')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          statsAsync.when(
            data: (s) => Wrap(spacing: 10, runSpacing: 10, children: [
              SizedBox(width: MediaQuery.of(context).size.width / 2 - 21,
                child: StatCard(icon: Icons.people, iconBg: const Color(0xFFDBEAFE),
                    value: s['total_users'].toString(), label: 'Utilisateurs')),
              SizedBox(width: MediaQuery.of(context).size.width / 2 - 21,
                child: StatCard(icon: Icons.local_hospital_outlined, iconBg: const Color(0xFFDCFCE7),
                    value: s['active_doctors'].toString(), label: 'Médecins')),
              SizedBox(width: MediaQuery.of(context).size.width / 2 - 21,
                child: StatCard(icon: Icons.calendar_month, iconBg: const Color(0xFFFEF3C7),
                    value: s['appointments_today'].toString(), label: "RDV aujourd'hui")),
              SizedBox(width: MediaQuery.of(context).size.width / 2 - 21,
                child: StatCard(icon: Icons.pending_outlined, iconBg: const Color(0xFFFEE2E2),
                    value: s['pending_appointments'].toString(), label: 'En attente')),
            ]),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e'),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Gestion'),
          const SizedBox(height: 10),
          _AdminTile(icon: Icons.people_outline,    iconBg: const Color(0xFFDBEAFE),
              label: 'Gérer les utilisateurs', onTap: () => context.push('/admin/users')),
          _AdminTile(icon: Icons.assignment_outlined, iconBg: const Color(0xFFFEF3C7),
              label: "Journaux d'activité",    onTap: () => context.push('/admin/logs')),
          _AdminTile(icon: Icons.security_outlined,  iconBg: const Color(0xFFDCFCE7),
              label: 'Rôles & Permissions (RBAC)', onTap: () {}),
          _AdminTile(icon: Icons.bar_chart_rounded,  iconBg: const Color(0xFFF3E8FF),
              label: 'Rapports & Analytics',  onTap: () {}),
          _AdminTile(icon: Icons.settings_outlined,  iconBg: const Color(0xFFF1F5F9),
              label: 'Paramètres système',    onTap: () {}),
        ]),
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String label;
  final VoidCallback onTap;
  const _AdminTile({required this.icon, required this.iconBg,
      required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      onTap: onTap,
      leading: Container(width: 40, height: 40,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 20, color: const Color(0xFF1A56DB))),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
    ),
  );
}

// ── Shared widget ─────────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B))),
          ]),
        ),
      ),
    ),
  );
}
