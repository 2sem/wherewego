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
    @State private var isLaunched = false
    @State private var isFromBackground = false
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
        case .background:
            isFromBackground = true;
        case .active:
            handleAppDidBecomeActive();
        default:
            break
        }
    }

    private func handleAppDidBecomeActive() {
        let mgr = adManager;
        Task { @MainActor in
            // Increase launch count only once per cold launch (not on return from system alerts)
            if !isLaunched {
                WWGDefaults.increaseLaunchCount();
                isLaunched = true;
                if WWGDefaults.LaunchCount > 0 && WWGDefaults.LaunchCount % 90 == 0 {
                    if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                        AppStore.requestReview(in: scene);
                    }
                }
            }

            // Show launch ad only when returning from true background (not system alerts)
            if isFromBackground {
                await mgr.requestAppTrackingIfNeed();
                await mgr.show(unit: .launch);
                isFromBackground = false;
            }
        }
    }
}
