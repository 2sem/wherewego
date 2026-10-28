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
    // Gates the location-error alert to only user-tap-initiated requests
    // (see handleLocationButtonTap) — the automatic launch-time location
    // request failing shouldn't pop an alert the user never asked for.
    @State private var isLocationButtonRequest = false
    @State private var selectedTour: KGDataTourInfo? = nil
    @State private var mapCameraPosition: MapCameraPosition = .automatic
    @State private var savedCameraPosition: MapCameraPosition? = nil
    @State private var currentRegion: MKCoordinateRegion? = nil
    @State private var requestedSpan: Double = 0.05
    // Viewport-driven fetch: shows what's actually visible on the map, not
    // just a fixed radius around "here". `showZoomInHint` covers the
    // zoomed-way-out case where computing a request radius would exceed the
    // TourAPI's 20km cap; `viewportFetchTask` is the ~250ms settle grace
    // period before firing.
    @State private var showZoomInHint = false
    @State private var viewportFetchTask: Task<Void, Never>? = nil
    // Quiet browsing: an empty result only pops the modal alert when the
    // user explicitly changed the type filter — a drag/zoom/location fetch
    // landing empty is a normal, frequent part of exploring a map and shows
    // the panel's inline "No places here" state instead. Set right before the one fetchList()
    // call that should alert, consumed (reset) the next time a fetch
    // resolves either way.
    @State private var expectingAlertOnEmpty = false
    // Nearby-places panel. `nearby` is rebuilt by refreshNearby() whenever its
    // inputs change (settled region, fetched infos, selection, GPS) — never
    // derived inside `body`, since sorting re-parses every place's fields.
    @State private var nearby = NearbyPlacesResult()
    @State private var detent: NearbyPanelDetent = .half
    @State private var favoriteIds: Set<Int> = []
    // Container size from contentBody, for the panel's detent heights, the
    // map controls' position and the selection camera offset. The initial
    // value is a typical-phone guess until the first layout pass reports.
    @State private var metrics = MapLayoutMetrics(height: UIScreen.main.bounds.height - 150, bottomInset: 34)
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("LaunchCount") private var launchCount: Int = 0
    @EnvironmentObject var adManager: SwiftUIAdManager

    // Current camera span — both lat/lon deltas, not just one. A recenter
    // used to request a square span (latitudeDelta == longitudeDelta), but
    // MapKit refits that asymmetrically to a portrait screen (~1.4x at
    // Korea's latitude), so every recenter silently zoomed out; keeping both
    // deltas preserves the aspect ratio the map actually settled on instead.
    // Remembered across launches via WWGDefaults.LastMapSpan /
    // LastMapSpanLongitude (both deltas — a lat-only square restore hits the
    // same MapKit refit drift described above). Tracks the user's live zoom
    // — updated from the .onMapCameraChange handlers on the map (not
    // handleMapSettled, so it stays current through a drag/zoom gesture),
    // but only once isLocationResolved: before launch's own camera move has
    // been applied, the map's initial .automatic country-wide framing would
    // otherwise clobber the value just restored in onScreenAppear. No range
    // control drives this anymore.
    @State private var mapSpan: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)

    private struct MapLayoutMetrics: Equatable {
        var height: CGFloat
        var bottomInset: CGFloat
    }

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
            handleLocationChange(newLoc);
        }
        .onChange(of: locationManager.isLocating) { wasLocating, isLocating in
            // A request cycle just ended (success or failure — LocationManager
            // flips isLocating false in both didUpdateLocations and
            // didFailWithError). Only a button-tap-initiated request should
            // ever surface the error alert, so consume the flag here rather
            // than leaving it set for whatever unrelated request comes next
            // (e.g. the automatic launch-time fix).
            if wasLocating && !isLocating { isLocationButtonRequest = false; }
        }
        .onChange(of: locationManager.locationErrorCount) { old, new in
            if new > old && isLocationButtonRequest { showLocationErrorAlert = true; }
        }
        .onChange(of: locationManager.authorizationStatus) { _, status in
            if status == .denied { showLocationAlert = true; }
        }
        .onChange(of: typeIndex) { _, _ in
            viewModel.selectedType = typeOptions[typeIndex].1;
            if viewModel.location != nil {
                // Only an explicit type-filter change warrants interrupting
                // the user with a modal "No Results" alert — everything else
                // (drag/zoom/location) is quiet, inline-only browsing.
                expectingAlertOnEmpty = true;
                viewModel.fetchList();
            }
        }
        .onChange(of: viewModel.isLoading) { oldValue, newValue in
            print("[TourMapScreen] isLoading changed: \(oldValue) → \(newValue), infos: \(viewModel.infos.count), total: \(viewModel.totalCount)");
            guard oldValue && !newValue else { return };
            if viewModel.infos.isEmpty && viewModel.location != nil {
                if expectingAlertOnEmpty {
                    showNoDataAlert = true;
                }
            } else {
                // First page loaded — auto-fetch remaining pages
                viewModel.fetchAllPages();
            }
            expectingAlertOnEmpty = false;
            refreshNearby();
        }
        .onChange(of: viewModel.infos.count) { _, _ in
            // If the selected place fell out of the current results (type
            // filter changed, or the search center moved far enough that it's
            // no longer nearby), drop the stale selection and its saved
            // camera position rather than leaving it pinned in the panel over
            // content that no longer matches, or letting a later deselect
            // snap back to a position from before the move.
            if let selected = selectedTour, !viewModel.infos.contains(where: { $0.id == selected.id }) {
                selectedTour = nil;
                savedCameraPosition = nil;
            }
            refreshNearby();
        }
        .onChange(of: viewModel.coveredRadius) { _, _ in refreshNearby(); }
        .onChange(of: navPath.count) { _, _ in
            // Returning from detail / favorites: hearts may have changed there.
            reloadFavorites();
        }
        .onChange(of: selectedTour?.id) { _, id in
            if let loc = selectedTour?.location {
                // Only the first selection saves the camera, so deselecting
                // after hopping between places restores the pre-selection view.
                if savedCameraPosition == nil { savedCameraPosition = mapCameraPosition; }
                // Pan only — the zoom stays, so neighboring pins remain visible.
                withAnimation(.easeInOut(duration: 0.5)) {
                    mapCameraPosition = .region(MKCoordinateRegion(
                        center: centeredCoordinate(for: loc),
                        span: currentRegion?.span ?? mapSpan
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
            refreshNearby();
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

            mapControls

            nearbyPanel
                .padding(.bottom, NearbyPanelLayout.bannerHeight)

            bannerAdView
        }
        .onGeometryChange(for: MapLayoutMetrics.self) { proxy in
            MapLayoutMetrics(height: proxy.size.height, bottomInset: proxy.safeAreaInsets.bottom)
        } action: { metrics = $0; }
    }

    // MARK: - Nearby panel

    private var panelAvailableHeight: CGFloat {
        max(0, metrics.height - NearbyPanelLayout.bannerHeight);
    }

    private func panelHeight(for detent: NearbyPanelDetent) -> CGFloat {
        NearbyPanelLayout.height(for: detent, available: panelAvailableHeight, hasSelection: selectedTour != nil);
    }

    private var panelAnimation: Animation {
        NearbyPanelLayout.animation(reduceMotion: reduceMotion);
    }

    private var nearbyContent: NearbyPanelContent {
        if showZoomInHint { return .zoomIn; }
        if !nearby.places.isEmpty { return .list; }
        if viewModel.isLoading || viewModel.location == nil { return .loading; }
        return .empty;
    }

    private var nearbyPanel: some View {
        NearbyPlacesPanel(
            places: nearby.places,
            totalCount: nearby.totalCount,
            isTruncated: nearby.isTruncated,
            content: nearbyContent,
            selectedId: selectedTour?.id,
            favoriteIds: favoriteIds,
            // Without a GPS fix the sort origin is the map center, which
            // isn't a distance the user cares about.
            showsDistance: locationManager.currentLocation != nil,
            loadedCount: viewModel.infos.count,
            pagingTotal: viewModel.totalCount,
            isPaging: viewModel.hasMorePages,
            availableHeight: panelAvailableHeight,
            detent: $detent,
            onSelect: { selectPlace($0); },
            onOpenDetails: { navigateToDetail(info: $0); },
            onToggleFavorite: { toggleFavorite($0); }
        )
    }

    /// Zoom + location controls ride the panel's top edge. Zoom +/- hides
    /// when there is no room for it, everything fades out at the large detent.
    private var mapControls: some View {
        let panelTop = panelAvailableHeight - panelHeight(for: detent);
        let topLimit: CGFloat = 60;
        let showsZoom = panelTop - 12 - topLimit >= 170;
        let controlsHeight: CGFloat = showsZoom ? 140 : 44;
        let top = max(topLimit, panelTop - 12 - controlsHeight);

        return VStack(spacing: 8) {
            if showsZoom { zoomControls; }
            locationButton
        }
        .padding(.leading, 12)
        .padding(.top, top)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .opacity(detent == .large ? 0 : 1)
        .allowsHitTesting(detent != .large)
        .animation(panelAnimation, value: detent)
        .animation(panelAnimation, value: selectedTour?.id)
    }

    private func refreshNearby() {
        let origin = locationManager.currentLocation ?? currentRegion?.center ?? viewModel.location;
        nearby = NearbyPlacesFilter.make(
            infos: viewModel.infos,
            region: currentRegion,
            selected: selectedTour,
            origin: origin
        );
    }

    private func reloadFavorites() {
        favoriteIds = Set(WWGDefaults.FavoritePlaces.compactMap { $0.id; });
    }

    private func toggleFavorite(_ info: KGDataTourInfo) {
        guard let id = info.id else { return; }
        if WWGDefaults.toggleFavorite(info) {
            favoriteIds.insert(id);
        } else {
            favoriteIds.remove(id);
        }
    }

    /// Pin or row tap: select, bring the panel to half, pan (see the
    /// selectedTour onChange). Re-selecting the selected place is a no-op.
    private func selectPlace(_ info: KGDataTourInfo) {
        guard selectedTour?.id != info.id else { return; }
        withAnimation(panelAnimation) {
            selectedTour = info;
            detent = .half;
        }
    }

    /// A user pan/zoom on the map folds a half-open panel away. Driven by
    /// gestures on the Map, not camera callbacks: those also fire for
    /// programmatic moves (selection pan, recenter, zoom buttons).
    private func collapsePanelForMapGesture() {
        guard detent == .half else { return; }
        withAnimation(panelAnimation) { detent = .collapsed; }
    }

    // MARK: - Map View

    // Markers filtered to items with a stable, non-nil id — `ForEach(..., id:
    // \.id)` needs that for stable SwiftUI identity (a nil id would collide
    // with any other nil-id item).
    private var mapMarkers: [KGDataTourInfo] {
        viewModel.infos.filter { $0.id != nil };
    }

    private var mapView: some View {
        Map(position: $mapCameraPosition) {
                // User location — always the actual GPS fix, never the search
                // center (which may be a dragged/deep-linked point far from
                // where the user actually is).
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

                // Tour markers — identity keyed on the place's own contentid
                // (not array offset), so a list change only rebuilds the
                // markers that actually changed instead of every marker.
                ForEach(mapMarkers, id: \.id) { info in
                    if let title = info.title, let location = info.location {
                        let isSelected = selectedTour?.id == info.id;
                        Annotation(title, coordinate: location) {
                            markerView(for: info, isSelected: isSelected)
                                .onTapGesture {
                                    selectPlace(info);
                                }
                        }
                    }
                }
            }
            .mapControls {
                MapCompass()
            }
            .onMapCameraChange { context in
                currentRegion = context.region;
                requestedSpan = context.region.span.latitudeDelta;
                refreshNearby();
                // Selection pans must not become the user's remembered zoom.
                // Also gated on
                // isLocationResolved — until launch's own camera move has
                // actually been applied (recenterAndFetch, or a resolved
                // denied/restricted status), this fires for the map's
                // initial .automatic country-wide framing, which would
                // otherwise clobber the zoom just restored in
                // onScreenAppear before the user ever touched the map.
                if selectedTour == nil, isLocationResolved {
                    mapSpan = context.region.span;
                }
            }
            .onMapCameraChange(frequency: .continuous) { context in
                handleMapMoving();
                // Keep mapSpan current through an in-progress drag/pinch too
                // (not just on settle) so a location-button tap right after
                // a gesture, before it settles, still uses the live zoom
                // instead of a stale one. Skip the @State write when nothing
                // actually changed. Gated on isLocationResolved for the same
                // reason as the handler above.
                if selectedTour == nil, isLocationResolved,
                   mapSpan.latitudeDelta != context.region.span.latitudeDelta
                    || mapSpan.longitudeDelta != context.region.span.longitudeDelta {
                    mapSpan = context.region.span;
                }
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                handleMapSettled(context.region);
            }
            .onTapGesture {
                withAnimation {
                    selectedTour = nil;
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 24)
                    .onChanged { _ in collapsePanelForMapGesture(); }
            )
            .simultaneousGesture(
                MagnifyGesture(minimumScaleDelta: 0.05)
                    .onChanged { _ in collapsePanelForMapGesture(); }
            )
    }

    private func markerView(for info: KGDataTourInfo, isSelected: Bool) -> some View {
        // `type` re-parses info's field dictionary on every access; with up
        // to a few hundred markers on screen, read it once per marker rather
        // than twice (color + icon).
        let type = info.type;
        return ZStack {
            // Outer ring for selected marker
            if isSelected {
                Circle()
                    .stroke(.white, lineWidth: 4)
                    .frame(width: 44, height: 44)
                    .shadow(color: .black.opacity(0.4), radius: 4)
            }

            // Background circle
            Circle()
                .fill(markerColor(for: type))
                .frame(width: isSelected ? 40 : 32, height: isSelected ? 40 : 32)
                .shadow(color: .black.opacity(0.3), radius: 3)

            // Icon
            Image(systemName: markerIcon(for: type))
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
        type.markerIconName;
    }

    private func markerColor(for type: KGDataTourInfo.ContentType) -> Color {
        type.markerColor;
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
            // TourMapScreen dropped the range picker entry point (map extent
            // now comes purely from the visible viewport) — kept only so
            // this switch stays exhaustive for TourNavDestination, which
            // legacy TourListScreen still navigates to.
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

        mapSpan = initialMapSpan();
        reloadFavorites();

        // Seed the launch camera from CLLocationManager's own cached fix,
        // read synchronously — skips the country-wide `.automatic` framing
        // entirely when one is available, landing straight on the restored
        // zoom around (approximately) where the user actually is. No
        // animation — this is the map's starting position, not a move.
        // Not a fetch trigger: fetching stays with the real fix, via
        // handleLocationChange → recenterAndFetch once it lands (same
        // mapSpan, so the zoom itself doesn't change — just a small center
        // shift from cached to fresh coordinate). With no cached fix (fresh
        // install / first authorization), mapCameraPosition is left at
        // `.automatic`, same as before; the isLocationResolved gate on the
        // mapSpan-updating onMapCameraChange handlers still protects
        // against that framing clobbering the restored mapSpan.
        if let cached = locationManager.lastKnownLocation {
            mapCameraPosition = .region(MKCoordinateRegion(center: cached, span: mapSpan));
        }

        // Handle deep link that arrived before screen was ready
        if let id = DeepLinkManager.shared.contentId {
            navPath.append(.tourInfoById(id, DeepLinkManager.shared.srcLocation));
            DeepLinkManager.shared.consume();
        }
    }

    /// The camera span to open with, before any real settle has recorded
    /// one of its own: the remembered last zoom if there is one (both
    /// deltas, via WWGDefaults.LastMapSpan / LastMapSpanLongitude — scaled
    /// down together, preserving their aspect ratio, if the saved zoom is
    /// past the "zoom in" hint cutoff), otherwise a square span derived from
    /// whichever is available next: a legacy latitude-only save (from
    /// before longitude was persisted), or the legacy range picker's
    /// persisted value (existing users land back where their old
    /// fixed-radius search used to be), falling back to ~3km for a fresh
    /// install. Either way it's clamped so the very first view is never
    /// already past the "zoom in" hint cutoff.
    private func initialMapSpan() -> MKCoordinateSpan {
        let hintCutoffSpan = spanForRadius(zoomInHintRadiusMeters);

        if let savedLat = WWGDefaults.LastMapSpan, let savedLon = WWGDefaults.LastMapSpanLongitude {
            if savedLat > hintCutoffSpan {
                let scale = hintCutoffSpan / savedLat;
                return MKCoordinateSpan(latitudeDelta: savedLat * scale, longitudeDelta: savedLon * scale);
            }
            return MKCoordinateSpan(latitudeDelta: savedLat, longitudeDelta: savedLon);
        }

        if let savedLat = WWGDefaults.LastMapSpan {
            let clamped = min(savedLat, hintCutoffSpan);
            return MKCoordinateSpan(latitudeDelta: clamped, longitudeDelta: clamped);
        }

        let fallback = min(spanForRadius(Double(WWGDefaults.Range)), hintCutoffSpan);
        return MKCoordinateSpan(latitudeDelta: fallback, longitudeDelta: fallback);
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
        // Route/share source: GPS is home base, falling back to the search
        // center only when GPS is unavailable (denied/restricted/no fix yet).
        navPath.append(.tourInfo(info, locationManager.currentLocation ?? viewModel.location));
    }

    /// Shifts the camera center below `loc` so the place lands in the middle
    /// of the map area visible above the panel, at the current zoom. Uses the
    /// panel's height for the current detent (selection has already moved it
    /// to half by the time this runs).
    private func centeredCoordinate(for loc: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let mapHeight = metrics.height + metrics.bottomInset;
        guard mapHeight > 0 else { return loc; }

        let latitudeDelta = currentRegion?.span.latitudeDelta ?? mapSpan.latitudeDelta;
        let panelTop = panelAvailableHeight - panelHeight(for: detent);

        // How far the middle of the uncovered map sits above the map center.
        let offsetPoints = mapHeight / 2 - panelTop / 2;
        let latOffset = Double(offsetPoints / mapHeight) * latitudeDelta;

        return CLLocationCoordinate2D(latitude: loc.latitude - latOffset, longitude: loc.longitude);
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

    /// The location button's tap handler. Unlike `handleLocationChange`
    /// (driven by `.onChange(of: locationManager.currentLocation)`), this
    /// does not depend on the coordinate actually changing — `.onChange`
    /// never fires when `didUpdateLocations` reports the same coordinate
    /// (CLLocationCoordinate2D is Equatable), which otherwise leaves the
    /// button looking dead when the user hasn't moved or a cached fix comes
    /// back unchanged. So this always recenters + fetches explicitly off
    /// the last-known fix (never a silent no-op while stationary); if a
    /// genuinely new fix lands afterward, handleLocationChange recenters +
    /// fetches again for it.
    private func handleLocationButtonTap() {
        guard locationManager.authorizationStatus != .denied,
              locationManager.authorizationStatus != .restricted else {
            // Already denied — asking again silently does nothing; surface
            // the same alert used for the deny transition instead.
            showLocationAlert = true;
            return;
        }

        isLocationButtonRequest = true;

        // Clear the saved camera position BEFORE deselecting: the
        // selectedTour?.id onChange below restores savedCameraPosition on
        // deselect, and that stale restore would otherwise immediately
        // clobber the recenter this tap is about to perform.
        savedCameraPosition = nil;
        selectedTour = nil;

        if let loc = locationManager.currentLocation {
            recenterAndFetch(loc);
        }
        locationManager.requestLocation();
    }

    private func handleLocationChange(_ newLoc: CLLocationCoordinate2D?) {
        guard let loc = newLoc else { return };
        refreshNearby();
        recenterAndFetch(loc);
    }

    private func recenterAndFetch(_ loc: CLLocationCoordinate2D) {
        viewModel.location = loc;
        // Clamp to the zoom-in hint cutoff so recentering never lands more
        // zoomed out than that — landing past it would immediately trigger
        // the "zoom in" hint instead of showing results. Scale both deltas
        // together (rather than forcing a square span) so the aspect ratio
        // the map last settled on is preserved — see mapSpan's comment.
        var span = mapSpan;
        let maxLatDelta = spanForRadius(zoomInHintRadiusMeters);
        if span.latitudeDelta > maxLatDelta {
            let scale = maxLatDelta / span.latitudeDelta;
            span = MKCoordinateSpan(
                latitudeDelta: span.latitudeDelta * scale,
                longitudeDelta: span.longitudeDelta * scale
            );
        }
        mapCameraPosition = .region(MKCoordinateRegion(center: loc, span: span));
        viewModel.fetchList();
    }

    private func handleDeepLink(_ newId: Int?) {
        guard let id = newId else { return };
        navPath.append(.tourInfoById(id, DeepLinkManager.shared.srcLocation));
        DeepLinkManager.shared.consume();
    }

    // MARK: - Viewport fetch

    /// True once the first GPS fix has landed, or authorization has resolved
    /// to denied/restricted. Gates handleMapSettled so a "Zoom in" flash
    /// can't appear before launch's own location flow has had a chance to
    /// run, while denied/restricted users — who never get a fix — can still
    /// browse by dragging the map.
    private var isLocationResolved: Bool {
        locationManager.currentLocation != nil
            || locationManager.authorizationStatus == .denied
            || locationManager.authorizationStatus == .restricted;
    }

    private func distanceMeters(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
        CLLocation(latitude: a.latitude, longitude: a.longitude)
            .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude));
    }

    /// Half the diagonal of `region`, in meters — the radius of the smallest
    /// circle centered on the region that still covers every visible corner.
    private func halfDiagonalMeters(of region: MKCoordinateRegion) -> Double {
        let center = region.center;
        let corner = CLLocationCoordinate2D(
            latitude: center.latitude + region.span.latitudeDelta / 2,
            longitude: center.longitude + region.span.longitudeDelta / 2
        );
        return distanceMeters(center, corner);
    }

    /// Approximate inverse of halfDiagonalMeters: the latitude/longitude
    /// delta (used equally for both, as everywhere else in this screen)
    /// whose half-diagonal is about `radiusMeters`, evaluated at a fixed
    /// Korea-wide reference latitude. Precision doesn't matter here — it
    /// only seeds the very first camera position before any real settle has
    /// recorded an actual span via WWGDefaults.LastMapSpan /
    /// LastMapSpanLongitude.
    private func spanForRadius(_ radiusMeters: Double) -> Double {
        let metersPerDegreeLat = 111_320.0;
        let refLatitudeRadians = 37.5 * Double.pi / 180;
        let metersPerDegreeLon = metersPerDegreeLat * cos(refLatitudeRadians);
        let metersPerDegreeDiagonal = (metersPerDegreeLat + metersPerDegreeLon) / 2 * 2.0.squareRoot();
        return 2 * radiusMeters / metersPerDegreeDiagonal;
    }

    /// Past this visible radius, the "zoom in to see places" hint shows
    /// instead of fetching — fetching a whole province's worth of pins into
    /// a phone-sized screen isn't useful even though the TourAPI would
    /// technically allow it up to 20km.
    private let zoomInHintRadiusMeters: Double = 10000;

    /// Cancels the pending viewport fetch and clears any stale "zoom in"
    /// hint the instant the camera starts moving again, rather
    /// than waiting for it to settle — so a hint computed for the position
    /// being left doesn't linger through the drag/zoom that's about to
    /// invalidate it. Guarded so this never writes @State on every frame,
    /// only when there's actually something pending or visible to clear.
    private func handleMapMoving() {
        if viewportFetchTask != nil {
            viewportFetchTask?.cancel();
            viewportFetchTask = nil;
        }
        if showZoomInHint {
            showZoomInHint = false;
        }
    }

    /// Called when the map camera settles (`.onMapCameraChange(frequency:
    /// .onEnd)`). Fetches whatever is now visible, after a short grace
    /// period, unless: the view is zoomed out past zoomInHintRadiusMeters
    /// (shows a "zoom in" hint instead), a card is open, or the visible area
    /// is already inside what's been fetched — recentering or deselecting
    /// moves the camera back over already-covered ground, so this coverage
    /// check is what keeps those from re-fetching without needing a
    /// separate "was this programmatic" flag.
    private func handleMapSettled(_ region: MKCoordinateRegion) {
        guard isLocationResolved else { return };
        guard selectedTour == nil else { return };

        // Persist this as the user's current zoom level regardless of what
        // happens below (hint vs. fetch vs. already-covered) — it's still a
        // real, deliberate camera position, just not always one that needs
        // a network call. mapSpan itself is kept live by the
        // .onMapCameraChange handlers on the map, not here. Both deltas are
        // saved (not just latitude) so a relaunch can restore the exact
        // aspect ratio instead of a square span MapKit would refit wider.
        WWGDefaults.LastMapSpan = region.span.latitudeDelta;
        WWGDefaults.LastMapSpanLongitude = region.span.longitudeDelta;

        let visibleRadius = halfDiagonalMeters(of: region);

        guard visibleRadius <= zoomInHintRadiusMeters else {
            showZoomInHint = true;
            return;
        }
        showZoomInHint = false;

        let newCenter = region.center;
        if let center = viewModel.location {
            let coveredRadius = Double(viewModel.coveredRadius);
            if distanceMeters(center, newCenter) + visibleRadius <= coveredRadius {
                return;
            }
        }

        let candidateRadius = min(20000, max(500, Int((visibleRadius * 1.5).rounded())));

        viewportFetchTask?.cancel();
        viewportFetchTask = Task {
            try? await Task.sleep(nanoseconds: 250_000_000);
            guard !Task.isCancelled else { return };
            viewModel.location = newCenter;
            viewModel.radius   = candidateRadius;
            viewModel.fetchList();
        }
    }

}
