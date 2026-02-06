import SwiftUI

import Firebase
import GoogleMobileAds
import StoreKit

@main
struct WhereWeGoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        FirebaseApp.configure();
    }

    @State private var isSplashDone = false
    @State private var isSetupDone = false
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var adManager = SwiftUIAdManager()

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isSplashDone {
                    MainScreen()
                }

                if !isSplashDone {
                    SplashScreen(isDone: $isSplashDone)
                        .transition(.opacity)
                }
            }
            .environmentObject(adManager)
            .onOpenURL { url in
                guard url.scheme?.starts(with: "kakao") ?? false else { return }
                DeepLinkManager.shared.handleURL(url)
            }
            .task {
                setupAds()
            }
            .onChange(of: scenePhase) { _, newPhase in
                handleScenePhaseChange(newPhase)
            }
        }
    }

    // MARK: - AdMob

    private func setupAds() {
        guard !isSetupDone else { return }
        isSetupDone = true

        let mgr = adManager
        MobileAds.shared.start { _ in
            mgr.setup()
            MobileAds.shared.requestConfiguration.testDeviceIdentifiers = ["8a00796a760e384800262e0b7c3d08fe"]

            #if DEBUG
            // mgr.prepare(interstitialUnit: .full, interval: 60.0)
            mgr.prepare(openingUnit: .launch, interval: 60.0)
            #else
            // mgr.prepare(interstitialUnit: .full, interval: 60.0 * 60.0 * 3.0)
            mgr.prepare(openingUnit: .launch, interval: 60.0 * 5.0)
            #endif
            mgr.canShowFirstTime = true
        }
    }

    // MARK: - Scene phase

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            handleAppDidBecomeActive()
        default:
            break
        }
    }

    private func handleAppDidBecomeActive() {
        let mgr = adManager
        Task { @MainActor in
            defer { WWGDefaults.increaseLaunchCount() }
            await mgr.requestAppTrackingIfNeed()
            await mgr.show(unit: .launch)

            if WWGDefaults.LaunchCount > 0 && WWGDefaults.LaunchCount % 90 == 0 {
                SKStoreReviewController.requestReview()
            }
        }
    }
}
