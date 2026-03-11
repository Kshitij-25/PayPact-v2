import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paypact/core/utils/currency_formatter.dart';

class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    required this.currency,
    required this.onChanged,
  });
  final TextEditingController controller;
  final String currency;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final symbol = CurrencyFormatter.symbolFor(currency);
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        labelText: 'Amount',
        // Show the symbol inline as a prefix widget so it always matches
        // the selected currency (no hardcoded $ icon).
        prefix: Text(
          '$symbol ',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Amount is required';
        final n = double.tryParse(v);
        if (n == null) return 'Enter a valid number';
        if (n <= 0) return 'Amount must be positive';
        return null;
      },
    );
  }
}