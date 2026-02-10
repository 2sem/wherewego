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
    @State private var showRangeSheet = false
    @State private var selectedTour: KGDataTourInfo? = nil
    @State private var mapCameraPosition: MapCameraPosition = .automatic
    @State private var savedCameraPosition: MapCameraPosition? = nil
    @State private var currentRegion: MKCoordinateRegion? = nil
    @State private var requestedSpan: Double = 0.05
    @AppStorage("LaunchCount") private var launchCount: Int = 0
    @EnvironmentObject var adManager: SwiftUIAdManager

    // Range picker bindings
    @State private var pickerLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.5866076, longitude: 126.974811);
    @State private var pickerRadius: Int = 3000;
    @State private var tempRadius: Int = 3000;  // Temporary while adjusting slider

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
        .sheet(isPresented: $showRangeSheet, onDismiss: {
            // Apply the new radius and fetch when sheet is dismissed
            if tempRadius != viewModel.radius {
                viewModel.radius = tempRadius;
                pickerRadius = tempRadius;
                WWGDefaults.Range = tempRadius;
                viewModel.fetchList();
            }
        }) {
            rangeSliderSheet
                .presentationDetents([.height(200)])
                .presentationDragIndicator(.visible)
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
            print("[TourMapScreen] isLoading changed: \(oldValue) → \(newValue), infos: \(viewModel.infos.count), total: \(viewModel.totalCount)");
            guard oldValue && !newValue else { return };
            if viewModel.infos.isEmpty && viewModel.location != nil {
                showNoDataAlert = true;
            } else {
                // First page loaded — auto-fetch remaining pages
                viewModel.fetchAllPages();
            }
        }
        .onChange(of: selectedTour?.id) { _, id in
            if let loc = selectedTour?.location {
                // Save current position before zooming in
                savedCameraPosition = mapCameraPosition;
                withAnimation(.easeInOut(duration: 0.5)) {
                    mapCameraPosition = .region(MKCoordinateRegion(
                        center: centeredCoordinate(for: loc),
                        span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
                    ));
                }
            } else {
                // Restore previous position on deselect
                if let saved = savedCameraPosition {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        mapCameraPosition = saved;
                    }
                    savedCameraPosition = nil;
                }
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

            if let tour = selectedTour {
                floatingInfoCard(for: tour)
                    .padding(.bottom, 60)  // Above banner
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if viewModel.hasMorePages {
                loadingMoreBadge
                    .padding(.bottom, selectedTour != nil ? 200 : 60)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            bannerAdView
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.hasMorePages)
    }

    // MARK: - Map View

    private var mapView: some View {
        ZStack(alignment: .leading) {
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

                // Range circle (only show while adjusting)
                if showRangeSheet, let center = viewModel.location {
                    MapCircle(center: center, radius: CLLocationDistance(tempRadius))
                        .foregroundStyle(Color.blue.opacity(0.15))
                        .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                }

                // Tour markers
                ForEach(Array(viewModel.infos.enumerated()), id: \.offset) { (index, info) in
                    if let title = info.title, let location = info.location {
                        let isSelected = selectedTour?.id == info.id;
                        Annotation(title, coordinate: location) {
                            markerView(for: info, isSelected: isSelected)
                                .onTapGesture {
                                    withAnimation {
                                        selectedTour = info;
                                    }
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
                currentRegion = context.region;
                requestedSpan = context.region.span.latitudeDelta;
            }
            .onTapGesture {
                withAnimation {
                    selectedTour = nil;
                }
            }

            // Zoom buttons on the left side
            zoomControls
                .padding(.leading, 12)
                .padding(.top, 60)
        }
    }

    private func markerView(for info: KGDataTourInfo, isSelected: Bool) -> some View {
        ZStack {
            // Outer ring for selected marker
            if isSelected {
                Circle()
                    .stroke(.white, lineWidth: 4)
                    .frame(width: 44, height: 44)
                    .shadow(color: .black.opacity(0.4), radius: 4)
            }

            // Background circle
            Circle()
                .fill(markerColor(for: info.type))
                .frame(width: isSelected ? 40 : 32, height: isSelected ? 40 : 32)
                .shadow(color: .black.opacity(0.3), radius: 3)

            // Icon
            Image(systemName: markerIcon(for: info.type))
                .font(.system(size: isSelected ? 20 : 16, weight: .semibold))
                .foregroundStyle(.white)
        }
        .scaleEffect(isSelected ? 1.0 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
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
        case .Tour, .Tour_Foreign:           return Color("TourMarkerColor")       // 관광지
        case .Culture, .Culture_Foreign:     return Color("CultureMarkerColor")    // 문화시설
        case .Event, .Event_Foreign:         return Color("EventMarkerColor")      // 행사/공연/축제
        case .Course:                        return Color("CourseMarkerColor")     // 여행코스
        case .Leports, .Leports_Foreign:     return Color("LeportsMarkerColor")    // 레포츠
        case .Hotel, .Hotel_Foreign:         return Color("HotelMarkerColor")      // 숙박
        case .Shopping, .Shopping_Foreign:   return Color("ShoppingMarkerColor")   // 쇼핑
        case .Food, .Food_Foreign:           return Color("FoodMarkerColor")       // 음식점
        case .Travel, .Travel_Foreign:       return Color("TravelMarkerColor")     // 여행
        }
    }

    private func floatingInfoCard(for tour: KGDataTourInfo) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Thumbnail
            if let imgUrl = tour.thumbnail {
                AsyncImage(url: imgUrl) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 100, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Info
            VStack(alignment: .leading, spacing: 6) {
                // Type badge
                HStack(spacing: 4) {
                    Image(systemName: markerIcon(for: tour.type))
                        .font(.system(size: 12))
                        .foregroundStyle(.white)

                    Text(tour.type.stringValue.localized())
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(markerColor(for: tour.type))
                .clipShape(RoundedRectangle(cornerRadius: 6))

                // Title
                Text(tour.title ?? "")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                // Address
                if let addr = tour.primaryAddr, !addr.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Text(addr)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                // Phone
                if let tel = tour.tel, !tel.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Text(tel)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }

                // Distance
                if let distance = tour.distance {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.blue)
                        Text(distance.stringForDistance())
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.blue)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
        .padding(.horizontal)
        .onTapGesture {
            navigateToDetail(info: tour);
        }
    }

    private var zoomControls: some View {
        let atMin = requestedSpan <= 0.002;
        let atMax = requestedSpan >= 2.0;

        return VStack(spacing: 0) {
            Button(action: zoomIn) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 44, height: 44)
                    .opacity(atMin ? 0.3 : 1.0)
            }
            .disabled(atMin)
            Divider()
                .frame(width: 44)
            Button(action: zoomOut) {
                Image(systemName: "minus")
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 44, height: 44)
                    .opacity(atMax ? 0.3 : 1.0)
            }
            .disabled(atMax)
        }
        .foregroundStyle(.primary)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
    }

    private var loadingMoreBadge: some View {
        HStack(spacing: 6) {
            ProgressView()
                .scaleEffect(0.8)
            Text("\(viewModel.infos.count) / \(viewModel.totalCount)")
                .font(.system(size: 13, weight: .medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
    }

    private var bannerAdView: some View {
        BannerAdView(unitName: .homeBanner)
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .shadow(color: .black.opacity(0.1), radius: 5, y: -2)
    }

    private var rangeSliderSheet: some View {
        VStack(spacing: 16) {
            Text("Search Range".localized())
                .font(.headline)
                .padding(.top, 8)

            HStack(spacing: 12) {
                // Minus button
                Button {
                    tempRadius = max(1000, tempRadius - 1000);
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.blue)
                }
                .disabled(tempRadius <= 1000)

                // Slider
                Slider(value: Binding(
                    get: { Double(tempRadius) },
                    set: { tempRadius = Int($0.rounded()) }
                ), in: 1000...20000, step: 1000)
                    .tint(.blue)

                // Plus button
                Button {
                    tempRadius = min(20000, tempRadius + 1000);
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.blue)
                }
                .disabled(tempRadius >= 20000)
            }
            .padding(.horizontal)

            // Distance label
            Text(tempRadius.stringForDistance())
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding()
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
            Button {
                tempRadius = viewModel.radius;
                showRangeSheet = true;
            } label: {
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
        tempRadius = viewModel.radius;

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

    /// Shifts the center coordinate downward so the place appears visually
    /// centered in the map area above the floating info card.
    private func centeredCoordinate(for loc: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let span: Double = 0.015;
        let screenHeight = UIScreen.main.bounds.height;

        // Approximate height of: card (~160pt) + bottom padding (60pt) + banner (50pt)
        let cardClearance: CGFloat = 270;
        let visibleHeight = screenHeight - cardClearance;

        // How far the visible center is below the map center, in points
        let offsetPoints = (screenHeight - visibleHeight) / 2;

        // Convert points to degrees
        let latOffset = Double(offsetPoints / screenHeight) * span;

        return CLLocationCoordinate2D(
            latitude: loc.latitude - latOffset,
            longitude: loc.longitude
        );
    }

    private func zoomIn() {
        guard let region = currentRegion else { return };
        let newDelta = max(0.002, region.span.latitudeDelta / 2);
        requestedSpan = newDelta;
        withAnimation(.easeInOut(duration: 0.3)) {
            mapCameraPosition = .region(MKCoordinateRegion(
                center: region.center,
                span: MKCoordinateSpan(latitudeDelta: newDelta, longitudeDelta: newDelta)
            ));
        }
    }

    private func zoomOut() {
        guard let region = currentRegion else { return };
        let newDelta = min(2.0, region.span.latitudeDelta * 2);
        requestedSpan = newDelta;
        withAnimation(.easeInOut(duration: 0.3)) {
            mapCameraPosition = .region(MKCoordinateRegion(
                center: region.center,
                span: MKCoordinateSpan(latitudeDelta: newDelta, longitudeDelta: newDelta)
            ));
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
