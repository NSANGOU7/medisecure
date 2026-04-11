import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/record_service.dart';
import '../../widgets/ms_button.dart';
import '../../widgets/ms_text_field.dart';

class PrescriptionScreen extends ConsumerStatefulWidget {
  const PrescriptionScreen({super.key});
  @override
  ConsumerState<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends ConsumerState<PrescriptionScreen> {
  final _medCtrl  = TextEditingController();
  final _dosCtrl  = TextEditingController();
  final _posCtrl  = TextEditingController();
  bool _loading   = false;
  String? _error;

  @override
  void dispose() {
    _medCtrl.dispose(); _dosCtrl.dispose(); _posCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_medCtrl.text.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      final record = await ref.read(recordServiceProvider).getMyRecord();
      await ref.read(recordServiceProvider).addPrescription(record.patientId, {
        'medicament': _medCtrl.text,
        'dosage':     _dosCtrl.text,
        'posologie':  _posCtrl.text,
        'date_debut': DateTime.now().toIso8601String().split('T').first,
      });
      ref.invalidate(myRecordProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Ordonnance créée et envoyée'),
                backgroundColor: Color(0xFF16A34A)));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('💊 Nouvelle ordonnance')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        MsTextField(controller: _medCtrl, label: 'Médicament',
            hint: 'Ex: Amoxicilline 500mg', prefixIcon: Icons.medication_outlined),
        const SizedBox(height: 14),
        MsTextField(controller: _dosCtrl, label: 'Dosage',
            hint: 'Ex: 500mg', prefixIcon: Icons.colorize_outlined),
        const SizedBox(height: 14),
        MsTextField(controller: _posCtrl, label: 'Posologie',
            hint: 'Ex: 1 comprimé 3x/jour pendant 7 jours',
            prefixIcon: Icons.schedule_outlined),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Color(0xFFDC2626))),
        ],
        const SizedBox(height: 24),
        MsButton(label: '✓ Émettre l\'ordonnance', loading: _loading, onPressed: _submit),
      ]),
    ),
  );
}
