import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../services/appointment_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/ms_button.dart';

// ── Booking state ─────────────────────────────────────────────────────────────

class _BookingData {
  String? specialtyName;
  int?    specialtyId;
  int?    doctorId;
  String? doctorName;
  DateTime? date;
  String?   timeSlot;
  String?   motif;
}

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});
  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  int _step = 0;
  final _data = _BookingData();
  bool _loading = false;

  static const _specialties = [
    (id: 1, icon: '❤️', name: 'Cardiologie',   bg: Color(0xFFFEE2E2)),
    (id: 2, icon: '🧠', name: 'Neurologie',    bg: Color(0xFFF3E8FF)),
    (id: 3, icon: '🦷', name: 'Dentaire',      bg: Color(0xFFFFFBEB)),
    (id: 4, icon: '👁️', name: 'Ophtalmologie', bg: Color(0xFFEFF6FF)),
    (id: 5, icon: '🩺', name: 'Généraliste',   bg: Color(0xFFDCFCE7)),
    (id: 6, icon: '🦴', name: 'Orthopédie',    bg: Color(0xFFFEF3C7)),
    (id: 7, icon: '🫁', name: 'Pneumologie',   bg: Color(0xFFE0F2FE)),
    (id: 8, icon: '🔬', name: 'Dermatologie',  bg: Color(0xFFFDF2F8)),
  ];

  static const _doctors = [
    (id: 1, name: 'Dr. Sophie Martin', rating: '4.9', avail: 'Disponible'),
    (id: 2, name: 'Dr. Marc Bernard',  rating: '4.7', avail: 'Disponible'),
    (id: 3, name: 'Dr. Aïcha Diallo',  rating: '4.8', avail: 'Lun prochain'),
  ];

  static const _slots = [
    '09:00', '09:30', '10:00', '10:30',
    '11:00', '11:30', '14:00', '14:30',
    '15:00', '15:30', '16:00', '16:30',
  ];
  static const _taken = {'10:30', '14:00'};

  void _next()  => setState(() => _step++);
  void _back()  { if (_step > 0) setState(() => _step--); else context.pop(); }

  Future<void> _confirm() async {
    if (_data.doctorId == null || _data.date == null || _data.timeSlot == null) return;
    setState(() => _loading = true);
    try {
      final parts  = _data.timeSlot!.split(':');
      final dateRdv = _data.date!.copyWith(
        hour: int.parse(parts[0]), minute: int.parse(parts[1]), second: 0);
      await ref.read(appointmentServiceProvider).createAppointment(
        doctorId: _data.doctorId!,
        dateRdv: dateRdv,
        motif: _data.motif,
      );
      ref.invalidate(appointmentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Rendez-vous réservé avec succès !'),
              backgroundColor: Color(0xFF16A34A)));
        context.go('/appointments');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: const Color(0xFFDC2626)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const steps = ['Spécialité', 'Médecin', 'Créneau', 'Confirmation'];
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Prendre RDV — ${steps[_step]}'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _back),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: (_step + 1) / steps.length,
            backgroundColor: Colors.white30,
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: [
          _buildStep0(),
          _buildStep1(),
          _buildStep2(),
          _buildStep3(),
        ][_step],
      ),
    );
  }

  // ── Step 0: Specialty ───────────────────────────────────────────────────────

  Widget _buildStep0() => Column(children: [
    const _StepTitle('Choisissez une spécialité'),
    Expanded(
      child: GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: _specialties.map((s) {
          final selected = _data.specialtyId == s.id;
          return GestureDetector(
            onTap: () => setState(() {
              _data.specialtyId = s.id;
              _data.specialtyName = s.name;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFEFF6FF) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? const Color(0xFF1A56DB) : const Color(0xFFE5E9EF),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(children: [
                Text(s.icon, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Expanded(child: Text(s.name,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                        color: selected ? const Color(0xFF1A56DB) : const Color(0xFF1E293B)))),
                if (selected) const Icon(Icons.check_circle, color: Color(0xFF1A56DB), size: 18),
              ]),
            ),
          );
        }).toList(),
      ),
    ),
    const SizedBox(height: 12),
    MsButton(
      label: 'Suivant →',
      onPressed: _data.specialtyId != null ? _next : null,
    ),
  ]);

  // ── Step 1: Doctor ──────────────────────────────────────────────────────────

  Widget _buildStep1() => Column(children: [
    _StepTitle('Choisissez un médecin en ${_data.specialtyName ?? ""}'),
    ..._doctors.map((d) {
      final selected = _data.doctorId == d.id;
      return GestureDetector(
        onTap: () => setState(() { _data.doctorId = d.id; _data.doctorName = d.name; }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? const Color(0xFF1A56DB) : const Color(0xFFE5E9EF),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFF1F5F9),
              child: const Icon(Icons.person, color: Color(0xFF64748B)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              Text('${_data.specialtyName} · ⭐ ${d.rating}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.circle, size: 8, color: Color(0xFF16A34A)),
                const SizedBox(width: 4),
                Text(d.avail, style: const TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w600, color: Color(0xFF16A34A))),
              ]),
            ])),
            if (selected) const Icon(Icons.check_circle, color: Color(0xFF1A56DB)),
          ]),
        ),
      );
    }),
    const SizedBox(height: 12),
    MsButton(label: 'Suivant →', onPressed: _data.doctorId != null ? _next : null),
  ]);

  // ── Step 2: Time slot ───────────────────────────────────────────────────────

  Widget _buildStep2() {
    _data.date ??= DateTime.now().add(const Duration(days: 1));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _StepTitle('Choisissez un créneau'),
      // Date picker row
      SizedBox(
        height: 80,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 14,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final d    = DateTime.now().add(Duration(days: i + 1));
            final sel  = _data.date?.day == d.day && _data.date?.month == d.month;
            return GestureDetector(
              onTap: () => setState(() => _data.date = d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 56,
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFF1A56DB) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: sel ? const Color(0xFF1A56DB) : const Color(0xFFE5E9EF)),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(DateFormat('E', 'fr').format(d).substring(0, 3),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                          color: sel ? Colors.white70 : const Color(0xFF94A3B8))),
                  const SizedBox(height: 4),
                  Text('${d.day}', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : const Color(0xFF1E293B))),
                ]),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 16),
      const Text('Créneaux disponibles',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
      const SizedBox(height: 10),
      Expanded(
        child: GridView.count(
          crossAxisCount: 4,
          childAspectRatio: 1.8,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: _slots.map((t) {
            final taken    = _taken.contains(t);
            final selected = _data.timeSlot == t;
            return GestureDetector(
              onTap: taken ? null : () => setState(() => _data.timeSlot = t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: taken ? const Color(0xFFF8FAFC)
                      : selected ? const Color(0xFF1A56DB) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: taken ? const Color(0xFFF1F5F9)
                        : selected ? const Color(0xFF1A56DB) : const Color(0xFFE2E8F0),
                    width: selected ? 2 : 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(t,
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: taken ? const Color(0xFFCBD5E1)
                          : selected ? Colors.white : const Color(0xFF1E293B),
                    )),
              ),
            );
          }).toList(),
        ),
      ),
      MsButton(label: 'Suivant →', onPressed: _data.timeSlot != null ? _next : null),
    ]);
  }

  // ── Step 3: Confirm ─────────────────────────────────────────────────────────

  Widget _buildStep3() {
    final motifCtrl = TextEditingController(text: _data.motif);
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _StepTitle('Confirmer le rendez-vous'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E9EF)),
          ),
          child: Column(children: [
            _ConfirmRow(label: 'Spécialité', value: _data.specialtyName ?? ''),
            _ConfirmRow(label: 'Médecin',    value: _data.doctorName    ?? ''),
            _ConfirmRow(label: 'Date',
                value: _data.date != null
                    ? DateFormat('EEEE d MMMM yyyy', 'fr').format(_data.date!)
                    : ''),
            _ConfirmRow(label: 'Heure',    value: _data.timeSlot ?? ''),
            _ConfirmRow(label: 'Durée',    value: '30 minutes', isLast: true),
          ]),
        ),
        const SizedBox(height: 16),
        const Text('Motif (optionnel)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                color: Color(0xFF64748B), letterSpacing: .5)),
        const SizedBox(height: 8),
        TextField(
          controller: motifCtrl,
          onChanged: (v) => _data.motif = v,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Ex: Douleur thoracique, bilan annuel...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),
        MsButton(label: '✓ Confirmer le rendez-vous', loading: _loading, onPressed: _confirm),
      ]),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _StepTitle extends StatelessWidget {
  final String text;
  const _StepTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16, top: 4),
    child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
  );
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;
  const _ConfirmRow({required this.label, required this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B))),
        ],
      ),
    ),
    if (!isLast) const Divider(height: 1, color: Color(0xFFF1F5F9)),
  ]);
}
