import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';
import '../../widgets/ms_button.dart';
import '../../widgets/ms_text_field.dart';
import '../../utils/validators.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading    = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authStateProvider.notifier).login(
        _emailCtrl.text.trim(),
        _passCtrl.text,
      );
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A56DB), Color(0xFF0A2D7A)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Logo
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.local_hospital, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 16),
                const Text('MediSecure',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Votre santé, sécurisée et connectée',
                    style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13)),
                const SizedBox(height: 36),

                // Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Connexion',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 20),

                        MsTextField(
                          controller: _emailCtrl,
                          label: 'Adresse email',
                          hint: 'vous@exemple.fr',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 14),
                        MsTextField(
                          controller: _passCtrl,
                          label: 'Mot de passe',
                          hint: '••••••••',
                          obscureText: true,
                          prefixIcon: Icons.lock_outline,
                          validator: Validators.required,
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push('/forgot'),
                            child: const Text('Mot de passe oublié ?',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),

                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(children: [
                              const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_error!,
                                  style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13))),
                            ]),
                          ),
                          const SizedBox(height: 14),
                        ],

                        MsButton(label: 'Se connecter', loading: _loading, onPressed: _submit),
                        const SizedBox(height: 16),

                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Text("Pas encore de compte ? ",
                              style: TextStyle(color: Color(0xFF64748B))),
                          GestureDetector(
                            onTap: () => context.push('/register'),
                            child: const Text('Créer un compte',
                                style: TextStyle(color: Color(0xFF1A56DB), fontWeight: FontWeight.w700)),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.lock, color: Colors.white54, size: 14),
                  const SizedBox(width: 6),
                  Text('Connexion chiffrée SSL/TLS — JWT',
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
