# PayPact — Flutter port of the v2 redesign

This folder mirrors your `lib/` structure. Drop these files in directly — they import the existing
design-system tokens (`PayPactColors`, `PayPactTypography`, `PayPactRadius`, `PayPactSpacing`,
`PayPactShadows`), the `PayPactThemeExtension` (via `context.pt`), and the existing components
(`PayPactButton`, `PayPactCard`, `PayPactBadge`, `PayPactBottomNav`).

All screens are **stateless / mock-data** — they render the visual design only. Wiring them up to
your BLoCs (`AuthBloc`, `GroupBloc`, `ExpenseBloc`, `NotificationBloc`, `SettingsBloc`) is the next
step.

## Map

| HTML mock              | Flutter file                                                       |
|------------------------|--------------------------------------------------------------------|
| Splash                 | `features/splash/splash_screen_v2.dart`                            |
| Onboarding · 01/02/03  | `features/onboarding/onboarding_screen.dart` (PageView, 3 pages)   |
| Sign in                | `features/auth/presentation/screens/sign_in_screen.dart`           |
| Home                   | `features/home/presentation/screens/home_screen_v2.dart`           |
| Groups                 | `features/group/presentation/screens/groups_screen_v2.dart`        |
| Create Group           | `features/group/presentation/screens/create_group_screen.dart`     |
| Group detail           | `features/group/presentation/screens/group_detail_screen_v2.dart`  |
| Add expense            | `features/expense/presentation/screens/add_expense_screen_v2.dart` |
| Expense detail         | `features/expense/presentation/screens/expense_detail_screen.dart` |
| Settle up              | `features/settle/settle_up_screen.dart`                            |
| Settled (success)      | `features/settle/settle_success_screen.dart`                       |
| Activity               | `features/activity/activity_screen.dart`                           |
| Notifications          | `features/notification/presentation/screens/notifications_screen_v2.dart` |
| Profile                | `features/profile/presentation/screens/profile_screen_v2.dart`     |
| Settings               | `features/profile/presentation/screens/settings_screen.dart`       |

Shared building blocks live in `widgets/pp_atoms.dart` — `PpAvatar`, `PpAvatarStack`,
`PpGlassCard`, `PpGlassIconButton`, `PpStatusBarSpacer`, `PpCategoryDisc`, `PpSectionLabel`,
`PpChip`, `PpBackdropGlow`, `PpAmount`.

## Notes

- **Font:** typography uses your existing `PayPactTypography` (Geist + Geist Mono). The HTML mocks
  used Plus Jakarta — the Flutter feel is similar but slightly more grotesk.
- **FAB & bottom nav:** I use your `PayPactBottomNav` for the main tabs (Home/Groups/Activity/You)
  and your `PayPactButton` for CTAs. The FAB tap routes you to `AddExpenseScreen`.
- **Glass / layering:** done with `BackdropFilter` + translucent fills. Most surfaces are still
  opaque paper to keep readability — only nav, sheet handles, and a few floating chips are glassy.
- **Imagery placeholders:** anywhere the HTML used an emoji as a cover or category, I kept the
  emoji as `Text` so it's swappable later for icons or photos.
- **Data:** all screen content is hard-coded mock data. Look for `_mock*` lists at the top of
  each file — replace with bloc state when you wire up.
