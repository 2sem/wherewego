# WhereWeGo — Project Overview

## Purpose
Korea tourism helper app for travelers. Discovers nearby attractions using user location + Korea Tourism API. Locale-aware (ko/en/ja/zh-Hans/zh-Hant/de/es/fr/ru).

## Tech Stack
- **Language**: Swift (SwiftUI)
- **Project generator**: Tuist v4.207.0 (via `mise`)
- **Dependencies**: SPM
- **Key SDKs**: Google Maps, KakaoSDK, Firebase (Crashlytics/Analytics/Messaging/RemoteConfig), Google Ads (GADManager)

## Project Structure
```
Projects/
  App/               # Main app target (.app)
    Sources/
      Screens/       # SwiftUI screens
      ViewModels/    # @Observable ViewModels
      Views/         # UIViewRepresentable wrappers
      Managers/      # Singleton managers
      Datas/         # Data layer (KGDataTourManager, KGDataTourObject, etc.)
      Extensions/    # Swift extensions
      Resources/     # Strings, assets, plists
    Tests/
Tuist/Package.swift  # Firebase + Kakao SDK + LSExtensions + StringLogger + GADManager (Tuist-integrated), linked by App via .external
```

## Screen Flow
```
WhereWeGoApp (App.swift)
├── SplashScreen
└── TourListScreen (root)
    ├── TourInfoScreen
    │   └── ImageViewerScreen
    └── RangePickerScreen
```

## Architecture
- Single `NavigationStack` with `path: [TourNavDestination]`
- `@Observable` for ViewModels (TourListViewModel, LocationManager, DeepLinkManager)
- `SwiftUIAdManager` as `@EnvironmentObject` (ObservableObject)
- `LSThemeManager` singleton for themes (default/summer/xmas) via Firebase RemoteConfig

## Encrypted Secrets
- `GoogleService-Info.plist`, `kakao.plist`, `KGData.plist` (API key)
- `.secret` variants committed; decrypted files in `.gitignore`
