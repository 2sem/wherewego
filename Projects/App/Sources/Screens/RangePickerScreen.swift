import SwiftUI
import CoreLocation
import MapKit

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

    var body: some View {
        VStack(spacing: 0) {
            // Map fills available space
            MapReader { proxy in
                Map(initialPosition: .region(regionForCircle(center: localLocation, radiusKm: localRadiusKm))) {
                    UserAnnotation()
                    Annotation("Here", coordinate: localLocation, anchor: .center) {
                        draggablePin(proxy: proxy)
                    }
                    MapPolygon(coordinates: circleCoordinates(center: localLocation, radius: Double(localRadiusMeters)))
                        .foregroundStyle(Color.blue.opacity(0.25))
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                }
            }
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

    // MARK: - Map helpers

    private func draggablePin(proxy: MapProxy) -> some View {
        Image(systemName: "mappin.circle.fill")
            .font(.system(size: 30))
            .foregroundStyle(.white, .blue)
            .shadow(color: .black.opacity(0.3), radius: 3)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { value in
                        if let newCoord = proxy.convert(value.location, from: .global) {
                            localLocation = newCoord;
                        }
                    }
            )
    }

    /// Generates coordinates around a circle on the map (64-segment polygon approximation).
    private func circleCoordinates(center: CLLocationCoordinate2D, radius: Double, segments: Int = 64) -> [CLLocationCoordinate2D] {
        let latRadius = radius / 111_320;
        let lonRadius = radius / (111_320 * cos(center.latitude * .pi / 180));
        return (0..<segments).map { i in
            let angle = Double(i) / Double(segments) * 2 * .pi;
            return CLLocationCoordinate2D(
                latitude:  center.latitude  + latRadius * sin(angle),
                longitude: center.longitude + lonRadius * cos(angle)
            );
        };
    }

    /// Computes an MKCoordinateRegion that fits a circle of the given radius around center.
    private func regionForCircle(center: CLLocationCoordinate2D, radiusKm: Int) -> MKCoordinateRegion {
        let meters   = Double(radiusKm * 1000);
        let latDelta = meters / 111_320 * 2.2;
        let lonDelta = meters / (111_320 * cos(center.latitude * .pi / 180)) * 2.2;
        return MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta));
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
