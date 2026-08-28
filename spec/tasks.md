# Rail & Seek TWA — Tasks

## Scaffold

- [ ] 1. Create root Gradle files: `build.gradle.kts`, `settings.gradle.kts`, `gradle.properties`
- [ ] 2. Create `gradle/libs.versions.toml` (minimal: AGP, Kotlin, androidx.browser, core-ktx)
- [ ] 3. Copy Gradle wrapper from sbb-ruby-slippers (gradlew, gradlew.bat, gradle/wrapper/)
- [ ] 4. Create `app/build.gradle.kts` (namespace `ch.rhosys.rail`, minSdk 33, TWA dependencies only)
- [ ] 5. Create `app/debug.keystore` (standard shared debug keystore)

## Android App

- [ ] 6. Create `app/src/main/res/values/colors.xml` with ink (`#1b2440`) and paper (`#f6f2e7`) from site tokens
- [ ] 7. Create `app/src/main/res/values/strings.xml` with app name "Rail & Seek"
- [ ] 8. Create `app/src/main/res/values/themes.xml` with splash theme using ink/paper colors
- [ ] 9. Create `app/src/main/res/drawable/ic_launcher_foreground.xml` with lucide train-front SVG paths
- [ ] 10. Create `app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` adaptive icon
- [ ] 11. Create `app/src/main/AndroidManifest.xml` with TWA LauncherActivity, App Links intent filter for `railandseek.rune.town`, all permissions (notifications, location + background, camera, audio, vibrate, wake lock, network, foreground service), TWA metadata (DEFAULT_URL, status bar color, nav bar color, splash), camera features as optional
- [ ] 12. Create `app/src/main/kotlin/ch/rhosys/rail/Application.kt` (empty Application subclass)
- [ ] 13. Create `app/proguard-rules.pro` (minimal, keep TWA classes)

## Deployment Scripts

- [ ] 14. Create `deployment/deploy-play-store.ts` (adapted from email-android-mobile-app, PACKAGE_NAME = `ch.rhosys.rail`)
- [ ] 15. Create `deployment/deploy-play-store.test.ts` (adapted tests, changed package name)
- [ ] 16. Create `deployment/notify-deploy.ts` (adapted, imports from deploy-play-store)
- [ ] 17. Create `deployment/README.md` (keystore generation instructions, alias = `rail`)

## Project Config

- [ ] 18. Create `package.json` with deploy scripts, jest, tsx, husky
- [ ] 19. Create `tsconfig.json` scoped to `deployment/**/*.ts`
- [ ] 20. Create `.gitignore` (same pattern as sbb-ruby-slippers)
- [ ] 21. Create `scripts/setup.sh` (Java 17, Android SDK, marker = `rail-seek`)
- [ ] 22. Create `scripts/check.sh` (`./gradlew compileDebugKotlin lintDebug`)

## CI

- [ ] 23. Create `.github/workflows/build.yml` (GitHub Actions: validate + release, same pattern as email-android-mobile-app, key alias `rail`)

## Website Artifacts

- [ ] 24. Create `website-artifacts/assetlinks.json` with placeholder SHA-256 fingerprints
- [ ] 25. Create `website-artifacts/manifest.webmanifest` with correct TWA fields, site colors, icon references

## Signing

- [ ] 26. Generate upload keystore: run `generate-android-keystore --alias rail --origin <remote>` from repo dir → `deployment/android-upload-signing.json`
- [ ] 27. Extract SHA-256 fingerprint from generated keystore, update `website-artifacts/assetlinks.json`

## Infrastructure

- [ ] 28. Add GCP WIF binding `play_store_wif_rail_seek_github` in `_rhosys-apps-infra/gcp/main.tf` for `Rhosys/Rail-Seek-Zurich-Mobile-App-Wrapper`

## Manual Setup (not automated — requires human action)

- [ ] 29. Set GitHub secret `AWS_ACCOUNT_ID` on `Rhosys/Rail-Seek-Zurich-Mobile-App-Wrapper`
- [ ] 30. Set GitHub secret `DISCORD_RHOSYS_CI_CD_CHANNEL_WEBHOOK` on the repo (or skip)
- [ ] 31. Verify AWS `GitHubActionsRole` trust policy allows this repo's OIDC tokens
- [ ] 32. Create app listing for `ch.rhosys.rail` in Google Play Console
- [ ] 33. Upload first AAB manually via Play Console Internal Testing
- [ ] 34. Add `ch.rhosys.rail` to the Play Store service account's app list (Play Console → Users and permissions)
