import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    @Binding var isVisible: Bool

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView()
        bannerView.adSize = AdSizeBanner
        bannerView.adUnitID = (Bundle.main.infoDictionary?["GADUnitIdentifiers"] as? [String: String])?["BottomBanner"]
        bannerView.delegate = context.coordinator
        bannerView.load(Request())
        return bannerView
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(isVisible: $isVisible)
    }

    class Coordinator: NSObject, BannerViewDelegate {
        let isVisible: Binding<Bool>

        init(isVisible: Binding<Bool>) {
            self.isVisible = isVisible
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            isVisible.wrappedValue = true
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: any Error) {
            isVisible.wrappedValue = false
        }
    }
}
