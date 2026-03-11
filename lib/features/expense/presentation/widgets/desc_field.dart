import 'package:flutter/material.dart';

class DescField extends StatelessWidget {
  const DescField({super.key, required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        maxLines: 2,
        decoration: InputDecoration(
          labelText: 'Note (optional)',
          hintText: 'Add a note...',
          prefixIcon: const Icon(Icons.notes_outlined, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
}