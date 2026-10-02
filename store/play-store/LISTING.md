# PayPact — Google Play listing

Copy-paste material for the Play Console. Character limits are Play's.

## Main store listing

| Field | Value | Limit |
|---|---|---|
| App name | `PayPact: Split Expenses` | 30 (23 used) |
| Short description | `Split bills with friends, settle up in a tap, and keep money between you calm.` | 80 (78 used) |
| Default language | English (India) — `en-IN`; add Hindi (`hi-IN`) later | |
| App icon | `logo/paypact-icon-512.png` (512×512) | |
| Feature graphic | `feature-graphic-1024x500.png` | 1024×500 |
| Phone screenshots | `screenshots/01…08` (1080×1920) — min 2, max 8 | |

### Full description (≈2,300 of 4,000 characters)

```
PayPact makes shared money feel quiet. Add what you spent, see who owes whom, and settle up in a few taps — no spreadsheets, no awkward reminders.

SPLIT ANYTHING, ANY WAY
• Equal, exact amounts, percentages or shares
• Back-date expenses, add notes and receipt photos
• Scan a receipt on your phone to pre-fill the amount, description and date (the scan happens on your device)
• Repeat rent, Wi-Fi or subscriptions weekly or monthly
• Foreign-currency expenses with the exchange rate saved at the time
• Custom categories for each group

SEE WHO OWES WHOM
• Live balances for every group and across all of them
• Smart debt simplification: the fewest payments that square everyone up
• Comments and an edit history on every expense
• Undo a delete before it's final

SETTLE UP YOUR WAY
• Record cash or bank-transfer payments in one tap
• Pay a friend through your own UPI app for ₹ groups — PayPact opens your UPI app with the amount filled in
• Show your personal UPI QR so friends can pay you in person
• Every settlement gets a receipt, and payments can be reversed by the person who was paid

GROUPS THAT RUN THEMSELVES
• Trips, flats, couples, friends — each with its own members and roles
• Invite with a link or QR code
• Admins manage members; nobody can leave with an unsettled balance by accident

STAY ON TOP OF IT
• An activity timeline of every expense and payment
• Insights: spending over time and where the money went
• A quiet in-app inbox, with notifications for new expenses, payments and an optional weekly digest — each one can be switched off
• Search across groups, expenses and people

YOURS TO CONTROL
• App Lock with fingerprint or face unlock
• Export your data as CSV or JSON
• Delete your account from Settings whenever you like
• Crash reports can be turned off, and usage analytics are off unless you opt in
• No ads. We don't sell your data.
• Available in English and Hindi

PayPact never handles your money: payments happen in your own UPI or banking app, and PayPact keeps the record. We never see card numbers, bank passwords or UPI PINs.

Questions or feedback? Reach us from the support contact on this page.
```

### Suggested tags / search terms (pick up to 5 in Play Console)
Expense tracker · Split bills · Group expenses · Personal finance (or Finance) · Money manager

## App details

| Field | Value |
|---|---|
| App or game | App |
| Free or paid | Free |
| Category | **Finance** (alternative: Productivity) |
| Package name | `com.kshitijcodecraft.paypact` |
| Version | 1.0.0 (build 1) — from `pubspec.yaml` |
| Contact email | *your support address — required, shown publicly* |
| Website | `https://paypact-fec8e.web.app` (optional) |
| Privacy policy URL | `https://paypact-fec8e.web.app/legal/privacy.html` |
| Terms | `https://paypact-fec8e.web.app/legal/terms.html` |

## Content rating questionnaire (IARC)
Category: **Utility, Productivity, Communication, or Other**. Answer **No** to violence, sexual content, profanity, controlled substances and gambling. Users can interact (group members see each other's names, comments and photos) and share some personal info (name, optional UPI ID) → answer **Yes** to "users interact / share personal info". Expected rating: **Everyone** (3+), possibly with the "users interact" notice.

## Target audience & content
- Target age: **18 and over** (a money app; policy says it isn't for under-13s)
- Not designed for children; no ads; no in-app purchases
- Ads: **No**
- Government app: No · News app: No · COVID-19: No

## App content declarations
- **Financial features**: select "Personal finance / expense tracking". PayPact doesn't provide loans, banking, trading or payment processing → "My app doesn't provide any of these".
- **Data safety** (see below)
- **Account deletion**: users can delete in-app (Settings → Privacy & data → Delete account). Play also wants a **web URL** for requesting deletion — see "Before you submit".

## Data safety form

All data is encrypted in transit. Users can request deletion. Nothing is sold; no data is shared with third parties for their own purposes (Firebase acts as a service provider processing data on your behalf, which Play does not count as "sharing").

| Data type | Collected | Shared | Optional | Purpose |
|---|---|---|---|---|
| Name | Yes | No | No | App functionality, account management |
| Email address | Yes | No | No | App functionality, account management |
| User IDs | Yes | No | No | App functionality, account management |
| Other financial info (expenses, balances, settlements, UPI ID) | Yes | No | UPI ID optional | App functionality |
| Photos (profile, group cover, receipts) | Yes | No | Yes | App functionality |
| Other user-generated content (notes, comments) | Yes | No | Yes | App functionality |
| Crash logs / Diagnostics | Yes | No | Yes (can be turned off in Settings) | Analytics (app stability) |
| App interactions | Yes, **only if user opts in** | No | Yes | Analytics |
| Device or other IDs (Firebase installation ID) | Yes | No | Yes (diagnostics) | Analytics / diagnostics |

Not collected: location, contacts, SMS, call logs, health, audio, files, web browsing history.

## Permissions to expect in the manifest
- `POST_NOTIFICATIONS` — local notifications from the in-app inbox
- `RECEIVE_BOOT_COMPLETED` — restarts the ~15-minute background inbox check (WorkManager)
- `USE_BIOMETRIC` — App Lock
- `INTERNET` (merged from Firebase) · camera/photo access via the system picker

## Release notes — 1.0.0 (en-IN, ≤500 chars)
```
Welcome to PayPact 🎉
• Split expenses equally, by amount, percent or shares
• See who owes whom, with the fewest payments to settle up
• Pay via your UPI app or record cash/bank transfers
• Invite friends with a link or QR code
• Insights, receipts, recurring expenses and an activity timeline
• English and Hindi
```

## Before you submit — things only you can fill in
1. **Support email** (public, required) — the privacy policy refers to "the support contact on the store page", so it must be set.
2. **Account-deletion web URL** — Play requires a link where users can request deletion without opening the app. `privacy.html` describes the in-app route only; add a short `web/legal/delete-account.html` (or a section in the privacy page) with your support email and the steps, then paste that URL in Data safety → Data deletion.
3. **App label** — `android/app/src/main/AndroidManifest.xml` has `android:label="paypact"` (lowercase). Set it to `PayPact` so the launcher shows the right name.
4. **Release signing + AAB** — build with `flutter build appbundle --release` using an upload key (`android/key.properties`). Enrol in Play App Signing when prompted.
5. **Deploy the web pages** (`flutter build web && firebase deploy --only hosting`) so the privacy-policy URL is live before you submit; Play checks it.
6. **App Check / Firestore rules** — the README's one-time setup notes (App Attest/Play Integrity registration) should be done before enforcing App Check for the production build.
7. **Privacy policy mentions "Apple"** sign-in, but the app only has Google and email sign-in on Android — tweak the wording to match what you ship.
8. **Testing track** — new personal developer accounts must run a closed test with 12+ testers for 14 days before production access; plan for that.
9. **Test credentials for review** — the app needs sign-in. Create a reviewer account in production (not the local demo account) and enter it under App access → "All or some functionality is restricted".
