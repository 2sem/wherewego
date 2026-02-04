import SwiftUI
import GoogleMaps
import Firebase

struct SplashScreen: View {
    @Binding var isDone: Bool

    var body: some View {
        ZStack {
            Color(LSThemeManager.shared.theme == .default ? .systemBackground : (LSThemeManager.shared.theme == .summer ? .init(uiColor: LSThemeManager.MaterialColors.lightBlue._400!) : .init(uiColor: LSThemeManager.MaterialColors.red.red400!)))
                .ignoresSafeArea()

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(2)
        }
        .task {
            // MARK: App initialization (moved from AppDelegate.didFinishLaunchingWithOptions)
            KakaoManager.initialize();
            FirebaseApp.configure();
            GMSServices.provideAPIKey("AIzaSyDb9V5xnYItUag4fy_yhXWmmDum0iIgBXY");

            LSRemoteConfig.shared.fetch { (config, error) in
                LSThemeManager.shared.theme = config.theme;
            };

            // Small delay to let RemoteConfig settle
            try? await Task.sleep(for: .seconds(1));

            withAnimation {
                isDone = true;
            }
        }
    }
}
