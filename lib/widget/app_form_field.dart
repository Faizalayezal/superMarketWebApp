import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Common reusable text field used across Add Product, POS, Settings screens
class AppFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isNumber;
  final int maxLines;
  final bool optional;
  final bool autoFocus;
  final Function(String)? onChange;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const AppFormField(
    this.controller,
    this.label, {
    super.key,
    this.isNumber = false,
    this.maxLines = 1,
    this.optional = false,
    this.autoFocus = false,
    this.onChange,
    this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        autofocus: autoFocus,
        controller: controller,
        inputFormatters: [
          if (isNumber) FilteringTextInputFormatter.digitsOnly,
        ],
        keyboardType: keyboardType ??
            (isNumber ? TextInputType.number : TextInputType.text),
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onChanged: onChange,
        validator: validator ??
            (value) {
              if (optional) return null;
              if (value == null || value.isEmpty) return "Enter $label";
              return null;
            },
      ),
    );
  }
}
