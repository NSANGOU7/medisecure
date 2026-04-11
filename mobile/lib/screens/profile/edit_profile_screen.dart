import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../services/api_client.dart';
import '../../widgets/ms_button.dart';
import '../../widgets/ms_text_field.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nomCtrl    = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _telCtrl    = TextEditingController();
  bool _loading     = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _nomCtrl.text    = user.nom;
      _prenomCtrl.text = user.prenom;
      _telCtrl.text    = user.telephone ?? '';
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose(); _prenomCtrl.dispose(); _telCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ApiClient().dio.put('/users/me', data: {
        'nom':       _nomCtrl.text,
        'prenom':    _prenomCtrl.text,
        'telephone': _telCtrl.text,
      });
      await ref.read(authStateProvider.notifier).refreshCurrentUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Profil mis à jour'),
                backgroundColor: Color(0xFF16A34A)));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Modifier le profil')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        MsTextField(controller: _prenomCtrl, label: 'Prénom',
            prefixIcon: Icons.person_outline),
        const SizedBox(height: 14),
        MsTextField(controller: _nomCtrl, label: 'Nom',
            prefixIcon: Icons.person_outline),
        const SizedBox(height: 14),
        MsTextField(controller: _telCtrl, label: 'Téléphone',
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined),
        const SizedBox(height: 24),
        MsButton(label: 'Enregistrer', loading: _loading, onPressed: _save),
      ]),
    ),
  );
}
