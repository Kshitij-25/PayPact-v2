import 'package:flutter/material.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      );
}
