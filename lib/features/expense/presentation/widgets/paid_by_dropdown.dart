import 'package:flutter/material.dart';
import 'package:paypact/features/group/domain/entities/member_entity.dart';

class PaidByDropdown extends StatelessWidget {
  const PaidByDropdown({
    super.key,
    required this.members,
    required this.value,
    required this.onChanged,
  });
  final List<MemberEntity> members;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
        initialValue: members.any((m) => m.userId == value) ? value : null,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.person_outline, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: members
            .map((m) => DropdownMenuItem(
                  value: m.userId,
                  child: Text(m.displayName),
                ))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      );
}
