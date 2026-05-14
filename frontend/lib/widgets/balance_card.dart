import 'package:flutter/material.dart';
import 'package:splitease/models/balance.dart';
import 'package:splitease/providers/app_provider.dart';
import 'package:provider/provider.dart';

class BalanceCard extends StatelessWidget {
  final Balance balance;
  final bool isMe;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final fromUser = app.getUserById(balance.from);
    final toUser = app.getUserById(balance.to);
    final accent = isMe ? Color(0xFFE11D48) : Color(0xFF059669);
    final fromName = fromUser?.name ?? 'Unknown';
    final toName = toUser?.name ?? 'Unknown';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Row(
            children: [
              _Avatar(emoji: fromUser?.avatar ?? '?'),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: 16, color: accent),
              const SizedBox(width: 8),
              _Avatar(emoji: toUser?.avatar ?? '?'),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$fromName owes $toName',
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 14)),
                Text(
                    isMe
                        ? 'You need to pay $toName'
                        : toUser?.id == app.currentUser.id
                            ? '$fromName should pay you'
                            : 'Outstanding between members',
                    style:
                        TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          Text('RM ${balance.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: accent,
              )),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String emoji;
  const _Avatar({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 18)),
    );
  }
}
