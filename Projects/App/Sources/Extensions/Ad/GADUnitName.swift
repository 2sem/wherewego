extension SwiftUIAdManager {
    enum GADUnitName: String {
        case full         = "FullAd"
        case launch       = "Launch"
        case homeBanner   = "HomeBanner"
        case detailBanner = "DetailBanner"
        case mapBanner    = "MapBanner"
        case rewardAd     = "RewardAd"
    }

#if DEBUG
    var testUnits: [GADUnitName] {
        [.full, .launch, .homeBanner, .detailBanner, .mapBanner, .rewardAd]
    }
#else
    var testUnits: [GADUnitName] { [] }
#endif
}
