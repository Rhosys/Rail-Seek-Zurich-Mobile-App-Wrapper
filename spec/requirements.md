# Rail & Seek — TWA Wrapper App

## Overview

A Trusted Web Activity (TWA) Android app that wraps the already-deployed website at `https://railandseek.rune.town/`. The app contains no business logic — it is a thin Android shell that launches the website in a verified, full-screen Custom Tab (no browser chrome). The app declares permissions for notifications, location (including background), camera, audio, and system features so the PWA can use them via standard Web APIs.

## Functional Requirements

### FR-1: TWA launch
The app launches `https://railandseek.rune.town/` as a Trusted Web Activity. When Digital Asset Links verification succeeds, the site renders full-screen with no browser UI. When verification fails (e.g. debug builds), the site opens in a Custom Tab with minimal browser chrome.

### FR-2: Digital Asset Links
The app's signing certificate SHA-256 fingerprint is declared in `/.well-known/assetlinks.json` on `railandseek.rune.town`, enabling Android to verify the app-to-site relationship and suppress the browser URL bar.

### FR-3: Notification permission
On first launch (or when the PWA requests it), the app prompts the user to grant `POST_NOTIFICATIONS` (Android 13+). The permission is forwarded to the web content so the PWA can use the Web Push API.

### FR-4: Location permission
The app requests `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, and `ACCESS_BACKGROUND_LOCATION` so the PWA's Geolocation API works. Background location is required so player position continues tracking during transit when the screen is off or app is backgrounded. `ACCESS_BACKGROUND_LOCATION` requires Play Store policy justification and a separate runtime prompt.

### FR-4a: Camera permission
The app declares `CAMERA` so the PWA can access front and rear cameras for photo proof of visited locations and QR code scanning.

### FR-4b: Audio permission
The app declares `RECORD_AUDIO` so the PWA can capture voice messages between teammates or video with audio.

### FR-4c: System permissions
The app declares:
- `VIBRATE` — haptic alerts for game events (opponent nearby, timer warnings)
- `WAKE_LOCK` — keep game connection alive during transit (screen off)
- `INTERNET` + `ACCESS_NETWORK_STATE` — explicit declaration for web content fetch/WebSocket reliability
- `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_LOCATION` — required on Android 14+ if background location tracking uses a foreground service (future native integration)

### FR-5: App identity
- Package name: `ch.rhosys.rail`
- User-visible name: "Rail & Seek"
- Theme color: `#1b2440` (ink — dark navy, from `<meta name="theme-color">` and CSS `--color-ink`)
- Background color: `#f6f2e7` (paper — warm cream, from CSS `--color-paper`)
- Status bar color: `#1b2440` (ink)
- Navigation bar color: `#f6f2e7` (paper, seamless with site body)
- Splash screen: paper background with train icon in ink color
- Icon: train-front SVG (lucide) on paper background — matches the site header icon

### FR-6: Signing and deployment
- Upload keystore generated via `generate-android-keystore` tool (alias: `rail`), encrypted with the rhosys-apps KMS key (`alias/deployment-encryption-key`). The tool auto-resolves the AWS account from the repo's git remote origin.
- GitHub Actions builds a signed AAB and deploys to Google Play Internal Testing via the shared GCP Play Store service account
- GCP WIF binding added in `_rhosys-apps-infra/gcp/main.tf` for the GitHub repository path
- `AWS_ACCOUNT_ID` is a GitHub repository secret — never hardcoded

### FR-7: Website artifacts
The spec produces ready-to-copy `assetlinks.json` and `manifest.webmanifest` files. The SHA-256 fingerprint placeholder is filled after keystore generation. These are manually deployed to the website.

## Non-functional Requirements

### NFR-1: Minimum SDK
`minSdk = 33` (Android 13). Ensures `POST_NOTIFICATIONS` runtime permission works natively without version checks. TWAs require Chrome 72+ which is standard on all Android 13+ devices.

### NFR-2: No business logic
The app contains no networking code, no database, no state management, no custom UI beyond the TWA launcher activity and a splash screen. All functionality lives in the website.

### NFR-3: AWS account
Uses the rhosys-apps account (same as `_rhosys-apps-infra`). No new AWS account needed. The account ID is resolved automatically by the SSO auth tool from the git remote origin, and injected by GitHub Actions as a repository secret.

## Out of Scope

- PostHog analytics (not needed for a TWA shell)
- Wear OS companion
- Any native UI screens
- Backend API integration
- Offline functionality (handled by the PWA's service worker)
- GitLab CI (this project is GitHub-only)
