import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';
import '../../widgets/ms_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
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
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const SizedBox(height: 40),
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white24,
                    child: Text(
                      '${user.prenom[0]}${user.nom[0]}',
                      style: const TextStyle(color: Colors.white, fontSize: 24,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(user.fullName, style: const TextStyle(color: Colors.white,
                      fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_roleLabel(user.role),
                        style: const TextStyle(color: Colors.white, fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push('/profile/edit')),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(delegate: SliverChildListDelegate([
              // Account info
              _SettingsSection(title: 'Mon compte', items: [
                _SettingsTile(icon: Icons.person_outline, iconBg: const Color(0xFFDBEAFE),
                    label: 'Informations personnelles',
                    subtitle: '${user.email}',
                    onTap: () => context.push('/profile/edit')),
                _SettingsTile(icon: Icons.phone_outlined, iconBg: const Color(0xFFDCFCE7),
                    label: 'Téléphone',
                    subtitle: user.telephone ?? 'Non renseigné',
                    onTap: () => context.push('/profile/edit')),
              ]),
              const SizedBox(height: 12),

              // Security
              _SettingsSection(title: 'Sécurité', items: [
                _SettingsTile(icon: Icons.lock_outline, iconBg: const Color(0xFFEFF6FF),
                    label: 'Changer le mot de passe', onTap: () {}),
                _SettingsToggleTile(
                    icon: Icons.security, iconBg: const Color(0xFFDCFCE7),
                    label: 'Double authentification (2FA)',
                    initialValue: true),
                _SettingsTile(icon: Icons.history, iconBg: const Color(0xFFF3E8FF),
                    label: "Journal d'activité", onTap: () {}),
              ]),
              const SizedBox(height: 12),

              // Preferences
              _SettingsSection(title: 'Préférences', items: [
                _SettingsToggleTile(
                    icon: Icons.notifications_outlined, iconBg: const Color(0xFFFEF3C7),
                    label: 'Notifications push', initialValue: true),
                _SettingsToggleTile(
                    icon: Icons.email_outlined, iconBg: const Color(0xFFDBEAFE),
                    label: 'Rappels par email', initialValue: true),
                _SettingsTile(icon: Icons.language, iconBg: const Color(0xFFF1F5F9),
                    label: 'Langue', subtitle: 'Français', onTap: () {}),
              ]),
              const SizedBox(height: 12),

              // Admin-specific
              if (user.role == 'admin') ...[
                _SettingsSection(title: 'Administration', items: [
                  _SettingsTile(icon: Icons.people_outline, iconBg: const Color(0xFFDBEAFE),
                      label: 'Gérer les utilisateurs',
                      onTap: () => context.push('/admin/users')),
                  _SettingsTile(icon: Icons.assignment_outlined, iconBg: const Color(0xFFFEF3C7),
                      label: "Journaux d'activité",
                      onTap: () => context.push('/admin/logs')),
                  _SettingsTile(icon: Icons.shield_outlined, iconBg: const Color(0xFFDCFCE7),
                      label: 'Rôles & Permissions',
                      onTap: () {}),
                ]),
                const SizedBox(height: 12),
              ],

              // Danger zone
              _SettingsSection(title: 'Danger', items: [
                _SettingsTile(icon: Icons.delete_outline, iconBg: const Color(0xFFFEE2E2),
                    label: 'Supprimer mon compte',
                    labelColor: const Color(0xFFDC2626),
                    onTap: () => _confirmDelete(context, ref)),
              ]),
              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authStateProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout),
                label: const Text('Se déconnecter'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 30),
            ])),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String r) => switch (r) {
    'admin'  => '🛡️ Administrateur',
    'doctor' => '👨‍⚕️ Médecin',
    'nurse'  => '👩‍⚕️ Infirmier·e',
    _        => '🧑 Patient',
  };

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer le compte ?'),
        content: const Text('Toutes vos données seront supprimées définitivement.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contactez un administrateur.')));
            },
            child: const Text('Supprimer', style: TextStyle(color: Color(0xFFDC2626))),
          ),
        ],
      ),
    );
  }
}

// ── Profile widgets ───────────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(title.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                color: Color(0xFF94A3B8), letterSpacing: .6)),
      ),
      Card(
        child: Column(children: items.map((item) => Column(children: [
          item,
          if (item != items.last) const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
        ])).toList()),
      ),
    ],
  );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String label;
  final String? subtitle;
  final Color? labelColor;
  final VoidCallback onTap;
  const _SettingsTile({required this.icon, required this.iconBg,
      required this.label, this.subtitle, this.labelColor, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, size: 18, color: const Color(0xFF1A56DB)),
    ),
    title: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
        color: labelColor ?? const Color(0xFF1E293B))),
    subtitle: subtitle != null
        ? Text(subtitle!, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)))
        : null,
    trailing: const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
  );
}

class _SettingsToggleTile extends StatefulWidget {
  final IconData icon;
  final Color iconBg;
  final String label;
  final bool initialValue;
  const _SettingsToggleTile({required this.icon, required this.iconBg,
      required this.label, required this.initialValue});
  @override
  State<_SettingsToggleTile> createState() => _ToggleState();
}

class _ToggleState extends State<_SettingsToggleTile> {
  late bool _val;
  @override
  void initState() { super.initState(); _val = widget.initialValue; }
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: widget.iconBg, borderRadius: BorderRadius.circular(10)),
      child: Icon(widget.icon, size: 18, color: const Color(0xFF1A56DB)),
    ),
    title: Text(widget.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    trailing: Switch(
      value: _val,
      onChanged: (v) => setState(() => _val = v),
      activeColor: const Color(0xFF1A56DB),
    ),
  );
}
