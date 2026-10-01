import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/design_system/components/paypact_card.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/features/expense/domain/entities/expense_entity.dart';
import 'package:paypact/features/expense/domain/entities/expense_extras.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/notification/domain/repositories/notifications_repository.dart';
import 'package:paypact/widgets/pp_atoms.dart';

/// Full-screen, pinch-to-zoom view of a receipt photo.
void showReceiptViewer(BuildContext context, String url) {
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(children: [
        Positioned.fill(
          child: InteractiveViewer(
            maxScale: 5,
            child: Center(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const Center(child: CircularProgressIndicator()),
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 48),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: IconButton(
              tooltip: 'Close',
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ),
        ),
      ]),
    ),
  );
}

String _ago(DateTime at) {
  final d = DateTime.now().difference(at);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 7) return '${d.inDays}d ago';
  return DateFormat('MMM d').format(at);
}

// ── Comments ──────────────────────────────────────────────────────────────────

class ExpenseCommentsSection extends StatefulWidget {
  const ExpenseCommentsSection({
    super.key,
    required this.expense,
    required this.groupName,
    required this.currentUserId,
    required this.currentUserName,
  });
  final ExpenseEntity expense;
  final String groupName;
  final String currentUserId;
  final String currentUserName;

  @override
  State<ExpenseCommentsSection> createState() => _ExpenseCommentsSectionState();
}

class _ExpenseCommentsSectionState extends State<ExpenseCommentsSection> {
  final _ctrl = TextEditingController();
  bool _sending = false;
  List<ExpenseComment> _latest = const [];
  late final Stream<List<ExpenseComment>> _stream = locator<ExpenseRepository>()
      .watchComments(widget.expense.groupId, widget.expense.id);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final e = widget.expense;
      await locator<ExpenseRepository>().addComment(e.groupId, e.id,
          authorId: widget.currentUserId,
          authorName: widget.currentUserName,
          text: text);
      _ctrl.clear();

      // Tell everyone involved: the people in the split, the payer, and anyone
      // who has already commented.
      final audience = <String>{
        e.paidById,
        ...e.splits.map((s) => s.userId),
        ..._latest.map((c) => c.authorId),
      }..remove(widget.currentUserId);
      final snippet = text.length > 80 ? '${text.substring(0, 80)}…' : text;
      final notifs = locator<NotificationsRepository>();
      await Future.wait(audience.map((id) => notifs.push(
            targetUserId: id,
            type: 'expense_comment',
            title: '${widget.currentUserName} commented on "${e.title}"',
            body: snippet,
            groupId: e.groupId,
            groupName: widget.groupName,
            actorId: widget.currentUserId,
            actorName: widget.currentUserName,
          )));
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text("Couldn't post your comment.")));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<List<ExpenseComment>>(
          stream: _stream,
          builder: (context, snap) {
            final comments = snap.data ?? const <ExpenseComment>[];
            _latest = comments;
            return PayPactCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                if (comments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text('No comments yet — ask a question or leave a note.',
                        style: PayPactTypography.bodySm.copyWith(color: pt.ink3)),
                  ),
                for (var i = 0; i < comments.length; i++) ...[
                  if (i > 0) Divider(color: pt.border, height: 1, indent: 16),
                  _CommentTile(
                    comment: comments[i],
                    mine: comments[i].authorId == widget.currentUserId,
                    onDelete: () => locator<ExpenseRepository>().deleteComment(
                        widget.expense.groupId,
                        widget.expense.id,
                        comments[i].id),
                  ),
                ],
              ]),
            );
          },
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              minLines: 1,
              maxLines: 4,
              maxLength: 1000,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              style: PayPactTypography.bodyMd.copyWith(color: pt.ink),
              decoration: InputDecoration(
                hintText: 'Add a comment',
                counterText: '',
                filled: true,
                fillColor: pt.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: PayPactRadius.md,
                    borderSide: BorderSide(color: pt.borderStrong)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: PayPactRadius.md,
                    borderSide: BorderSide(color: pt.borderStrong)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Send comment',
            onPressed: _sending ? null : _send,
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send_rounded, size: 18),
          ),
        ]),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile(
      {required this.comment, required this.mine, required this.onDelete});
  final ExpenseComment comment;
  final bool mine;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PpAvatar(name: comment.authorName, size: 30),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text(mine ? 'You' : comment.authorName,
                    overflow: TextOverflow.ellipsis,
                    style: PayPactTypography.bodySm.copyWith(
                        color: pt.ink, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Text(_ago(comment.createdAt),
                  style: PayPactTypography.bodySm.copyWith(color: pt.ink3)),
            ]),
            const SizedBox(height: 2),
            SelectableText(comment.text,
                style: PayPactTypography.bodyMd.copyWith(color: pt.ink2)),
          ]),
        ),
        if (mine)
          IconButton(
            tooltip: 'Delete comment',
            visualDensity: VisualDensity.compact,
            onPressed: onDelete,
            icon: Icon(Icons.close_rounded, size: 16, color: pt.ink3),
          ),
      ]),
    );
  }
}

// ── History ───────────────────────────────────────────────────────────────────

class ExpenseHistorySection extends StatelessWidget {
  const ExpenseHistorySection({super.key, required this.expense});
  final ExpenseEntity expense;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return StreamBuilder<List<ExpenseHistoryEntry>>(
      stream: locator<ExpenseRepository>()
          .watchHistory(expense.groupId, expense.id),
      builder: (context, snap) {
        final entries = snap.data ?? const <ExpenseHistoryEntry>[];
        if (entries.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 22),
            const PpSectionLabel(label: 'EDIT HISTORY', padding: EdgeInsets.zero),
            const SizedBox(height: 10),
            PayPactCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                for (var i = 0; i < entries.length; i++) ...[
                  if (i > 0) Divider(color: pt.border, height: 1, indent: 16),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${entries[i].byName} · ${_ago(entries[i].at)}',
                              style: PayPactTypography.bodySm.copyWith(
                                  color: pt.ink, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          for (final c in entries[i].changes)
                            Text('• $c',
                                style: PayPactTypography.bodySm
                                    .copyWith(color: pt.ink2)),
                        ]),
                  ),
                ],
              ]),
            ),
          ],
        );
      },
    );
  }
}
