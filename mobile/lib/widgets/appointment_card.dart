import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment_model.dart';

class AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback onTap;
  const AppointmentCard({super.key, required this.appointment, required this.onTap});

  Color _statusColor(String s) => switch (s) {
    'confirmed'  => const Color(0xFF16A34A),
    'pending'    => const Color(0xFFC2410C),
    'cancelled'  => const Color(0xFFDC2626),
    'completed'  => const Color(0xFF64748B),
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
  Widget build(BuildContext context) {
    final color = _statusColor(appointment.statut);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E9EF)),
        ),
        child: Row(children: [
          // Time column
          Column(children: [
            Text(DateFormat('HH:mm').format(appointment.dateRdv),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                    color: Color(0xFF1A56DB))),
            Text('${appointment.duration}m',
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(width: 12),
          Container(width: 2, height: 44, color: const Color(0xFFE5E9EF),
              margin: const EdgeInsets.symmetric(horizontal: 4)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Médecin #${appointment.doctorId}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(DateFormat('EEE d MMM', 'fr').format(appointment.dateRdv),
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            if (appointment.motif != null) ...[
              const SizedBox(height: 2),
              Text(appointment.motif!, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ],
          ])),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(20)),
              child: Text(_statusLabel(appointment.statut),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
            ),
            const SizedBox(height: 6),
            const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 18),
          ]),
        ]),
      ),
    );
  }
}
