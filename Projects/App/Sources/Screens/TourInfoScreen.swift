import SwiftUI
import CoreLocation
import MapKit
import SDWebImage
import KakaoSDKShare
import SafariServices

struct TourInfoScreen: View {
    // Initialised from list row tap
    var info: KGDataTourInfo? = nil
    // Initialised from deep link (ID only)
    var infoId: Int = 0
    var currentLocation: CLLocationCoordinate2D?

    @Environment(\.dismiss) private var dismiss;
    @State private var detailInfo: KGDataTourInfo? = nil;
    @State private var loadedImage: UIImage? = nil;
    @State private var showShareSheet = false;
    @State private var shareItems: [Any] = [];
    @State private var routeCoordinates: [CLLocationCoordinate2D] = [];
    @State private var mapCameraPosition: MapCameraPosition = .automatic;

    private var resolvedInfo: KGDataTourInfo? { detailInfo ?? info; }
    private var resolvedId: Int { info?.id ?? infoId; }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Row 0: action buttons
                HStack(spacing: 12) {
                    roundButton(title: "", icon: "phone.fill") { onPhone(); }
                    roundButton(title: "", icon: "map.fill") { onRoute(); }
                    roundButton(title: "", icon: "magnifyingglass") { onSearch(); }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)

                // Row 1: image + address
                if let imgUrl = resolvedInfo?.image {
                    NavigationLink(value: TourNavDestination.imageViewer(imgUrl)) {
                        SDWebImageSwiftUIView(url: imgUrl, placeholder: WWGImages.noImage)
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        SDWebImageManager.shared.loadImage(with: imgUrl, options: .scaleDownLargeImages, progress: nil) { image, _, _, _, _, _ in
                            loadedImage = image;
                        };
                    }
                }

                // Address
                HStack(spacing: 8) {
                    Image("icon_tour_api_")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(themeAccent())
                        .frame(width: 20, height: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Address".localized())
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(themeLabelColor())
                        Text("\(resolvedInfo?.primaryAddr ?? "") \(resolvedInfo?.detailAddr ?? "")")
                            .font(.system(size: 14))
                            .foregroundStyle(themeLabelColor())
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Row 2: map
                if let dest = resolvedInfo?.location, let src = currentLocation {
                    let _ = print("[Route] Map content eval — routeCoordinates.count: \(routeCoordinates.count)");
                    Map(position: $mapCameraPosition) {
                        Marker("Here", coordinate: src)
                            .foregroundStyle(.blue)
                        Marker(resolvedInfo?.title ?? "", coordinate: dest)
                            .foregroundStyle(.red)
                        if !routeCoordinates.isEmpty {
                            let _ = print("[Route] MapPolyline rendered, count: \(routeCoordinates.count)");
                            MapPolyline(coordinates: routeCoordinates)
                                .stroke(Color("PathColor"), lineWidth: 5)
                        }
                    }
                    .frame(height: 450)
                    .mapControls {
                        MapCompass()
                    }
                    .onChange(of: resolvedInfo?.location) { _, _ in
                        mapCameraPosition = .region(regionFitting(src, dest));
                    }
                    .task {
                        mapCameraPosition = .region(regionFitting(src, dest));
                        await fetchRoute(from: src, to: dest);
                    }
                }

                // Row 3: overview
                if let overview = resolvedInfo?.overview, !overview.isEmpty {
                    Divider()
                    HStack(spacing: 8) {
                        Image("icon_overview")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundStyle(themeAccent())
                            .frame(width: 20, height: 20)
                        Text("Overview".localized())
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(themeLabelColor())
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    Text(overview)
                        .font(.system(size: 14))
                        .foregroundStyle(themeLabelColor())
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                }
            }
        }
        .background(themeBackground())
        .navigationTitle(resolvedInfo?.title ?? "")
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
                Button { onShare(); } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(themeBarTintColor())
                }
            }
        }
        // Full-screen image navigation — handled by parent NavigationStack
        // Share sheet
        .sheet(isPresented: $showShareSheet) {
            ShareSheetView(items: shareItems)
        }
        // Fetch detail on appear
        .task {
            fetchDetail();
        }
    }

    // MARK: - Data

    private func fetchDetail() {
        let needDefault = (info == nil);
        KGDataTourManager.shared.requestDetail(contentId: resolvedId, needDefault: needDefault) { detail, error in
            DispatchQueue.main.async {
                if self.info == nil {
                    self.detailInfo = detail;
                } else {
                    // Merge overview into existing info
                    self.info?.overview = detail?.overview;
                    self.detailInfo = self.info;
                }
            }
        };
    }

    // MARK: - Actions

    private func onPhone() {
        guard let tel = resolvedInfo?.tel, !tel.isEmpty else { return };
        UIApplication.shared.openTel(tel);
    }

    private func onRoute() {
        guard let dest = resolvedInfo?.location else { return };
        let src = currentLocation ?? dest;
        let url = src.urlForGoogleRoute(startName: "Current Location".localized(), end: dest, endName: resolvedInfo?.title ?? "Destination".localized());
        let safari = SFSafariViewControllerPresenter();
        safari.present(url: url);
    }

    private func onSearch() {
        if Locale.current.isKorean {
            UIApplication.shared.searchByDaum(resolvedInfo?.title ?? "");
        } else {
            UIApplication.shared.searchByGoogle(resolvedInfo?.title ?? "");
        }
    }

    private func onShare() {
        guard let info = resolvedInfo else { return };
        if Locale.current.isKorean {
            info.shareByKakao(currentLocation ?? info.location!);
        } else {
            var items: [Any] = [];
            if let img = loadedImage { items.append(img); }
            items.append("[\(info.title ?? "")] \(info.tel ?? "")");
            if let loc = currentLocation, let dest = info.location {
                items.append(loc.urlForGoogleRoute(startName: "Current Location".localized(), end: dest, endName: info.title ?? "Destination".localized()));
            }
            shareItems = items;
            showShareSheet = true;
        }
    }

    // MARK: - Map helpers

    private func fetchRoute(from src: CLLocationCoordinate2D, to dest: CLLocationCoordinate2D) async {
        print("[Route] fetchRoute called: src=(\(src.latitude),\(src.longitude)) dest=(\(dest.latitude),\(dest.longitude))");

        let request = MKDirections.Request();
        request.source      = MKMapItem(placemark: MKPlacemark(coordinate: src));
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: dest));
        request.transportType = .walking;

        let (response, error): (MKDirections.Response?, Error?) = await withCheckedContinuation { continuation in
            MKDirections(request: request).calculate { response, error in
                continuation.resume(returning: (response, error));
            };
        };

        if let error = error {
            print("[Route] MKDirections error: \(error)");
            return;
        }

        guard let response = response else {
            print("[Route] response is nil");
            return;
        }

        print("[Route] routes count: \(response.routes.count)");

        guard let route = response.routes.first else {
            print("[Route] no routes in response");
            return;
        }

        let polyline = route.polyline;
        print("[Route] polyline pointCount: \(polyline.pointCount)");

        let points = polyline.points();
        routeCoordinates = (0..<polyline.pointCount).map { points[$0].coordinate };
        print("[Route] routeCoordinates set, count: \(routeCoordinates.count)");
        print("[Route] first: (\(routeCoordinates.first?.latitude ?? -1), \(routeCoordinates.first?.longitude ?? -1))");
        print("[Route] last:  (\(routeCoordinates.last?.latitude ?? -1), \(routeCoordinates.last?.longitude ?? -1))");

        // Adjust camera to fit entire route
        if !routeCoordinates.isEmpty {
            mapCameraPosition = .region(regionFittingRoute(routeCoordinates));
        }
    }

    private func regionFitting(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> MKCoordinateRegion {
        let center = CLLocationCoordinate2D(
            latitude: (a.latitude + b.latitude) / 2,
            longitude: (a.longitude + b.longitude) / 2
        );
        let latSpan = max(abs(a.latitude - b.latitude) * 1.4, 0.005);
        let lonSpan = max(abs(a.longitude - b.longitude) * 1.4, 0.005);
        return MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: latSpan, longitudeDelta: lonSpan));
    }

    private func regionFittingRoute(_ coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard !coordinates.isEmpty else {
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1));
        }

        // Find bounding box
        var minLat = coordinates[0].latitude;
        var maxLat = coordinates[0].latitude;
        var minLon = coordinates[0].longitude;
        var maxLon = coordinates[0].longitude;

        for coord in coordinates {
            minLat = min(minLat, coord.latitude);
            maxLat = max(maxLat, coord.latitude);
            minLon = min(minLon, coord.longitude);
            maxLon = max(maxLon, coord.longitude);
        }

        // Calculate center and span with padding
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        );
        let latSpan = max((maxLat - minLat) * 1.6, 0.005);  // 60% padding for markers
        let lonSpan = max((maxLon - minLon) * 1.6, 0.005);

        return MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: latSpan, longitudeDelta: lonSpan));
    }

    // MARK: - Theme helpers

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
    private func themeAccent() -> Color {
        switch LSThemeManager.shared.theme {
        case .xmas:  return Color(uiColor: LSThemeManager.MaterialColors.red.red50 ?? .white);
        case .summer: return Color(uiColor: LSThemeManager.MaterialColors.lightBlue._50 ?? .white);
        default:     return .accentColor;
        }
    }

    private func roundButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(themeRoundButtonBg())
                .clipShape(Circle())
        }
    }
    private func themeRoundButtonBg() -> Color {
        switch LSThemeManager.shared.theme {
        case .xmas:  return Color(uiColor: LSThemeManager.RoundButtonBackgroundColors.red ?? .systemBlue);
        case .summer: return Color(uiColor: LSThemeManager.RoundButtonBackgroundColors.lightBlue ?? .systemBlue);
        default:     return .accentColor;
        }
    }
}

// MARK: - Helper: present SFSafariViewController

class SFSafariViewControllerPresenter {
    func present(url: URL) {
        let safari = SFSafariViewController(url: url);
        UIApplication.shared.keyWindow?.rootViewController?.present(safari, animated: true);
    }
}

// MARK: - Helper: Share sheet wrapper

struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
