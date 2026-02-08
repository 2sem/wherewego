import SwiftUI
import CoreLocation
import MapKit
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
    @State private var showShareSheet = false;
    @State private var shareItems: [Any] = [];
    @State private var routeCoordinates: [CLLocationCoordinate2D] = [];
    @State private var mapCameraPosition: MapCameraPosition = .automatic;
    @State private var transportType: TransportType = .fastest;
    @State private var showRouteSheet = false;
    @State private var showNaverWebSheet = false;
    @State private var naverWebURL: URL?;

    enum TransportType {
        case fastest
        case walking
        case automobile
        case bicycle
        case transit

        var mkDirectionsType: MKDirectionsTransportType {
            switch self {
            case .fastest:    return .any
            case .walking:    return .walking
            case .automobile: return .automobile
            case .bicycle:    return .cycling
            case .transit:    return .transit
            }
        }
    }

    private var resolvedInfo: KGDataTourInfo? { detailInfo ?? info; }
    private var resolvedId: Int { info?.id ?? infoId; }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero section: Large image with title overlay (40-50% of screen)
                heroSection

                // Action button bar
                actionButtonBar
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                // Banner ad slot
                bannerAdSlot

                // Address card
                addressCard
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                // Map section (30-40% of screen)
                mapSection
                    .padding(.top, 16)

                // External navigation buttons
                externalNavButtons
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                // Bottom padding
                Color.clear.frame(height: 20)
            }
        }
        .background(Color(UIColor.systemBackground))
        .navigationBarBackButtonHidden()
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.backward")
                        .foregroundStyle(.primary)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheetView(items: shareItems)
        }
        .sheet(isPresented: $showRouteSheet) {
            routeOptionsSheet
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showNaverWebSheet) {
            if let url = naverWebURL {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
        .task {
            fetchDetail();
        }
    }

    // MARK: - Sub-views

    private var heroSection: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                // Background: Photo or gradient fallback
                if let imgUrl = resolvedInfo?.image {
                    // Case 1: Photo exists
                    NavigationLink(value: TourNavDestination.imageViewer(imgUrl)) {
                        AsyncImage(url: imgUrl) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure, .empty:
                                // Fallback to gradient if image fails to load
                                categoryGradientBackground
                            @unknown default:
                                categoryGradientBackground
                            }
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                    }
                    .buttonStyle(.plain)
                } else {
                    // Case 2: No photo - gradient with category icon
                    categoryGradientBackground
                        .overlay(
                            // Large category icon
                            Image(systemName: categoryIcon(for: resolvedInfo?.type))
                                .font(.system(size: 140, weight: .light))
                                .foregroundStyle(.white.opacity(0.25))
                        )
                }

                // Gradient overlay for title readability
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                // Title overlay
                VStack(alignment: .leading, spacing: 4) {
                    Text(resolvedInfo?.title ?? "")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 8)

                    if let type = resolvedInfo?.type {
                        Text(type.stringValue.localized())
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.3), radius: 4)
                    }
                }
                .padding(20)
                .allowsHitTesting(false)
            }
        }
        .frame(height: UIScreen.main.bounds.height * 0.45)
    }

    private var categoryGradientBackground: some View {
        LinearGradient(
            colors: categoryGradientColors(for: resolvedInfo?.type),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func categoryGradientColors(for type: KGDataTourInfo.ContentType?) -> [Color] {
        guard let type = type else {
            return [Color(red: 0.0, green: 0.66, blue: 0.59), Color(red: 0.0, green: 0.48, blue: 1.0)]  // Default teal to blue
        }

        switch type {
        case .Tour, .Tour_Foreign:
            return [Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 1.0, green: 0.4, blue: 0.0)]  // Orange
        case .Culture, .Culture_Foreign:
            return [Color(red: 0.6, green: 0.4, blue: 0.8), Color(red: 0.4, green: 0.2, blue: 0.6)]  // Purple
        case .Event, .Event_Foreign:
            return [Color(red: 1.0, green: 0.3, blue: 0.5), Color(red: 0.9, green: 0.1, blue: 0.3)]  // Pink
        case .Course:
            return [Color(red: 0.2, green: 0.6, blue: 0.9), Color(red: 0.1, green: 0.4, blue: 0.7)]  // Blue
        case .Leports, .Leports_Foreign:
            return [Color(red: 0.3, green: 0.8, blue: 0.3), Color(red: 0.2, green: 0.6, blue: 0.2)]  // Green
        case .Hotel, .Hotel_Foreign:
            return [Color(red: 0.4, green: 0.5, blue: 0.7), Color(red: 0.2, green: 0.3, blue: 0.5)]  // Navy
        case .Shopping, .Shopping_Foreign:
            return [Color(red: 0.9, green: 0.5, blue: 0.8), Color(red: 0.7, green: 0.3, blue: 0.6)]  // Magenta
        case .Food, .Food_Foreign:
            return [Color(red: 0.0, green: 0.66, blue: 0.59), Color(red: 0.0, green: 0.48, blue: 1.0)]  // Teal to blue
        case .Travel, .Travel_Foreign:
            return [Color(red: 0.5, green: 0.7, blue: 0.9), Color(red: 0.3, green: 0.5, blue: 0.7)]  // Sky blue
        }
    }

    private func categoryIcon(for type: KGDataTourInfo.ContentType?) -> String {
        guard let type = type else { return "mappin.circle.fill" }

        switch type {
        case .Tour, .Tour_Foreign:           return "camera.fill"
        case .Culture, .Culture_Foreign:     return "building.columns.fill"
        case .Event, .Event_Foreign:         return "party.popper.fill"
        case .Course:                        return "map.fill"
        case .Leports, .Leports_Foreign:     return "figure.run"
        case .Hotel, .Hotel_Foreign:         return "bed.double.fill"
        case .Shopping, .Shopping_Foreign:   return "cart.fill"
        case .Food, .Food_Foreign:           return "fork.knife"
        case .Travel, .Travel_Foreign:       return "airplane"
        }
    }

    private var actionButtonBar: some View {
        HStack(spacing: 12) {
            // Call button
            Button(action: onPhone) {
                HStack(spacing: 8) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Call".localized())
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(red: 0.0, green: 0.66, blue: 0.59))  // Teal #00A896
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Directions button
            Button(action: onRoute) {
                HStack(spacing: 8) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Directions".localized())
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(red: 0.0, green: 0.48, blue: 1.0))  // iOS Blue #007AFF
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Share button
            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var bannerAdSlot: some View {
        BannerAdView()
            .frame(height: 50)
            .frame(maxWidth: .infinity)
    }

    private var addressCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Address".localized())
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button(action: {
                    let address = "\(resolvedInfo?.primaryAddr ?? "") \(resolvedInfo?.detailAddr ?? "")";
                    UIPasteboard.general.string = address;
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 13))
                        Text("Copy".localized())
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(.blue)
                }
            }

            Text("\(resolvedInfo?.primaryAddr ?? "") \(resolvedInfo?.detailAddr ?? "")")
                .font(.system(size: 17))
                .foregroundStyle(.primary)

            if let tel = resolvedInfo?.tel, !tel.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Text(tel)
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var mapSection: some View {
        VStack(spacing: 0) {
            if let dest = resolvedInfo?.location, let src = currentLocation {
                Map(position: $mapCameraPosition) {
                    Marker("Here", coordinate: src)
                        .foregroundStyle(.blue)
                    Marker(resolvedInfo?.title ?? "", coordinate: dest)
                        .foregroundStyle(.red)
                    if !routeCoordinates.isEmpty {
                        MapPolyline(coordinates: routeCoordinates)
                            .stroke(Color("PathColor"), lineWidth: 5)
                    }
                }
                .frame(height: UIScreen.main.bounds.height * 0.35)
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                }
                .onChange(of: resolvedInfo?.location) { _, _ in
                    mapCameraPosition = .region(regionFitting(src, dest));
                }
                .task {
                    mapCameraPosition = .region(regionFitting(src, dest));
                    await fetchRoute(from: src, to: dest);
                }
            } else {
                Color.gray.opacity(0.2)
                    .frame(height: UIScreen.main.bounds.height * 0.35)
                    .overlay(
                        Text("Map not available".localized())
                            .foregroundStyle(.secondary)
                    )
            }
        }
    }

    private var externalNavButtons: some View {
        HStack(spacing: 12) {
            Button(action: {
                // Open in Apple Maps
                guard let dest = resolvedInfo?.location else { return };
                let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: dest));
                mapItem.name = resolvedInfo?.title;
                mapItem.openInMaps(launchOptions: [
                    MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
                ]);
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Open in Apple Maps".localized())
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            if Locale.current.isKorean {
                Button(action: {
                    // Open in KakaoMap
                    guard let dest = resolvedInfo?.location else { return };
                    let urlString = "kakaomap://route?ep=\(dest.latitude),\(dest.longitude)&by=CAR";
                    if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url);
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Open in KakaoMap".localized())
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    private var routeOptionsSheet: some View {
        VStack(spacing: 16) {
            Text("Choose Navigation App".localized())
                .font(.system(size: 17, weight: .semibold))
                .padding(.top, 8)

            VStack(spacing: 12) {
                // First row: KakaoMap + Naver Map
                HStack(spacing: 12) {
                    // KakaoMap button
                    Button(action: {
                        showRouteSheet = false;
                        openKakaoMap();
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "map.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.yellow)
                            Text("KakaoMap")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Naver Map button
                    Button(action: {
                        showRouteSheet = false;
                        openNaverMap();
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "map.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.green)
                            Text("Naver Map")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                // Second row: Google Maps (full width)
                Button(action: {
                    showRouteSheet = false;
                    openGoogleMaps();
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.blue)
                        Text("Google Maps")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 20)
    }

    @EnvironmentObject var adManager: SwiftUIAdManager

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
        if Locale.current.isKorean {
            showRouteSheet = true;
        } else {
            // Non-Korean users: open Google Maps via Safari
            guard let dest = resolvedInfo?.location else { return };
            let src = currentLocation ?? dest;
            let url = src.urlForGoogleRoute(startName: "Current Location".localized(), end: dest, endName: resolvedInfo?.title ?? "Destination".localized());
            let safari = SFSafariViewControllerPresenter();
            safari.present(url: url);
        }
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
            items.append("[\(info.title ?? "")] \(info.tel ?? "")");
            if let loc = currentLocation, let dest = info.location {
                items.append(loc.urlForGoogleRoute(startName: "Current Location".localized(), end: dest, endName: info.title ?? "Destination".localized()));
            }
            shareItems = items;
            showShareSheet = true;
        }
    }

    private func openKakaoMap() {
        guard let dest = resolvedInfo?.location else { return };
        let urlString = "kakaomap://route?ep=\(dest.latitude),\(dest.longitude)&by=CAR";

        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url);
        } else {
            // KakaoMap not installed - open App Store
            if let appStoreURL = URL(string: "http://itunes.apple.com/app/id304608425?mt=8") {
                UIApplication.shared.open(appStoreURL);
            }
        }
    }

    private func openNaverMap() {
        guard let dest = resolvedInfo?.location, let src = currentLocation else { return };

        // Map transport type to Naver's format
        let naverMode: String = {
            switch transportType {
            case .fastest, .automobile:
                return "car"
            case .walking, .bicycle:
                return "walk"
            case .transit:
                return "bus"
            }
        }();

        let sname = "Current Location".localized().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Current";
        let dname = (resolvedInfo?.title ?? "Destination").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Destination";
        let appname = "com.leesam.wherewego".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "wherewego";

        let urlString = "nmap://route/\(naverMode)?slat=\(src.latitude)&slng=\(src.longitude)&sname=\(sname)&dlat=\(dest.latitude)&dlng=\(dest.longitude)&dname=\(dname)&appname=\(appname)";

        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url);
        } else {
            // Naver Map not installed - open Safari with web version
            openNaverMapWeb();
        }
    }

    private func openNaverMapWeb() {
        guard let dest = resolvedInfo?.location, let src = currentLocation else { return };

        // Map transport type to Naver web format
        let webMode: String = {
            switch transportType {
            case .fastest, .automobile:
                return "car"
            case .walking:
                return "walk"
            case .bicycle:
                return "bike"
            case .transit:
                return "transit"
            }
        }();

        let sname = (resolvedInfo?.title ?? "Destination").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Destination";

        // Note: Naver web uses projected coordinates, but we'll try with WGS84
        // User may need to manually adjust in the web interface
        let urlString = "https://map.naver.com/p/directions/\(src.latitude),\(src.longitude),Current,,PLACE_POI/\(dest.latitude),\(dest.longitude),\(sname),,PLACE_POI/-/\(webMode)?c=12.00,0,0,0,dh";

        if let url = URL(string: urlString) {
            naverWebURL = url;
            showNaverWebSheet = true;
        }
    }

    private func openGoogleMaps() {
        guard let dest = resolvedInfo?.location, let src = currentLocation else { return };

        // Map transport type to Google Maps format
        let googleMode: String = {
            switch transportType {
            case .fastest, .automobile:
                return "driving"
            case .walking:
                return "walking"
            case .bicycle:
                return "bicycling"
            case .transit:
                return "transit"
            }
        }();

        // Try app URL scheme first
        let appURLString = "comgooglemaps://?saddr=\(src.latitude),\(src.longitude)&daddr=\(dest.latitude),\(dest.longitude)&directionsmode=\(googleMode)";

        if let appURL = URL(string: appURLString), UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL);
        } else {
            // Fallback to web URL in Safari sheet
            let webURLString = "https://www.google.com/maps/dir/?api=1&origin=\(src.latitude),\(src.longitude)&destination=\(dest.latitude),\(dest.longitude)&travelmode=\(googleMode)";

            if let webURL = URL(string: webURLString) {
                naverWebURL = webURL;
                showNaverWebSheet = true;
            }
        }
    }

    // MARK: - Map helpers

    private func fetchRoute(from src: CLLocationCoordinate2D, to dest: CLLocationCoordinate2D) async {
        print("[Route] fetchRoute called: src=(\(src.latitude),\(src.longitude)) dest=(\(dest.latitude),\(dest.longitude))");

        let request = MKDirections.Request();
        request.source      = MKMapItem(placemark: MKPlacemark(coordinate: src));
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: dest));
        request.transportType = transportType.mkDirectionsType;

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

}

// MARK: - Helper: SafariView

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
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
