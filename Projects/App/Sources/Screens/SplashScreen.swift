import SwiftUI
import GoogleMaps

struct SplashScreen: View {
    @Binding var isDone: Bool

    var body: some View {
        ZStack {
            themeBackground()
                .ignoresSafeArea()

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(2)
        }
        .task {
            // MARK: App initialization
            // FirebaseApp.configure() is in AppDelegate — must run before any view code.
            KakaoManager.initialize();
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

    private func themeBackground() -> Color {
        switch LSThemeManager.shared.theme {
        case .summer: return Color(uiColor: LSThemeManager.MaterialColors.lightBlue._400!);
        case .xmas:   return Color(uiColor: LSThemeManager.MaterialColors.red.red400!);
        default:      return Color(uiColor: .systemBackground);
        }
    }
}
