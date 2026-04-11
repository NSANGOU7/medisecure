import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String value;
  final String label;
  const StatCard({super.key, required this.icon, required this.iconBg,
      required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE5E9EF)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: const Color(0xFF1A56DB)),
      ),
      const SizedBox(height: 10),
      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
          color: Color(0xFF1E293B))),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
          color: Color(0xFF94A3B8))),
    ]),
  );
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
          color: Color(0xFF94A3B8), letterSpacing: .6)),
      if (actionLabel != null && onAction != null)
        GestureDetector(
          onTap: onAction,
          child: Text(actionLabel!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
              color: Color(0xFF1A56DB))),
        ),
    ],
  );
}
