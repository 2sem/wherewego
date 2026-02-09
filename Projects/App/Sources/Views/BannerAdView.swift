import SwiftUI
import GoogleMobileAds

struct BannerAdView: View {
    let unitName: SwiftUIAdManager.GADUnitName

    @EnvironmentObject private var adManager: SwiftUIAdManager
    @State private var coordinator = BannerAdCoordinator()

    var body: some View {
        Group {
            if let bannerView = coordinator.bannerView {
                BannerAdRepresentable(bannerView: bannerView)
            } else {
                Color.clear.frame(height: 0)
            }
        }
        .onChange(of: adManager.isReady, initial: true) { _, isReady in
            print("[BannerAdView] Manager is ready? \(isReady)")
            guard isReady else {
                print("[BannerAdView] Manager is not ready")
                return
            }
            coordinator.load(withAdManager: adManager, unitName: unitName)
        }.task {
            guard adManager.isReady else {
                return
            }

            coordinator.load(withAdManager: adManager, unitName: unitName)
        }
    }
}

@Observable
final class BannerAdCoordinator: NSObject, BannerViewDelegate {
    var bannerView: BannerView?
    private var hasLoaded = false

    func load(withAdManager manager: SwiftUIAdManager, unitName: SwiftUIAdManager.GADUnitName) {
        guard !hasLoaded else { return }

        print("[BannerAdCoordinator] Creating banner view for \(unitName.rawValue)...")

        if let banner = manager.createBannerAdView(withAdSize: AdSizeBanner, forUnit: unitName) {
            print("[BannerAdCoordinator] Banner created, setting delegate and loading...")
            banner.delegate = self
            self.bannerView = banner
            self.hasLoaded = true
            let request = Request()
            banner.load(request)
        } else {
            print("[BannerAdCoordinator] Failed to create banner view")
        }
    }

    // MARK: - BannerViewDelegate

    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        print("[BannerAdCoordinator] ✅ Ad loaded successfully")
    }

    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        print("[BannerAdCoordinator] ❌ Ad failed to load: \(error.localizedDescription)")
    }

    func bannerViewDidRecordImpression(_ bannerView: BannerView) {
        print("[BannerAdCoordinator] Ad impression recorded")
    }

    func bannerViewWillPresentScreen(_ bannerView: BannerView) {
        print("[BannerAdCoordinator] Ad will present screen")
    }

    func bannerViewWillDismissScreen(_ bannerView: BannerView) {
        print("[BannerAdCoordinator] Ad will dismiss screen")
    }

    func bannerViewDidDismissScreen(_ bannerView: BannerView) {
        print("[BannerAdCoordinator] Ad did dismiss screen")
    }
}

private struct BannerAdRepresentable: UIViewRepresentable {
    let bannerView: BannerView

    func makeUIView(context: Context) -> BannerView {
        print("[BannerAdRepresentable] makeUIView called")
        return bannerView
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        // Nothing to update
    }
}
