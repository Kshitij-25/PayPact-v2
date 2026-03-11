import 'package:flutter/material.dart';

class TitleField extends StatelessWidget {
  const TitleField({super.key, required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: 'Title',
          hintText: 'e.g. Dinner, Hotel, Groceries...',
          prefixIcon: const Icon(Icons.label_outline, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Title is required' : null,
      );
}
