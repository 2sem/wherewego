# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Build & Development Commands

This project uses **Tuist** (v4.38.2, managed via `mise`) as the project generator, with SPM for dependencies.

```bash
# Install tool versions (tuist via mise)
mise install

# Resolve & fetch SPM dependencies
tuist install

# Generate Xcode project and build
tuist build

# Run tests
tuist test

# Open in Xcode (after install)
tuist generate
```

`mise` reads `.mise.toml` at the repo root for tool versions. All `tuist` commands must be prefixed with `mise x --` to use the correct version.

---

## Project Structure

The workspace (`Workspace.swift`) composes three Tuist projects under `Projects/`:

| Project | Product | Role |
|---|---|---|
| **App** | `.app` | Main application target. SwiftUI screens, ViewModels, Views, data layer, extensions. |
| **ThirdParty** | `.staticFramework` | Bundles static SPM deps: GoogleMaps, KakaoSDK, MBProgressHUD, LSExtensions, StringLogger, DownPicker. |
| **DynamicThirdParty** | `.framework` (dynamic) | Bundles dynamic SPM deps: Firebase (Crashlytics, Analytics, Messaging, RemoteConfig), SDWebImage. |

App depends on both ThirdParty and DynamicThirdParty as framework dependencies, plus GADManager (Google Ads wrapper) as a direct SPM package.

Each project has its own `Project.swift` — package declarations live there, not in a shared Package.swift. The workspace-level `Tuist/Package.swift` only sets global SPM product-type overrides.

---

## App: Usage & Features

WhereWeGo is a Korea tourism helper for travelers. It discovers nearby attractions using the user's location and the official Korea Tourism API. The app is locale-aware throughout — API endpoints, content type IDs, routing targets, and search engines all switch based on `Locale.current`.

### Main list (TourListScreen)
- On launch, requests location permission, then fetches attractions within a default 3 km radius sorted by distance.
- Results appear in a SwiftUI `List` with thumbnail image, title, and distance (`TourCellView`).
- **Pull-to-refresh** reloads the current query. **Infinite scroll** auto-fetches the next page when 2 rows from the end are reached.
- **Type filter** — segmented `Picker` with categories: Tour, Culture, Event, Course, Sports, Hotel, Shopping, Food, Travel. Korean and foreign locales use different API type IDs for the same categories.
- **Radius/location picker** — opens a `GMSMapViewRepresentable` where the user can drag the location marker and adjust a distance slider (up to 50 km). The chosen radius is persisted across sessions via `WWGDefaults.Range`.

### Detail view (TourInfoScreen)
- Shows the attraction's full image (tappable `NavigationLink` to `ImageViewerScreen`), address, and overview text.
- A `GMSMapViewRepresentable` displays both the user's current position (blue marker) and the destination (red marker), auto-fitted to show both.
- Three action buttons:
  - **Phone** — opens the system dialer with the attraction's number.
  - **Route** — Korean users are routed via Daum Map; non-Korean users via `SFSafariViewController` to Google Maps.
  - **Search** — Korean users search on Daum; non-Korean users search on Google.
- **Share** — Korean users share via Kakao Link (includes source coords + content ID as deep-link params so the recipient lands directly on the detail view). Non-Korean users get a `UIActivityViewController` share sheet with the image and a Google Maps directions link.

### Deep linking
Kakao Link URLs carry `srcLatitude`, `srcLongitude`, and `destContentId` as query parameters. When the app is opened via such a link (cold or warm start), it skips the list and navigates straight to the matching detail view. If the detail view is already visible for the same content ID, the segue is suppressed.

### Theming
The app has seasonal visual themes (`summer` = light blue palette, `xmas` = red palette, `default` = system). The active theme is set remotely via Firebase RemoteConfig at launch. SwiftUI views read colors declaratively from `LSThemeManager` static color classes — no imperative `apply()` calls.

### Ads
- **App-open ad** shown when the app returns to foreground (scene phase `.active`).
- **Interstitial ad** shown before navigating to the detail view.
- **Bottom banner** on the main screen, visible after the first launch.
- **Rewarded ad** unit is declared but not currently triggered in the user flow.
- Ad frequency is capped via timestamps stored in `WWGDefaults`. App Tracking Transparency permission is requested via `SwiftUIAdManager.requestAppTrackingIfNeed()` after `LaunchCount > 1`.

---

## App Architecture

**SwiftUI based.** Entry point: `@main WhereWeGoApp` in `App.swift`. A bare `AppDelegate` is kept solely for `@UIApplicationDelegateAdaptor`. Navigation is a single `NavigationStack` with a programmatic `path: [TourNavDestination]` — all screen transitions are append/remove on that path.

### Screen flow

```
WhereWeGoApp (App.swift)
├── SplashScreen          — Firebase + KakaoSDK + GMS init; 1 s delay; fades out
└── TourListScreen        — root list; owns LocationManager + TourListViewModel
    ├── TourInfoScreen    — detail; fetches via KGDataTourManager
    │   └── ImageViewerScreen — full-screen SDWebImage viewer
    └── RangePickerScreen — GMSMapView drag-marker + slider; writes back via @Binding
```

`TourListScreen` owns a `LocationManager` (`@Observable` CLLocationManager wrapper) and `TourListViewModel` (`@Observable`). It handles pull-to-refresh, infinite scroll (2 rows before end), type-filter picker, and deep-link consumption via `DeepLinkManager`.

### ViewModels & state

| Class | Pattern | Responsibility |
|---|---|---|
| `TourListViewModel` | `@Observable` | Tour list data, pagination, selected type, radius |
| `LocationManager` | `@Observable` | `CLLocationManager` wrapper; current location + auth status |
| `DeepLinkManager` | `@Observable` singleton | Parses Kakao URL query params; consumed once via `consume()` |
| `SwiftUIAdManager` | `ObservableObject` (`@StateObject`) | Wraps `GADManager<GADUnitName>`; interstitial, app-open, ATT |

### Data layer

All API communication goes through `KGDataTourManager` (singleton). It builds `URLRequest`s via request objects (`KGDataTourListRequest`, `KGDataTourDetailRequest`) that inherit from `KGDataTourRequest`. The request objects construct the full URL including the locale-aware service path (via `KGDataAPI.RestURL.VisitKorea`). Responses are parsed with `JSONSerialization` into `KGDataTourInfo` instances, which store fields in a raw dictionary (`fields: [String: AnyObject]`) inherited from `KGDataTourObject` and expose typed properties via computed getters/setters.

API key (`ServiceKey`) is loaded from `KGData.plist` at runtime. The plist is encrypted at rest as `KGData.plist.secret` and decrypted by `git-secret` in CI.

### Locale / i18n

The Korea Tourism API has separate service endpoints per language (KorService1, EngService1, JpnService1, etc.). `KGDataAPI.RestURL.VisitKorea()` routes based on `Locale.current` using extensions from `LSExtensions` (e.g., `.isKorean`, `.isJapanese`). `ContentType` enum has separate Korean vs foreign raw-value sets (`values` vs `values_foreign`) because the API assigns different type IDs per language.

Strings localization uses `.strings` files in `Resources/Strings/<lang>.lproj/`. Supported: ko, en, ja, zh-Hans, zh-Hant, de, es, fr, ru.

### Theming

`LSThemeManager` singleton holds the active theme (`default` / `summer` / `xmas`), fetched at launch from **Firebase RemoteConfig** via `LSRemoteConfig`. SwiftUI views read themed colors directly from its static nested classes (e.g., `LSThemeManager.NavigationBarBackgroundColors.red`, `LSThemeManager.MaterialColors.lightBlue._50`). Each screen has private theme-color helpers that switch on `LSThemeManager.shared.theme`. No imperative `apply()` calls.

### Ad management

Ads are managed through `SwiftUIAdManager` (`ObservableObject`, passed as `@EnvironmentObject`), which wraps `GADManager<GADUnitName>` (SPM package `2sem/GADManager`). Ad unit IDs are declared in `Info.plist` under `GADUnitIdentifiers` and matched by `GADUnitName` raw values (`FullAd`, `Launch`, `BottomBanner`, `RewardAd`).

- `App.swift` calls `MobileAds.shared.start` on first appear, then `prepare(interstitialUnit:)` and `prepare(openingUnit:)`.
- Scene-phase `.active` triggers the app-open ad via `show(unit: .launch)`.
- `TourListScreen` calls `show(unit: .full)` before each detail navigation.
- `BannerAdView` (`UIViewRepresentable` wrapping `GADBannerView`) is shown at the bottom of the list after the first launch.
- Ad-show timestamps and frequency capping are persisted in `WWGDefaults`.
- ATT permission is requested via `SwiftUIAdManager.requestAppTrackingIfNeed()` once `LaunchCount > 1`.

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
- New screens are SwiftUI `View` structs under `Sources/Screens/`. Add a case to `TourNavDestination` and a `.navigationDestination` branch in `TourListScreen` to wire navigation. Theme colors via private helpers that switch on `LSThemeManager.shared.theme`.
- `SwiftUIAdManager` is passed as `@EnvironmentObject` — screens that need ads consume it via `@EnvironmentObject var adManager: SwiftUIAdManager`.
- UIViewRepresentable wrappers live in `Sources/Views/` (e.g., `GMSMapViewRepresentable`, `BannerAdView`, `SDWebImageSwiftUIView`).
- Do not regenerate the Tuist project without an actual file insert/delete change.
