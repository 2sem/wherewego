import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    @Binding var isVisible: Bool

    func makeUIView(context: Context) -> GADBannerView {
        let bannerView = GADBannerView()
        bannerView.adSize = GADAdSizeBanner
        bannerView.adUnitID = (Bundle.main.infoDictionary?["GADUnitIdentifiers"] as? [String: String])?["BottomBanner"]
        bannerView.delegate = context.coordinator
        bannerView.load(GADRequest())
        return bannerView
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(isVisible: $isVisible)
    }

    class Coordinator: NSObject, GADBannerViewDelegate {
        let isVisible: Binding<Bool>

        init(isVisible: Binding<Bool>) {
            self.isVisible = isVisible
        }

        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            isVisible.wrappedValue = true
        }

        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
            isVisible.wrappedValue = false
        }
    }
}
