import SwiftUI
import CoreLocation

// MARK: - Navigation destination

enum TourNavDestination: Hashable {
    case tourInfo(KGDataTourInfo, CLLocationCoordinate2D?)
    case tourInfoById(Int, CLLocationCoordinate2D?)
    case imageViewer(URL)
    case rangePicker

    // Hashable conformance — CLLocationCoordinate2D is not Hashable by default
    static func == (lhs: TourNavDestination, rhs: TourNavDestination) -> Bool {
        switch (lhs, rhs) {
        case (.tourInfo(let a, let b), .tourInfo(let c, let d)):
            return a == c && coordEqual(b, d);
        case (.tourInfoById(let a, let b), .tourInfoById(let c, let d)):
            return a == c && coordEqual(b, d);
        case (.imageViewer(let a), .imageViewer(let b)):
            return a == b;
        case (.rangePicker, .rangePicker):
            return true;
        default:
            return false;
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .tourInfo(let info, let loc):
            hasher.combine(0); hasher.combine(info.id); hashCoord(loc, &hasher);
        case .tourInfoById(let id, let loc):
            hasher.combine(1); hasher.combine(id); hashCoord(loc, &hasher);
        case .imageViewer(let url):
            hasher.combine(2); hasher.combine(url);
        case .rangePicker:
            hasher.combine(3);
        }
    }
}

private func coordEqual(_ a: CLLocationCoordinate2D?, _ b: CLLocationCoordinate2D?) -> Bool {
    guard let a = a, let b = b else { return a == nil && b == nil };
    return a.latitude == b.latitude && a.longitude == b.longitude;
}

private func hashCoord(_ coord: CLLocationCoordinate2D?, _ hasher: inout Hasher) {
    if let c = coord {
        hasher.combine(c.latitude);
        hasher.combine(c.longitude);
    }
}

// MARK: - Screen

struct TourListScreen: View {
    @State private var locationManager = LocationManager()
    @State private var viewModel = TourListViewModel()
    @State private var navPath: [TourNavDestination] = []
    @State private var typeIndex: Int = 0          // 0 = All, 1… = ContentType
    @State private var showLocationAlert = false
    @State private var isBannerVisible = false
    @State private var showReviewAlert = false
    @AppStorage("LaunchCount") private var launchCount: Int = 0
    @EnvironmentObject var adManager: SwiftUIAdManager

    // Range picker bindings — written back when picker pops
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
            VStack(spacing: 0) {
                // Type filter
                Picker("Type", selection: $typeIndex) {
                    ForEach(typeOptions.indices) { i in
                        Text(typeOptions[i].0).tag(i);
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 6)
                .background(themeNavBarColor())

                // List
                List {
                    ForEach(viewModel.infos.indices, id: \.self) { index in
                        let info = viewModel.infos[index];
                        TourCellView(info: info)
                            .onAppear {
                                // Infinite scroll: 2 rows before end
                                if index == viewModel.infos.count - 2 {
                                    viewModel.fetchNextPage();
                                }
                            }
                            .onTapGesture {
                                showInterstitialThenNavigate(info: info)
                            }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await viewModel.refresh();
                }
                .overlay {
                    if viewModel.infos.isEmpty && !viewModel.isLoading {
                        Text("No data available in a current range.\nIncrease range or move the marker to another place.\nCheck if the marker or you are in Korea.".localized())
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                }

                // Banner ad
                if launchCount > 1 {
                    BannerAdView(isVisible: $isBannerVisible)
                        .frame(maxWidth: .infinity, height: isBannerVisible ? 50 : 0)
                }
            }
            .background(themeNavBarColor())
            // MARK: Navigation destinations
            .navigationDestination(for: TourNavDestination.self) { dest in
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
            .navigationBarTitle("WhereWeGo")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { locationManager.requestLocation() } label: {
                        Image(systemName: "location.fill")
                            .foregroundStyle(themeBarTintColor())
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { navPath.append(.rangePicker) } label: {
                        Text(viewModel.radius.stringForDistance())
                            .foregroundStyle(themeBarTintColor())
                            .font(.system(size: 14))
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(themeNavBarColor(), for: .navigationBar)
            .toolbarForegroundStyle(themeBarTintColor(), for: .navigationBar)
        }
        // Location denied alert
        .alert("\"WhereWeGo\" needs to use your location".localized(), isPresented: $showLocationAlert) {
            Button("Settings".localized()) {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!);
            }
            Button("Ok".localized()) {}
        } message: {
            Text("This app will not work without the location permission.".localized())
        }
        // Review alert
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
        // Startup + location flow
        .onAppear { onScreenAppear(); }
        .onChange(of: locationManager.currentLocation) { _, newLoc in
            guard let loc = newLoc else { return };
            viewModel.location = loc;
            pickerLocation = loc;
            viewModel.fetchList();
        }
        .onChange(of: locationManager.authorizationStatus) { _, status in
            if status == .denied { showLocationAlert = true; }
        }
        .onChange(of: typeIndex) { _, _ in
            viewModel.selectedType = typeOptions[typeIndex].1;
            if viewModel.location != nil { viewModel.fetchList(); }
        }
        // Deep link
        .onChange(of: DeepLinkManager.shared.contentId) { _, newId in
            guard let id = newId else { return };
            navPath.append(.tourInfoById(id, DeepLinkManager.shared.srcLocation));
            DeepLinkManager.shared.consume();
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
        // pickerLocation / pickerRadius were updated via bindings
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

    private func showInterstitialThenNavigate(info: KGDataTourInfo) {
        let mgr = adManager
        Task { @MainActor in
            await mgr.show(unit: .full)
            navPath.append(.tourInfo(info, viewModel.location))
        }
    }

    // MARK: - Theme colors

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
}
