# Rail & Seek TWA — Design

## Architecture

This is a Trusted Web Activity (TWA) wrapper. The entire app is one activity that launches Chrome Custom Tabs in verified mode, rendering `https://railandseek.rune.town/` full-screen without browser chrome.

```
Android app (ch.rhosys.rail)
  └── LauncherActivity (extends browser.customtabs.trusted.LauncherActivity)
        └── Chrome Custom Tab → https://railandseek.rune.town/
```

No ViewModels, no repositories, no Room, no Retrofit, no Hilt. The website handles all logic.

`minSdk = 33` (Android 13) — ensures `POST_NOTIFICATIONS` runtime permission works natively.

---

## Design Tokens (from site CSS)

| Token | Value | Usage |
|-------|-------|-------|
| `--color-paper` | `#f6f2e7` | Page background (cream) |
| `--color-ink` | `#1b2440` | Text, buttons, status bar (dark navy) |
| `--color-line-red` | `#e94f37` | Transit line accent |
| `--color-line-amber` | `#ffb703` | Transit line accent |
| `--color-line-green` | `#1f9e73` | Transit line accent |
| `--color-line-blue` | `#3466c0` | Transit line accent, focus ring |
| theme-color meta | `#1b2440` | Android status bar |

---

## Project Structure

```
Rail-Seek-Zurich-Mobile-App-Wrapper/
├── .github/workflows/
│   └── build.yml                        # GitHub Actions: validate + release
├── app/
│   ├── build.gradle.kts
│   ├── debug.keystore
│   ├── proguard-rules.pro
│   └── src/main/
│       ├── AndroidManifest.xml
│       ├── kotlin/ch/rhosys/rail/
│       │   └── Application.kt          # Empty Application class (future-proofing)
│       └── res/
│           ├── values/
│           │   ├── strings.xml          # App name: "Rail & Seek"
│           │   ├── colors.xml           # ink, paper from site tokens
│           │   └── themes.xml           # Splash theme using ink/paper colors
│           ├── drawable/
│           │   └── ic_launcher_foreground.xml  # Train icon (lucide train-front SVG path)
│           └── mipmap-anydpi-v26/
│           │   └── ic_launcher.xml      # Adaptive icon referencing foreground + paper background
├── build.gradle.kts                     # Root — plugin declarations only
├── settings.gradle.kts                  # rootProject.name = "RailAndSeek", include(":app")
├── gradle.properties
├── gradle/
│   ├── libs.versions.toml              # Minimal: AGP, Kotlin, browser library
│   └── wrapper/
│       └── gradle-wrapper.properties   # Gradle 8.9
├── gradlew, gradlew.bat
├── deployment/
│   ├── README.md
│   ├── android-upload-signing.json     # Generated keystore + KMS-encrypted password
│   ├── deploy-play-store.ts
│   ├── deploy-play-store.test.ts
│   └── notify-deploy.ts
├── scripts/
│   ├── setup.sh
│   └── check.sh
├── website-artifacts/                   # Ready-to-copy files for the website
│   ├── assetlinks.json                 # Goes to /.well-known/assetlinks.json
│   └── manifest.webmanifest            # Updated version for railandseek.rune.town
├── .gitignore
├── package.json
├── tsconfig.json
└── spec/                               # This spec
```

---

## AndroidManifest.xml

The manifest declares a single activity using the `androidx.browser` TWA launcher. Key elements:

```xml
<application android:name=".Application">
    <activity android:name="androidx.browser.trusted.LauncherActivity"
              android:exported="true">
        <!-- Standard launcher -->
        <intent-filter>
            <action android:name="android.intent.action.MAIN" />
            <category android:name="android.intent.category.LAUNCHER" />
        </intent-filter>

        <!-- App Links — verified domain claim -->
        <intent-filter android:autoVerify="true">
            <action android:name="android.intent.action.VIEW" />
            <category android:name="android.intent.category.DEFAULT" />
            <category android:name="android.intent.category.BROWSABLE" />
            <data android:scheme="https" android:host="railandseek.rune.town" />
        </intent-filter>

        <!-- TWA metadata -->
        <meta-data android:name="android.support.customtabs.trusted.DEFAULT_URL"
                   android:value="https://railandseek.rune.town/" />
        <meta-data android:name="android.support.customtabs.trusted.STATUS_BAR_COLOR"
                   android:resource="@color/ink" />
        <meta-data android:name="android.support.customtabs.trusted.NAVIGATION_BAR_COLOR"
                   android:resource="@color/paper" />
        <meta-data android:name="android.support.customtabs.trusted.SPLASH_IMAGE_DRAWABLE"
                   android:resource="@drawable/ic_launcher_foreground" />
        <meta-data android:name="android.support.customtabs.trusted.SPLASH_SCREEN_BACKGROUND_COLOR"
                   android:resource="@color/paper" />
    </activity>
</application>
```

Permissions declared in the manifest:
```xml
<!-- Notifications -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- Location (foreground + background) -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />

<!-- Camera (photo proof, QR scanning) -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.front" android:required="false" />

<!-- Audio (voice messages, video with audio) -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />

<!-- System -->
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
```

Camera features are declared `required="false"` so the app is installable on devices without cameras.

The TWA library delegates permission prompts to the Android system when the web content requests them via the standard Web APIs (Geolocation, MediaDevices, Notifications).

---

## Dependencies (minimal)

| Dependency | Purpose |
|-----------|---------|
| `androidx.browser:browser` | TWA LauncherActivity, Custom Tabs |
| `androidx.core:core-ktx` | Core Android extensions |

That's it. No Compose, no Room, no Retrofit, no Hilt, no serialization.

---

## Keystore Generation

The upload keystore is generated using the existing `generate-android-keystore` tool. Run from inside this repo (the tool auto-resolves the AWS account from the git remote origin):

```bash
npx tsx ~/.kiro/skills/004-secrets/scripts/generate-android-keystore.ts \
  --alias rail \
  --origin "$(git remote get-url origin)" \
  > deployment/android-upload-signing.json
```

This:
1. Generates RSA 4096-bit PKCS12 keystore (30-year validity, DN: `CN=rhosys.ch, O=Rhosys AG, OU=Mobile`)
2. Encrypts the password with KMS (`alias/deployment-encryption-key`, auto-resolved region)
3. Outputs JSON with base64 keystore + base64 KMS ciphertext of the password

After generation, extract the SHA-256 fingerprint:

```bash
# Decode the keystore from the JSON
jq -r '.keystore' deployment/android-upload-signing.json | base64 --decode > /tmp/rail.p12

# Decrypt the password (requires SSO approval)
STORE_PASSWORD=$(jq -r '.passwordCiphertext' deployment/android-upload-signing.json \
  | base64 --decode \
  | aws kms decrypt --ciphertext-blob fileb:///dev/stdin --region eu-west-1 \
    --output text --query Plaintext \
  | base64 --decode)

# Get the fingerprint
keytool -list -v -keystore /tmp/rail.p12 -alias rail -storepass "$STORE_PASSWORD" \
  | grep SHA256

# Clean up
rm /tmp/rail.p12
```

The SHA-256 fingerprint goes into `website-artifacts/assetlinks.json`.

**Note:** After the first Play Store upload, Google re-signs with their own key. The Play App Signing SHA-256 fingerprint (from Play Console > Setup > App signing) must ALSO be added to `assetlinks.json` for verification to work on production installs.

---

## Website Artifacts

### `website-artifacts/assetlinks.json`

Goes to `https://railandseek.rune.town/.well-known/assetlinks.json`:

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "ch.rhosys.rail",
    "sha256_cert_fingerprints": [
      "__UPLOAD_KEY_SHA256__",
      "__PLAY_APP_SIGNING_SHA256__"
    ]
  }
}]
```

Both fingerprints are needed:
- Upload key fingerprint — for debug/sideloaded installs signed with the upload key
- Play App Signing fingerprint — for production installs from the Play Store (Google re-signs)

### `website-artifacts/manifest.webmanifest`

The site already has `/manifest.webmanifest` (referenced in `<link rel="manifest">`). It needs to contain proper TWA-compatible fields. The generated file:

```json
{
  "name": "Rail & Seek",
  "short_name": "Rail & Seek",
  "description": "Hide and seek, played on public transport.",
  "start_url": "/",
  "display": "standalone",
  "orientation": "portrait",
  "theme_color": "#1b2440",
  "background_color": "#f6f2e7",
  "icons": [
    { "src": "/icons/icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "/icons/icon-512.png", "sizes": "512x512", "type": "image/png" },
    { "src": "/icons/icon-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
  ]
}
```

---

## CI — GitHub Actions

Follows the same pattern as the email-catcher Android app (`email-android-mobile-app/.github/workflows/build.yml`).

### Validate job (every push + PR)
- Compile debug Kotlin
- Lint debug
- Run unit tests

### Release job (push to main only)
1. Compute version from `github.run_number`
2. `aws-actions/configure-aws-credentials@v4` — assumes `GitHubActionsRole` using `secrets.AWS_ACCOUNT_ID`
3. Decode keystore from `deployment/android-upload-signing.json`
4. Decrypt signing password via `aws kms decrypt`
5. `gradle bundleRelease` with signing properties, alias `rail`
6. Get OIDC token for GCP, write WIF credential config
7. `npm run deploy:play-store`
8. `npm run deploy:notify`
9. Upload AAB as artifact

### Required GitHub repository secrets
- `AWS_ACCOUNT_ID` — the rhosys-apps account ID (for OIDC role assumption)
- `DISCORD_RHOSYS_CI_CD_CHANNEL_WEBHOOK` — Discord webhook URL for deploy notifications

### Required GitHub repository settings
- **Actions permissions**: "Allow all actions and reusable workflows"
- **OIDC**: `id-token: write` permission (set in workflow, no manual config needed)

---

## Manual Setup Checklist

These steps must be performed manually before the first automated deploy:

- [ ] **GitHub secret**: `AWS_ACCOUNT_ID` — set on the `Rhosys/Rail-Seek-Zurich-Mobile-App-Wrapper` repository
- [ ] **GitHub secret**: `DISCORD_RHOSYS_CI_CD_CHANNEL_WEBHOOK` — set on the repository (or skip if notifications not needed)
- [ ] **AWS IAM**: Verify `GitHubActionsRole` in the rhosys-apps account trusts `Rhosys/Rail-Seek-Zurich-Mobile-App-Wrapper` (check the role's trust policy OIDC conditions)
- [ ] **GCP WIF**: Add `play_store_wif_rail_seek` binding in `_rhosys-apps-infra/gcp/main.tf` (spec task #28), then `tofu apply`
- [ ] **Play Console**: Create app listing for `ch.rhosys.rail` manually
- [ ] **Play Console**: Upload first AAB manually via Internal Testing (API can't create a new app)
- [ ] **Play Console → Users and permissions**: Add `ch.rhosys.rail` to the `gitlab-play-store@rhosys-apps.iam.gserviceaccount.com` service account's app list

---

## Infrastructure Changes

### `_rhosys-apps-infra/gcp/main.tf`

Add WIF binding for Play Store deployment from GitHub:

```hcl
# The pool is named "gitlab-oidc" historically but has both GitLab and GitHub providers.
resource "google_service_account_iam_member" "play_store_wif_rail_seek_github" {
  service_account_id = google_service_account.play_store.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.gitlab.name}/attribute.repository/Rhosys/Rail-Seek-Zurich-Mobile-App-Wrapper"
}
```

---

## Future: Native Background Location Integration

The manifest declares `ACCESS_BACKGROUND_LOCATION`, `FOREGROUND_SERVICE`, and `FOREGROUND_SERVICE_LOCATION`. These are **inactive in the initial TWA** — Chrome handles foreground geolocation via `navigator.geolocation.watchPosition()` without a foreground service, but stops tracking when the app is backgrounded or the screen is off.

For persistent location tracking during games (e.g. player on a train with screen off), a native foreground service will need to be added later. This is a separate scope that changes the app from a pure TWA to a hybrid:

- Native `LocationTrackingService` (foreground service with ongoing notification)
- Communication bridge between the service and the web content (postMessage or local WebSocket)
- The permissions are pre-declared so this upgrade doesn't require a new permission prompt from existing users

This integration should be designed separately after the base TWA is shipping.

---

## Launcher Icon

The adaptive icon uses the lucide `train-front` SVG paths (same icon as the site header) rendered in ink color (`#1b2440`) on a paper background (`#f6f2e7`).

`ic_launcher_foreground.xml` contains the train SVG paths scaled to the 108dp adaptive icon canvas. The background layer is a solid `@color/paper` fill.
