import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paypact/core/constants/app_links.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/design_system/components/paypact_button.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/features/group/domain/entities/group_entity.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// Text sent through the share sheet.
String inviteMessage(String groupName, String code) =>
    'Join "$groupName" on PayPact and split expenses with us: '
    '${AppLinks.invite(code)}';

/// Opens the system share sheet for [code]; falls back to copying the link
/// where sharing isn't available (some desktop browsers).
Future<void> shareInvite(BuildContext context,
    {required String groupName, required String code}) async {
  final messenger = ScaffoldMessenger.of(context);
  final box = context.findRenderObject() as RenderBox?;
  try {
    final result = await SharePlus.instance.share(ShareParams(
      text: inviteMessage(groupName, code),
      subject: 'Join $groupName on PayPact',
      // iPad / macOS need an anchor for the share popover.
      sharePositionOrigin:
          box != null && box.hasSize ? box.localToGlobal(Offset.zero) & box.size : null,
    ));
    if (result.status != ShareResultStatus.unavailable) return;
  } catch (_) {}
  await Clipboard.setData(ClipboardData(text: AppLinks.invite(code)));
  messenger
      .showSnackBar(const SnackBar(content: Text('Invite link copied')));
}

/// Shows the invite link, QR code and share/copy actions for [group].
/// Admins create the code on demand (older groups have none) and can reset it;
/// other members see the existing link.
Future<void> showInviteSheet(BuildContext context,
    {required GroupEntity group, required String currentUserId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _InviteSheet(
      group: group,
      isAdmin: group.isAdmin(currentUserId),
    ),
  );
}

/// Home shortcut: invite to one of several groups. Picks the group first when
/// the user is in more than one.
Future<void> showInviteForGroups(BuildContext context,
    {required List<GroupEntity> groups, required String currentUserId}) async {
  if (groups.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a group first to invite people.')));
    return;
  }
  if (groups.length == 1) {
    return showInviteSheet(context,
        group: groups.first, currentUserId: currentUserId);
  }
  final picked = await showModalBottomSheet<GroupEntity>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final pt = ctx.pt;
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: pt.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Invite to which group?',
                  style: PayPactTypography.headingMd.copyWith(color: pt.ink)),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final g in groups)
                      ListTile(
                        leading:
                            Text(g.emoji, style: const TextStyle(fontSize: 24)),
                        title: Text(g.name,
                            style: PayPactTypography.bodyMd
                                .copyWith(color: pt.ink)),
                        onTap: () => Navigator.pop(ctx, g),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  if (picked != null && context.mounted) {
    await showInviteSheet(context, group: picked, currentUserId: currentUserId);
  }
}

class _InviteSheet extends StatefulWidget {
  const _InviteSheet({required this.group, required this.isAdmin});
  final GroupEntity group;
  final bool isAdmin;

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  String? _code;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _code = widget.group.inviteCode;
    _loading = _code == null && widget.isAdmin;
    if (_loading) _create();
  }

  Future<void> _create({bool reset = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = locator<GroupRepository>();
      final code = reset
          ? await repo.resetInviteCode(widget.group.id)
          : await repo.ensureInviteCode(widget.group.id);
      if (mounted) setState(() => _code = code);
    } catch (_) {
      if (mounted) setState(() => _error = "Couldn't create the invite link.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset invite link?'),
        content: const Text(
            'The current link and QR code will stop working. Anyone you '
            'already shared them with will need the new link.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reset')),
        ],
      ),
    );
    if (ok == true) await _create(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final code = _code;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      decoration: BoxDecoration(
        color: pt.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 5,
                decoration: BoxDecoration(
                  color: pt.borderStrong.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),
              Text('${widget.group.emoji}  ${widget.group.name}',
                  textAlign: TextAlign.center,
                  style: PayPactTypography.headingMd.copyWith(color: pt.ink)),
              const SizedBox(height: 4),
              Text('Anyone with this link can join the group',
                  style: PayPactTypography.bodySm.copyWith(color: pt.ink3)),
              const SizedBox(height: 20),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                )
              else if (code == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    _error ??
                        'This group has no invite link yet. Ask a group admin to create one.',
                    textAlign: TextAlign.center,
                    style: PayPactTypography.bodyMd.copyWith(color: pt.ink2),
                  ),
                )
              else ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: PayPactRadius.lg,
                    border: Border.all(color: pt.border),
                  ),
                  child: QrImageView(
                    data: AppLinks.invite(code),
                    size: 180,
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 14),
                SelectableText(AppLinks.invite(code),
                    textAlign: TextAlign.center,
                    style: PayPactTypography.bodySm.copyWith(color: pt.ink2)),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: PayPactButton(
                      onPressed: () async {
                        await Clipboard.setData(
                            ClipboardData(text: AppLinks.invite(code)));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Link copied')));
                        }
                      },
                      label: 'Copy link',
                      variant: PayPactButtonVariant.secondary,
                      size: PayPactButtonSize.large,
                      isFullWidth: true,
                      leftIcon: Icons.link_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Builder(
                      builder: (btnContext) => PayPactButton(
                        onPressed: () => shareInvite(btnContext,
                            groupName: widget.group.name, code: code),
                        label: 'Share',
                        variant: PayPactButtonVariant.accent,
                        size: PayPactButtonSize.large,
                        isFullWidth: true,
                        leftIcon: Icons.ios_share_rounded,
                      ),
                    ),
                  ),
                ]),
                if (widget.isAdmin)
                  TextButton(
                    onPressed: _confirmReset,
                    child: Text('Reset link',
                        style:
                            PayPactTypography.bodySm.copyWith(color: pt.ink3)),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
