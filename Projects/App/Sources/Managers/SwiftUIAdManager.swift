import UIKit
import Combine
import GADManager
import GoogleMobileAds

class SwiftUIAdManager: NSObject, ObservableObject {
    private var gadManager: GADManager<GADUnitName>!
    var canShowFirstTime = true

    static var shared: SwiftUIAdManager?
    @Published var isReady: Bool = false

    func setup() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }

        let adManager = GADManager<GADUnitName>(window)
        self.gadManager = adManager
        adManager.delegate = self

        SwiftUIAdManager.shared = self
        self.isReady = true
    }

    func prepare(interstitialUnit unit: GADUnitName, interval: TimeInterval) {
        gadManager?.prepare(interstitialUnit: unit, isTesting: self.isTesting(unit: unit), interval: interval)
    }

    func prepare(openingUnit unit: GADUnitName, interval: TimeInterval) {
        gadManager?.prepare(openingUnit: unit, isTesting: self.isTesting(unit: unit), interval: interval)
    }

    @MainActor
    @discardableResult
    func show(unit: GADUnitName) async -> Bool {
        await withCheckedContinuation { continuation in
            guard let gadManager else {
                continuation.resume(returning: false)
                return
            }

            gadManager.show(unit: unit, isTesting: self.isTesting(unit: unit)) { _, _, result in
                continuation.resume(returning: result)
            }
        }
    }

    // MARK: - Testing

    func isTesting(unit: GADUnitName) -> Bool {
        return testUnits.contains(unit)
    }

    func requestPermission(completion: @escaping (Bool) -> Void) {
        guard let gadManager else {
            completion(false)
            return
        }

        gadManager.requestPermission { status in
            completion(status == .authorized)
        }
    }

    @discardableResult
    func requestAppTrackingIfNeed() async -> Bool {
        guard !WWGDefaults.AdsTrackingRequested else {
            debugPrint(#function, "Already requested")
            return false
        }

        guard WWGDefaults.LaunchCount > 1 else {
            debugPrint(#function, "GAD requestPermission", "LaunchCount", WWGDefaults.LaunchCount)
            return false
        }

        return await withCheckedContinuation { continuation in
            self.requestPermission { granted in
                WWGDefaults.AdsTrackingRequested = true
                continuation.resume(returning: granted)
            }
        }
    }
}

// MARK: - GADManagerDelegate

extension SwiftUIAdManager: GADManagerDelegate {
    typealias E = GADUnitName

    func GAD<E>(manager: GADManager<E>, lastPreparedTimeForUnit unit: E) -> Date {
        return WWGDefaults.LastOpeningAdPrepared
    }

    func GAD<E>(manager: GADManager<E>, updateLastPreparedTimeForUnit unit: E, preparedTime time: Date) {
        WWGDefaults.LastOpeningAdPrepared = time
    }

    func GAD<E>(manager: GADManager<E>, lastShownTimeForUnit unit: E) -> Date {
        let now = Date()
        if WWGDefaults.LastFullADShown > now {
            WWGDefaults.LastFullADShown = now
        }
        return WWGDefaults.LastFullADShown
    }

    func GAD<E>(manager: GADManager<E>, updatShownTimeForUnit unit: E, showTime time: Date) {
        WWGDefaults.LastFullADShown = time
    }
}
