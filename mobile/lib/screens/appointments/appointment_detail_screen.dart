import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../services/appointment_service.dart';
import '../../models/appointment_model.dart';
import '../../widgets/ms_button.dart';

class AppointmentDetailScreen extends ConsumerWidget {
  final int id;
  const AppointmentDetailScreen({super.key, required this.id});

  Color _statusColor(String s) => switch (s) {
    'confirmed'  => const Color(0xFF16A34A),
    'pending'    => const Color(0xFFC2410C),
    'cancelled'  => const Color(0xFFDC2626),
    _            => const Color(0xFF64748B),
  };

  String _statusLabel(String s) => switch (s) {
    'confirmed'  => 'Confirmé',
    'pending'    => 'En attente',
    'cancelled'  => 'Annulé',
    'completed'  => 'Terminé',
    _            => s,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apptAsync = ref.watch(appointmentsProvider);

    return apptAsync.when(
      data: (appts) {
        final appt = appts.firstWhere((a) => a.id == id,
            orElse: () => throw Exception('Not found'));
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(title: const Text('Détails du RDV')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              // Doctor card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFFDBEAFE),
                      child: const Icon(Icons.person, size: 28, color: Color(0xFF1A56DB)),
                    ),
                    const SizedBox(width: 14),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Médecin #${appt.doctorId}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const Text('Spécialité',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    ]),
                  ]),
                ),
              ),
              const SizedBox(height: 12),

              // Details card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    _DetailRow(icon: Icons.calendar_month, label: 'Date',
                        value: DateFormat('EEEE d MMMM yyyy', 'fr').format(appt.dateRdv)),
                    _DetailRow(icon: Icons.access_time, label: 'Heure',
                        value: DateFormat('HH:mm').format(appt.dateRdv)),
                    _DetailRow(icon: Icons.timer_outlined, label: 'Durée',
                        value: '${appt.duration} minutes'),
                    if (appt.motif != null)
                      _DetailRow(icon: Icons.notes_outlined, label: 'Motif', value: appt.motif!),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: _statusColor(appt.statut).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.info_outline,
                              size: 16, color: _statusColor(appt.statut)),
                        ),
                        const SizedBox(width: 12),
                        const Text('Statut',
                            style: TextStyle(fontSize: 13, color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(appt.statut).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(_statusLabel(appt.statut),
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                                  color: _statusColor(appt.statut))),
                        ),
                      ]),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 20),

              // Actions
              if (!appt.isCancelled && !appt.isCompleted) ...[
                MsButton(
                  label: '↻ Reporter',
                  onPressed: () => _reschedule(context, ref, appt),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => _cancel(context, ref, appt),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Annuler le rendez-vous',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ]),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref, AppointmentModel appt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Annuler le rendez-vous ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Retour')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Annuler le RDV', style: TextStyle(color: Color(0xFFDC2626)))),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(appointmentServiceProvider).cancelAppointment(appt.id);
      ref.invalidate(appointmentsProvider);
      if (context.mounted) context.pop();
    }
  }

  void _reschedule(BuildContext context, WidgetRef ref, AppointmentModel appt) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reportez via Prendre RDV')));
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: const Color(0xFF64748B)),
      ),
      const SizedBox(width: 12),
      Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B),
          fontWeight: FontWeight.w600)),
      const Spacer(),
      Flexible(child: Text(value, textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B)))),
    ]),
  );
}
