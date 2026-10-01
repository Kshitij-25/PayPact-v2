import 'package:paypact/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/services/app_lock_service.dart';
import 'package:paypact/core/services/file_export.dart';
import 'package:paypact/core/services/telemetry_service.dart';
import 'package:paypact/design_system/components/paypact_card.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/radius.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';
import 'package:paypact/features/profile/domain/data_export.dart';
import 'package:paypact/features/profile/presentation/widgets/delete_account_flow.dart';
import 'package:intl/intl.dart';

/// Settings → Privacy & data: app lock, diagnostics, export, account deletion.
class PrivacySection extends StatefulWidget {
  const PrivacySection({super.key});
  @override
  State<PrivacySection> createState() => _PrivacySectionState();
}

class _PrivacySectionState extends State<PrivacySection> {
  final _lock = locator<AppLockService>();
  final _telemetry = locator<TelemetryService>();

  bool _lockSupported = false;
  late bool _lockOn = _lock.enabled;
  late bool _analytics = _telemetry.analyticsEnabled;
  late bool _crash = _telemetry.crashReportsEnabled;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _lock.supported.then((s) {
      if (mounted) setState(() => _lockSupported = s);
    });
  }

  void _toast(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _setLock(bool on) async {
    final notEnabled = context.l10n.appLockNotEnabled;
    if (on) {
      // Prove the device can actually unlock before we start requiring it.
      final ok = await _lock.authenticate('Turn on App Lock');
      if (!ok) {
        if (mounted) _toast(notEnabled);
        return;
      }
    }
    await _lock.setEnabled(on);
    if (mounted) setState(() => _lockOn = on);
  }

  Future<void> _export() async {
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated || _exporting) return;
    setState(() => _exporting = true);
    try {
      final json = await DataExporter(
              locator<GroupRepository>(), locator<ExpenseRepository>())
          .buildJson(
              userId: auth.user.id, name: auth.user.name, email: auth.user.email);
      final outcome = await shareTextFile(
        fileName:
            'paypact-export-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.json',
        mimeType: 'application/json',
        content: json,
        subject: 'My PayPact data',
      );
      if (outcome == ExportOutcome.copied) {
        _toast('Your data was copied to the clipboard as JSON.');
      }
    } catch (_) {
      _toast("Couldn't export your data. Try again.");
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return PayPactCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        if (_lockSupported) ...[
          _Row(
            icon: Icons.lock_outline_rounded,
            label: context.l10n.appLock,
            sub: context.l10n.appLockSub,
            trailing: Switch(value: _lockOn, onChanged: _setLock),
          ),
          Divider(color: pt.border, height: 1),
        ],
        _Row(
          icon: Icons.bug_report_outlined,
          label: context.l10n.crashReports,
          sub: context.l10n.crashReportsSub,
          trailing: Switch(
            value: _crash,
            onChanged: (v) async {
              await _telemetry.setCrashReports(v);
              if (mounted) setState(() => _crash = v);
            },
          ),
        ),
        Divider(color: pt.border, height: 1),
        _Row(
          icon: Icons.donut_small_rounded,
          label: context.l10n.usageData,
          sub: context.l10n.usageDataSub,
          trailing: Switch(
            value: _analytics,
            onChanged: (v) async {
              await _telemetry.setAnalytics(v);
              if (mounted) setState(() => _analytics = v);
            },
          ),
        ),
        Divider(color: pt.border, height: 1),
        _Row(
          icon: Icons.download_outlined,
          label: context.l10n.exportData,
          sub: context.l10n.exportDataSub,
          onTap: _exporting ? null : _export,
          trailing: _exporting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(Icons.chevron_right_rounded, color: pt.ink3),
        ),
        Divider(color: pt.border, height: 1),
        _Row(
          icon: Icons.delete_outline_rounded,
          label: context.l10n.deleteAccount,
          sub: context.l10n.deleteAccountSub,
          negative: true,
          onTap: () => runDeleteAccountFlow(context),
          trailing: Icon(Icons.chevron_right_rounded, color: pt.ink3),
        ),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.trailing,
    this.sub,
    this.negative = false,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String? sub;
  final Widget trailing;
  final bool negative;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: negative ? pt.negativeSoft : pt.surfaceAlt,
              borderRadius: PayPactRadius.sm,
            ),
            alignment: Alignment.center,
            child: Icon(icon,
                size: 16, color: negative ? pt.negative : pt.ink2),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: PayPactTypography.bodyMd.copyWith(
                        color: negative ? pt.negative : pt.ink,
                        fontWeight: FontWeight.w600)),
                if (sub != null)
                  Text(sub!,
                      style: PayPactTypography.bodySm.copyWith(color: pt.ink3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ]),
      ),
    );
  }
}
