import 'package:flutter/material.dart';
import 'package:paypact/core/utils/currency_formatter.dart';
import 'package:paypact/features/group/domain/entities/member_entity.dart';

class SplitPreview extends StatelessWidget {
  const SplitPreview({
    super.key,
    required this.preview,
    required this.members,
    required this.currency,
  });
  final Map<String, double> preview;
  final List<MemberEntity> members;
  final String currency;

  String _name(String uid) =>
      members.where((m) => m.userId == uid).firstOrNull?.displayName ??
      uid.substring(0, 6);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.04),
          border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.preview_outlined,
                  size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Text('Split preview',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary)),
            ]),
            const SizedBox(height: 10),
            ...preview.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    Expanded(
                        child: Text(_name(e.key),
                            style: const TextStyle(fontSize: 13))),
                    Text(
                      CurrencyFormatter.format(e.value, currency),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ]),
                )),
          ],
        ),
      );
}
