# WhereWeGo — Code Style & Conventions

## General
- **Semicolons** at end of all statements (match existing style)
- **Singletons**: `static let shared` or `static var shared`
- **No Codable** — manual `JSONSerialization` + `KGDataTourObject` base-class field dictionary
  - New fields: declare key in `fieldNames`, add computed property with `parseToX`/setter pattern

## State & Persistence
- `WWGDefaults` is the single place for all persisted app state

## Navigation
- Add new screens: create SwiftUI `View` struct under `Sources/Screens/`
- Add case to `TourNavDestination`
- Add `.navigationDestination` branch in `TourListScreen`

## Theming
- Theme colors via private helpers switching on `LSThemeManager.shared.theme`
- NO imperative `apply()` calls

## Ads
- `SwiftUIAdManager` passed as `@EnvironmentObject` — consume via `@EnvironmentObject var adManager: SwiftUIAdManager`

## UIViewRepresentable Wrappers
- Live in `Sources/Views/`
- **Split `.frame` calls** when combining dimensions (e.g., `.frame(height:)` then `.frame(maxWidth:)` separately)

## SwiftUI Pitfalls (see MEMORY.md for details)
1. Extract large `body` into sub-views to avoid type-check timeout
2. `CLLocationCoordinate2D` needs `@retroactive Equatable` extension for `.onChange`
3. `toolbarForegroundStyle` is macOS-only — use `.foregroundStyle` per item on iOS
4. Split `.frame` calls for UIViewRepresentable to avoid overload resolution issues
