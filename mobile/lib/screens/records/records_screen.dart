import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../services/record_service.dart';
import '../../services/auth_service.dart';
import '../../models/medical_record_model.dart';
import '../../widgets/ms_button.dart';

class RecordsScreen extends ConsumerWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role        = ref.watch(userRoleProvider);
    final recordAsync = ref.watch(myRecordProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 110,
            backgroundColor: const Color(0xFF0F766E),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('📋 Dossier médical',
                        style: TextStyle(color: Colors.white, fontSize: 20,
                            fontWeight: FontWeight.w700)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(children: [
                        Icon(Icons.lock, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text('Chiffré', style: TextStyle(color: Colors.white, fontSize: 11,
                            fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: recordAsync.when(
              data: (record) => SliverList(
                delegate: SliverChildListDelegate([
                  _ExpandableSection(
                    icon: '👤', title: 'Informations personnelles',
                    color: const Color(0xFFDBEAFE),
                    child: _InfoSection(record: record),
                  ),
                  const SizedBox(height: 10),
                  _ExpandableSection(
                    icon: '🏥', title: 'Antécédents & Allergies',
                    color: const Color(0xFFFEE2E2),
                    child: _AntecedentsSection(record: record),
                  ),
                  const SizedBox(height: 10),
                  _ExpandableSection(
                    icon: '💊', title: 'Ordonnances actives',
                    color: const Color(0xFFDCFCE7),
                    child: _PrescriptionsSection(
                      prescriptions: record.prescriptions,
                      isDoctor: role == 'doctor' || role == 'nurse',
                      patientId: record.patientId,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ExpandableSection(
                    icon: '📝', title: 'Historique consultations',
                    color: const Color(0xFFF3E8FF),
                    child: _ConsultationsSection(consultations: record.consultations),
                  ),
                  const SizedBox(height: 10),
                  _ExpandableSection(
                    icon: '🔬', title: "Résultats d'analyses",
                    color: const Color(0xFFFEF3C7),
                    child: _LabResultsSection(results: record.labResults),
                  ),
                  if (role == 'doctor' || role == 'nurse') ...[
                    const SizedBox(height: 20),
                    MsButton(
                      label: '+ Ajouter une note médicale',
                      onPressed: () => _addNote(context, ref, record),
                    ),
                  ],
                  const SizedBox(height: 30),
                ]),
              ),
              loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SliverFillRemaining(
                  child: Center(child: Text('Erreur: $e'))),
            ),
          ),
        ],
      ),
    );
  }

  void _addNote(BuildContext context, WidgetRef ref, MedicalRecordModel record) {
    final diagCtrl = TextEditingController();
    final obsCtrl  = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('📝 Note médicale', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(controller: diagCtrl,
              decoration: const InputDecoration(labelText: 'Diagnostic')),
          const SizedBox(height: 12),
          TextField(controller: obsCtrl, maxLines: 3,
              decoration: const InputDecoration(labelText: 'Observations')),
          const SizedBox(height: 16),
          MsButton(label: 'Enregistrer', onPressed: () async {
            await ref.read(recordServiceProvider).addConsultation(record.patientId, {
              'date_consult':  DateTime.now().toIso8601String(),
              'diagnostic':    diagCtrl.text,
              'observations':  obsCtrl.text,
            });
            ref.invalidate(myRecordProvider);
            if (context.mounted) Navigator.pop(context);
          }),
        ]),
      ),
    );
  }
}

// ── Expandable section widget ─────────────────────────────────────────────────

class _ExpandableSection extends StatefulWidget {
  final String icon;
  final String title;
  final Color color;
  final Widget child;
  const _ExpandableSection({required this.icon, required this.title,
      required this.color, required this.child});

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => Card(
    child: Column(children: [
      ListTile(
        onTap: () => setState(() => _open = !_open),
        leading: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(widget.icon, style: const TextStyle(fontSize: 18))),
        ),
        title: Text(widget.title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        trailing: AnimatedRotation(
          turns: _open ? 0.5 : 0,
          duration: const Duration(milliseconds: 200),
          child: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF94A3B8)),
        ),
      ),
      if (_open) ...[
        const Divider(height: 1, color: Color(0xFFF1F5F9)),
        Padding(padding: const EdgeInsets.all(16), child: widget.child),
      ],
    ]),
  );
}

// ── Section content widgets ───────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  final MedicalRecordModel record;
  const _InfoSection({required this.record});

  @override
  Widget build(BuildContext context) => Column(children: [
    _Row(label: 'ID dossier', value: '#${record.id}'),
    _Row(label: 'Créé le', value: DateFormat('dd/MM/yyyy').format(record.dateCreation)),
  ]);
}

class _AntecedentsSection extends StatelessWidget {
  final MedicalRecordModel record;
  const _AntecedentsSection({required this.record});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (record.antecedents != null && record.antecedents!.isNotEmpty) ...[
        const _SectionLabel('Antécédents'),
        Text(record.antecedents!, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
        const SizedBox(height: 10),
      ],
      if (record.allergies != null && record.allergies!.isNotEmpty) ...[
        const _SectionLabel('Allergies'),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(record.allergies!,
                style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626),
                    fontWeight: FontWeight.w700))),
          ]),
        ),
      ],
      if ((record.antecedents == null || record.antecedents!.isEmpty) &&
          (record.allergies   == null || record.allergies!.isEmpty))
        const Text('Aucune information renseignée.',
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
    ],
  );
}

class _PrescriptionsSection extends StatelessWidget {
  final List<PrescriptionModel> prescriptions;
  final bool isDoctor;
  final int patientId;
  const _PrescriptionsSection({required this.prescriptions,
      required this.isDoctor, required this.patientId});

  @override
  Widget build(BuildContext context) {
    final active = prescriptions.where((p) => p.isActive).toList();
    if (active.isEmpty) return const Text('Aucune ordonnance active.',
        style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)));
    return Column(children: [
      ...active.map((p) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.medicament,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          if (p.dosage != null)
            Text('${p.dosage}${p.posologie != null ? " — ${p.posologie}" : ""}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          if (p.dateFin != null)
            Text('Jusqu\'au ${DateFormat('dd/MM/yyyy').format(p.dateFin!)}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        ]),
      )),
    ]);
  }
}

class _ConsultationsSection extends StatelessWidget {
  final List<ConsultationModel> consultations;
  const _ConsultationsSection({required this.consultations});

  @override
  Widget build(BuildContext context) {
    if (consultations.isEmpty) return const Text('Aucune consultation enregistrée.',
        style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)));
    return Column(children: consultations.map((c) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(DateFormat('dd MMM yyyy', 'fr').format(c.dateConsult),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A56DB))),
        if (c.diagnostic != null)
          Text(c.diagnostic!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        if (c.observations != null)
          Text(c.observations!, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      ]),
    )).toList());
  }
}

class _LabResultsSection extends StatelessWidget {
  final List<LabResultModel> results;
  const _LabResultsSection({required this.results});

  Color _statusColor(String? s) => switch (s) {
    'normal' => const Color(0xFF16A34A),
    'high'   => const Color(0xFFDC2626),
    'low'    => const Color(0xFFC2410C),
    _        => const Color(0xFF64748B),
  };

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const Text('Aucun résultat disponible.',
        style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)));
    return Column(children: results.map((r) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Expanded(child: Text(r.examen,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: Color(0xFF64748B)))),
        if (r.valeur != null)
          Text('${r.valeur} ${r.unite ?? ""}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: _statusColor(r.statut))),
      ]),
    )).toList());
  }
}

// ── Tiny helpers ──────────────────────────────────────────────────────────────

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
      Text(value,  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
    ]),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
        color: Color(0xFF94A3B8), letterSpacing: .5, textBaseline: TextBaseline.alphabetic)),
  );
}
