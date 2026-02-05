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

                // Row 2: map (1/3 screen height)
                if let dest = resolvedInfo?.location, let src = currentLocation {
                    Map(initialPosition: .region(regionFitting(src, dest))) {
                        Marker("Here", coordinate: src)
                            .foregroundStyle(.blue)
                        Marker(resolvedInfo?.title ?? "", coordinate: dest)
                            .foregroundStyle(.red)
                    }
                    .frame(height: UIScreen.main.bounds.height / 3)
                    .mapControls {
                        MapCompass()
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

    private func regionFitting(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> MKCoordinateRegion {
        let center = CLLocationCoordinate2D(
            latitude: (a.latitude + b.latitude) / 2,
            longitude: (a.longitude + b.longitude) / 2
        );
        let latSpan = max(abs(a.latitude - b.latitude) * 1.4, 0.005);
        let lonSpan = max(abs(a.longitude - b.longitude) * 1.4, 0.005);
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
