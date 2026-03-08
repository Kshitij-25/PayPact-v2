import 'package:flutter/material.dart';
import 'package:paypact/core/theme/app_theme.dart';
import 'package:paypact/core/utils/currency_formatter.dart';
import 'package:paypact/domain/entities/group_entity.dart';

class GroupCard extends StatelessWidget {
  const GroupCard({
    super.key,
    required this.group,
    required this.currentUserId,
    required this.onTap,
  });

  final GroupEntity group;
  final String currentUserId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final currentMember = group.getMember(currentUserId);
    final balance = currentMember?.balance ?? 0.0;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildGroupAvatar(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${group.memberCount} members · ${CurrencyFormatter.format(group.totalExpenses, group.currency)} total',
                      style: const TextStyle(
                        fontSize: 13,
                        color: PaypactColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildBalanceBadge(context, balance, group.currency),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _gradientColors(group.category),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          _categoryEmoji(group.category),
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }

  Widget _buildBalanceBadge(
      BuildContext context, double balance, String currency) {
    if (balance == 0) {
      return const Chip(
        label: Text('Settled',
            style: TextStyle(fontSize: 12, color: PaypactColors.textSecondary)),
        backgroundColor: Color(0xFFF3F4F6),
        padding: EdgeInsets.zero,
      );
    }
    final isOwed = balance > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          isOwed ? 'you get' : 'you owe',
          style:
              const TextStyle(fontSize: 11, color: PaypactColors.textSecondary),
        ),
        Text(
          CurrencyFormatter.format(balance.abs(), currency),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: isOwed
                ? PaypactColors.secondary
                : Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }

  List<Color> _gradientColors(GroupCategory cat) => switch (cat) {
        GroupCategory.home => [
            const Color(0xFF6366F1),
            const Color(0xFF8B5CF6)
          ],
        GroupCategory.trip => [
            const Color(0xFF3B82F6),
            const Color(0xFF06B6D4)
          ],
        GroupCategory.couple => [
            const Color(0xFFEC4899),
            const Color(0xFFF97316)
          ],
        GroupCategory.friends => [
            const Color(0xFF10B981),
            const Color(0xFF3B82F6)
          ],
        GroupCategory.work => [
            const Color(0xFF6B7280),
            const Color(0xFF374151)
          ],
        GroupCategory.other => [
            const Color(0xFFF59E0B),
            const Color(0xFFEF4444)
          ],
      };

  String _categoryEmoji(GroupCategory cat) => switch (cat) {
        GroupCategory.home => '🏠',
        GroupCategory.trip => '✈️',
        GroupCategory.couple => '❤️',
        GroupCategory.friends => '🎉',
        GroupCategory.work => '💼',
        GroupCategory.other => '📂',
      };
}
