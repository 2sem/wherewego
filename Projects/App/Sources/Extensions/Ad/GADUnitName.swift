extension SwiftUIAdManager {
    enum GADUnitName: String {
        case full         = "FullAd"
        case launch       = "Launch"
        case bottomBanner = "BottomBanner"
        case rewardAd     = "RewardAd"
    }

#if DEBUG
    var testUnits: [GADUnitName] {
        [.full, .launch, .bottomBanner, .rewardAd]
    }
#else
    var testUnits: [GADUnitName] { [] }
#endif
}
