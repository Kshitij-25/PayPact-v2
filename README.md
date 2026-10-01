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
  your default currency (Settings → Currency).

## Layout

```
lib/
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
flutter test                         # Dart unit tests
cd functions && npm install && npm test        # Cloud Functions logic
cd rules_test && npm install && npm test       # security rules, needs Java + firebase-tools
```

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
| `weeklyDigest` | Sundays 20:00 IST | writes a digest notification for users who opted in |

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
