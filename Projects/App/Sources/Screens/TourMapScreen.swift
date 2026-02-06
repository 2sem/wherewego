import SwiftUI
import CoreLocation
import MapKit

struct TourMapScreen: View {
    @State private var locationManager = LocationManager()
    @State private var viewModel = TourListViewModel()
    @State private var navPath: [TourNavDestination] = []
    @State private var typeIndex: Int = 0
    @State private var showLocationAlert = false
    @State private var showReviewAlert = false
    @State private var showNoDataAlert = false
    @State private var mapCameraPosition: MapCameraPosition = .automatic
    @AppStorage("LaunchCount") private var launchCount: Int = 0
    @EnvironmentObject var adManager: SwiftUIAdManager

    // Range picker bindings
    @State private var pickerLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.5866076, longitude: 126.974811);
    @State private var pickerRadius: Int = 3000;

    private var typeOptions: [(String, KGDataTourInfo.ContentType?)] {
        var options: [(String, KGDataTourInfo.ContentType?)] = [("All Tour Informations".localized(), nil)];
        let types = Locale.current.isKorean ? KGDataTourInfo.ContentType.values : KGDataTourInfo.ContentType.values_foreign;
        for t in types {
            options.append((t.stringValue.localized(), t));
        }
        return options;
    }

    var body: some View {
        NavigationStack(path: $navPath) {
            contentBody
                .navigationDestination(for: TourNavDestination.self) { dest in
                    navigationDestinationView(for: dest)
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarItems }
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
//                .toolbarColorScheme(themeColorScheme(), for: .navigationBar)
        }
        .alert("\"WhereWeGo\" needs to use your location".localized(), isPresented: $showLocationAlert) {
            Button("Settings".localized()) {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!);
            }
            Button("Ok".localized()) {}
        } message: {
            Text("This app will not work without the location permission.".localized())
        }
        .alert("앱 평가 및 추천".localized(), isPresented: $showReviewAlert) {
            Button(String(format: "'%@' 평가".localized(), UIApplication.shared.displayName ?? "")) {
                UIApplication.shared.openReview()
            }
            Button(String(format: "'%@' 추천".localized(), UIApplication.shared.displayName ?? "")) {
                UIApplication.shared.shareByKakao()
            }
            Button("다음에 하기".localized()) {
                WWGDefaults.LastShareShown = Date().addingTimeInterval(60 * 60 * 24)
            }
        } message: {
            Text(String(format: "'%@'을 평가하거나 친구들에게 추천해보세요.".localized(), UIApplication.shared.displayName ?? ""))
        }
        .alert("No Results".localized(), isPresented: $showNoDataAlert) {
            Button("OK".localized()) {}
        } message: {
            Text("No locations found for the selected type.\nTry selecting a different type or adjusting your search range.".localized())
        }
        .onAppear { onScreenAppear(); }
        .onChange(of: locationManager.currentLocation) { _, newLoc in
            handleLocationChange(newLoc);
        }
        .onChange(of: locationManager.authorizationStatus) { _, status in
            if status == .denied { showLocationAlert = true; }
        }
        .onChange(of: typeIndex) { _, _ in
            viewModel.selectedType = typeOptions[typeIndex].1;
            if viewModel.location != nil { viewModel.fetchList(); }
        }
        .onChange(of: viewModel.isLoading) { oldValue, newValue in
            // Show alert when loading finishes and no data found
            if oldValue && !newValue && viewModel.infos.isEmpty && viewModel.location != nil {
                showNoDataAlert = true;
            }
        }
        .onChange(of: DeepLinkManager.shared.contentId) { _, newId in
            handleDeepLink(newId);
        }
    }

    // MARK: - Sub-views

    private var contentBody: some View {
        ZStack(alignment: .bottom) {
            mapView
                .ignoresSafeArea(edges: .bottom)

            bannerAdView
        }
    }

    // MARK: - Map View

    private var mapView: some View {
        Map(position: $mapCameraPosition) {
            // User location
            if let userLoc = viewModel.location {
                Annotation("Here", coordinate: userLoc) {
                    Circle()
                        .fill(.blue)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(.white, lineWidth: 2)
                        )
                }
            }

            // Tour markers
            ForEach(Array(viewModel.infos.enumerated()), id: \.offset) { (index, info) in
                if let title = info.title, let location = info.location {
                    Annotation(title, coordinate: location) {
                        markerView(for: info)
                            .onTapGesture {
                                navigateToDetail(info: info)
                            }
                    }
                }
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .onMapCameraChange { context in
            // Fetch more when user pans/zooms to edge of loaded data
            checkAndLoadMore(region: context.region)
        }
    }

    private func markerView(for info: KGDataTourInfo) -> some View {
        ZStack {
            // Background circle
            Circle()
                .fill(markerColor(for: info.type))
                .frame(width: 32, height: 32)
                .shadow(color: .black.opacity(0.3), radius: 3)

            // Icon
            Image(systemName: markerIcon(for: info.type))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private func pickerIcon(for type: KGDataTourInfo.ContentType?) -> String {
        guard let type = type else { return "list.bullet" } // "All" option

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

    private func markerIcon(for type: KGDataTourInfo.ContentType) -> String {
        switch type {
        case .Tour, .Tour_Foreign:           return "camera.fill"              // 관광지
        case .Culture, .Culture_Foreign:     return "building.columns.fill"    // 문화시설
        case .Event, .Event_Foreign:         return "party.popper.fill"        // 행사/공연/축제
        case .Course:                        return "map.fill"                 // 여행코스
        case .Leports, .Leports_Foreign:     return "figure.run"               // 레포츠
        case .Hotel, .Hotel_Foreign:         return "bed.double.fill"          // 숙박
        case .Shopping, .Shopping_Foreign:   return "cart.fill"                // 쇼핑
        case .Food, .Food_Foreign:           return "fork.knife"               // 음식점
        case .Travel, .Travel_Foreign:       return "airplane"                 // 여행
        }
    }

    private func markerColor(for type: KGDataTourInfo.ContentType) -> Color {
        switch type {
        case .Tour, .Tour_Foreign:           return .orange     // 관광지
        case .Culture, .Culture_Foreign:     return .purple     // 문화시설
        case .Event, .Event_Foreign:         return .pink       // 행사/공연/축제
        case .Course:                        return .blue       // 여행코스
        case .Leports, .Leports_Foreign:     return .green      // 레포츠
        case .Hotel, .Hotel_Foreign:         return .indigo     // 숙박
        case .Shopping, .Shopping_Foreign:   return .cyan       // 쇼핑
        case .Food, .Food_Foreign:           return .red        // 음식점
        case .Travel, .Travel_Foreign:       return .teal       // 여행
        }
    }

    private var bannerAdView: some View {
        BannerAdView()
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .shadow(color: .black.opacity(0.1), radius: 5, y: -2)
    }

    @ViewBuilder
    private func navigationDestinationView(for dest: TourNavDestination) -> some View {
        switch dest {
        case .tourInfo(let info, let loc):
            TourInfoScreen(info: info, currentLocation: loc)
                .onDisappear { onDetailDismiss(); }
        case .tourInfoById(let id, let loc):
            TourInfoScreen(infoId: id, currentLocation: loc)
                .onDisappear { onDetailDismiss(); }
        case .imageViewer(let url):
            ImageViewerScreen(imageUrl: url)
        case .rangePicker:
            RangePickerScreen(location: $pickerLocation, radius: $pickerRadius)
                .onDisappear { onRangePickerDone(); }
        }
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Menu {
                Picker("Type", selection: $typeIndex) {
                    ForEach(typeOptions.indices) { i in
                        Label(typeOptions[i].0, systemImage: pickerIcon(for: typeOptions[i].1))
                            .tag(i);
                    }
                }
                .pickerStyle(.inline)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: pickerIcon(for: typeOptions[typeIndex].1))
                        .font(.system(size: 14))
                    Text(typeOptions[typeIndex].0)
                        .font(.system(size: 15, weight: .medium))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(themeBarTintColor())
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button { locationManager.requestLocation() } label: {
                Image(systemName: "location.fill")
                    .foregroundStyle(themeBarTintColor())
            }
        }
        ToolbarItem(placement: .navigationBarLeading) {
            Button { navPath.append(.rangePicker) } label: {
                Text(viewModel.radius.stringForDistance())
                    .foregroundStyle(themeBarTintColor())
                    .font(.system(size: 14))
            }
        }
    }

    // MARK: - Helpers

    private func onScreenAppear() {
        locationManager.requestAuthorization();
        locationManager.requestLocation();

        // Restore persisted radius
        viewModel.radius = WWGDefaults.Range;
        pickerRadius = viewModel.radius;

        // Handle deep link that arrived before screen was ready
        if let id = DeepLinkManager.shared.contentId {
            navPath.append(.tourInfoById(id, DeepLinkManager.shared.srcLocation));
            DeepLinkManager.shared.consume();
        }
    }

    private func onRangePickerDone() {
        viewModel.location = pickerLocation;
        viewModel.radius = pickerRadius;
        WWGDefaults.Range = pickerRadius;
        viewModel.fetchList();
    }

    private func onDetailDismiss() {
        let interval: TimeInterval = 60 * 60 * 24 * 30
        let last = WWGDefaults.LastShareShown
        let spent = Date().timeIntervalSince(last)
        guard spent > interval || last.timeIntervalSince1970 == 0 else { return }
        showReviewAlert = true
        WWGDefaults.LastShareShown = Date()
    }

    private func navigateToDetail(info: KGDataTourInfo) {
        navPath.append(.tourInfo(info, viewModel.location));
    }

    private func checkAndLoadMore(region: MKCoordinateRegion) {
        // Load next page when user explores the map
        // Simple heuristic: if we have tours and user moved significantly
        guard !viewModel.infos.isEmpty, !viewModel.isLoading else { return }

        // Fetch next page in background
        Task {
            viewModel.fetchNextPage();
        }
    }

    private func handleLocationChange(_ newLoc: CLLocationCoordinate2D?) {
        guard let loc = newLoc else { return };
        viewModel.location = loc;
        pickerLocation = loc;
        mapCameraPosition = .region(MKCoordinateRegion(
            center: loc,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ));
        viewModel.fetchList();
    }

    private func handleDeepLink(_ newId: Int?) {
        guard let id = newId else { return };
        navPath.append(.tourInfoById(id, DeepLinkManager.shared.srcLocation));
        DeepLinkManager.shared.consume();
    }

    // MARK: - Theme colors

    private func themeColorScheme() -> ColorScheme? {
        switch LSThemeManager.shared.theme {
        case .xmas, .summer: return .dark;
        default:             return nil;
        }
    }

    private func themeBarTintColor() -> Color {
        switch LSThemeManager.shared.theme {
        case .xmas, .summer: return .white;
        default:             return .init(UIColor.label);
        }
    }
}
