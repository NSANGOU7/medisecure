import 'package:flutter/material.dart';

class MsTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;

  const MsTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.validator,
  });

  @override
  State<MsTextField> createState() => _MsTextFieldState();
}

class _MsTextFieldState extends State<MsTextField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.label.toUpperCase(),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              color: Color(0xFF64748B), letterSpacing: .5)),
      const SizedBox(height: 6),
      TextFormField(
        controller: widget.controller,
        obscureText: widget.obscureText && !_visible,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon, size: 18) : null,
          suffixIcon: widget.obscureText
              ? IconButton(
                  icon: Icon(_visible ? Icons.visibility_off : Icons.visibility, size: 18),
                  onPressed: () => setState(() => _visible = !_visible),
                )
              : null,
        ),
      ),
    ],
  );
}
