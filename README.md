# PayPact

Shared expenses with smart debt simplification. Flutter app (iOS, Android, web)
on Firebase: Auth, Firestore, Cloud Functions, Cloud Messaging and Hosting.

## What's in the app

- **Groups & expenses** — create groups, add expenses (equal / exact / percent /
  shares splits, multi-currency with a snapshot exchange rate), edit and delete.
- **Settle up** — the fewest payments that square everyone up, recorded as an
  immutable ledger entry with a receipt.
- **Invites** — every group has a secret invite code behind a shareable link and
  QR (`https://paypact-fec8e.web.app/invite/CODE`, `paypact://invite/CODE`).
  Joining goes through a Cloud Function, so non-members never touch group data.
- **Roles** — admins edit/delete the group and manage members and roles. You
  can't remove someone, or leave, while you have an unsettled balance; the last
  admin can't leave a group that still has other members.
- **Notifications** — in-app inbox plus push. Settings (settlements, expenses,
  smart nudges, weekly digest) and per-group mute are stored on the account and
  honoured by whoever is notifying you.
- **Insights, activity, home dashboard** — totals across groups are converted to
  your default currency (Settings → Currency). Search spans groups, expenses and
  people; Insights and Settings can export CSV / JSON.
- **Richer expenses** — back-dated entries, notes, receipt photos (with on-device
  scanning that pre-fills the amount, description and date), comments, an edit
  history, recurring expenses (weekly / monthly), per-group custom categories,
  and delete-with-undo. Payments can be reversed by the person who was paid.
- **Paying people** — add a UPI ID in Profile to show a payment QR and let friends
  pay via their UPI app from the settle-up screen.
- **Account & privacy** — App Lock (Face ID / fingerprint), crash reports and
  opt-in analytics, data export, and full account deletion.
- **Languages** — English and Hindi (Settings → Language); navigation, sign-in,
  search, settings and privacy are translated so far.

## Layout

```
lib/
  l10n/            ARB files (en, hi) + generated localizations
  core/            DI (get_it), router + auth guard, services, utils
  design_system/   tokens, theme, shared components
  features/<name>/ domain (entities, repositories) · data (Firestore) · presentation (cubits, screens)
  widgets/         shared atoms (avatars, amounts, chips)
functions/         Cloud Functions (push delivery, invites, weekly digest) + tests
rules_test/        Firestore security-rules tests (run against the emulator)
firestore.rules    security rules
web/invite/        static landing page for invite links
```

State management is `flutter_bloc` (cubits); repositories are interfaces with
Firestore implementations registered in `lib/core/di/injection_container.dart`.

## Run it

```bash
flutter pub get
flutter run                      # pick a device
```

Firebase is already configured in `lib/firebase_options.dart`.

> The iOS build uses CocoaPods (`enable-swift-package-manager: false` in
> `pubspec.yaml`) because Swift Package Manager breaks on project paths that
> contain a space. Once the project lives in a path without spaces you can
> remove that setting.

## Tests

```bash
flutter test                                   # Dart unit + widget tests
cd functions && npm install && npm test        # Cloud Functions logic (pure)
cd functions && npm run test:it                # functions end-to-end on the emulators
cd rules_test && npm install && npm test       # Firestore + Storage security rules
```

The last two start the Firebase emulators themselves (needs Java and
`firebase-tools`). CI (`.github/workflows/ci.yml`) runs all of them.

### Trying signed-in flows without touching production

```bash
cd functions && npm install && cd ..
firebase emulators:start --project paypact-fec8e   # Auth, Firestore, Functions, Storage
flutter run -d chrome --dart-define=USE_EMULATORS=true
# Android emulator: add --dart-define=EMULATOR_HOST=10.0.2.2
```

Sign up with any email/password — it exists only in the emulator.

### Localization

Strings live in `lib/l10n/app_<locale>.arb`. Add the key to `app_en.arb` (and
`app_hi.arb`), run `flutter gen-l10n`, then use `context.l10n.yourKey`. Screens
not listed above still have English-only text; migrate them the same way.

## Deploy

Order matters: rules and functions go out together because the app now depends
on both (invites call a function; push tokens live under `users/{uid}/private`).

```bash
firebase deploy --only firestore:rules,firestore:indexes
firebase deploy --only functions      # needs the Blaze plan
flutter build web && firebase deploy --only hosting
```

Functions (`functions/index.js`):

| Function | Trigger | What it does |
|---|---|---|
| `onNotificationCreated` | a doc is added to `users/{uid}/notifications` | sends the FCM push for it |
| `getInvitePreview`, `joinGroupByCode` | callable | resolves an invite code; adds the caller to the group |
| `onGroupDeleted` | a group doc is deleted | deletes its expenses and settlements |
| `onExpenseWritten`, `onSettlementCreated`, `onGroupCreated` | expense / settlement / group written | keep each group's balances and totals up to date on the group document, so the app never downloads whole histories |
| `recomputeGroupSummary` | callable | builds that summary for groups that predate it |
| `searchUsers` | callable | finds people by name or exact email (emails masked); the users collection can't be listed from the app |
| `deleteAccount` | callable | deletes the caller's account after re-authentication; refuses while money is outstanding |
| `onUserWritten` | user document written | keeps a lower-cased name for search |
| `runRecurringExpenses` | daily 03:00 IST | turns due recurring templates into expenses |
| `weeklyDigest` | Sundays 20:00 IST | writes a digest notification for users who opted in |

Also deploy Storage rules (receipt, cover and profile photos) and indexes:

```bash
firebase deploy --only storage,firestore:indexes
```

### One-time Firebase setup

- **Storage** must be enabled in the console (Build → Storage) before photo uploads work.
- **App Check**: register your app (Play Integrity / App Attest; reCAPTCHA v3 for web, passed as
  `--dart-define=RECAPTCHA_SITE_KEY=…`), run a debug build once to obtain the debug token and add it
  in the console, and only then switch *Enforce* on for Firestore, Storage and Functions —
  enforcing first locks everyone out.
- **Crashlytics** needs no setup on Android. For iOS crash symbolication add the
  `upload-symbols` build phase (the Firebase docs describe it); Dart errors are reported without it.

### Existing data

Groups created before roles/invites existed keep working: admin falls back to
the creator, and an admin gets an invite code the first time they open the
invite sheet. Push tokens used to live on the public profile; the app moves
them to the private path on next launch and scrubs the old field.

### Deep links — one-time setup

- **Android App Links:** `web/.well-known/assetlinks.json` lists the app's
  package; replace the SHA-256 with your release signing certificate
  (`cd android && ./gradlew signingReport`).
- **iOS universal links:** add the *Associated Domains* capability
  (`applinks:paypact-fec8e.web.app`) to the Runner target in Xcode. The key in
  `Info.plist` is ignored by iOS; it has to be in the entitlements. This needs a
  paid Apple developer team. Until then `paypact://invite/CODE` and the web
  page's "Open in the app" button still work.
