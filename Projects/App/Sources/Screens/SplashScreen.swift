import SwiftUI


struct SplashScreen: View {
    @Binding var isDone: Bool

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(2)
        }
        .task {
            // MARK: App initialization
            // FirebaseApp.configure() is in AppDelegate — must run before any view code.
            KakaoManager.initialize();

            try? await Task.sleep(for: .seconds(1));

            withAnimation {
                isDone = true;
            }
        }
    }
}
