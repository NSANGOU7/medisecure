// ── MsButton ──────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

class MsButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  const MsButton({super.key, required this.label, this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
          : Text(label),
    ),
  );
}
