import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../widgets/ms_button.dart';
import '../../widgets/ms_text_field.dart';
import '../../utils/validators.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _State();
}

class _State extends ConsumerState<ForgotPasswordScreen> {
  final _ctrl    = TextEditingController();
  bool _loading  = false;
  bool _sent     = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    await ref.read(authStateProvider.notifier).forgotPassword(_ctrl.text.trim());
    setState(() { _loading = false; _sent = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe oublié')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _sent
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.mark_email_read_outlined, size: 64, color: Color(0xFF16A34A)),
                const SizedBox(height: 16),
                const Text('Email envoyé !', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text('Si cet email existe, un lien de réinitialisation a été envoyé.',
                    textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B))),
                const SizedBox(height: 24),
                MsButton(label: 'Retour à la connexion', onPressed: () => Navigator.pop(context)),
              ])
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text('Réinitialiser votre mot de passe',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text('Entrez votre email et nous vous enverrons un lien de réinitialisation.',
                      style: TextStyle(color: Color(0xFF64748B))),
                  const SizedBox(height: 24),
                  MsTextField(controller: _ctrl, label: 'Email',
                      hint: 'vous@exemple.fr', keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined, validator: Validators.email),
                  const SizedBox(height: 20),
                  MsButton(label: 'Envoyer le lien', loading: _loading, onPressed: _submit),
                ],
              ),
      ),
    );
  }
}
