import SwiftUI
import CoreLocation
import MapKit

struct TourMapScreen: View {
    @State private var locationManager = LocationManager()
    @State private var viewModel = TourListViewModel()
    @State private var navPath: [TourNavDestination] = []
    @State private var typeIndex: Int = 0
    @State private var showLocationAlert = false
    @State private var showLocationErrorAlert = false
    @State private var showReviewAlert = false
    @State private var showNoDataAlert = false
    @State private var selectedTour: KGDataTourInfo? = nil
    @State private var mapCameraPosition: MapCameraPosition = .automatic
    @State private var savedCameraPosition: MapCameraPosition? = nil
    @State private var currentRegion: MKCoordinateRegion? = nil
    @State private var requestedSpan: Double = 0.05
    @AppStorage("LaunchCount") private var launchCount: Int = 0
    @EnvironmentObject var adManager: SwiftUIAdManager

    // MARK: - Fetch-on-drop state

    /// A short settle-grace `Task` started once `.onEnd` decides a fetch is
    /// needed; cancelled by the `.continuous` handler the instant the camera
    /// moves again, so only the drag/pinch the user actually stops on costs
    /// a network call.
    @State private var fetchTask: Task<Void, Never>? = nil
    /// True while the required radius for the visible region exceeds the API
    /// max — shown as a non-modal "zoom in" hint instead of fetching.
    @State private var showZoomInHint = false
    /// Gates all fetch/hint evaluation from camera movement until either the
    /// first GPS fix has been applied or authorization is denied/restricted.
    /// Without this, the initial wide `.automatic` camera settling before a
    /// fix arrives briefly flashes the "zoom in" hint at launch.
    @State private var canEvaluateCamera = false
    /// True after a map-driven fetch (drag/zoom/location button) comes back
    /// empty — a non-modal badge, never the blocking alert.
    @State private var showNoPlacesBadge = false
    /// True only for fetches triggered by an explicit user action (type
    /// filter change) — the only case that still shows the blocking alert.
    @State private var pendingFetchIsExplicit = false
    /// True while a location fix is pending specifically because the user
    /// tapped the location button — gates the error alert so it never fires
    /// for the silent, automatic launch-time location request.
    @State private var isLocationButtonTap = false

    private let minSearchRadius = 500
    private let maxSearchRadius = 20_000
    private let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)

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
        .alert("Couldn't Get Your Location".localized(), isPresented: $showLocationErrorAlert) {
            Button("OK".localized()) {}
        } message: {
            Text("We couldn't determine your location. Please try again.".localized())
        }
        .onAppear { onScreenAppear(); }
        .onChange(of: locationManager.currentLocation) { _, newLoc in
            isLocationButtonTap = false;
            handleLocationChange(newLoc);
        }
        .onChange(of: locationManager.locationErrorCount) { old, new in
            guard new > old else { return };
            if isLocationButtonTap { showLocationErrorAlert = true; }
            isLocationButtonTap = false;
        }
        .onChange(of: locationManager.isLocating) { wasLocating, isLocating in
            // Belt-and-suspenders clear: if the fresh fix matched the
            // coordinate we already had, `currentLocation`'s onChange never
            // fires and never clears the flag. A request cycle ending is the
            // one event that always fires either way, so clear it here too —
            // this flag has no fetch side effects, so clearing it twice (or
            // redundantly) is harmless, unlike the old suppression flag.
            if wasLocating && !isLocating { isLocationButtonTap = false; }
        }
        .onChange(of: locationManager.authorizationStatus) { _, status in
            if status == .denied { showLocationAlert = true; }
            if status == .denied || status == .restricted { canEvaluateCamera = true; }
        }
        .onChange(of: typeIndex) { _, _ in
            viewModel.selectedType = typeOptions[typeIndex].1;
            if viewModel.location != nil {
                pendingFetchIsExplicit = true;
                viewModel.fetchList();
            }
        }
        .onChange(of: viewModel.isLoading) { oldValue, newValue in
            if !oldValue && newValue {
                // A fetch just started — clear any stale "no places" badge.
                showNoPlacesBadge = false;
                return;
            }
            guard oldValue && !newValue else { return };
            print("[TourMapScreen] isLoading changed: \(oldValue) → \(newValue), infos: \(viewModel.infos.count), total: \(viewModel.totalCount)");
            if viewModel.infos.isEmpty {
                if pendingFetchIsExplicit {
                    showNoDataAlert = true;
                } else {
                    showNoPlacesBadge = true;
                }
            } else {
                // First page loaded — auto-fetch remaining pages
                viewModel.fetchAllPages();
            }
            if let selected = selectedTour, !viewModel.infos.contains(where: { $0.id == selected.id }) {
                // The selected place fell out of the new results (e.g. an
                // area fetch replaced it) — clear the saved camera too, so a
                // later deselect doesn't restore a now-irrelevant position.
                selectedTour = nil;
                savedCameraPosition = nil;
            }
            pendingFetchIsExplicit = false;
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
            } else if let saved = savedCameraPosition {
                // Restore previous position on deselect
                withAnimation(.easeInOut(duration: 0.4)) {
                    mapCameraPosition = saved;
                }
                savedCameraPosition = nil;
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

            statusBadges
                .padding(.bottom, selectedTour != nil ? 200 : 60)

            bannerAdView
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.hasMorePages)
        .animation(.easeInOut(duration: 0.3), value: showZoomInHint)
        .animation(.easeInOut(duration: 0.3), value: showNoPlacesBadge)
    }

    // MARK: - Map View

    private var mapView: some View {
        ZStack(alignment: .leading) {
            Map(position: $mapCameraPosition) {
                // User's GPS location (blue dot) — "near me" home base,
                // independent of wherever the map has been dragged to search.
                if let userLoc = locationManager.currentLocation {
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
                MapCompass()
            }
            .onMapCameraChange(frequency: .continuous) { _ in
                // Fires every frame during a drag/pinch — stay allocation-free
                // and only touch @State when something is actually pending,
                // so this doesn't cause a SwiftUI re-render on every frame.
                // `currentRegion`/`requestedSpan` (for the zoom buttons) are
                // only updated in the `.onEnd` handler below, on purpose.
                if fetchTask != nil {
                    fetchTask?.cancel();
                    fetchTask = nil;
                }
                if showNoPlacesBadge {
                    showNoPlacesBadge = false;
                }
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                currentRegion = context.region;
                requestedSpan = context.region.span.latitudeDelta;
                handleCameraSettled(context.region);
            }
            .onTapGesture {
                withAnimation {
                    selectedTour = nil;
                }
            }

            // Zoom + location controls on the left side
            VStack(spacing: 8) {
                zoomControls
                locationButton
            }
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

                // Distance from the user's GPS position (falls back to the
                // API's query-point distance only when GPS is unavailable).
                if let distance = tour.distance(from: locationManager.currentLocation) {
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

    private var locationButton: some View {
        Button(action: handleLocationButtonTap) {
            Group {
                if locationManager.isLocating {
                    ProgressView()
                } else {
                    Image(systemName: "location.fill")
                        .font(.system(size: 18, weight: .medium))
                }
            }
            .frame(width: 44, height: 44)
        }
        .disabled(locationManager.isLocating)
        .foregroundStyle(.primary)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
        .accessibilityLabel("My Location".localized())
        .accessibilityHint("Centers the map on your current location".localized())
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

    private var areaLoadingBadge: some View {
        ProgressView()
            .scaleEffect(0.8)
            .padding(10)
            .background(.ultraThinMaterial, in: Circle())
            .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
    }

    private var zoomInHintBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "plus.magnifyingglass")
                .font(.system(size: 13))
            Text("Zoom in to see places".localized())
                .font(.system(size: 13, weight: .medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
    }

    private var noPlacesBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 13))
            Text("No places here".localized())
                .font(.system(size: 13, weight: .medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
    }

    private var statusBadges: some View {
        VStack(spacing: 8) {
            if showZoomInHint {
                zoomInHintBadge
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            if showNoPlacesBadge {
                noPlacesBadge
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            if viewModel.isLoading {
                areaLoadingBadge
                    .transition(.opacity)
            }
            if viewModel.hasMorePages {
                loadingMoreBadge
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    private var bannerAdView: some View {
        BannerAdView(unitName: .homeBanner)
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
            // Unreachable from this screen — TourMapScreen no longer offers
            // a range picker. The case stays in `TourNavDestination` because
            // the legacy (unreachable) TourListScreen still uses it.
            EmptyView()
        case .favorites:
            // Reached via the heart button in toolbarItems (navigationBarTrailing)
            // since TourMapScreen — not TourListScreen — is the live root
            // (see App.swift / MainScreen).
            FavoritesScreen(currentLocation: locationManager.currentLocation, navPath: $navPath)
        }
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Menu {
                Picker("Type", selection: $typeIndex) {
                    ForEach(typeOptions.indices, id: \.self) { i in
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
                .foregroundStyle(.primary)
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button { navPath.append(.favorites) } label: {
                Image(systemName: "heart")
                    .foregroundStyle(.primary)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Favorite".localized())
            .accessibilityHint("Opens your saved places".localized())
        }
    }

    // MARK: - Helpers

    private func onScreenAppear() {
        locationManager.requestAuthorization();
        locationManager.requestLocation();

        // Handle deep link that arrived before screen was ready
        if let id = DeepLinkManager.shared.contentId {
            navPath.append(.tourInfoById(id, DeepLinkManager.shared.srcLocation));
            DeepLinkManager.shared.consume();
        }
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
        // Route/share source is GPS first — the search center (wherever the
        // map has been dragged to) is only a fallback when GPS is nil.
        navPath.append(.tourInfo(info, locationManager.currentLocation ?? viewModel.location));
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

    /// The location button's tap handler. Always does something visible:
    /// if a GPS fix already exists, recenters + fetches immediately with it
    /// (never a silent no-op even if the map doesn't end up moving), then
    /// still asks for a fresh fix — if that fix turns out to differ, the
    /// `currentLocation` onChange recenters + fetches again.
    private func handleLocationButtonTap() {
        guard locationManager.authorizationStatus != .denied,
              locationManager.authorizationStatus != .restricted else {
            // Already denied — asking again silently does nothing; surface
            // the same alert used for the deny transition instead.
            showLocationAlert = true;
            return;
        }

        isLocationButtonTap = true;
        if let loc = locationManager.currentLocation {
            recenterAndFetch(loc);
        }
        locationManager.requestLocation();
    }

    private func handleLocationChange(_ newLoc: CLLocationCoordinate2D?) {
        guard let loc = newLoc else { return };
        recenterAndFetch(loc);
    }

    /// Recenters the camera on `loc` at the default ~3 km view and fetches
    /// that visible area. Used for the initial GPS fix, every subsequent GPS
    /// update, and the location button.
    private func recenterAndFetch(_ loc: CLLocationCoordinate2D) {
        // Clear the saved camera BEFORE deselecting — `.onChange(of:
        // selectedTour?.id)` runs after this function returns, and if a
        // saved position were still around it would restore it and override
        // the recenter we're about to do below.
        savedCameraPosition = nil;
        selectedTour = nil;
        canEvaluateCamera = true;
        fetchTask?.cancel();
        showZoomInHint = false;
        pendingFetchIsExplicit = false;

        let region = MKCoordinateRegion(center: loc, span: defaultSpan);
        mapCameraPosition = .region(region);

        viewModel.location = loc;
        viewModel.radius = fetchRadius(forVisibleRadius: visibleRadiusMeters(for: region));
        viewModel.fetchList();
    }

    private func handleDeepLink(_ newId: Int?) {
        guard let id = newId else { return };
        navPath.append(.tourInfoById(id, DeepLinkManager.shared.srcLocation));
        DeepLinkManager.shared.consume();
    }

    // MARK: - Fetch-on-drop

    /// Called every time the map camera settles (`.onEnd` — drag/pinch end,
    /// or a programmatic animation like zoom +/- or marker select
    /// finishing). `.onEnd` already means "dropped": it fires once after
    /// the finger lifts and momentum settles, never mid-drag, so there's no
    /// extra debounce needed here — just a short settle grace before the
    /// network call (see `scheduleAreaFetch`).
    private func handleCameraSettled(_ region: MKCoordinateRegion) {
        // Before the first GPS fix (or a denial), the initial wide
        // `.automatic` camera settling would otherwise flash the zoom-in
        // hint. `recenterAndFetch` flips this true on the first fix; the
        // authorization onChange flips it true on denial/restriction so
        // denied users can still browse by dragging/zooming.
        guard canEvaluateCamera else { return; }
        guard selectedTour == nil else { return; } // don't pull the rug while a card is open

        let visibleRadius = visibleRadiusMeters(for: region);
        guard visibleRadius <= maxSearchRadius else {
            showZoomInHint = true;
            fetchTask?.cancel();
            return;
        }
        showZoomInHint = false;

        // Coverage test: only fetch when the visible area is no longer
        // fully inside the circle we last fetched. This alone handles
        // drag, zoom-out and zoom-in with no separate threshold constants —
        // zoom-in shrinks `visibleRadius` while the center barely moves, so
        // it always stays covered and never hits the network.
        guard !isCoveredByCurrentFetch(center: region.center, visibleRadius: visibleRadius) else { return; }

        scheduleAreaFetch(for: region, radius: fetchRadius(forVisibleRadius: visibleRadius));
    }

    /// True when every corner of the visible region at `center` is still
    /// inside the circle (search center + `coveredRadius`) we've actually
    /// *loaded* data for — i.e. we already have data covering what's on
    /// screen, so no network call is needed.
    ///
    /// Deliberately compares against `viewModel.coveredRadius`, not
    /// `viewModel.radius`: the latter is only what was *requested*, and in
    /// a dense area (e.g. Seoul) a fetch commonly gets capped at 300 places
    /// well short of a 15-20km requested radius. Comparing against the
    /// requested radius there would pass this test on a normal drag even
    /// though the newly-revealed area has no loaded data — exactly the
    /// false "nothing here" this whole feature exists to prevent.
    private func isCoveredByCurrentFetch(center: CLLocationCoordinate2D, visibleRadius: Int) -> Bool {
        guard let searchCenter = viewModel.location else { return false; };
        let shift = CLLocation(latitude: searchCenter.latitude, longitude: searchCenter.longitude)
            .distance(from: CLLocation(latitude: center.latitude, longitude: center.longitude));
        return shift + Double(visibleRadius) <= Double(viewModel.coveredRadius);
    }

    /// Over-fetches by a 1.5x margin beyond the visible half-diagonal, so a
    /// moderate drag still lands inside the already-fetched circle instead
    /// of leaving the newly-revealed corners empty. Clamped to the API's
    /// [500, 20000] range.
    private func fetchRadius(forVisibleRadius visibleRadius: Int) -> Int {
        min(maxSearchRadius, max(minSearchRadius, Int((Double(visibleRadius) * 1.5).rounded())));
    }

    /// Starts a short settle-grace `Task`, then fetches. The grace period
    /// is short (not a "debounce" against repeated `.onEnd` calls — `.onEnd`
    /// itself already only fires once per settle) — it exists purely so a
    /// fetch that's about to start can still be cancelled by the
    /// `.continuous` handler if the user immediately starts a new drag
    /// before this one's data would even be useful.
    private func scheduleAreaFetch(for region: MKCoordinateRegion, radius: Int) {
        fetchTask?.cancel();
        let center = region.center;
        fetchTask = Task {
            try? await Task.sleep(nanoseconds: 250_000_000);
            guard !Task.isCancelled else { return };

            pendingFetchIsExplicit = false;
            viewModel.location = center;
            viewModel.radius = radius;
            viewModel.fetchList();
            fetchTask = nil;
        };
    }

    /// Half the diagonal of the visible region, in meters, so a fetch built
    /// from it covers every corner of what's on screen.
    private func visibleRadiusMeters(for region: MKCoordinateRegion) -> Int {
        let halfLat = region.span.latitudeDelta / 2;
        let halfLng = region.span.longitudeDelta / 2;
        let center = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude);
        let corner = CLLocation(
            latitude: region.center.latitude + halfLat,
            longitude: region.center.longitude + halfLng
        );
        return Int(center.distance(from: corner).rounded());
    }

}
