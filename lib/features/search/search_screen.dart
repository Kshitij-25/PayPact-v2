import 'package:paypact/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paypact/core/di/injection_container.dart';
import 'package:paypact/core/navigation/app_router.dart';
import 'package:paypact/core/utils/currency_utils.dart';
import 'package:paypact/design_system/components/paypact_card.dart';
import 'package:paypact/design_system/theme/paypact_theme_extension.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:paypact/features/expense/domain/repositories/expense_repository.dart';
import 'package:paypact/features/group/domain/repositories/group_repository.dart';
import 'package:paypact/features/search/search_cubit.dart';
import 'package:paypact/features/search/search_logic.dart';
import 'package:paypact/widgets/pp_atoms.dart';

/// Search across groups, expenses and people. `scope` narrows it when opened
/// from the Groups or Activity tabs.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key, this.scope = SearchScope.all});
  final SearchScope scope;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthCubit>().state;
    final uid = auth is AuthAuthenticated ? auth.user.id : '';
    return BlocProvider(
      create: (_) => SearchCubit(
          locator<GroupRepository>(), locator<ExpenseRepository>(), uid, scope)
        ..load(),
      child: _SearchBody(scope: scope),
    );
  }
}

class _SearchBody extends StatefulWidget {
  const _SearchBody({required this.scope});
  final SearchScope scope;

  @override
  State<_SearchBody> createState() => _SearchBodyState();
}

class _SearchBodyState extends State<_SearchBody> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _hint(BuildContext context) => switch (widget.scope) {
        SearchScope.groups => context.l10n.searchHintGroups,
        SearchScope.expenses => context.l10n.searchHintExpenses,
        SearchScope.all => context.l10n.searchHintAll,
      };

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Scaffold(
      backgroundColor: pt.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
            child: Row(children: [
              IconButton(
                tooltip: 'Back',
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: (v) => context.read<SearchCubit>().search(v),
                  style: PayPactTypography.bodyLg.copyWith(color: pt.ink),
                  decoration: InputDecoration(
                    hintText: _hint(context),
                    prefixIcon: Icon(Icons.search_rounded, color: pt.ink3),
                    suffixIcon: _ctrl.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _ctrl.clear();
                              context.read<SearchCubit>().search('');
                              setState(() {});
                            },
                          ),
                  ),
                ),
              ),
            ]),
          ),
          Expanded(
            child: BlocBuilder<SearchCubit, SearchState>(
              builder: (context, state) {
                if (state is! SearchReady) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _Results(state: state, scope: widget.scope);
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.state, required this.scope});
  final SearchReady state;
  final SearchScope scope;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    final r = state.results;
    final typing = state.query.trim().isNotEmpty;

    // Nothing typed yet: offer the groups as shortcuts.
    if (!typing) {
      if (scope == SearchScope.expenses || state.groups.isEmpty) {
        return _Hint(
            icon: Icons.search_rounded, text: context.l10n.searchTypeToSearch);
      }
      return ListView(padding: const EdgeInsets.all(20), children: [
        PpSectionLabel(
            label: context.l10n.searchYourGroups, padding: EdgeInsets.zero),
        const SizedBox(height: 10),
        _GroupCard(groups: state.groups),
      ]);
    }

    if (r.isEmpty && !state.loadingExpenses) {
      return _Hint(
          icon: Icons.search_off_rounded,
          text: context.l10n.searchNothing(state.query.trim()));
    }

    return ListView(padding: const EdgeInsets.all(20), children: [
      if (r.groups.isNotEmpty) ...[
        PpSectionLabel(
            label: context.l10n.searchGroups, padding: EdgeInsets.zero),
        const SizedBox(height: 10),
        _GroupCard(groups: r.groups),
        const SizedBox(height: 22),
      ],
      if (r.people.isNotEmpty) ...[
        PpSectionLabel(
            label: context.l10n.searchPeople, padding: EdgeInsets.zero),
        const SizedBox(height: 10),
        PayPactCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            for (var i = 0; i < r.people.length; i++) ...[
              if (i > 0) Divider(height: 1, color: pt.border, indent: 16),
              ListTile(
                leading: PpAvatar(name: r.people[i].name, size: 36),
                title: Text(r.people[i].name),
                subtitle: Text(
                    r.people[i].groups.map((g) => g.name).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                onTap: () =>
                    context.push('/group/${r.people[i].groups.first.id}'),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 22),
      ],
      if (r.expenses.isNotEmpty || state.loadingExpenses) ...[
        PpSectionLabel(
            label: state.loadingExpenses
                ? context.l10n.searchExpensesLoading
                : context.l10n.searchExpenses,
            padding: EdgeInsets.zero),
        const SizedBox(height: 10),
        if (r.expenses.isNotEmpty)
          PayPactCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              for (var i = 0; i < r.expenses.length; i++) ...[
                if (i > 0) Divider(height: 1, color: pt.border, indent: 16),
                ListTile(
                  title: Text(r.expenses[i].expense.title),
                  subtitle: Text(
                      '${r.expenses[i].group.emoji} ${r.expenses[i].group.name} · ${DateFormat('MMM d, yyyy').format(r.expenses[i].expense.date)}'
                      ' · ${r.expenses[i].expense.paidByName} paid'),
                  trailing: Text(
                      '${currencySymbol(r.expenses[i].group.currency)}${r.expenses[i].expense.amount.toStringAsFixed(r.expenses[i].expense.amount.truncateToDouble() == r.expenses[i].expense.amount ? 0 : 2)}',
                      style: PayPactTypography.bodyMd.copyWith(
                          color: pt.ink, fontWeight: FontWeight.w700)),
                  onTap: () => context.push(AppRoutes.expense(
                      r.expenses[i].expense.id, r.expenses[i].group.id)),
                ),
              ],
            ]),
          ),
      ],
    ]);
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.groups});
  final List groups;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return PayPactCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        for (var i = 0; i < groups.length; i++) ...[
          if (i > 0) Divider(height: 1, color: pt.border, indent: 16),
          ListTile(
            leading: Text(groups[i].emoji, style: const TextStyle(fontSize: 24)),
            title: Text(groups[i].name),
            subtitle: Text(context.l10n.memberCount(groups[i].memberIds.length)),
            onTap: () => context.push('/group/${groups[i].id}'),
          ),
        ],
      ]),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final pt = context.pt;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 36, color: pt.ink3),
        const SizedBox(height: 10),
        Text(text, style: PayPactTypography.bodyMd.copyWith(color: pt.ink3)),
      ]),
    );
  }
}
