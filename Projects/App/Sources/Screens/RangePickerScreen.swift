import SwiftUI
import CoreLocation
import GoogleMaps

struct RangePickerScreen: View {
    @Binding var location: CLLocationCoordinate2D
    @Binding var radius: Int
    @Environment(\.dismiss) private var dismiss;

    // Local state for live map updates
    @State private var localLocation: CLLocationCoordinate2D
    @State private var localRadiusKm: Int  // slider value in km

    private let minKm = 1
    private let maxKm = 20

    init(location: Binding<CLLocationCoordinate2D>, radius: Binding<Int>) {
        self._location = location;
        self._radius = radius;
        self._localLocation = State(initialValue: location.wrappedValue);
        self._localRadiusKm = State(initialValue: max(1, min(20, radius.wrappedValue / 1000)));
    }

    private var localRadiusMeters: Int { localRadiusKm * 1000; }

    private var sliderValue: Binding<Double> {
        Binding(
            get: { Double(localRadiusKm) },
            set: { localRadiusKm = Int($0.rounded()) }
        )
    }

    private var circleBounds: GMSCoordinateBounds {
        let circle = GMSCircle(position: localLocation, radius: CLLocationDistance(localRadiusMeters));
        return circle.bounds;
    }

    var body: some View {
        VStack(spacing: 0) {
            // Map fills available space
            GMSMapViewRepresentable(
                initialCamera: GMSCameraPosition.camera(withLatitude: localLocation.latitude, longitude: localLocation.longitude, zoom: 10),
                markers: [
                    MapMarkerConfig(position: localLocation, title: "Here", color: .blue, isDraggable: true)
                ],
                circle: MapCircleConfig(position: localLocation, radius: CLLocationDistance(localRadiusMeters), fillColor: UIColor.blue.withAlphaComponent(0.3)),
                fitBounds: circleBounds,
                isMyLocationEnabled: true,
                myLocationButtonEnabled: true,
                onMarkerDragEnd: { newPos in
                    localLocation = newPos;
                }
            )
            .ignoresSafeArea(edges: .horizontal)

            // Bottom controls
            VStack(spacing: 8) {
                Divider()

                HStack(alignment: .center, spacing: 12) {
                    // Minus
                    Button {
                        localRadiusKm = max(minKm, localRadiusKm - 1);
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(themeButtonColor())
                    }
                    .disabled(localRadiusKm <= minKm)

                    // Slider
                    Slider(value: sliderValue, in: Double(minKm)...Double(maxKm), step: 1.0)
                        .tint(themeSliderColor())

                    // Plus
                    Button {
                        localRadiusKm = min(maxKm, localRadiusKm + 1);
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(themeButtonColor())
                    }
                    .disabled(localRadiusKm >= maxKm)
                }
                .padding(.horizontal)

                // Distance label
                Text(localRadiusMeters.stringForDistance())
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(themeLabelColor())
                    .padding(.bottom, 8)
            }
            .background(themeBackground())
        }
        .navigationTitle("Search Range".localized())
        .navigationBarBackButtonHidden()
        .toolbarBackground(themeNavBarColor(), for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.backward")
                        .foregroundStyle(themeBarTintColor())
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done".localized()) {
                    location = localLocation;
                    radius = localRadiusMeters;
                    dismiss();
                }
                .foregroundStyle(themeBarTintColor())
            }
        }
    }

    // MARK: - Theme

    private func themeNavBarColor() -> Color {
        switch LSThemeManager.shared.theme {
        case .xmas:  return Color(uiColor: LSThemeManager.NavigationBarBackgroundColors.red ?? .systemBackground);
        case .summer: return Color(uiColor: LSThemeManager.NavigationBarBackgroundColors.lightBlue ?? .systemBackground);
        default:     return .init(UIColor.systemBackground);
        }
    }
    private func themeBarTintColor() -> Color {
        switch LSThemeManager.shared.theme {
        case .xmas, .summer: return .white;
        default:             return .init(UIColor.label);
        }
    }
    private func themeBackground() -> Color {
        switch LSThemeManager.shared.theme {
        case .xmas:  return Color(uiColor: LSThemeManager.BackgroundColors.red ?? .systemBackground);
        case .summer: return Color(uiColor: LSThemeManager.BackgroundColors.lightBlue ?? .systemBackground);
        default:     return .init(UIColor.systemBackground);
        }
    }
    private func themeLabelColor() -> Color {
        switch LSThemeManager.shared.theme {
        case .xmas, .summer: return .white;
        default:             return .init(UIColor.label);
        }
    }
    private func themeButtonColor() -> Color {
        switch LSThemeManager.shared.theme {
        case .xmas:  return Color(uiColor: LSThemeManager.MaterialColors.red.red400 ?? .systemBlue);
        case .summer: return Color(uiColor: LSThemeManager.MaterialColors.lightBlue._400 ?? .systemBlue);
        default:     return .accentColor;
        }
    }
    private func themeSliderColor() -> Color {
        switch LSThemeManager.shared.theme {
        case .xmas:  return Color(uiColor: LSThemeManager.MaterialColors.red.red100 ?? .systemBlue);
        case .summer: return Color(uiColor: LSThemeManager.MaterialColors.lightBlue._100 ?? .systemBlue);
        default:     return .accentColor;
        }
    }
}
