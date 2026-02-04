# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Build & Development Commands

This project uses **Tuist** (v4.38.2, managed via `mise`) as the project generator, with SPM for dependencies.

```bash
# Install tool versions (tuist via mise)
mise install

# Resolve & fetch SPM dependencies
mise x -- tuist install

# Generate Xcode project and build
mise x -- tuist build

# Run tests
mise x -- tuist test

# Open in Xcode (after install)
mise x -- tuist generate
```

`mise` reads `.mise.toml` at the repo root for tool versions. All `tuist` commands must be prefixed with `mise x --` to use the correct version.

---

## Project Structure

The workspace (`Workspace.swift`) composes three Tuist projects under `Projects/`:

| Project | Product | Role |
|---|---|---|
| **App** | `.app` | Main application target. All feature code, VCs, data layer, extensions. |
| **ThirdParty** | `.staticFramework` | Bundles static SPM deps: GoogleMaps, KakaoSDK, MBProgressHUD, LSExtensions, StringLogger, DownPicker. |
| **DynamicThirdParty** | `.framework` (dynamic) | Bundles dynamic SPM deps: Firebase (Crashlytics, Analytics, Messaging, RemoteConfig), SDWebImage. |

App depends on both ThirdParty and DynamicThirdParty as framework dependencies, plus GADManager (Google Ads wrapper) as a direct SPM package.

Each project has its own `Project.swift` — package declarations live there, not in a shared Package.swift. The workspace-level `Tuist/Package.swift` only sets global SPM product-type overrides.

---

## App: Usage & Features

WhereWeGo is a Korea tourism helper for travelers. It discovers nearby attractions using the user's location and the official Korea Tourism API. The app is locale-aware throughout — API endpoints, content type IDs, routing targets, and search engines all switch based on `Locale.current`.

### Main list (KGDTableViewController)
- On launch, requests location permission, then fetches attractions within a default 3 km radius sorted by distance.
- Results appear in a scrollable table with thumbnail image, title, and distance.
- **Pull-to-refresh** reloads the current query. **Infinite scroll** auto-fetches the next page when 2 rows from the end are reached.
- **Type filter** (top toolbar) — dropdown picker with categories: Tour, Culture, Event, Course, Sports, Hotel, Shopping, Food, Travel. Korean and foreign locales use different API type IDs for the same categories.
- **Radius/location picker** — opens a GMSMapView where the user can drag the location marker and adjust a distance slider (up to 50 km). The chosen radius is persisted across sessions via `WWGDefaults.Range`.

### Detail view (KGDTourInfoViewController)
- Shows the attraction's full image (tappable to open full-screen viewer), address, and overview text.
- A GMSMapView displays both the user's current position (blue marker) and the destination (red marker), auto-fitted to show both.
- Three action buttons:
  - **Phone** — opens the system dialer with the attraction's number.
  - **Route** — Korean users are routed via Daum Map; non-Korean users via Google Maps (app or web fallback).
  - **Search** — Korean users search on Daum; non-Korean users search on Google.
- **Share** — Korean users share via Kakao Link (includes source coords + content ID as deep-link params so the recipient lands directly on the detail view). Non-Korean users get the standard share sheet with the image and a Google Maps directions link.

### Deep linking
Kakao Link URLs carry `srcLatitude`, `srcLongitude`, and `destContentId` as query parameters. When the app is opened via such a link (cold or warm start), it skips the list and navigates straight to the matching detail view. If the detail view is already visible for the same content ID, the segue is suppressed.

### Theming
The app has seasonal visual themes (`summer` = light blue palette, `xmas` = red palette, `default` = system). The active theme is set remotely via Firebase RemoteConfig at launch and applied imperatively to every UIKit outlet in each VC's `viewWillAppear`.

### Ads
- **App-open ad** shown when the app returns to foreground.
- **Interstitial ad** shown after dismissing the detail view.
- **Bottom banner** on the main screen, hidden while an interstitial or rewarded ad is active.
- **Rewarded ad** is wired but not currently triggered in the user flow.
- Ad frequency is capped via timestamps stored in `WWGDefaults`. App Tracking Transparency permission is requested only after the user has seen 3 ads.

---

## App Architecture

**UIKit + Storyboard based.** The `wherewego/` directory at the root contains a minimal SwiftUI scaffold that is not the active app target — the real app lives entirely under `Projects/App/Sources/`.

Entry point: `AppDelegate.swift` (`@UIApplicationMain`). Navigation is Storyboard-driven (`Main.storyboard`), no programmatic nav stack or SwiftUI navigation.

### ViewController flow

```
MainViewController          — root; owns the bottom banner ad + delegates to table
└── KGDTableViewController  — UITableViewController; location-based list of attractions
    ├── KGDTourInfoViewController  — detail view; GMSMapView + tour info
    │   └── KGDImageViewController — full-screen image viewer
    └── KGDRangePickerViewController — GMSMapView-based radius/location picker
```

`KGDTableViewController` is the workhorse: it owns `CLLocationManager`, fetches the tour list from the Korea Tourism API, handles pull-to-refresh and infinite scroll (triggers next-page fetch 2 rows before the end), and segues to detail/picker.

### Data layer

All API communication goes through `KGDataTourManager` (singleton). It builds `URLRequest`s via request objects (`KGDataTourListRequest`, `KGDataTourDetailRequest`) that inherit from `KGDataTourRequest`. The request objects construct the full URL including the locale-aware service path (via `KGDataAPI.RestURL.VisitKorea`). Responses are parsed with `JSONSerialization` into `KGDataTourInfo` instances, which store fields in a raw dictionary (`fields: [String: AnyObject]`) inherited from `KGDataTourObject` and expose typed properties via computed getters/setters.

API key (`ServiceKey`) is loaded from `KGData.plist` at runtime. The plist is encrypted at rest as `KGData.plist.secret` and decrypted by `git-secret` in CI.

### Locale / i18n

The Korea Tourism API has separate service endpoints per language (KorService1, EngService1, JpnService1, etc.). `KGDataAPI.RestURL.VisitKorea()` routes based on `Locale.current` using extensions from `LSExtensions` (e.g., `.isKorean`, `.isJapanese`). `ContentType` enum has separate Korean vs foreign raw-value sets (`values` vs `values_foreign`) because the API assigns different type IDs per language.

Strings localization uses `.strings` files in `Resources/Strings/<lang>.lproj/`. Supported: ko, en, ja, zh-Hans, zh-Hant, de, es, fr, ru.

### Theming

`LSThemeManager` is a singleton that applies a Material Design color palette to every UIKit element imperatively in `viewWillAppear`. The active theme (`default` / `summer` / `xmas`) is fetched at launch from **Firebase RemoteConfig** via `LSRemoteConfig`. Each VC calls `LSThemeManager.shared.apply(...)` on its outlets individually — there is no automatic theming mechanism.

### Ad management

Ads are managed through `GADManager` (SPM package `2sem/GADManager`). Ad unit IDs are declared in `Info.plist` under `GADUnitIdentifiers`. `AppDelegate` wires up interstitial and app-open ads; `MainViewController` manages the bottom banner. Ad-show timestamps and frequency capping are persisted in `WWGDefaults` (a static wrapper around `UserDefaults`).

App Tracking Transparency is gated: ATT permission is requested only after the user has been shown 3 ads (`WWGDefaults.requestAppTrackingIfNeed()`).

### Secrets & encrypted plists

Sensitive plists are encrypted with `git-secret`:
- `GoogleService-Info.plist` (Firebase)
- `kakao.plist` (Kakao SDK)
- `KGData.plist` (Korea Tourism API key)

The `.secret` variants are committed; the decrypted files are in `.gitignore`. CI decrypts them via GPG before build.

---

## CI / CD

GitHub Actions workflow: `.github/workflows/deploy-ios.yml` (manual trigger via `workflow_dispatch`).

Pipeline: checkout → decrypt secrets (git-secret + GPG) → mise install → tuist install → tuist build → import signing cert + profile → fastlane upload.

Fastlane (`fastlane/Fastfile`) handles build numbering (queries latest TestFlight build) and upload — either to TestFlight or App Store Review depending on the `isReleasing` input.

Runner: `macos-15`, Xcode 16.2.

---

## Key conventions to follow

- Semicolons are used at end of statements throughout the existing codebase — match this style.
- Singletons use `static let shared` or `static var shared` pattern consistently.
- No Codable/Decodable — the data layer uses manual `JSONSerialization` + the `KGDataTourObject` base-class field dictionary. Add new fields the same way: declare the key in `fieldNames`, add a computed property with `parseToX` / setter pattern.
- `WWGDefaults` is the single place for persisted app state. Add new keys there.
- When adding a new VC, wire it via Storyboard segue and call `LSThemeManager.shared.apply(...)` on all themed outlets in `viewWillAppear`.
- Do not regenerate the Tuist project without an actual file insert/delete change.
